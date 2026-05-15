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
board_h = 49;
board_t = 4;
board_hole_d = 3.0;   // M3 mounting holes

// Explicit driver board hole positions (PCB local coordinates,
// origin = top-left corner near USB connectors).
// Top edge (near USB-C / HDMI) — holes have only 0.5mm edge clearance
// to the top, so center y is 0.5 + (hole_d/2) = 2.
// Asymmetric x: left hole 6.5mm edge distance, right hole 1mm.
// Bottom 2 holes are 19mm from the same reference edge.
board_hole_pts = [
    [6.5 + board_hole_d/2,           0.5 + board_hole_d/2],          // TL (8.0,  2.0)
    [board_w - 1.0 - board_hole_d/2, 0.5 + board_hole_d/2],          // TR (69.5, 2.0)
    [6.5 + board_hole_d/2,           19.0 + board_hole_d/2],         // BL (8.0,  20.5)
    [board_w - 1.0 - board_hole_d/2, 19.0 + board_hole_d/2],         // BR (69.5, 20.5)
];

// Orange Pi Zero 2W
pi_w = 65;
pi_h = 30;
pi_t = 7;            // includes USB-C and HDMI port height
pi_hole_d = 2.7;     // M2.5 self-tapping into post

// Enclosure margins
side_margin = 7;    // horizontal padding inside enclosure
top_margin = 7;     // vertical padding
back_clearance = 3; // air gap between screen back and tallest component

// Extra Z-clearance for the internal cable plugs.
// Both Pi and driver board use Mini-HDMI female ports. A Mini-HDMI
// plug body is ~17×9×6mm — fits within the existing pi_t/board_t
// envelope but we add a small margin so the connector seats fully.
hdmi_plug_clearance = 2;  // extra mm on top of pi_t / board_t

// Outer shell
front_wall = 2;     // front bezel thickness
back_wall = 2;      // back cover thickness
side_wall = 2;      // side wall thickness
inner_depth = screen_t + back_clearance + max(board_t, pi_t) + hdmi_plug_clearance;
total_w = screen_w + 2 * (bezel_inset + side_wall);
total_h = screen_h + 2 * (bezel_inset + side_wall);
total_d = front_wall + inner_depth + back_wall;

// ─── Internal layout map ──────────────────────────────────
//
// Back view of cavity (looking at screen back from inside the case).
// Pi on the LEFT, driver board on the RIGHT. Mini-HDMI to Mini-HDMI
// short cable runs through the middle channel. External power exits
// the bottom side wall.
//
// ┌────────────────────────────────────────────────────────┐ ← top
// │  ┌──Pi──┐                              ┌──Driver──┐    │
// │  │      │ ← mini-HDMI       HDMI in →  │  72×49   │    │
// │  │ 65×30│ ←===== HDMI cable ========→  │          │    │
// │  │      │ ← USB-C out                  │  FPC ↓   │    │
// │  └──────┘                              └──────────┘    │
// │     │                                       │          │
// │     ▼ optional external power               ▼ FPC to   │
// │  (run through bottom cable cutout)        screen edge  │
// └─────────────────────┬┬─────────────────────────────────┘
//                      bottom cable opening (36×9mm)
//
// Driver board orientation: USB-C / HDMI / I2C connectors face UPWARD
// toward the top wall (since the 72mm long edge is horizontal here).
// Pi's mini-HDMI should face RIGHT toward the driver board for the
// shortest cable run.
//
// Touch FFC slot is on the RIGHT side wall, lined up with the driver
// board's 6-pin I2C connector (CN3).

// Mounting interface (VESA-style on back)
mount_hole_d = 3.2;       // through-hole for M3
mount_spacing_x = 75;     // pattern width
mount_spacing_y = 35;     // pattern height (smaller to fit 80mm height)
mount_post_h = 4;          // boss height for heat-set insert
mount_insert_d = 4.0;      // hole for M3 heat-set insert (3.5mm taper)

// Cable cutout (bottom edge of the enclosure)
// Sized for 1× Type-C power cable + 1× optional HDMI strain relief
cable_cut_w = 36;     // wide enough for Type-C + room for cable bend
cable_cut_h = 9;      // tall enough for Type-C connector body
cable_cut_offset = 0; // 0 = centered along bottom edge; +N moves right

// Touch panel FFC ribbon slot (right side wall, near driver board's
// I2C connector). Small flat slot for a future 6-pin touch ribbon.
touch_slot_w = 8;     // ribbon width + margin
touch_slot_h = 1.5;   // ribbon thickness + margin
touch_slot_z = 0;     // vertical center along the inner cavity (0 = mid)
enable_touch_slot = true;

// Echo computed sizes — useful for sanity checking
echo("Total enclosure W:", total_w, "H:", total_h, "D:", total_d);
echo("Inner cavity depth:", inner_depth);
echo("Driver board hole positions (PCB-local):", board_hole_pts);

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
    shell_depth = front_wall + inner_depth + 2;
    difference() {
        // Outer shell
        rounded_rect(total_w, total_h, 4, shell_depth);
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

        // ── Cable cutout on the BOTTOM side wall (Type-C power + HDMI) ──
        // Cuts a notch through the bottom wall into the cavity
        cut_x = (total_w - cable_cut_w) / 2 + cable_cut_offset;
        cut_z = front_wall + screen_t + 1;  // start just behind the screen
        translate([cut_x, -1, cut_z])
            cube([cable_cut_w, side_wall + 3, cable_cut_h]);
        // Bottom edge chamfer (45° outside, prevents sharp edge cutting cable)
        translate([cut_x, side_wall, cut_z + cable_cut_h])
            rotate([45, 0, 0])
                cube([cable_cut_w, 3, 3]);

        // ── Touch FFC ribbon slot on the RIGHT side wall ──
        if (enable_touch_slot) {
            slot_z_pos = front_wall + screen_t + back_clearance +
                         (max(board_t, pi_t) / 2) + touch_slot_z;
            // Cut horizontally through right side wall
            translate([total_w - side_wall - 1,
                       (total_h - touch_slot_w) / 2,
                       slot_z_pos - touch_slot_h / 2])
                cube([side_wall + 3, touch_slot_w, touch_slot_h]);
        }
    }
}

