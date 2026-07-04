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

# Cooler (heat pipe + stock heatsink). NOT a printed part — the primary
# output is the bend/routing template (DIM sheet). The heat pipe and the
# heatsink are two SEPARATE physical parts (pipe epoxied into the heatsink
# groove), so they are emitted as separate label-free reference STLs — a
# merged mesh can't be told apart. A combined STL is kept for context.
echo "==> heat_pipe_cooler"
openscad -q -o "$OUT/hold_down_clamp.stl"     -D 'part="evaporator"' -D NO_LABELS=1 "$SRC"
openscad -q -o "$OUT/heat_pipe.stl"           -D 'part="pipe"'       -D NO_LABELS=1 "$SRC"
openscad -q -o "$OUT/condenser.stl"           -D 'part="heatsink"'   -D NO_LABELS=1 "$SRC"
openscad -q -o "$OUT/heat_pipe_cooler.stl"    -D 'part="cooler"'     -D NO_LABELS=1 "$SRC"
openscad -q -o "$OUT/heat_pipe_cooler_DIM.svg" -D 'sheet="cooler"' "$DRW"

# Optional: render the dimensioned sheets to print-ready PDF (vector, 1:1).
# Prefer the project venv (system python3 is PEP-668 externally-managed);
# fall back to any python3 that has cairosvg.
PY=""
for cand in "$(dirname "$0")/../venv/bin/python3" python3; do
    if "$cand" -c "import cairosvg" 2>/dev/null; then PY="$cand"; break; fi
done
if [ -n "$PY" ]; then
    echo "==> PDF (cairosvg via $PY)"
    for s in front_frame back_cover wall_mount heat_pipe_cooler; do
        "$PY" -c "import cairosvg; cairosvg.svg2pdf(url='$OUT/${s}_DIM.svg', write_to='$OUT/${s}_DIM.pdf')"
    done
else
    echo "   (cairosvg not found — skipping PDF; open the *_DIM.svg in a browser and print at 100%)"
fi

echo "Done. Files in $OUT/:"
ls -1 "$OUT/"
