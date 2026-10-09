"""Build the 50-frame FocusQuest swordsman run-attack animation.

The input consists of transparent PNG montages. Each montage contains five
chronological poses. Frames are separated using alpha connected
components (not thirds), then aligned on a waist/foot anchor so weapon and cape
extents cannot make the actor jitter.
"""

from __future__ import annotations

import argparse
from collections import deque
import json
from dataclasses import dataclass
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


ALPHA_THRESHOLD = 4
FRAME_MARGIN = 12
SHEET_SCALE = 0.5
SHEET_COLUMNS = 5
HIT_FRAMES = {15, 16, 29, 30}
ACCENT_FRAMES = {14, 17, 28, 31}
NORMAL_FRAME_MS = 60
ACCENT_FRAME_MS = 88
HIT_FRAME_MS = 120


class UnionFind:
    def __init__(self) -> None:
        self.parent: list[int] = []

    def add(self) -> int:
        value = len(self.parent)
        self.parent.append(value)
        return value

    def find(self, value: int) -> int:
        root = value
        while self.parent[root] != root:
            root = self.parent[root]
        while self.parent[value] != value:
            parent = self.parent[value]
            self.parent[value] = root
            value = parent
        return root

    def union(self, left: int, right: int) -> None:
        left_root = self.find(left)
        right_root = self.find(right)
        if left_root != right_root:
            self.parent[right_root] = left_root


@dataclass
class Run:
    y: int
    x0: int
    x1: int
    label: int


@dataclass
class ExtractedFrame:
    pixels: Image.Image
    source: str
    source_bbox: tuple[int, int, int, int]
    waist_x: int
    foot_y: int

    @property
    def anchor(self) -> tuple[int, int]:
        return self.waist_x - self.source_bbox[0], self.foot_y - self.source_bbox[1]


def _row_runs(row: np.ndarray, y: int, union_find: UnionFind) -> list[Run]:
    padded = np.pad(row.astype(np.int8), (1, 1))
    changes = np.diff(padded)
    starts = np.flatnonzero(changes == 1)
    ends = np.flatnonzero(changes == -1) - 1
    return [Run(y, int(x0), int(x1), union_find.add()) for x0, x1 in zip(starts, ends)]


def connected_components(mask: np.ndarray) -> tuple[np.ndarray, list[dict[str, int]]]:
    """Label an 8-connected mask using scan-line runs."""
    height, width = mask.shape
    union_find = UnionFind()
    rows: list[list[Run]] = []
    previous: list[Run] = []

    for y in range(height):
        current = _row_runs(mask[y], y, union_find)
        previous_index = 0
        for run in current:
            while previous_index < len(previous) and previous[previous_index].x1 < run.x0 - 1:
                previous_index += 1
            candidate = previous_index
            while candidate < len(previous) and previous[candidate].x0 <= run.x1 + 1:
                union_find.union(run.label, previous[candidate].label)
                candidate += 1
        rows.append(current)
        previous = current

    root_to_label: dict[int, int] = {}
    labels = np.zeros((height, width), dtype=np.int16)
    components: list[dict[str, int]] = []
    for row in rows:
        for run in row:
            root = union_find.find(run.label)
            label = root_to_label.get(root)
            if label is None:
                label = len(components) + 1
                root_to_label[root] = label
                components.append({
                    "label": label,
                    "area": 0,
                    "x0": width,
                    "y0": height,
                    "x1": 0,
                    "y1": 0,
                })
            labels[run.y, run.x0 : run.x1 + 1] = label
            component = components[label - 1]
            length = run.x1 - run.x0 + 1
            component["area"] += length
            component["x0"] = min(component["x0"], run.x0)
            component["y0"] = min(component["y0"], run.y)
            component["x1"] = max(component["x1"], run.x1)
            component["y1"] = max(component["y1"], run.y)
    return labels, components


def _distance_to_bbox(component: dict[str, int], actor: dict[str, int]) -> float:
    x = (component["x0"] + component["x1"]) / 2
    y = (component["y0"] + component["y1"]) / 2
    dx = max(actor["x0"] - x, 0, x - actor["x1"])
    dy = max(actor["y0"] - y, 0, y - actor["y1"])
    return dx * dx + dy * dy


