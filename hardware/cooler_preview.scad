// ═══════════════════════════════════════════════════════════
// Standalone preview — heat-pipe cooler ONLY (no enclosure).
// Open this file directly in OpenSCAD (no -D needed): it pulls in the
// cooler modules from enclosure.scad and draws just those, with the
// enclosure's own part dispatch suppressed (via DRAW_SHEET).
// ═══════════════════════════════════════════════════════════
DRAW_SHEET = "cooler_preview";   // suppress enclosure.scad's own render
include <enclosure.scad>;
$fn = 48;

// The three cooler pieces. Comment out evaporator_block() if you want
// strictly the heat pipe + finned heatsink.
evaporator_block();   // 吸热盘  cold plate (SoC end)
heat_pipe_model();    // 热管    bent heat pipe
fin_stack_model();    // 散热器  finned condenser
