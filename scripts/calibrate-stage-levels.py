"""Run the real Dart combat source without Flutter's UI notification overhead.

Usage: python scripts/calibrate-stage-levels.py /absolute/path/to/dart.exe
The Flutter calibration test remains the reference implementation of the audit.
"""
from pathlib import Path
import re
import subprocess
import sys

repo = Path(__file__).resolve().parent.parent
mobile = repo / "mobile"
generated = mobile / ".tmp" / "calibration"
generated.mkdir(parents=True, exist_ok=True)
for name in ("playable_stage_battle.dart", "playable_stage_catalog.dart", "playable_character.dart"):
    source = (mobile / "lib/features/playable_stage/domain" / name).read_text(encoding="utf-8")
    if name == "playable_stage_battle.dart":
        source = source.replace("import 'package:flutter/foundation.dart';", "")
        source = source.replace("extends ChangeNotifier", "extends SimulationNotifier")
        source += "\nclass SimulationNotifier { void notifyListeners() {} void dispose() {} }\n"
    (generated / name).write_text(source, encoding="utf-8")
source = (mobile / "test/stage_recommendation_simulation_test.dart").read_text(encoding="utf-8")
source = source.replace("import 'package:flutter_test/flutter_test.dart';", "")
source = re.sub(r"import 'package:focusquest/features/playable_stage/domain/(.*?)';", r"import '\1';", source)
start = source.index("  test(")
body = source.index("    final report", start)
source = source[:start] + "  (() {\n" + source[body:]
source = re.sub(r"expect\(ready\(high\), isTrue,\s*reason: '\$\{stage.number\}/\$\{hero.id\}'\);", "if (!ready(high)) throw StateError('Cannot calibrate');", source)
source = source.replace("expect(level, lessThan(512));", "if (level >= 512) throw StateError('No attainable recommendation');")
source = source[:source.index("  },\n      timeout:")] + "  })();\n}\n"
(generated / "main.dart").write_text(source, encoding="utf-8")
subprocess.run([sys.argv[1], "run", str(generated / "main.dart")], cwd=mobile, check=True)