def _foot_y(mask: np.ndarray) -> int:
    row_counts = mask.sum(axis=1)
    substantial = np.flatnonzero(row_counts >= max(14, int(mask.shape[1] * 0.016)))
    if len(substantial):
        return int(substantial[-1])
    return int(np.flatnonzero(mask.any(axis=1))[-1])


def _waist_x(rgba: np.ndarray, mask: np.ndarray, foot_y: int) -> int:
    """Estimate the belt/pelvis centre instead of using the whole sprite bbox."""
    red = rgba[:, :, 0].astype(np.int16)
    green = rgba[:, :, 1].astype(np.int16)
    blue = rgba[:, :, 2].astype(np.int16)
    alpha = rgba[:, :, 3]
    brown = (
        (alpha > 80)
        & (red >= 42)
        & (red <= 195)
        & (green >= 18)
        & (green <= 138)
        & (blue <= 116)
        & (red > green + 12)
        & (green > blue - 8)
        & mask
    )
    y0 = max(0, foot_y - 390)
    y1 = max(y0 + 1, foot_y - 215)
    band = brown[y0:y1]
    row_counts = band.sum(axis=1)
    if int(row_counts.max(initial=0)) >= 8:
        best_y = y0 + int(np.argmax(row_counts))
        ys = slice(max(y0, best_y - 18), min(y1, best_y + 19))
        _, xs = np.nonzero(brown[ys])
        if len(xs) >= 8:
            return int(np.median(xs))

    # Fallback: median of the opaque torso/pelvis band.
    torso_y0 = max(0, foot_y - 380)
    torso_y1 = max(torso_y0 + 1, foot_y - 205)
    _, xs = np.nonzero(mask[torso_y0:torso_y1])
    if len(xs):
        return int(np.median(xs))
    return int(np.median(np.nonzero(mask)[1]))


def frame_duration_ms(index: int) -> int:
    if index in HIT_FRAMES:
        return HIT_FRAME_MS
    if index in ACCENT_FRAMES:
        return ACCENT_FRAME_MS
    return NORMAL_FRAME_MS


def _hair_seed_masks(rgba: np.ndarray, expected_actors: int) -> list[np.ndarray]:
    """Find one stable blonde-hair seed inside each horizontal actor region."""
    red = rgba[:, :, 0].astype(np.int16)
    green = rgba[:, :, 1].astype(np.int16)
    blue = rgba[:, :, 2].astype(np.int16)
    alpha = rgba[:, :, 3]
    height, width = alpha.shape
    ys = np.indices(alpha.shape)[0]
    hair = (
        (alpha > 80)
        & (ys < min(height, 420))
        & (red >= 130)
        & (green >= 70)
        & (green <= 230)
        & (blue <= 190)
        & (red > green + 8)
        & (green > blue + 8)
    )
    hair_labels, components = connected_components(hair)
    candidates = [
        component
        for component in components
        if component["area"] >= 350
        and 24 <= component["x1"] - component["x0"] + 1 <= 165
        and 24 <= component["y1"] - component["y0"] + 1 <= 220
    ]

    seeds: list[np.ndarray] = []
    slot_width = width / expected_actors
    for actor_index in range(expected_actors):
        slot_x0 = actor_index * slot_width
        slot_x1 = (actor_index + 1) * slot_width
        in_slot = [
            component
            for component in candidates
            if slot_x0
            <= (component["x0"] + component["x1"]) / 2
            < slot_x1
        ]
        if not in_slot:
            raise RuntimeError(f"Could not find hair seed for actor {actor_index + 1}")
        chosen = min(
            in_slot,
            key=lambda component: (
                abs((component["y0"] + component["y1"]) / 2 - 270),
                abs((component["x1"] - component["x0"] + 1) - 105),
                -component["area"],
            ),
        )
        seeds.append(hair_labels == chosen["label"])
    return seeds


