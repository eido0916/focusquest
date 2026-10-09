"""Extract the supplied transparent hero sheets into articulated rig parts."""

from __future__ import annotations

import argparse
import json
from collections import deque
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageDraw


@dataclass(frozen=True)
class Part:
    name: str
    sheet: str
    box: tuple[int, int, int, int]
    pivot: tuple[float, float]
    polygon: tuple[tuple[int, int], ...] | None = None


PARTS = (
    Part("head", "hair", (150, 210, 690, 710), (0.48, 0.82),
         ((90, 75), (360, 35), (500, 150), (470, 345), (340, 475),
          (175, 445), (45, 275))),
    Part("hair_front", "hair", (735, 35, 1435, 610), (0.50, 0.72)),
    Part("hair_back", "hair", (440, 505, 1040, 1085), (0.50, 0.70)),
    Part("body", "clothes", (20, 45, 445, 325), (0.50, 0.68)),
    Part("waist", "clothes", (0, 655, 380, 1080), (0.50, 0.18)),
    Part("cape_front", "clothes", (820, 45, 1440, 625), (0.50, 0.13)),
    Part("cape_back", "clothes", (815, 535, 1445, 1085), (0.50, 0.12)),
    Part("upper_arm_r", "arms", (255, 10, 700, 525), (0.66, 0.12)),
    Part("lower_arm_r", "arms", (155, 390, 520, 855), (0.58, 0.13)),
    Part("hand_r", "arms", (145, 720, 475, 1075), (0.58, 0.14)),
    Part("upper_arm_l", "arms", (745, 10, 1195, 525), (0.34, 0.12)),
    Part("lower_arm_l", "arms", (960, 390, 1335, 855), (0.42, 0.13)),
    Part("hand_l", "arms", (1010, 720, 1375, 1075), (0.42, 0.14)),
    Part("thigh_r", "legs", (120, 15, 560, 390), (0.50, 0.12)),
    Part("shin_r", "legs", (130, 350, 560, 820), (0.50, 0.12)),
    Part("foot_r", "legs", (55, 745, 530, 1080), (0.55, 0.20)),
    Part("thigh_l", "legs", (680, 15, 1045, 390), (0.50, 0.12)),
    Part("shin_l", "legs", (665, 350, 1075, 820), (0.50, 0.12)),
    Part("foot_l", "legs", (675, 745, 1130, 1080), (0.45, 0.20)),
    Part("sword", "legs", (1080, 45, 1445, 1075), (0.50, 0.12)),
)


def extract(source: Image.Image, part: Part, padding: int = 4) -> Image.Image:
    image = source.crop(part.box).convert("RGBA")
    if part.polygon:
        mask = Image.new("L", image.size)
        ImageDraw.Draw(mask).polygon(part.polygon, fill=255)
        alpha = image.getchannel("A")
        image.putalpha(Image.composite(alpha, Image.new("L", image.size), mask))
    alpha = image.getchannel("A")
    width, height = image.size
    visible = bytearray(1 if value > 10 else 0 for value in alpha.getdata())
    seen = bytearray(width * height)
    largest: list[int] = []
    for start in range(width * height):
        if not visible[start] or seen[start]:
            continue
        seen[start] = 1
        queue = deque([start])
        component: list[int] = []
        while queue:
            index = queue.popleft()
            component.append(index)
            x, y = index % width, index // width
            for ny in range(max(0, y - 1), min(height, y + 2)):
                for nx in range(max(0, x - 1), min(width, x + 2)):
                    neighbour = ny * width + nx
                    if visible[neighbour] and not seen[neighbour]:
                        seen[neighbour] = 1
                        queue.append(neighbour)
        if len(component) > len(largest):
            largest = component
    keep = bytearray(width * height)
    for index in largest:
        keep[index] = 255
    clean_mask = Image.frombytes("L", image.size, bytes(keep))
    image.putalpha(Image.composite(alpha, Image.new("L", image.size), clean_mask))

    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise RuntimeError(f"No visible pixels for {part.name}")
    left = max(0, bbox[0] - padding)
    top = max(0, bbox[1] - padding)
    right = min(image.width, bbox[2] + padding)
    bottom = min(image.height, bbox[3] + padding)
    return image.crop((left, top, right, bottom))


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--hair", type=Path, required=True)
    parser.add_argument("--clothes", type=Path, required=True)
    parser.add_argument("--arms", type=Path, required=True)
    parser.add_argument("--legs", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    sheets = {
        "hair": Image.open(args.hair).convert("RGBA"),
        "clothes": Image.open(args.clothes).convert("RGBA"),
        "arms": Image.open(args.arms).convert("RGBA"),
        "legs": Image.open(args.legs).convert("RGBA"),
    }
    args.output.mkdir(parents=True, exist_ok=True)
    metadata = {"parts": {}}
    for part in PARTS:
        image = extract(sheets[part.sheet], part)
        filename = f"{part.name}.png"
        image.save(args.output / filename, optimize=True)
        metadata["parts"][part.name] = {
            "file": filename,
            "width": image.width,
            "height": image.height,
            "pivot": {"x": part.pivot[0], "y": part.pivot[1]},
        }

    (args.output / "rig.json").write_text(
        json.dumps(metadata, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(metadata, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
