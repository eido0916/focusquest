"""Build the 35-frame FocusQuest swordsman skill animation, Sousen.

This keeps the supplied source files untouched and reuses the battle sprite
extractor's alpha-component segmentation and waist/foot alignment.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw


SHEET_SCALE = 0.5
SHEET_COLUMNS = 5
FRAME_TIMES_MS = [
    *([70] * 5),
    *([90] * 5),
    *([100] * 5),
    *([90] * 5),
    *([55] * 3),
    *([120] * 2),
    180,
    *([140] * 2),
    *([100] * 2),
    *([70] * 5),
]
DAMAGE_FRAME = 23
EFFECT_FRAMES = set(range(21, 26))


def _load_extractor():
    source = Path(__file__).with_name("build-swordsman-run-attack.py")
    spec = importlib.util.spec_from_file_location("swordsman_sprite_extractor", source)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load sprite extractor: {source}")
    module = importlib.util.module_from_spec(spec)
    # Dataclasses resolve forward references through sys.modules.
    import sys

    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def _checker(size: tuple[int, int], square: int = 16) -> Image.Image:
    width, height = size
    image = Image.new("RGBA", size, (238, 231, 213, 255))
    draw = ImageDraw.Draw(image)
    for y in range(0, height, square):
        for x in range(0, width, square):
            if (x // square + y // square) % 2:
                draw.rectangle(
                    (x, y, x + square - 1, y + square - 1),
                    fill=(211, 202, 184, 255),
                )
    return image


def _remove_overlap_contamination(canvas: Image.Image, frame_index: int) -> Image.Image:
    """Remove pixels visibly belonging to a neighbouring montage pose.

    Two supplied sheets contain poses whose sword/cape pixels overlap. Alpha
    connectivity alone cannot infer the original layer at those intersections,
    so these tiny, audited regions are removed by colour/region without
    redrawing or changing the character artwork.
    """
    rgba = np.asarray(canvas).copy()
    red = rgba[:, :, 0].astype(np.int16)
    green = rgba[:, :, 1].astype(np.int16)
    blue = rgba[:, :, 2].astype(np.int16)
    height, width = rgba.shape[:2]
    yy, xx = np.indices((height, width))
    alpha = rgba[:, :, 3]
    chroma = np.maximum.reduce([red, green, blue]) - np.minimum.reduce(
        [red, green, blue]
    )

    blue_fabric = (
        (rgba[:, :, 3] > 0)
        & (blue > red + 12)
        & (blue > green + 8)
        & (blue >= 55)
    )
    if frame_index == 23:
        overlap = (xx >= 480) & (yy >= 430)
        alpha[overlap & (blue_fabric | (chroma >= 45))] = 0
    elif frame_index == 24:
        overlap = (xx >= 520) & (yy >= 470)
        alpha[overlap & (blue_fabric | (chroma >= 45))] = 0
        # Previous pose's blade entering from the left edge.
        polygon = Image.new("1", (width, height))
        ImageDraw.Draw(polygon).polygon(
            [(112, 452), (235, 497), (228, 527), (104, 480)], fill=1
        )
        alpha[np.asarray(polygon, dtype=bool)] = 0
    elif frame_index == 26:
        alpha[(xx >= 565) & (yy >= 470) & blue_fabric] = 0
    elif frame_index == 27:
        # Previous pose's blade below the left boot.
        polygon = Image.new("1", (width, height))
        ImageDraw.Draw(polygon).polygon(
            [(145, 537), (270, 584), (253, 616), (137, 566)], fill=1
        )
        alpha[np.asarray(polygon, dtype=bool)] = 0
    return Image.fromarray(rgba, "RGBA")


def build(sources: list[Path], output: Path) -> dict[str, object]:
    if len(sources) != 7:
        raise ValueError("Exactly seven chronological source PNGs are required")
    for source in sources:
        if not source.is_file():
            raise FileNotFoundError(source)

    extractor = _load_extractor()
    extracted = []
    diagnostics = []
    for source in sources:
        frames, source_diagnostics = extractor.extract_actors(
            source, expected_actors=5
        )
        if len(frames) != 5:
            raise RuntimeError(f"Expected five actors in {source}, got {len(frames)}")
        extracted.extend(frames)
        diagnostics.append(source_diagnostics)

    margin = extractor.FRAME_MARGIN
    left = max(frame.anchor[0] for frame in extracted) + margin
    right = max(frame.pixels.width - frame.anchor[0] for frame in extracted) + margin
    above = max(frame.anchor[1] for frame in extracted) + margin
    below = max(frame.pixels.height - frame.anchor[1] for frame in extracted) + margin
    frame_width = extractor._round_up(left + right)
    frame_height = extractor._round_up(above + below)
    anchor_x = left
    anchor_y = above

    output.mkdir(parents=True, exist_ok=True)
    frames_dir = output / "frames"
    frames_dir.mkdir(parents=True, exist_ok=True)
    aligned: list[Image.Image] = []
    frame_records: list[dict[str, object]] = []
    elapsed_ms = 0
    for index, frame in enumerate(extracted, start=1):
        canvas = Image.new("RGBA", (frame_width, frame_height))
        source_anchor_x, source_anchor_y = frame.anchor
        paste_x = anchor_x - source_anchor_x
        paste_y = anchor_y - source_anchor_y
        canvas.alpha_composite(frame.pixels, (paste_x, paste_y))
        canvas = _remove_overlap_contamination(canvas, index)
        filename = f"sousen_{index:02d}.png"
        canvas.save(frames_dir / filename, optimize=True)
        aligned.append(canvas)
        frame_records.append(
            {
                "index": index,
                "file": f"frames/{filename}",
                "source": frame.source,
                "sourceBbox": list(frame.source_bbox),
                "sourceAnchor": {"x": frame.waist_x, "y": frame.foot_y},
                "canvasOffset": {"x": paste_x, "y": paste_y},
                "durationMs": FRAME_TIMES_MS[index - 1],
                "startMs": elapsed_ms,
                "damage": index == DAMAGE_FRAME,
                "effect": index in EFFECT_FRAMES,
            }
        )
        elapsed_ms += FRAME_TIMES_MS[index - 1]

    game_width = round(frame_width * SHEET_SCALE)
    game_height = round(frame_height * SHEET_SCALE)
    rows = (len(aligned) + SHEET_COLUMNS - 1) // SHEET_COLUMNS
    sheet = Image.new("RGBA", (game_width * SHEET_COLUMNS, game_height * rows))
    preview_width = 560
    preview_scale = min(preview_width / frame_width, 0.56)
    preview_size = (
        round(frame_width * preview_scale),
        round(frame_height * preview_scale),
    )
    preview_frames: list[Image.Image] = []
    for index, frame in enumerate(aligned):
        game_frame = frame.resize((game_width, game_height), Image.Resampling.LANCZOS)
        sheet.alpha_composite(
            game_frame,
            (
                (index % SHEET_COLUMNS) * game_width,
                (index // SHEET_COLUMNS) * game_height,
            ),
        )
        preview = _checker(preview_size)
        preview.alpha_composite(frame.resize(preview_size, Image.Resampling.LANCZOS))
        preview_frames.append(
            preview.convert("P", palette=Image.Palette.ADAPTIVE, colors=255)
        )

    sheet_name = "swordsman_sousen_spritesheet.png"
    sheet.save(output / sheet_name, optimize=True)
    # GIF stores delays in 10 ms units. Alternate 50/60 ms for the 55 ms
    # strike frames so the preview stays within 5 ms of the runtime duration.
    preview_durations_ms = list(FRAME_TIMES_MS)
    preview_durations_ms[20:23] = [50, 60, 60]
    preview_frames[0].save(
        output / "swordsman_sousen_preview.gif",
        save_all=True,
        append_images=preview_frames[1:],
        duration=preview_durations_ms,
        loop=0,
        disposal=2,
        optimize=False,
    )

    contact = _checker((preview_size[0] * SHEET_COLUMNS, preview_size[1] * rows))
    draw = ImageDraw.Draw(contact)
    for index, frame in enumerate(aligned):
        x = (index % SHEET_COLUMNS) * preview_size[0]
        y = (index // SHEET_COLUMNS) * preview_size[1]
        contact.alpha_composite(
            frame.resize(preview_size, Image.Resampling.LANCZOS), (x, y)
        )
        draw.rectangle((x + 6, y + 6, x + 52, y + 30), fill=(3, 24, 43, 220))
        draw.text((x + 13, y + 10), f"{index + 1:02d}", fill=(255, 225, 145, 255))
    contact.save(output / "swordsman_sousen_contact_sheet.png", optimize=True)

    damage_time_ms = frame_records[DAMAGE_FRAME - 1]["startMs"]
    metadata: dict[str, object] = {
        "image": sheet_name,
        "frameCount": 35,
        "sourceOrder": [source.name for source in sources],
        "sourceFrameSize": {"width": frame_width, "height": frame_height},
        "frameSize": {"width": game_width, "height": game_height},
        "sheet": {"columns": SHEET_COLUMNS, "rows": rows},
        "anchor": {
            "x": anchor_x / frame_width,
            "y": anchor_y / frame_height,
            "sourcePixels": {"x": anchor_x, "y": anchor_y},
        },
        "animation": {
            "name": "swordsmanSousen",
            "displayName": "蒼閃",
            "loop": False,
            "durationMs": sum(FRAME_TIMES_MS),
            "damageFrame": DAMAGE_FRAME,
            "damageTimeMs": damage_time_ms,
            "effectFrames": sorted(EFFECT_FRAMES),
            "stepTimesMs": FRAME_TIMES_MS,
        },
        "frames": frame_records,
        "extraction": diagnostics,
    }
    (output / "swordsman_sousen_spritesheet.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    return metadata


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, action="append", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    metadata = build(args.source, args.output)
    print(
        json.dumps(
            {
                "frameCount": metadata["frameCount"],
                "sourceFrameSize": metadata["sourceFrameSize"],
                "frameSize": metadata["frameSize"],
                "durationMs": metadata["animation"]["durationMs"],
                "damageTimeMs": metadata["animation"]["damageTimeMs"],
                "output": str(args.output),
            },
            ensure_ascii=False,
            indent=2,
        )
    )


if __name__ == "__main__":
    main()