def _split_component(
    component_mask: np.ndarray,
    seed_masks: list[np.ndarray],
    actor_indexes: list[int],
) -> np.ndarray:
    """Geodesically divide touching actors without slicing swords or capes."""
    ys, xs = np.nonzero(component_mask)
    x0, x1 = int(xs.min()), int(xs.max()) + 1
    y0, y1 = int(ys.min()), int(ys.max()) + 1
    local_mask = component_mask[y0:y1, x0:x1]
    owner = np.full(local_mask.shape, -1, dtype=np.int8)
    queue: deque[int] = deque()
    local_width = owner.shape[1]

    for actor_index in actor_indexes:
        seed = seed_masks[actor_index][y0:y1, x0:x1] & local_mask
        seed_ys, seed_xs = np.nonzero(seed)
        owner[seed_ys, seed_xs] = actor_index
        queue.extend((seed_ys * local_width + seed_xs).tolist())

    while queue:
        encoded = queue.popleft()
        y, x = divmod(encoded, local_width)
        actor_index = owner[y, x]
        for ny in range(max(0, y - 1), min(owner.shape[0], y + 2)):
            for nx in range(max(0, x - 1), min(owner.shape[1], x + 2)):
                if local_mask[ny, nx] and owner[ny, nx] < 0:
                    owner[ny, nx] = actor_index
                    queue.append(ny * local_width + nx)

    result = np.full(component_mask.shape, -1, dtype=np.int8)
    result[y0:y1, x0:x1] = owner
    return result


def _actor_masks(
    rgba: np.ndarray,
    labels: np.ndarray,
    components: list[dict[str, int]],
    expected_actors: int,
) -> tuple[list[np.ndarray], str]:
    meaningful = [component for component in components if component["area"] >= 24]
    if len(meaningful) >= expected_actors:
        actors = sorted(
            meaningful, key=lambda item: item["area"], reverse=True
        )[:expected_actors]
        actors.sort(key=lambda item: (item["x0"] + item["x1"]) / 2)
        assigned_labels: list[set[int]] = [{actor["label"]} for actor in actors]
        actor_label_set = {actor["label"] for actor in actors}
        for component in meaningful:
            if component["label"] in actor_label_set:
                continue
            closest = min(
                range(expected_actors),
                key=lambda index: _distance_to_bbox(component, actors[index]),
            )
            assigned_labels[closest].add(component["label"])
        return [
            np.isin(labels, list(component_labels))
            for component_labels in assigned_labels
        ], "alpha-components"

    seed_masks = _hair_seed_masks(rgba, expected_actors)
    seed_centres: list[tuple[float, float]] = []
    for seed in seed_masks:
        ys, xs = np.nonzero(seed)
        seed_centres.append((float(xs.mean()), float(ys.mean())))

    masks = [np.zeros(labels.shape, dtype=bool) for _ in range(expected_actors)]
    for component in meaningful:
        component_mask = labels == component["label"]
        owners = [
            index
            for index, seed in enumerate(seed_masks)
            if np.any(seed & component_mask)
        ]
        if len(owners) == 1:
            masks[owners[0]] |= component_mask
        elif len(owners) > 1:
            split = _split_component(component_mask, seed_masks, owners)
            for actor_index in owners:
                masks[actor_index] |= split == actor_index
        else:
            centre_x = (component["x0"] + component["x1"]) / 2
            centre_y = (component["y0"] + component["y1"]) / 2
            closest = min(
                range(expected_actors),
                key=lambda index: (
                    (centre_x - seed_centres[index][0]) ** 2
                    + (centre_y - seed_centres[index][1]) ** 2
                ),
            )
            masks[closest] |= component_mask
    return masks, "alpha-geodesic"


