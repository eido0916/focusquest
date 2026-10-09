"""Extract overlapping hero animation montages into Flame-ready frames.

The source art is a montage rather than a strict grid: neighbouring poses
overlap. Visual-gap splitting and edge-fragment cleanup preserve the original
pixels without a generative redraw.
"""

from __future__ import annotations

import argparse
import json
from collections import deque
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image


@dataclass(frozen=True)
class AnimationSource:
    name: str
    path: Path
    centers: tuple[int, ...]
    step_time: float
    loop: bool


def foreground_alpha(rgb: np.ndarray) -> np.ndarray:
    """Turn the near-white paper background into a soft antialiased alpha."""
    minimum = rgb.min(axis=2).astype(np.int16)
    maximum = rgb.max(axis=2).astype(np.int16)
    darkness = 255 - minimum
    chroma = maximum - minimum
    strength = np.maximum(darkness, chroma * 2).astype(np.int32)
    # Promote before multiplying; int16 overflow turns solid colours into
    # transparent holes on high-contrast source art.
    alpha = np.clip((strength - 5) * 255 / 22, 0, 255).astype(np.uint8)
    alpha[(minimum > 246) & (chroma < 7)] = 0
    return alpha


def segment_frames(source: AnimationSource) -> list[tuple[np.ndarray, tuple[int, int]]]:
    rgba = np.asarray(Image.open(source.path).convert("RGBA")).copy()
    rgb = rgba[:, :, :3]
    alpha = foreground_alpha(rgb)
    foreground = alpha > 18
    height, width = foreground.shape

    # The source is a flattened montage, so pixels hidden beneath a neighbour
    # cannot be reconstructed.  Split at the least-occupied column between
    # adjacent heads. This follows the visual gap between poses more closely
    # than a simple midpoint and avoids pulling the next runner into a frame.
    labels = np.full((height, width), -1, dtype=np.int16)
    density = foreground[320:min(height, 640)].sum(axis=0)
    boundaries = [0]
    for left, right in zip(source.centers, source.centers[1:]):
        search_left = left + min(20, max(1, (right - left) // 4))
        search_right = right - min(20, max(1, (right - left) // 4))
        boundary = int(np.argmin(density[search_left:search_right]) + search_left)
        boundaries.append(boundary)
    boundaries.append(width)
    for label, (x0, x1) in enumerate(zip(boundaries, boundaries[1:])):
        labels[:, x0:x1][foreground[:, x0:x1]] = label

        # Drop detached pieces of the neighbouring pose that enter through a
        # crop edge. Components reaching back toward this pose's head/torso
        # are retained, which preserves its cape and long sword.
        local = labels[:, x0:x1] == label
        solid = local & (alpha[:, x0:x1] > 80)
        seen = np.zeros_like(local)
        for start_y, start_x in zip(*np.nonzero(solid & ~seen)):
            if seen[start_y, start_x]:
                continue
            queue = deque([(int(start_y), int(start_x))])
            seen[start_y, start_x] = True
            component: list[tuple[int, int]] = []
            while queue:
                y, x = queue.popleft()
                component.append((y, x))
                for ny, nx in (
                    (y - 1, x - 1), (y - 1, x), (y - 1, x + 1),
                    (y, x - 1), (y, x + 1),
                    (y + 1, x - 1), (y + 1, x), (y + 1, x + 1),
                ):
                    if (0 <= ny < height and 0 <= nx < x1 - x0
                            and solid[ny, nx] and not seen[ny, nx]):
                        seen[ny, nx] = True
                        queue.append((ny, nx))
            xs = [point[1] for point in component]
            absolute_min, absolute_max = min(xs) + x0, max(xs) + x0
            from_left_neighbour = min(xs) <= 1 and absolute_max < source.centers[label] - 10
            from_right_neighbour = max(xs) >= x1 - x0 - 2 and absolute_min > source.centers[label] + 10
            if from_left_neighbour or from_right_neighbour:
                for y, x in component:
                    y_from, y_to = max(0, y - 1), min(height, y + 2)
                    x_from, x_to = max(0, x + x0 - 1), min(width, x + x0 + 2)
                    fragment = labels[y_from:y_to, x_from:x_to]
                    fragment[fragment == label] = -1

    frames: list[tuple[np.ndarray, tuple[int, int]]] = []
    for label in range(len(source.centers)):
        owned = labels == label
        ys, xs = np.nonzero(owned)
        if not len(xs):
            raise RuntimeError(f"No pixels found for {source.name} frame {label + 1}")
        x0, x1 = max(0, int(xs.min()) - 2), min(width, int(xs.max()) + 3)
        y0, y1 = max(0, int(ys.min()) - 2), min(height, int(ys.max()) + 3)
        crop = rgba[y0:y1, x0:x1].copy()
        crop_alpha = np.where(owned[y0:y1, x0:x1], alpha[y0:y1, x0:x1], 0)
        crop[:, :, 3] = crop_alpha
        frames.append((crop, (source.centers[label] - x0, int(ys.max()) - y0)))
    return frames


def round_up(value: int, unit: int = 16) -> int:
    return ((value + unit - 1) // unit) * unit


def build(run: AnimationSource, attack: AnimationSource, output: Path) -> dict:
    extracted = {run.name: segment_frames(run), attack.name: segment_frames(attack)}
    all_frames = [frame for animation in extracted.values() for frame, _ in animation]
    frame_width = round_up(max(frame.shape[1] for frame in all_frames) + 20)
    frame_height = round_up(max(frame.shape[0] for frame in all_frames) + 16)
    baseline = frame_height - 8
    columns = max(len(run.centers), len(attack.centers))

    output.mkdir(parents=True, exist_ok=True)
    sheet = Image.new("RGBA", (frame_width * columns, frame_height * 2))
    metadata: dict = {
        "image": "spritesheet.png",
        "frameSize": {"width": frame_width, "height": frame_height},
        "columns": columns,
        "rows": 2,
        "anchor": {"x": 0.5, "y": baseline / frame_height},
        "animations": {},
    }

    for row, source in enumerate((run, attack)):
        frame_dir = output / "frames" / source.name
        frame_dir.mkdir(parents=True, exist_ok=True)
        placements = []
        for index, (pixels, (foot_x, foot_y)) in enumerate(extracted[source.name]):
            frame = Image.fromarray(pixels, "RGBA")
            target_x = frame_width // 2 - foot_x
            target_y = baseline - foot_y
            canvas = Image.new("RGBA", (frame_width, frame_height))
            canvas.alpha_composite(frame, (target_x, target_y))
            filename = f"{source.name}_{index + 1:02d}.png"
            canvas.save(frame_dir / filename, optimize=True)
            sheet.alpha_composite(canvas, (index * frame_width, row * frame_height))
            placements.append({
                "file": f"frames/{source.name}/{filename}",
                "column": index,
                "row": row,
            })
        metadata["animations"][source.name] = {
            "row": row,
            "frameCount": len(source.centers),
            "stepTime": source.step_time,
            "loop": source.loop,
            "frames": placements,
        }

    sheet.save(output / "spritesheet.png", optimize=True)
    (output / "spritesheet.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return metadata


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-source", type=Path, required=True)
    parser.add_argument("--attack-source", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    metadata = build(
        AnimationSource(
            "run", args.run_source,
            (105, 222, 339, 453, 568, 684, 804, 924, 1042, 1157, 1275, 1388, 1506, 1613),
            0.075, True,
        ),
        AnimationSource(
            "attack", args.attack_source,
            (88, 185, 263, 351, 454, 536, 652, 829, 943, 1054, 1168, 1288, 1376, 1527, 1635),
            0.015, False,
        ),
        args.output,
    )
    print(json.dumps(metadata, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