// ─── Back cover ───────────────────────────────────────────

module back_cover() {
    // Outer plate + mounting features. Cable cutouts are handled by
    // the front frame's side walls (front_frame module).
    union() {
        // Outer plate
        rounded_rect(total_w, total_h, 4, back_wall);
        // Mounting posts for driver board (right side, back view)
        translate([0, 0, back_wall])
            board_mount_posts();
        // Mounting posts for Orange Pi (left side, back view)
        translate([0, 0, back_wall])
            pi_mount_posts();
        // VESA mount inserts in middle
        translate([0, 0, back_wall])
            vesa_mount_inserts();
    }
}

// Driver board posts at the 4 explicit hole positions.
// Position the board so the USB-C/HDMI edge (top of PCB locally,
// y=0) faces DOWN in the enclosure cavity — this puts the HDMI plug
// stub in the middle of the cavity where the cable can route to the
// Pi via a right-angle (90°) HDMI cable.
module board_mount_posts() {
    // Inner cavity bounds: x in [side_wall, total_w - side_wall],
    // y in [side_wall, total_h - side_wall]
    // Driver board placed in upper-right area, with PCB y axis FLIPPED
    // so USB-C side faces DOWN (toward middle of cavity).
    bx = total_w - side_wall - board_w - 10;   // 10mm gap from right wall
    by = side_wall + 4;                         // 4mm gap from top wall
    // Flip PCB y so y=0 of PCB lands at the BOTTOM (facing cavity center)
    pillar_h = inner_depth - board_t;
    for (pt = board_hole_pts) {
        // pt[0] = PCB x (kept as-is), pt[1] = PCB y (flipped vertically)
        px = bx + pt[0];
        py = by + (board_h - pt[1]);
        translate([px, py, 0])
            difference() {
                cylinder(d=6, h=pillar_h, $fn=24);
                translate([0, 0, pillar_h - 5])
                    cylinder(d=board_hole_d, h=6, $fn=24);
            }
    }
}

// Pi posts — Pi placed on left side of cavity, vertically centered.
// Orient Pi so its mini-HDMI port (on the short edge) faces RIGHT
// toward the driver board for shortest cable path.
module pi_mount_posts() {
    px = side_wall + 10;                       // 10mm gap from left wall
    py = (total_h - pi_h) / 2;                 // vertically centered
    pillar_h = inner_depth - pi_t;
    // Orange Pi Zero 2W mounting holes ~2.5mm from each corner edge
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

// ─── Wall mount plate (slim, hangs on a single wall screw) ──

module wall_mount() {
    plate_w = mount_spacing_x + 40;
    plate_h = mount_spacing_y + 50;
    plate_t = 5;            // a little thicker for keyhole strength
    keyhole_d = 9;          // wall-screw head diameter
    keyhole_slot_w = 4.5;   // wall-screw shaft slot width
    keyhole_slot_h = 14;    // slot depth below the round hole

    difference() {
        rounded_rect(plate_w, plate_h, 8, plate_t);

        // Keyhole slot at top center (round hole + slot below for slide-down)
        translate([plate_w / 2, plate_h - 14, -1]) {
            cylinder(d=keyhole_d, h=plate_t + 2, $fn=32);
            translate([-keyhole_slot_w/2, -keyhole_slot_h, 0])
                cube([keyhole_slot_w, keyhole_slot_h, plate_t + 2]);
        }

        // Secondary screw hole at bottom center (anti-rotation pin)
        translate([plate_w / 2, 10, -1])
            cylinder(d=mount_hole_d, h=plate_t + 2, $fn=20);

        // VESA pattern through-holes — countersunk
        for (dx = [-mount_spacing_x/2, mount_spacing_x/2])
        for (dy = [-mount_spacing_y/2, mount_spacing_y/2])
            translate([plate_w/2 + dx, plate_h/2 - 4 + dy, -1]) {
                cylinder(d=mount_hole_d, h=plate_t + 2, $fn=24);
                // Countersink the back side for flat-head screws
                translate([0, 0, plate_t - 1.5])
                    cylinder(d1=mount_hole_d, d2=6, h=2, $fn=24);
            }
    }
}

// ─── Render selector ──────────────────────────────────────
// Set `part` to render one of the parts at a time

part = "all";  // "front" | "back" | "wall" | "all"

if (part == "front")
    color("DimGray") front_frame();
else if (part == "back")
    color("SlateGray") back_cover();
else if (part == "wall")
    color("LightGray") wall_mount();
else if (part == "all") {
    color("DimGray") front_frame();
    translate([0, 0, -back_wall - 1])
        color("SlateGray") back_cover();
    translate([total_w + 30, 0, 0])
        color("LightGray") wall_mount();
}
