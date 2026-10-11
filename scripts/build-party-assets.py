"""Copy v010 originals without image processing; verify byte and RGBA hashes."""
from pathlib import Path
import hashlib
import json
import shutil
from PIL import Image

root = Path(__file__).resolve().parents[1]
source = root / "art/workspace_materials/FocusQuest_pixel_keyframes_v010"
target = root / "mobile/assets/images/party"
catalog = {}
verified = 0
for group in ("players", "players_female", "enemies"):
    for actor in sorted((source / group).iterdir()):
        if not actor.is_dir():
            continue
        motions = {}
        for motion in sorted(actor.iterdir()):
            metadata = motion / "animation.json"
            if not metadata.exists() or motion.name.startswith("run_then"):
                continue
            data = json.loads(metadata.read_text(encoding="utf-8"))
            if not data.get("holds"):
                continue
            destination = target / group / actor.name / motion.name
            (destination / "keyframes").mkdir(parents=True, exist_ok=True)
            for frame in data["keyframes"]:
                original = motion / frame["file"]
                copied = destination / frame["file"]
                if not copied.exists() or copied.read_bytes() != original.read_bytes():
                    shutil.copy2(original, copied)
                assert copied.read_bytes() == original.read_bytes(), copied
                with Image.open(copied) as image:
                    assert image.size == (128, 128), copied
                    digest = hashlib.sha256(image.convert("RGBA").tobytes()).hexdigest()
                    assert digest == frame["rgba_sha256"], copied
                verified += 1
            motions[motion.name] = data
        catalog[f"{group}/{actor.name}"] = motions
(target / "catalog.json").write_text(json.dumps(catalog, ensure_ascii=False), encoding="utf-8")
print(f"Verified {verified} identical 128x128 originals for {len(catalog)} actors.")