def extract_actors(
    path: Path, expected_actors: int
) -> tuple[list[ExtractedFrame], dict[str, object]]:
    image = Image.open(path).convert("RGBA")
    rgba = np.asarray(image)
    labels, components = connected_components(rgba[:, :, 3] > ALPHA_THRESHOLD)
    actor_masks, segmentation = _actor_masks(
        rgba, labels, components, expected_actors
    )

    frames: list[ExtractedFrame] = []
    diagnostics: list[dict[str, object]] = []
    for actor_index, actor_mask in enumerate(actor_masks):
        ys, xs = np.nonzero(actor_mask)
        x0 = max(0, int(xs.min()) - FRAME_MARGIN)
        y0 = max(0, int(ys.min()) - FRAME_MARGIN)
        x1 = min(image.width, int(xs.max()) + FRAME_MARGIN + 1)
        y1 = min(image.height, int(ys.max()) + FRAME_MARGIN + 1)
        frame_rgba = rgba[y0:y1, x0:x1].copy()
        frame_rgba[:, :, 3] = np.where(
            actor_mask[y0:y1, x0:x1], frame_rgba[:, :, 3], 0
        )
        foot_y = _foot_y(actor_mask)
        waist_x = _waist_x(rgba, actor_mask, foot_y)
        frames.append(ExtractedFrame(
            pixels=Image.fromarray(frame_rgba, "RGBA"),
            source=path.name,
            source_bbox=(x0, y0, x1, y1),
            waist_x=waist_x,
            foot_y=foot_y,
        ))
        diagnostics.append({
            "actor": actor_index + 1,
            "bbox": [x0, y0, x1, y1],
            "waist": [waist_x, foot_y],
        })
    return frames, {
        "source": path.name,
        "segmentation": segmentation,
        "actors": diagnostics,
    }


