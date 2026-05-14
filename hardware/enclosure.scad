// ═══════════════════════════════════════════════════════════
// Info-Pi · 1920×440 Ultra-wide Display Enclosure
// Parametric 3D-printable case for BOE QV101F6M-N10 panel
// + HM-V1.0B driver board + Orange Pi Zero 2W
// ═══════════════════════════════════════════════════════════
//
// Components (all measured in mm):
//   Screen:     265 × 65 × 4
//   Driver board: 72 × 50 × 4  (incl. tallest components)
//   Orange Pi Zero 2W: 65 × 30 × ~7 (incl. HDMI/USB-C port height)
//   FPC ribbon: exits screen short edge, foldable to back
//
// Print settings:
//   Wall thickness 2mm, layer 0.2mm, PETG or PLA, 20% infill
//   Recommended: M3 heat-set inserts in marked posts
//
// ═══════════════════════════════════════════════════════════

// ─── Parameters (edit these freely) ───────────────────────

// Screen physical dimensions
screen_w = 265;
screen_h = 65;
screen_t = 4;

// How much of the screen edge the front bezel covers (must hide LCD bezel)
bezel_inset = 2;   // mm inward from screen edge

// Driver board dimensions (HM-V1.0B)
board_w = 72;
board_h = 50;
board_t = 4;
board_hole_d = 2.5;   // M2.5 mounting holes (adjust to actual)
board_hole_inset = 3; // from each corner (adjust to actual)

// Orange Pi Zero 2W
pi_w = 65;
pi_h = 30;
pi_t = 7;            // includes USB-C and HDMI port height
pi_hole_d = 2.7;     // M2.5 self-tapping into post

// Enclosure margins
side_margin = 7;    // horizontal padding inside enclosure
top_margin = 7;     // vertical padding
back_clearance = 3; // air gap between screen back and tallest component

// Outer shell
front_wall = 2;     // front bezel thickness
back_wall = 2;      // back cover thickness
side_wall = 2;      // side wall thickness
inner_depth = screen_t + back_clearance + max(board_t, pi_t);
total_w = screen_w + 2 * (bezel_inset + side_wall);
total_h = screen_h + 2 * (bezel_inset + side_wall);
total_d = front_wall + inner_depth + back_wall;

// Mounting interface (VESA-style on back)
mount_hole_d = 3.2;       // through-hole for M3
mount_spacing_x = 75;     // pattern width
mount_spacing_y = 35;     // pattern height (smaller to fit 80mm height)
mount_post_h = 4;          // boss height for heat-set insert
mount_insert_d = 4.0;      // hole for M3 heat-set insert (3.5mm taper)

// Cable cutouts on bottom edge
cable_cut_w = 30;
cable_cut_h = 8;

// Echo computed sizes
echo("Total enclosure W:", total_w, "H:", total_h, "D:", total_d);

// ─── Helper modules ───────────────────────────────────────

module rounded_rect(w, h, r, depth) {
    hull() {
        translate([r, r, 0])         cylinder(d=2*r, h=depth);
        translate([w-r, r, 0])       cylinder(d=2*r, h=depth);
        translate([r, h-r, 0])       cylinder(d=2*r, h=depth);
        translate([w-r, h-r, 0])     cylinder(d=2*r, h=depth);
    }
}

// ─── Front frame ──────────────────────────────────────────

module front_frame() {
    difference() {
        // Outer shell
        rounded_rect(total_w, total_h, 4, front_wall + inner_depth + 2);
        // Display window (visible area)
        translate([side_wall + bezel_inset,
                   side_wall + bezel_inset,
                   front_wall])
            cube([screen_w - 2*bezel_inset,
                  screen_h - 2*bezel_inset,
                  screen_t + 10]);
        // Inner cavity (back removed for cover)
        translate([side_wall, side_wall, front_wall])
            cube([total_w - 2*side_wall,
                  total_h - 2*side_wall,
                  inner_depth + 5]);
    }
}

// ─── Back cover ───────────────────────────────────────────

module back_cover() {
    difference() {
        union() {
            // Outer plate
            rounded_rect(total_w, total_h, 4, back_wall);
            // Mounting posts for driver board (top center area)
            translate([0, 0, back_wall])
                board_mount_posts();
            // Mounting posts for Orange Pi (bottom center area)
            translate([0, 0, back_wall])
                pi_mount_posts();
            // VESA mount inserts in middle
            translate([0, 0, back_wall])
                vesa_mount_inserts();
        }
        // Cable cutout at bottom center
        translate([(total_w - cable_cut_w) / 2, -1, back_wall + 0])
            cube([cable_cut_w, cable_cut_h + 1, 50]);
    }
}

