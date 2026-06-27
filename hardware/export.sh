#!/usr/bin/env bash
# ───────────────────────────────────────────────────────────────
# Per-part manufacturing export for the Info-Pi enclosure.
# Produces, in hardware/drawings/, for each printable/machinable part:
#   <part>.stl              — solid for FDM 3D printing / CAM
#   <part>_DIM.svg          — DIMENSIONED plan shop drawing (1:1, primary)
#   <part>_DIM.pdf          — same, print-ready (if cairosvg available)
#   <part>_plan.svg / .dxf  — true-scale top (XY) outline for CAD/CAM
#   <part>_front.svg        — front (XZ) profile  (height × depth)
#   <part>_side.svg         — side  (YZ) profile  (depth)
#
# Usage:  bash export.sh
# ───────────────────────────────────────────────────────────────
set -euo pipefail
cd "$(dirname "$0")"
SRC="enclosure.scad"
DRW="drawings.scad"
OUT="drawings"
mkdir -p "$OUT"

declare -A STEM=( [front]=front_frame [back]=back_cover [wall]=wall_mount )

for p in front back wall; do
    s="${STEM[$p]}"
    echo "==> $s"
    # 3D solid for printing / CAM
    openscad -q -o "$OUT/$s.stl"  -D "part=\"$p\"" "$SRC"
    # true-scale orthographic outlines (import to CAD at 1:1)
    for v in plan front side; do
        openscad -q -o "$OUT/${s}_${v}.svg" \
                 -D "part=\"$p\"" -D draw2d=true -D "view=\"$v\"" "$SRC"
    done
    openscad -q -o "$OUT/${s}_plan.dxf" \
             -D "part=\"$p\"" -D draw2d=true -D "view=\"plan\"" "$SRC"
    # dimensioned shop drawing
    openscad -q -o "$OUT/${s}_DIM.svg" -D "sheet=\"$p\"" "$DRW"
done

# Optional: render the dimensioned sheets to print-ready PDF (vector, 1:1).
# Prefer the project venv (system python3 is PEP-668 externally-managed);
# fall back to any python3 that has cairosvg.
PY=""
for cand in "$(dirname "$0")/../venv/bin/python3" python3; do
    if "$cand" -c "import cairosvg" 2>/dev/null; then PY="$cand"; break; fi
done
if [ -n "$PY" ]; then
    echo "==> PDF (cairosvg via $PY)"
    for p in front back wall; do
        s="${STEM[$p]}"
        "$PY" -c "import cairosvg; cairosvg.svg2pdf(url='$OUT/${s}_DIM.svg', write_to='$OUT/${s}_DIM.pdf')"
    done
else
    echo "   (cairosvg not found — skipping PDF; open the *_DIM.svg in a browser and print at 100%)"
fi

echo "Done. Files in $OUT/:"
ls -1 "$OUT/"