def _round_up(value: int, unit: int = 16) -> int:
    return ((value + unit - 1) // unit) * unit


def _checker(size: tuple[int, int], square: int = 16) -> Image.Image:
    width, height = size
    background = Image.new("RGBA", size, (238, 231, 213, 255))
    draw = ImageDraw.Draw(background)
    for y in range(0, height, square):
        for x in range(0, width, square):
            if (x // square + y // square) % 2:
                draw.rectangle((x, y, x + square - 1, y + square - 1), fill=(211, 202, 184, 255))
    return background


def build(sources: list[Path], output: Path) -> dict[str, object]:
    if len(sources) != 10:
        raise ValueError("Exactly ten chronological source PNGs are required")

    extracted: list[ExtractedFrame] = []
    source_diagnostics: list[dict[str, object]] = []
    for source in sources:
        source_frames, diagnostics = extract_actors(source, expected_actors=5)
        extracted.extend(source_frames)
        source_diagnostics.append(diagnostics)

    left = max(frame.anchor[0] for frame in extracted) + FRAME_MARGIN
    right = max(frame.pixels.width - frame.anchor[0] for frame in extracted) + FRAME_MARGIN
    above = max(frame.anchor[1] for frame in extracted) + FRAME_MARGIN
    below = max(frame.pixels.height - frame.anchor[1] for frame in extracted) + FRAME_MARGIN
    frame_width = _round_up(left + right)
    frame_height = _round_up(above + below)
    anchor_x = left
    anchor_y = above

    output.mkdir(parents=True, exist_ok=True)
    frames_dir = output / "frames"
    frames_dir.mkdir(parents=True, exist_ok=True)
    aligned: list[Image.Image] = []
    frame_records: list[dict[str, object]] = []
    for index, frame in enumerate(extracted, start=1):
        canvas = Image.new("RGBA", (frame_width, frame_height))
        frame_anchor_x, frame_anchor_y = frame.anchor
        paste_x = anchor_x - frame_anchor_x
        paste_y = anchor_y - frame_anchor_y
        canvas.alpha_composite(frame.pixels, (paste_x, paste_y))
        filename = f"attack_{index:02d}.png"
        canvas.save(frames_dir / filename, optimize=True)
        aligned.append(canvas)
        frame_records.append({
            "index": index,
            "file": f"frames/{filename}",
            "source": frame.source,
            "sourceBbox": list(frame.source_bbox),
            "sourceAnchor": {"x": frame.waist_x, "y": frame.foot_y},
            "canvasOffset": {"x": paste_x, "y": paste_y},
            "durationMs": frame_duration_ms(index),
            "hit": index in HIT_FRAMES,
            "accent": index in ACCENT_FRAMES,
        })

    sheet_frame_width = round(frame_width * SHEET_SCALE)
    sheet_frame_height = round(frame_height * SHEET_SCALE)
    sheet_rows = (len(aligned) + SHEET_COLUMNS - 1) // SHEET_COLUMNS
    sheet = Image.new(
        "RGBA",
        (sheet_frame_width * SHEET_COLUMNS, sheet_frame_height * sheet_rows),
    )
    preview_frames: list[Image.Image] = []
    preview_width = 720
    preview_scale = min(preview_width / frame_width, 0.55)
    preview_size = (round(frame_width * preview_scale), round(frame_height * preview_scale))
    for index, frame in enumerate(aligned):
        game_frame = frame.resize(
            (sheet_frame_width, sheet_frame_height), Image.Resampling.LANCZOS
        )
        sheet.alpha_composite(
            game_frame,
            ((index % SHEET_COLUMNS) * sheet_frame_width,
             (index // SHEET_COLUMNS) * sheet_frame_height),
        )
        preview = _checker(preview_size)
        preview.alpha_composite(frame.resize(preview_size, Image.Resampling.LANCZOS))
        preview_frames.append(preview.convert("P", palette=Image.Palette.ADAPTIVE, colors=255))

    sheet_name = "swordsman_attack_spritesheet.png"
    sheet.save(output / sheet_name, optimize=True)
    preview_frames[0].save(
        output / "swordsman_run_attack_preview.gif",
        save_all=True,
        append_images=preview_frames[1:],
        duration=[frame_duration_ms(index) for index in range(1, 51)],
        loop=0,
        disposal=2,
        optimize=False,
    )

    contact = _checker((preview_size[0] * SHEET_COLUMNS, preview_size[1] * sheet_rows))
    draw = ImageDraw.Draw(contact)
    for index, frame in enumerate(aligned):
        x = (index % SHEET_COLUMNS) * preview_size[0]
        y = (index // SHEET_COLUMNS) * preview_size[1]
        contact.alpha_composite(frame.resize(preview_size, Image.Resampling.LANCZOS), (x, y))
        draw.rectangle((x + 6, y + 6, x + 52, y + 30), fill=(3, 24, 43, 220))
        draw.text((x + 13, y + 10), f"{index + 1:02d}", fill=(255, 225, 145, 255))
    contact.save(output / "swordsman_run_attack_contact_sheet.png", optimize=True)

    durations = [record["durationMs"] for record in frame_records]
    metadata: dict[str, object] = {
        "image": sheet_name,
        "frameCount": 50,
        "sourceOrder": [source.name for source in sources],
        "sourceFrameSize": {"width": frame_width, "height": frame_height},
        "frameSize": {"width": sheet_frame_width, "height": sheet_frame_height},
        "sheet": {"columns": SHEET_COLUMNS, "rows": sheet_rows},
        "anchor": {
            "x": anchor_x / frame_width,
            "y": anchor_y / frame_height,
            "sourcePixels": {"x": anchor_x, "y": anchor_y},
        },
        "animation": {
            "name": "swordsmanRunAttack",
            "loop": False,
            "durationMs": sum(durations),
            "hitFrames": sorted(HIT_FRAMES),
            "accentFrames": sorted(ACCENT_FRAMES),
            "stepTimesMs": durations,
        },
        "frames": frame_records,
        "extraction": source_diagnostics,
    }
    (output / "swordsman_attack_spritesheet.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    return metadata


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--source",
        type=Path,
        action="append",
        required=True,
        help="Chronological source PNG. Pass exactly ten times.",
    )
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    metadata = build(args.source, args.output)
    print(json.dumps({
        "frameCount": metadata["frameCount"],
        "sourceFrameSize": metadata["sourceFrameSize"],
        "frameSize": metadata["frameSize"],
        "durationMs": metadata["animation"]["durationMs"],
        "output": str(args.output),
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