// Driver board posts — assume 4 corners with hole_inset from each
module board_mount_posts() {
    // Board placed in upper-right area (back view)
    bx = total_w - side_wall - board_w - 10;  // 10mm from right edge
    by = side_wall + 5;                        // 5mm from top
    pillar_h = inner_depth - board_t;
    for (cx = [board_hole_inset, board_w - board_hole_inset])
    for (cy = [board_hole_inset, board_h - board_hole_inset])
        translate([bx + cx, by + cy, 0])
            difference() {
                cylinder(d=6, h=pillar_h, $fn=20);
                translate([0, 0, pillar_h - 5])
                    cylinder(d=board_hole_d, h=6, $fn=20);
            }
}

// Pi posts — Pi placed on left side
module pi_mount_posts() {
    px = side_wall + 10;
    py = side_wall + 10;
    pillar_h = inner_depth - pi_t;
    // Orange Pi Zero 2W mounting holes are approximately at corners
    // with 60mm × 25mm spacing (offset ~2.5mm from edges)
    for (cx = [2.5, pi_w - 2.5])
    for (cy = [2.5, pi_h - 2.5])
        translate([px + cx, py + cy, 0])
            difference() {
                cylinder(d=5, h=pillar_h, $fn=20);
                translate([0, 0, pillar_h - 4])
                    cylinder(d=pi_hole_d, h=5, $fn=20);
            }
}

// VESA-style mount inserts (4 holes for M3 heat-set)
module vesa_mount_inserts() {
    cx = total_w / 2;
    cy = total_h / 2;
    for (dx = [-mount_spacing_x/2, mount_spacing_x/2])
    for (dy = [-mount_spacing_y/2, mount_spacing_y/2])
        translate([cx + dx, cy + dy, 0])
            difference() {
                cylinder(d=8, h=mount_post_h, $fn=24);
                translate([0, 0, 0.8])
                    cylinder(d=mount_insert_d, h=mount_post_h, $fn=24);
            }
}

// ─── Desk stand (detachable A-frame) ──────────────────────

module desk_stand() {
    foot_w = 100;
    foot_d = 80;
    foot_t = 4;
    tilt = 15;       // degrees backward
    height = 30;

    // Base
    translate([0, 0, 0])
        rounded_rect(foot_w, foot_d, 6, foot_t);
    // Riser arm (single column tilted back, screws into VESA mounts)
    translate([(foot_w - mount_spacing_x) / 2 - 5,
               foot_d / 2 - 5,
               foot_t])
        rotate([tilt, 0, 0])
            cube([mount_spacing_x + 10, 10, height]);
    // Top mount plate with screw holes
    translate([(foot_w - mount_spacing_x) / 2 - 5,
               foot_d / 2,
               foot_t + height])
        difference() {
            rotate([tilt, 0, 0])
                cube([mount_spacing_x + 10,
                      mount_spacing_y + 10,
                      foot_t]);
            // VESA pattern through holes
            for (dx = [0, mount_spacing_x])
            for (dy = [0, mount_spacing_y])
                translate([dx + 5, dy + 5, -1])
                    rotate([tilt, 0, 0])
                        cylinder(d=mount_hole_d, h=10, $fn=20);
        }
}

// ─── Wall mount plate ─────────────────────────────────────

module wall_mount() {
    plate_w = mount_spacing_x + 40;
    plate_h = mount_spacing_y + 60;
    plate_t = 4;
    difference() {
        rounded_rect(plate_w, plate_h, 6, plate_t);
        // Keyhole slot for hanging on wall screw
        translate([plate_w / 2, plate_h - 12, -1]) {
            cylinder(d=8, h=plate_t + 2, $fn=24);
            translate([-2, 0, 0]) cube([4, 8, plate_t + 2]);
        }
        // VESA screw holes
        for (dx = [-mount_spacing_x/2, mount_spacing_x/2])
        for (dy = [-mount_spacing_y/2, mount_spacing_y/2])
            translate([plate_w/2 + dx, plate_h/2 - 5 + dy, -1])
                cylinder(d=mount_hole_d, h=plate_t + 2, $fn=20);
    }
}

// ─── Render selector ──────────────────────────────────────
// Set `part` to render one of the parts at a time

part = "front";  // "front" | "back" | "stand" | "wall" | "all"

if (part == "front")
    color("DimGray") front_frame();
else if (part == "back")
    color("SlateGray") back_cover();
else if (part == "stand")
    color("Tan") desk_stand();
else if (part == "wall")
    color("LightGray") wall_mount();
else if (part == "all") {
    color("DimGray") front_frame();
    translate([0, 0, -back_wall - 1])
        color("SlateGray") back_cover();
    translate([total_w + 30, 0, 0])
        color("Tan") desk_stand();
    translate([total_w + 30, 100, 0])
        color("LightGray") wall_mount();
}
