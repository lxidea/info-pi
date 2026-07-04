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

// Driver board hole positions (in enclosure-placement coordinates,
// origin = bottom-left of the board AS PLACED in the cavity).
//
// IMPORTANT: The driver board is mounted ROTATED 180° in-plane from
// its native orientation, so its HDMI/USB-C connectors face the
// OUTER right wall of the enclosure (away from Pi), and the FPC
// connector + I2C touch header face the cavity CENTER / BOTTOM.
//
// Native PCB hole positions (HDMI/USB on left short edge):
//   [2.0, 8.5], [51.5, 8.5], [2.0, 46.5], [51.5, 46.5]
//
// After 180° rotation (x, y) → (board_w - x, board_h - y):
//   [2.0, 8.5]   → [70.0, 40.5]
//   [51.5, 8.5]  → [20.5, 40.5]
//   [2.0, 46.5]  → [70.0, 2.5]
//   [51.5, 46.5] → [20.5, 2.5]
//
// In the rotated frame:
//   - x = 70 holes are now NEAR the HDMI/USB-C edge (RIGHT short edge,
//     facing outer wall). Hole-to-edge = 2mm.
//   - x = 20.5 holes are now near the FPC edge (LEFT short edge,
//     facing cavity center / Pi side). ~20mm gap for FPC connector.
//   - y = 40.5 (was "near top") is now NEAR the BOTTOM long edge.
//   - y = 2.5 (was "near bottom") is now NEAR the TOP long edge.
//   - I2C touch header that was on the top long edge of native PCB
//     is now on the BOTTOM long edge of the placed driver board.
board_hole_pts = [
    [70.0, 40.5],   // BR (placed) — near HDMI, bottom-right
    [20.5, 40.5],   // BL (placed) — near FPC, bottom-left
    [70.0, 2.5],    // TR (placed) — near USB-C, top-right
    [20.5, 2.5],    // TL (placed) — near FPC, top-left
];

// Orange Pi Zero 2W — mounted VERTICALLY in enclosure so HDMI port
// (which sits on Pi's LONG edge) faces RIGHT toward driver board.
//
// IMPORTANT: Pi is mounted with its COMPONENT SIDE FACING THE SCREEN
// (front), NOT the back cover. On Orange Pi Zero 2W the SoC + USB-C +
// Mini-HDMI + GPIO all share ONE side (the "component side"); only the
// SPI-NOR flash + WiFi module live on the back. With the component side
// toward the screen, the SoC and connectors sit in the gap between the
// PCB and the SCREEN, and the bare PCB back faces the back cover.
//
// THERMAL DESIGN — heat pipe (the SoC can no longer press the back cover):
//   Because the SoC faces the screen, the old "press a heatsink into a
//   metal back cover" path is gone. Instead a flattened heat-pipe
//   evaporator clamps onto the SoC on the FRONT face and carries its
//   heat out to a finned condenser + blower in the open centre strip
//   (see the Heat-pipe active cooler section below). The back cover only
//   carries the blower intake grille + fin chamber — it is no longer the
//   primary radiator, so it can stay plastic.
//
// Pi post height: pillar_h in pi_mount_posts() lifts the PCB so the
// front-face stack (SoC + evaporator + connectors) clears the screen and
// the bare PCB back clears the back cover. pi_t budgets that stack.
pi_long = 65;        // long axis (will be vertical in enclosure)
pi_short = 30;       // short axis (will be horizontal in enclosure)
pi_t = 8;            // PCB (1.4) + chip (1.5) + heatsink (5) = 7.9, rounded
                     // up to 8 for thermal-pad tolerance. This determines
                     // pillar_h_p so the heatsink presses against the
                     // (ideally metal) back cover.
pi_hole_d = 2.7;     // M2.5 self-tapping into post
pi_hole_inset = 2.5; // typical inset from each corner

// Enclosure margins
side_margin = 7;    // horizontal padding inside enclosure
top_margin = 7;     // vertical padding

// Air gap between the SCREEN and the tallest front-facing component.
// Both boards now sit low (against the back cover) with their components
// facing the screen, so this 1mm is the clearance between the tallest
// front feature (the SoC heat-pipe evaporator / the connector bodies) and
// the screen back. See board_back_gap below.
back_clearance = 1;

// Board mounting height: both the Pi and the driver board sit on SHORT
// posts so their PCB backs hug the back cover, leaving the full remaining
// depth on the SCREEN side for the (now front-facing) components — SoC +
// evaporator + connectors. This is what keeps the evaporator from poking
// into the screen. The gap only needs to clear the bare PCB-back parts
// (Pi: WiFi module ~1.5mm + SPI flash; driver: mostly bare).
board_back_gap = 2;   // PCB back face → back-cover inner surface

// HDMI plug clearance — set to 0 now that connectors are positioned
// at PCB edge with the plug body protruding sideways out of the
// HDMI socket (not vertically). The 22mm right-wall gap handles
// the 90° plug body horizontally.
hdmi_plug_clearance = 0;

// Outer shell
front_wall = 2;     // front bezel thickness
back_wall = 2;      // back cover thickness
side_wall = 2;      // side wall thickness
inner_depth = screen_t + back_clearance + max(board_t, pi_t) + hdmi_plug_clearance;
total_w = screen_w + 2 * (bezel_inset + side_wall);
total_h = screen_h + 2 * (bezel_inset + side_wall);
total_d = front_wall + inner_depth + back_wall;

// PCB mounting plane measured from the FRONT outer face (the front_frame
// is printed/cut in its own coordinate, z=0 at the front bezel surface).
// With both boards lowered onto board_back_gap posts, any side-wall slot
// that aligns to a PCB-edge feature (microSD card, touch FFC ribbon)
// references this plane so it tracks the board height automatically.
pcb_nom_t = 1.5;
pcb_plane_front = total_d - back_wall - board_back_gap - pcb_nom_t/2;

// ─── Internal layout map (FINAL) ──────────────────────────
//
// All SCAD coordinates use the BACK VIEW (looking at the screen back
// from inside the cavity). User-facing descriptions may use FRONT
// VIEW (mirrored): "left from front" = "right from back" and vice
// versa. Top/bottom are the same in both views.
//
// Pi Zero 2W: native 65×30mm, mounted VERTICALLY in enclosure after a
// 90° CW rotation from its native landscape layout.
//   Native top long edge → enclosure RIGHT long edge:
//                            USB-C, USB-C, Mini-HDMI (top → bottom)
//   Native right short edge → enclosure BOTTOM short edge: microSD
//   Native left short edge  → enclosure TOP short edge: aux FFC
//   Native bottom long edge → enclosure LEFT long edge: 40-pin GPIO
//
// Driver board: 72×49mm, mounted HORIZONTALLY at RIGHT side of cavity
// (back view), rotated 180° in-plane from native, so that its
// HDMI/USB-C connectors face the OUTER right wall and its FPC +
// I2C connectors face the cavity center / bottom.
//   Right short edge (49mm side): Mini-HDMI + USB-C — faces outer wall
//   Left short edge: FPC ribbon connector → screen (back-folded ribbon)
//   Bottom long edge (72mm side, after rotation): 6-pin I2C touch
//
// ┌──────────────────────────────────────────────────────────────────┐ top
// │                                                                  │
// │  ┌────────┐                                                      │
// │  │  Pi    │ ←USB-C                                               │
// │  │ 30×65  │ ←USB-C        ┌── Driver 72×49 ──┐                   │
// │  │ vert.  │ ←HDMI ┐       │ FPC←      HDMI →→│ ← 90° HDMI cable  │
// │  │ (CW)   │       └──── 90° HDMI cable ──────┘                   │
// │  │        │               │                  │                   │
// │  │ GPIO ← │               │ ↓ I2C            │  ~22mm gap        │
// │  └────────┘               └──────────────────┘  (HDMI plug body) │
// │     ║║                                  ║║                       │
// │   SD slot                          touch-FFC ║║                  │
// └────────────────────┬┬────────────────────────────────────────────┘
//                  external Type-C power (bottom wall, centered)
//
// HDMI cable: short Mini-HDMI cable with at least one 90° angled
// plug (driver-side plug body sits in the ~22mm right-wall gap,
// cable exits angled and routes back left to Pi).
//
// Note: Pi's HDMI is at the BOTTOM of its right long edge (after CW
// rotation), so cable terminates near the lower portion of cavity.

// Mounting interface (VESA-style on back)
mount_hole_d = 3.2;       // through-hole for M3
mount_spacing_x = 75;     // pattern width
mount_spacing_y = 35;     // pattern height (smaller to fit 80mm height)
mount_post_h = 4;          // boss height for heat-set insert
mount_insert_d = 4.0;      // hole for M3 heat-set insert (3.5mm taper)

// Cable cutout (bottom edge of the enclosure)
// Just the 1× Type-C POWER cable — the HDMI is internal (Pi→driver), so no
// HDMI strain relief is needed here. A USB-C plug is ~8.5mm wide; 16mm gives
// the plug body + a little bend room without leaving a needlessly big hole
// (the blower does NOT draw from the bottom, so this isn't an air intake).
cable_cut_w = 16;     // Type-C plug (~8.5) + margin/bend room
cable_cut_h = 7;      // Type-C connector/plug body height
cable_cut_offset = 0; // 0 = centered along bottom edge; +N moves right

// Touch panel FFC ribbon slot (top side wall, near driver board's
// I2C connector). Small flat slot for a future 6-pin touch ribbon.
touch_slot_w = 8;     // ribbon width + margin
touch_slot_h = 1.5;   // ribbon thickness + margin
touch_slot_z = 0;     // vertical center along the inner cavity (0 = mid)
enable_touch_slot = true;

// Ventilation slots — top + bottom walls, for natural convection
// (cool air in from bottom, hot air exhausted from top). Vital for
// always-on kiosk operation where SoC + LCD backlight + driver chips
// continuously dissipate ~5-8W into the sealed cavity.
enable_vents = true;
vent_slot_w = 15;     // width along the wall length
vent_slot_h = 1.5;    // slit height (perpendicular to wall length, in z)
n_top_vents = 10;     // evenly distributed along top wall

// microSD card protrusion slot
// Pi is mounted VERTICALLY (long axis vertical) after a 90° CW
// rotation from its native landscape layout. In native orientation:
//   Top long edge (65mm):  USB-C, USB-C, Mini-HDMI (left → right)
//   Right short edge (30mm): microSD slot
//   Bottom long edge: 40-pin GPIO
//   Left short edge: aux FFC ribbon (camera connector)
// After CW rotation, in our enclosure:
//   Right long edge: USB-C, USB-C, Mini-HDMI (top → bottom)
//   Bottom short edge: microSD slot — card protrudes DOWNWARD 4mm
//   Top short edge: aux FFC connector
//   Left long edge: GPIO header
//
// SD card slot dimensions (measured on board):
//   Slot is 11mm wide, slot right edge is 7.5mm from Pi's far edge.
//   So slot center is 17mm from Pi's near edge, i.e., 2mm offset
//   from Pi's centerline.
sd_slot_w = 13;            // SD card 11mm + 2mm margin
sd_slot_h = 2.5;           // SD card 1mm + slot housing margin
sd_slot_side = "bottom";   // protrudes through BOTTOM wall
sd_slot_offset_x = 2;      // 2mm right of Pi center
enable_sd_slot = true;

// ─── Heat-pipe active cooler (DIY kit — no CNC, no soldering) ──
// Built entirely from off-the-shelf parts + thermal epoxy:
//   • a PRE-FLATTENED heat pipe (sold by length) — its flat end presses
//     directly on the SoC die, so the pipe itself is the cold plate (no
//     machined evaporator block);
//   • a STOCK extruded-aluminium finned heatsink in the centre strip,
//     with the pipe epoxied into a groove in its base (no soldered fins).
//
// The H618 SoC and ALL connectors sit on the Pi's COMPONENT SIDE, which
// faces the SCREEN (front). So the SoC cannot press a heatsink into the
// back cover — instead the flat pipe end sits on the SoC (front face,
// board CENTRE) and carries its heat into the OPEN MIDDLE STRIP, where the
// stock heatsink + blower live on the back-cover side, well clear of both
// the wall-mount (VESA) posts and the connectors.
//
//   SoC evaporator (front face) → pipe runs the cavity-CENTRE lane y≈36,
//   which threads BETWEEN the VESA rows (y19/y54) AND between the HDMI
//   (y20-31) and OTG (y41-50) connectors → drops to the back plane once
//   clear of the Pi (open space past the PCB edge) → climbs left of the
//   blower → turns into the condenser fin base at x≈135 (dead centre,
//   between the VESA columns x99 & x174) → blower below blows +y up
//   through the fins → top-wall vents exhaust.
//
// Heat-pipe orientation note: the display is wall-mounted with its long
// axis horizontal, so the pipe runs HORIZONTAL (evaporator and condenser
// at equal height) — the ideal, gravity-neutral working condition.
//
// Speed is controlled by the Pi: a PWM GPIO drives an N-MOSFET low-side
// switch on the fan's GND lead (wiring documented in README).
enable_fan = true;        // master switch for the whole cooler

// Flattened heat pipe (off-the-shelf, bent to shape)
hp_w = 6;                 // pipe width  (flattened from Ø6 round)
hp_t = 3;                 // pipe thickness — fits the cavity flat
hp_lane_y = 36;           // horizontal-run y: clear cavity-CENTRE lane
                          // (between VESA rows AND between HDMI/OTG ports)

// Condenser fin stack (dead centre of the cavity, between VESA columns)
fin_cx = 135;             // fin block centre x (clear of VESA posts 99/174)
fin_w = 30;               // x extent (across the airflow)
fin_y0 = 41;              // fins start just above the blower nozzle
fin_len = 18;             // y extent (the airflow direction)
fin_h = 6;                // z height of the fins
n_fins = 9;               // plate-fin count

// Blower (3007/3004) — in the clear centre strip, below the fins, +y
fan_w = 30;               // 30×30 body footprint
fan_t = 7;                // 3007 = 7mm; set 4 for a 3004
fan_cx = 135;             // centred under the fin stack (clear of VESA)
fan_cy = 24;              // body y ≈ 9..39, tangential nozzle on top edge
fan_intake_gap = 1;       // gap from fan back face to back cover (intake)
fan_nozzle_w = 14;        // tangential outlet width feeding the fins
fan_grille_d = 24;        // intake grille outer diameter (impeller eye)
fan_grille_rings = 3;     // concentric slot rings
fan_grille_rib = 1.2;     // solid rib between slots (dust + strength)
fan_screw_d = 2.2;        // M2 self-tap into the 2 diagonal mount posts
// Derived
fan_z  = back_wall + fan_intake_gap;   // fan back (intake) face height
// SoC location — VERIFIED from the board photo: the H618 sits just
// inboard of the Mini-HDMI (native ≈ (40,15)), i.e. horizontally centred
// but in the HDMI y-band. Placed (15,25); matches pi_board_model.
// Because it's inside the HDMI band, the pipe jogs UP to hp_lane_y(36)
// — the HDMI↔OTG gap — before crossing the connector zone.
soc_gx = side_wall + 10 + 15;          // ≈ 27 (placed x15, board horiz-centre)
soc_gy = side_wall + 1 + 25;           // ≈ 28 (placed y25, in the HDMI band)

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

        // ── Touch FFC ribbon slot on the BOTTOM side wall ──
        // After 180° driver rotation, the I2C touch header sits on
        // the driver's BOTTOM long edge (it was on the top long edge
        // in native PCB orientation). FFC ribbon routes downward and
        // out through this slot to an external touch panel.
        if (enable_touch_slot) {
            // FFC ribbon exits at the driver PCB plane (boards hug the
            // back cover now), so track pcb_plane_front, not the old
            // mid-stack estimate.
            slot_z_pos = pcb_plane_front + touch_slot_z;
            // X position of driver board's I2C connector after rotation:
            // approximately mid-bottom of the placed driver. Driver
            // bx = total_w - side_wall - board_w - hdmi_plug_gap;
            bx_local = total_w - side_wall - board_w - hdmi_plug_gap;
            // Native PCB I2C was ~10mm from PCB-local "left" edge
            // (HDMI/USB side). After 180° rotation, that's now
            // ~10mm from the placed driver's RIGHT edge. Center the
            // slot on that point.
            i2c_center_x = bx_local + board_w - 10;
            i2c_x = i2c_center_x - touch_slot_w / 2;
            // Cut vertically through bottom side wall
            translate([i2c_x, -1, slot_z_pos - touch_slot_h / 2])
                cube([touch_slot_w, side_wall + 3, touch_slot_h]);
        }

        // ── Ventilation slots (top + bottom walls) ──
        // Cool air in from bottom, hot air out from top via natural
        // convection. The Pi SoC heatsink also conducts directly
        // into the (preferably metal) back cover, so vents handle
        // the LCD backlight + driver-board heat.
        if (enable_vents) {
            // Vertical center within the cavity depth (between front
            // bezel and back cover, in z)
            vent_z = front_wall + screen_t +
                     (inner_depth - screen_t) / 2;

            // ── TOP wall: 10 evenly-spaced slots ──
            usable_w = total_w - 2 * side_wall;
            top_gap = (usable_w - n_top_vents * vent_slot_w) /
                      (n_top_vents + 1);
            for (i = [0 : n_top_vents - 1]) {
                vx = side_wall + top_gap * (i + 1) + vent_slot_w * i;
                translate([vx,
                           total_h - side_wall - 1,
                           vent_z - vent_slot_h / 2])
                    cube([vent_slot_w, side_wall + 3, vent_slot_h]);
            }

            // ── Dedicated forced-exhaust outlet above the blower/fin stack ──
            // The blower pushes air +y through the fins to the top wall, but
            // the evenly-spaced convection slots miss the fin CENTRE (x=fin_cx
            // lands on a rib between two vents), so the forced jet hits solid
            // wall. Cut one generous outlet directly above the fin stack, the
            // full fin width and tall enough (in z) to span the fin/jet depth,
            // so the pushed air actually has somewhere to exhaust.
            if (enable_fan) {
                ex_w = fin_w + 4;     // span the fin width + a little margin
                ex_h = 8;             // z height — covers the fin/jet depth
                translate([fin_cx - ex_w / 2,
                           total_h - side_wall - 1,
                           vent_z - ex_h / 2])
                    cube([ex_w, side_wall + 3, ex_h]);
            }

            // ── BOTTOM wall: slots in the 4 clear zones between
            // existing cutouts (SD, power cable, touch FFC) ──
            // Clear zones approximate (x ranges):
            //   pre-SD (0-20), SD-to-power (38-115),
            //   power-to-FFC (157-228), post-FFC (242-271)
            bottom_zones = [
                [2,   20],
                [38,  115],
                [157, 228],
                [242, total_w - 2]
            ];
            for (z = bottom_zones) {
                zone_w = z[1] - z[0];
                // 1 slot per ~25mm of zone width, min 1 slot
                n_slots = max(1, floor(zone_w / 22));
                if (n_slots > 0) {
                    slot_step = zone_w / n_slots;
                    actual_slot_w = min(vent_slot_w, slot_step - 5);
                    for (j = [0 : n_slots - 1]) {
                        vx = z[0] + (slot_step - actual_slot_w) / 2 +
                             slot_step * j;
                        translate([vx, -1,
                                   vent_z - vent_slot_h / 2])
                            cube([actual_slot_w, side_wall + 3,
                                  vent_slot_h]);
                    }
                }
            }
        }

        // ── microSD card protrusion slot ──
        // Cuts through the top or bottom side wall aligned with Pi's
        // short edge. Pi is mounted vertically, so SD card protrudes
        // out through the top or bottom (depending on Pi's mounting
        // orientation set via sd_slot_side).
        if (enable_sd_slot) {
            // SD card sits at the Pi PCB plane (board hugs back cover);
            // track pcb_plane_front so the slot follows board_back_gap.
            sd_z_pos = pcb_plane_front;
            // Pi placement: px = side_wall + 10, pi_short = 30
            // Default: center the slot on Pi's short axis.
            // Use sd_slot_offset_x to bias toward one end if Pi's actual
            // SD slot isn't centered on its short edge.
            sd_x = side_wall + 10 + (pi_short - sd_slot_w) / 2 + sd_slot_offset_x;
            if (sd_slot_side == "bottom") {
                translate([sd_x, -1, sd_z_pos - sd_slot_h / 2])
                    cube([sd_slot_w, side_wall + 3, sd_slot_h]);
            } else {
                // top
                translate([sd_x, total_h - side_wall - 1,
                           sd_z_pos - sd_slot_h / 2])
                    cube([sd_slot_w, side_wall + 3, sd_slot_h]);
            }
        }
    }
}

// ─── Back cover ───────────────────────────────────────────

module back_cover() {
    // Outer plate + mounting features. Cable cutouts are handled by
    // the front frame's side walls (front_frame module).
    difference() {
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
            // Blower cradle (corner ribs + 2 screw posts + intake nubs)
            if (enable_fan)
                fan_cradle();
            // Finned-condenser mount + heat-pipe routing clips
            if (enable_fan)
                cooler_mounts();
        }
        // Fan intake grille cut straight through the back cover, behind
        // the impeller eye.
        if (enable_fan)
            fan_grille_cut();
    }
}

// ─── Blower fan cradle + intake grille ─────────────────────
// The fan is sandwiched between the back cover and the screen/front
// frame. Four corner ribs locate it in X/Y; two short intake nubs lift
// it off the back cover so the impeller can breathe through the grille;
// two diagonal screw posts take the fan's M2 mounting lugs.
module fan_cradle() {
    fx = fan_cx - fan_w / 2;             // fan left edge (x)
    fy = fan_cy - fan_w / 2;             // fan bottom edge (y)
    rib_t = 1.6;                          // rib wall thickness
    rib_l = 6;                            // rib leg length along each edge
    rib_h = fan_t;                        // cradle the full fan body height
    // Corner L-ribs at the 4 corners of the fan footprint
    for (cx = [fx, fx + fan_w])
    for (cy = [fy, fy + fan_w]) {
        sx = (cx == fx) ? 0 : -rib_t;          // grow inward from corner
        sy = (cy == fy) ? 0 : -rib_t;
        dx = (cx == fx) ? 1 : -1;              // leg direction along x
        dy = (cy == fy) ? 1 : -1;              // leg direction along y
        translate([0, 0, back_wall]) {
            // leg along X
            translate([cx + min(0, dx*rib_l), cy + sy, 0])
                cube([rib_l, rib_t, rib_h]);
            // leg along Y
            translate([cx + sx, cy + min(0, dy*rib_l), 0])
                cube([rib_t, rib_l, rib_h]);
        }
    }
    // Two intake standoff nubs (lift fan by fan_intake_gap)
    for (nx = [fx + 5, fx + fan_w - 5])
        translate([nx, fan_cy, back_wall])
            cylinder(d=3, h=fan_intake_gap, $fn=16);
    // Two diagonal M2 screw bosses for the blower's mounting lugs
    // (typical 3007 lugs sit at two opposite corners ~3mm in).
    // SHORT bosses: the fan intake faces the back cover, so its mounting
    // holes are on that side. The boss must NOT rise into the fan body
    // (z = fan_z .. fan_z+fan_t); it tops out flush with the fan's
    // underside (fan_intake_gap) and the screw self-taps DOWN through the
    // boss and into the back wall for thread depth (blind, 0.5mm short of
    // the outer face) — same scheme as the PCB mount posts.
    boss_h = fan_intake_gap;
    for (s = [[fx + 3, fy + 3], [fx + fan_w - 3, fy + fan_w - 3]])
        translate([s[0], s[1], back_wall])
            difference() {
                cylinder(d=4.2, h=boss_h, $fn=20);
                translate([0, 0, -(back_wall - 0.5)])
                    cylinder(d=fan_screw_d, h=boss_h + back_wall - 0.5, $fn=20);
            }
}

// Concentric-ring intake grille cut through the back cover, centred on
// the impeller eye. Thin ribs between rings keep dust out and preserve
// plate strength. The slots are NOT full 360° rings — radial spokes are
// left uncut so every concentric rib stays bridged to the wall and to the
// central hub; otherwise the ribs print as loose, disconnected loops.
module fan_grille_cut() {
    step = fan_grille_rib + 1.4;          // ring pitch (rib + slot width)
    n = fan_grille_rings;
    spoke_w = fan_grille_rib + 0.4;       // width of each radial bridge
    translate([fan_cx, fan_cy, -0.1])
        linear_extrude(back_wall + 0.2)
            difference() {
                // all the annular slots, unioned
                for (i = [0 : n - 1]) {
                    r_out = fan_grille_d/2 - i * step;
                    r_in  = r_out - 1.4;   // 1.4mm slot width
                    if (r_in > 0)
                        difference() {
                            circle(r = r_out, $fn = 64);
                            circle(r = r_in,  $fn = 64);
                        }
                }
                // radial spokes: uncut bridges that tie all rings together
                for (a = [45 : 90 : 359])
                    rotate(a)
                        translate([-spoke_w/2, 0])
                            square([spoke_w, fan_grille_d/2 + 1]);
            }
    // Plus a small central hole so the impeller hub area also draws air
    translate([fan_cx, fan_cy, -0.1])
        cylinder(d = 4, h = back_wall + 0.2, $fn = 24);
}

// ─── Cooler mounts: fin-stack base + heat-pipe clips ───────
// Printed features on the back cover that hold the condenser fin block
// above the blower's nozzle and clip the heat pipe down along its route
// from the SoC (the y≈16 lane, under the HDMI) to the fin base.
module cooler_mounts() {
    wall = 1.5;
    translate([0, 0, back_wall]) {
        // Fin-stack base wall pair (locates the finned heatsink in X). The
        // heat pipe enters the heatsink groove from the LEFT at y_into, so
        // the LEFT wall gets a bottom notch (a channel for the pipe); the
        // right wall stays solid. Without this notch the wall sits across
        // the pipe's path into the fins.
        y_into   = fin_y0 + 3;                  // pipe entry y (matches heat_pipe_model)
        notch_y0 = y_into - hp_w/2 - 0.5;       // pipe y-extent + clearance
        notch_w  = hp_w + 1;
        notch_h  = hp_t + 0.5;                  // channel height (z) for the pipe
        // left wall, notched
        difference() {
            translate([fin_cx - fin_w/2 - wall, fin_y0, 0])
                cube([wall, fin_len, fan_t]);
            translate([fin_cx - fin_w/2 - wall - 0.1, notch_y0, -0.1])
                cube([wall + 0.2, notch_w, notch_h + 0.1]);
        }
        // right wall, solid
        translate([fin_cx + fin_w/2, fin_y0, 0])
            cube([wall, fin_len, fan_t]);
        // Heat-pipe hold-down clips along the back-plane centre-lane run
        // (between the z-drop point ≈50 and the turn ≈115 left of the
        // blower): channel side walls keep the flattened pipe seated. Both
        // x positions clear the VESA posts (x99 posts are at y19/y54, far
        // from this y≈36 lane).
        for (cx = [65, 100])
            translate([cx - hp_w/2 - wall, hp_lane_y - hp_w/2 - wall, 0]) {
                // side walls of the channel
                cube([hp_w + 2*wall, wall, hp_t + 1]);
                translate([0, hp_w + wall, 0])
                    cube([hp_w + 2*wall, wall, hp_t + 1]);
            }
    }
}

// Driver board posts at the 4 hole positions.
// Driver board mounted on RIGHT side of cavity, rotated 180° in-plane
// from native so that its HDMI/USB-C edge faces the OUTER right wall
// (~22mm clearance to accommodate a 90° angled HDMI plug body) and
// its FPC + I2C edges face the cavity center and bottom.
hdmi_plug_gap = 22;   // clearance between driver right short edge and right wall
module board_mount_posts() {
    // Driver board placement: long axis (72mm) horizontal,
    // short axis (49mm) vertical. Position in upper-right of cavity,
    // with extra right-wall gap for HDMI plug clearance.
    bx = total_w - side_wall - board_w - hdmi_plug_gap;
    by = (total_h - board_h) / 2;              // vertically centered
    // SAME short post height as the Pi: both PCBs hug the back cover so
    // their (screen-facing) components get the depth toward the front.
    pillar_h = board_back_gap;
    for (pt = board_hole_pts) {
        translate([bx + pt[0], by + pt[1], 0])
            difference() {
                cylinder(d=6, h=pillar_h, $fn=24);
                // pilot through post + into back wall for screw grip
                translate([0, 0, -(back_wall - 0.5)])
                    cylinder(d=board_hole_d, h=pillar_h + back_wall - 0.5, $fn=24);
            }
    }
}

// Pi posts — Pi placed on left side of cavity, mounted VERTICALLY
// after a 90° CW rotation from native. HDMI port at the BOTTOM of
// Pi's RIGHT long edge faces RIGHT toward driver. SD card on Pi's
// BOTTOM short edge protrudes 4mm DOWN through bottom-wall slot.
module pi_mount_posts() {
    // Position Pi flush to bottom so SD card aligns with bottom slot.
    // Pi's BOTTOM edge sits 1mm above the inside surface of bottom
    // wall, so SD card sticks ~1mm beyond outside of bottom wall.
    px = side_wall + 10;                       // 10mm gap from left wall
    py = side_wall + 1;                         // 1mm gap from bottom inside
    pillar_h = board_back_gap;                  // short post: PCB hugs back cover
    for (cx = [pi_hole_inset, pi_short - pi_hole_inset])
    for (cy = [pi_hole_inset, pi_long - pi_hole_inset])
        translate([px + cx, py + cy, 0])
            difference() {
                cylinder(d=5, h=pillar_h, $fn=20);
                // Pilot bores through the short post AND into the back wall
                // so the M2.5 self-tap still gets full thread engagement
                // (blind, stops 0.5mm short of the outer face).
                translate([0, 0, -(back_wall - 0.5)])
                    cylinder(d=pi_hole_d, h=pillar_h + back_wall - 0.5, $fn=20);
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

// ─── Wall mount plate (stand-off frame; hangs on a single wall screw) ──
// Three jobs at once:
//   1) keyhole (top) + anti-rotation screw (bottom) must clear the 73mm-tall
//      enclosure — so the plate is TALLER than the enclosure and the two wall
//      screws sit beyond its top/bottom edges (reachable, no head conflict);
//   2) the blower's back-cover intake grille must not be sealed against the
//      wall — so 4 printed STAND-OFFS hold the enclosure ~8mm off the plate,
//      creating an air plenum the fan draws from (the enclosure is far wider
//      than the plate, so this plenum is wide open at the left/right sides);
//   3) a relief window behind the grille so the plate isn't a flat cap there.
module wall_mount() {
    plate_w    = mount_spacing_x + 40;   // 115
    plate_h    = 105;                    // tall: keyhole above + anti-rot below the enclosure
    plate_t    = 4;
    standoff_h = 8;                      // air gap between enclosure back and plate
    standoff_d = 9;
    keyhole_d  = 9; slot_w = 4.5; slot_h = 14;

    vcx = plate_w / 2;                   // VESA pattern centre on the plate
    vcy = plate_h / 2;
    // fan grille mapped from enclosure coords onto the plate (VESA centre aligns
    // the plate's (vcx,vcy) with the enclosure centre (total_w/2,total_h/2)).
    gx = vcx + (fan_cx - total_w/2);
    gy = vcy + (fan_cy - total_h/2);

    difference() {
        union() {
            rounded_rect(plate_w, plate_h, 8, plate_t);
            // 4 stand-offs on the enclosure-facing side (hold the air gap)
            for (dx = [-mount_spacing_x/2, mount_spacing_x/2])
            for (dy = [-mount_spacing_y/2, mount_spacing_y/2])
                translate([vcx + dx, vcy + dy, plate_t])
                    cylinder(d=standoff_d, h=standoff_h, $fn=24);
        }

        // Keyhole slot at top (now ABOVE the enclosure's top edge)
        translate([vcx, plate_h - 9, -1]) {
            cylinder(d=keyhole_d, h=plate_t + 2, $fn=32);
            translate([-slot_w/2, -slot_h, 0])
                cube([slot_w, slot_h, plate_t + 2]);
        }

        // Anti-rotation screw at bottom (now BELOW the enclosure's bottom edge)
        translate([vcx, 9, -1])
            cylinder(d=mount_hole_d, h=plate_t + 2, $fn=20);

        // VESA holes through plate + stand-offs; countersunk on the WALL face
        // (z=0) for flat-head screws that thread up into the back-cover inserts.
        for (dx = [-mount_spacing_x/2, mount_spacing_x/2])
        for (dy = [-mount_spacing_y/2, mount_spacing_y/2])
            translate([vcx + dx, vcy + dy, 0]) {
                translate([0, 0, -1])
                    cylinder(d=mount_hole_d, h=plate_t + standoff_h + 2, $fn=24);
                translate([0, 0, -0.01])
                    cylinder(d1=6, d2=mount_hole_d, h=2, $fn=24);  // c'sink, wall face
            }

        // Relief window behind the fan grille (so the plate doesn't cap it)
        translate([gx, gy, -1])
            cylinder(d=fan_grille_d + 6, h=plate_t + 2, $fn=48);
    }
}

// ─── Visualization models (NOT for printing) ──────────────
// These approximate the PCBs and connectors for layout verification.
// Use part="preview" to render alongside the back cover and see where
// each board sits and which edge each connector lives on.

// Driver board (HM-V1.0B). Sits on the 4 driver posts. After 180°
// in-plane rotation: HDMI/USB-C on its RIGHT short edge facing outer
// wall; FPC connector on its LEFT short edge facing cavity center;
// I2C touch header on its BOTTOM long edge.
module driver_board_model() {
    bx = total_w - side_wall - board_w - hdmi_plug_gap;
    by = (total_h - board_h) / 2;
    // PCB sits on the short posts, hugging the back cover; components
    // (HDMI/USB-C/FPC) point toward the screen (+z).
    bz = back_wall + board_back_gap;
    // PCB itself is ~1.6mm; the 4mm board_t includes tallest components.
    pcb_t = 1.6;

    translate([bx, by, bz]) {
        // PCB body (dark green, semi-transparent so post tops are visible)
        color([0.05, 0.30, 0.10, 0.55])
            cube([board_w, board_h, pcb_t]);

        // ── RIGHT short edge (faces outer wall): USB-C + HDMI ──
        // After 180° rotation, the native HDMI (originally near the
        // top-left) ends up near the BOTTOM-right, and the native
        // USB-C (originally bottom-left) ends up near the TOP-right.
        //
        // USB-C socket on TOP of right edge: ~9mm × 7mm deep × 3mm tall
        color([0.25, 0.25, 0.25])
        translate([board_w - 2, board_h - 14, pcb_t])
            cube([9, 11, 3]);
        color("White") translate([board_w - 12, board_h - 8.5, pcb_t + 3.05])
            linear_extrude(0.4)
                text("USB-C", size=2.5, halign="center", valign="center");

        // Mini-HDMI socket on BOTTOM of right edge: ~11mm × 8mm × 4mm
        color("Silver")
        translate([board_w - 2, 3, pcb_t])
            cube([10, 11, 4]);
        color("White") translate([board_w - 12, 8.5, pcb_t + 4.05])
            linear_extrude(0.4)
                text("HDMI", size=2.5, halign="center", valign="center");

        // ── LEFT short edge (faces cavity center / Pi): FPC ─────
        // FPC ZIF connector: thin slot ~25mm × 2mm × 2mm tall
        color([0.95, 0.55, 0.10])
        translate([-1, (board_h - 25) / 2, pcb_t])
            cube([3, 25, 2]);
        color("White") translate([4, board_h/2, pcb_t + 2.05])
            linear_extrude(0.4)
                text("FPC", size=2.5, halign="center", valign="center");

        // ── BOTTOM long edge (after 180° rotation): I2C touch ──
        // 6-pin 1.0mm pitch ZIF: ~9mm × 3mm × 2.5mm tall
        i2c_offset_x = board_w - 10;  // ~10mm from right (HDMI) edge
        color([0.85, 0.85, 0.85])
        translate([i2c_offset_x - 4.5, -1, pcb_t])
            cube([9, 4, 2.5]);
        // Label placed above the connector, inboard so it doesn't
        // collide with USB-C label on the right edge.
        color("Black") translate([i2c_offset_x - 12, 5, pcb_t + 2.55])
            linear_extrude(0.4)
                text("I2C", size=2.2, halign="center", valign="center");

        // Tiny dots on the 4 mounting holes (so we can sanity-check
        // that the holes line up with the posts below).
        for (pt = board_hole_pts) {
            color("Red")
            translate([pt[0], pt[1], -0.5])
                cylinder(d=board_hole_d, h=pcb_t + 1, $fn=16);
        }
    }
}

// Orange Pi Zero 2W. Mounted vertically (long axis vertical) after
// 90° CW rotation from native landscape. Sits on the 4 Pi posts.
//   Right long edge (in placed coords): USB-C power (top), USB-C OTG
//                                       (middle), Mini-HDMI (bottom)
//   Bottom short edge: microSD slot
//   Top short edge:    aux FFC (camera connector)
//   Left long edge:    40-pin GPIO header
module pi_board_model() {
    px = side_wall + 10;
    py = side_wall + 1;
    pz = back_wall + board_back_gap;   // PCB hugs back cover; components face screen
    pcb_t = 1.4;

    translate([px, py, pz]) {
        // PCB body
        color([0.10, 0.40, 0.15, 0.55])
            cube([pi_short, pi_long, pcb_t]);

        // ── RIGHT long edge: USB-C ×2 + Mini-HDMI (top → bottom) ──
        // Verified against official Orange Pi Zero 2W layout:
        //   Native top edge (left → right): USB-C(power), USB-C(OTG), Mini-HDMI
        //   Two USB-C are clustered together on the LEFT half (small gap)
        //   Mini-HDMI is on the RIGHT half, separated by ~15mm of WiFi chip area
        //   Approximate native centers: USB-PWR (11, 28), USB-OTG (23, 28),
        //   Mini-HDMI (43, 28)
        // After 90° CW rotation → placed centers (28, 54), (28, 42), (28, 22)
        // y values below are CUBE BOTTOMS (placed center - width/2):
        hdmi_y = 17;      // 11mm body → center 22.5 (HDMI on bottom of placed Pi)
        usb_otg_y = 38;   //  9mm body → center 42.5 (USB OTG clustered with PWR)
        usb_pwr_y = 50;   //  9mm body → center 54.5 (USB PWR closest to FFC top)

        // Mini-HDMI (bottom)
        color("Silver")
        translate([pi_short - 2, hdmi_y, pcb_t])
            cube([8, 11, 4]);
        color("White") translate([pi_short - 11, hdmi_y + 5.5, pcb_t + 4.05])
            linear_extrude(0.4)
                text("HDMI", size=2.2, halign="center", valign="center");

        // USB-C OTG (middle)
        color([0.25, 0.25, 0.25])
        translate([pi_short - 2, usb_otg_y, pcb_t])
            cube([7, 9, 3]);
        color("White") translate([pi_short - 11, usb_otg_y + 4.5, pcb_t + 3.05])
            linear_extrude(0.4)
                text("OTG", size=2, halign="center", valign="center");

        // USB-C power (top)
        color([0.25, 0.25, 0.25])
        translate([pi_short - 2, usb_pwr_y, pcb_t])
            cube([7, 9, 3]);
        color("White") translate([pi_short - 11, usb_pwr_y + 4.5, pcb_t + 3.05])
            linear_extrude(0.4)
                text("PWR", size=2, halign="center", valign="center");

        // ── BOTTOM short edge: microSD slot ──
        // SD slot is 11mm wide; center is at pi_short/2 + sd_slot_offset_x
        sd_cx = pi_short / 2 + sd_slot_offset_x;
        color("Silver")
        translate([sd_cx - 5.5, -2, pcb_t])
            cube([11, 4, 1.4]);
        color("White") translate([sd_cx, 4, pcb_t + 1.45])
            linear_extrude(0.4)
                text("SD", size=2.2, halign="center", valign="center");

        // ── TOP short edge: aux FFC (camera ribbon) ──
        color([0.85, 0.85, 0.85])
        translate([pi_short/2 - 7, pi_long - 1, pcb_t])
            cube([14, 3, 2]);
        color("Black") translate([pi_short/2, pi_long - 5, pcb_t + 2.05])
            linear_extrude(0.4)
                text("FFC", size=2, halign="center", valign="center");

        // ── LEFT long edge: 40-pin GPIO header ──
        color("Black")
        translate([-1, (pi_long - 51) / 2, pcb_t])
            cube([4, 51, 4]);
        color("White") translate([5, pi_long/2, pcb_t + 4.05])
            linear_extrude(0.4)
                text("GPIO", size=2.2, halign="center", valign="center");

        // ── H618 SoC + adjacent LPDDR4 (component / SCREEN face) ──
        // VERIFIED from the board photo (native landscape 65×30):
        //   - H618 BGA ~12×12mm, native ≈ (40,15) — just inboard of the
        //     Mini-HDMI, horizontally centred on the board height.
        //   - LPDDR4 RAM to its right, native ≈ (50,15).
        // After the 90° CW rotation (placed = (ny, 65-nx)):
        //   - H618 centre:  placed (15, 25)   ← in the HDMI y-band
        //   - LPDDR4:       placed (15, 15)
        // Both face the SCREEN; the flat heat-pipe end presses the H618.
        soc_cx = 15;
        soc_cy = 25;
        soc_size = 12;        // H618 BGA ~12×12mm
        soc_h_thick = 1.5;    // chip + solder balls
        chip2_cx = 15;
        chip2_cy = 15;        // LPDDR4 RAM, toward the SD-slot edge
        chip2_w = 8;
        chip2_h = 6;
        chip2_thick = 1.2;
        // H618 SoC chip
        color([0.15, 0.15, 0.18, 0.85])
        translate([soc_cx - soc_size/2,
                   soc_cy - soc_size/2,
                   pcb_t])
            cube([soc_size, soc_size, soc_h_thick]);
        // Adjacent smaller chip (must also sit under heatsink)
        color([0.18, 0.18, 0.22, 0.85])
        translate([chip2_cx - chip2_w/2,
                   chip2_cy - chip2_h/2,
                   pcb_t])
            cube([chip2_w, chip2_h, chip2_thick]);
        // Heatsink envelope — only in the PASSIVE design. When the
        // heat-pipe cooler is enabled (enable_fan), the pipe's evaporator
        // pad (drawn by heat_pipe_model) sits on the SoC instead, so the
        // standalone gold heatsink is suppressed to avoid a double model.
        hs_cy = (soc_cy + chip2_cy) / 2;   // midpoint of the two chips
        if (!enable_fan) {
            hs_w = 16;        // x dimension (slightly wider than chips)
            hs_l = 22;        // y dimension (covers both chips vertically)
            hs_z = 5;         // heatsink height
            hs_cx = 17;
            color([1.0, 0.75, 0.15, 0.70])
            translate([hs_cx - hs_w/2,
                       hs_cy - hs_l/2,
                       pcb_t + max(soc_h_thick, chip2_thick)])
                cube([hs_w, hs_l, hs_z]);
        }
        // Labels — placed beside the SoC so they're not occluded
        soc_label_x = pi_short + 6;   // ~6mm to the right of Pi
        soc_label_y = hs_cy;
        label_z = pcb_t + max(soc_h_thick, chip2_thick) + 5.1;
        color("Red") translate([soc_label_x, soc_label_y + 1.5, label_z])
            linear_extrude(0.4)
                text(enable_fan ? "H618 SoC (screen face) → heat-pipe evaporator"
                                : "H618 SoC + adjacent chip",
                     size=2.2, halign="left", valign="center");
        // Thin callout lines from label to BOTH chips
        color("Red") {
            hull() {
                translate([soc_label_x - 0.3, soc_label_y, label_z])
                    cube([0.3, 0.3, 0.4]);
                translate([soc_cx + soc_size/2, soc_cy, label_z])
                    cube([0.3, 0.3, 0.4]);
            }
            hull() {
                translate([soc_label_x - 0.3, soc_label_y, label_z])
                    cube([0.3, 0.3, 0.4]);
                translate([chip2_cx + chip2_w/2, chip2_cy, label_z])
                    cube([0.3, 0.3, 0.4]);
            }
        }
    }
}

// ─── Heat-pipe cooler visualization (preview only) ─────────
// Semi-transparent models of the blower, the flattened heat pipe routed
// from the SoC to the condenser, and the finned condenser block — for
// comparing against the real parts and checking clearances. Everything
// lives in the open strip, clear of the connectors.
module fan_model() {
    fx = fan_cx - fan_w / 2;
    fy = fan_cy - fan_w / 2;
    // Volute body (square blower shell)
    color([0.12, 0.12, 0.14, 0.55])
        translate([fx, fy, fan_z])
            cube([fan_w, fan_w, fan_t]);
    // Impeller hint (intake side, on the back face)
    color([0.30, 0.30, 0.34, 0.7])
        translate([fan_cx, fan_cy, fan_z + 0.2])
            cylinder(d = fan_grille_d - 2, h = 0.8, $fn = 40);
    // Tangential exhaust nozzle — TOP (+y) edge, feeding the fin stack.
    color([0.12, 0.12, 0.14, 0.55])
        translate([fan_cx - fan_nozzle_w/2, fy + fan_w - 1, fan_z])
            cube([fan_nozzle_w, 4, fan_t]);
    // Airflow arrow pointing +y up through the fins
    arrow_z = fan_z + fan_t + 0.3;
    color([0.2, 0.7, 1.0]) {
        translate([fan_cx - 0.7, fy + fan_w, arrow_z])
            cube([1.4, 12, 0.4]);
        translate([fan_cx, fy + fan_w + 12, arrow_z])
            linear_extrude(0.4)
                polygon([[0, 0], [-2, -3], [2, -3]]);
    }
    // Labels
    color("DeepSkyBlue")
        translate([fan_cx, fy - 3, fan_z + fan_t + 0.2])
            linear_extrude(0.4)
                text(str(fan_w, "×", fan_w, "×", fan_t, " blower (intake from back)"),
                     size = 2.4, halign = "center", valign = "center");
}

// DIY-KIT cooler (no CNC, no soldering): an off-the-shelf PRE-FLATTENED
// heat pipe whose flat end presses DIRECTLY on the SoC die (the pipe IS
// the cold plate — no machined evaporator block), routed through the
// connector-free cavity-centre lane (y≈36), dropped to the back routing
// plane once clear of the Pi, then epoxied into the groove of a STOCK
// extruded-aluminium heatsink in the centre strip (drawn by fin_stack).
module heat_pipe_model() {
    z_back  = back_wall + 0.5;                       // back routing plane
    // front face: top of the SoC die, where the flat pipe end presses
    z_front = back_wall + board_back_gap + 1.4 + 1.5;   // ≈ 6.9
    x_drop  = side_wall + 10 + pi_short + 8;          // ≈ 50, clear of Pi/ports
    x_turn  = fan_cx - fan_w/2 - 5;                   // ≈ 115, left of the fan
    y_into  = fin_y0 + 3;                             // enters fin base
    // Flattened pipe END pressed on the SoC die (thermal pad between) —
    // a widened/flattened section of the SAME pipe, NOT a separate block.
    color([0.74, 0.47, 0.22])
        translate([soc_gx - 7, soc_gy - 7, z_front])
            cube([14, 14, hp_t]);
    color([0.80, 0.52, 0.30]) {
        // vertical jog: the SoC sits in the HDMI band (y≈28), so first climb
        // to the connector-free crossing lane (y≈36) — done at x≈27, well
        // LEFT of the connectors (x40-48), so it touches nothing
        translate([soc_gx - hp_w/2, soc_gy - hp_w/2, z_front])
            cube([hp_w, hp_lane_y - soc_gy + hp_w, hp_t]);
        // front-face run along the lane: out past the Pi, threading the y≈36
        // gap between the HDMI and OTG connectors
        translate([soc_gx - hp_w/2, hp_lane_y - hp_w/2, z_front])
            cube([x_drop - soc_gx + hp_w/2, hp_w, hp_t]);
        // z-drop riser: front face → back routing plane (open space, no PCB).
        // MUST sit on the lane (y36) where the front-face run ends — NOT at
        // soc_gy(28), which would plant it on top of the Mini-HDMI.
        translate([x_drop - hp_w/2, hp_lane_y - hp_w/2, z_back])
            cube([hp_w, hp_w, z_front - z_back + hp_t]);
        // back-plane horizontal run along the centre lane to the turn point
        translate([x_drop - hp_w/2, hp_lane_y - hp_w/2, z_back])
            cube([x_turn - x_drop + hp_w/2, hp_w, hp_t]);
        // climb up to fin level (left of the blower)
        translate([x_turn - hp_w/2, hp_lane_y - hp_w/2, z_back])
            cube([hp_w, y_into - hp_lane_y + hp_w/2, hp_t]);
        // turn right into the condenser fin base
        translate([x_turn - hp_w/2, y_into - hp_w/2, z_back])
            cube([fin_cx - x_turn + hp_w/2, hp_w, hp_t]);
    }
    if (is_undef(NO_LABELS))
    color("SaddleBrown")
        translate([soc_gx + 6, soc_gy - 11, z_front + hp_t + 0.1])
            linear_extrude(0.4)
                text("pre-flattened heat pipe: SoC die -> stock heatsink (epoxy)",
                     size = 2.2, halign = "center");
}

// STOCK extruded-aluminium heatsink (off-the-shelf, e.g. a 30mm-wide
// finned block) sitting in the centre strip; the heat pipe is epoxied
// into a groove milled/cast in its base, and the blower pushes air up
// between the fins into the top-wall vents. No custom fin fabrication.
module fin_stack_model() {
    z0 = back_wall + 0.5;
    base_t = 1.5;
    // base plate with a pipe groove (the off-the-shelf heatsink's base)
    color([0.75, 0.75, 0.78])
        difference() {
            translate([fin_cx - fin_w/2, fin_y0, z0])
                cube([fin_w, fin_len, base_t]);
            // groove for the epoxied heat pipe (entered from the left at y_into)
            translate([fin_cx - fin_w/2 - 0.1, fin_y0 + 3 - hp_w/2, z0 - 0.1])
                cube([fin_w/2 + 0.1, hp_w, hp_t]);
        }
    // extruded plate fins running along the airflow (y), spaced across x
    pitch = fin_w / n_fins;
    color([0.82, 0.82, 0.85, 0.9])
        for (i = [0 : n_fins - 1])
            translate([fin_cx - fin_w/2 + i*pitch + pitch/2 - 0.4, fin_y0, z0 + base_t])
                cube([0.8, fin_len, fin_h]);
    if (is_undef(NO_LABELS))
    color("DeepSkyBlue")
        translate([fin_cx, fin_y0 + fin_len + 3, z0 + base_t + fin_h])
            linear_extrude(0.4)
                text("stock Al heatsink (pipe epoxied in base) → top vents",
                     size = 2.2, halign = "center");
}

// ─── Render selector ──────────────────────────────────────
// Set `part` to render one of the parts at a time

part = "preview";  // "front" | "back" | "wall" | "all" | "preview"

// ─── Per-part export plumbing (non-breaking; driven by -D on the CLI) ──
// STL (3D, for FDM/CAM):   openscad -o front.stl -D 'part="front"' ...
// 2D drawing (DXF/SVG):    openscad -o back_plan.svg -D 'part="back"' \
//                                   -D draw2d=true -D 'view="plan"' ...
// The defaults below keep the interactive preview unchanged.
draw2d = false;    // true → emit a flat 2D projection instead of the 3D solid
view   = "plan";   // "plan" (XY footprint) | "front" (XZ) | "side" (YZ)

module part_solid(p) {
    if (p == "front")         front_frame();
    else if (p == "back")     back_cover();
    else if (p == "wall")     wall_mount();
    else if (p == "pipe")     heat_pipe_model();      // heat pipe alone
    else if (p == "heatsink") fin_stack_model();      // stock heatsink alone
    else if (p == "cooler")   { heat_pipe_model(); fin_stack_model(); }
}

module emit_view(p, v) {
    if (v == "plan")       projection(cut=false) part_solid(p);
    else if (v == "front") projection(cut=false) rotate([-90, 0, 0]) part_solid(p);
    else if (v == "side")  projection(cut=false) rotate([0, -90, 0]) part_solid(p);
}

// When this file is `include`d by drawings.scad, DRAW_SHEET is defined and
// the whole interactive/export selector below is suppressed so the drawing
// generator can drive its own output (it still gets all the modules + dims).
if (!is_undef(DRAW_SHEET)) {
    // suppressed — drawings.scad is in control
}
else if (draw2d)
    emit_view(part, view);
else if (part == "front")
    color("DimGray") front_frame();
else if (part == "back")
    color("SlateGray") back_cover();
else if (part == "wall")
    color("LightGray") wall_mount();
else if (part == "cooler" || part == "pipe" || part == "heatsink")
    part_solid(part);
else if (part == "all") {
    color("DimGray") front_frame();
    translate([0, 0, -back_wall - 1])
        color("SlateGray") back_cover();
    translate([total_w + 30, 0, 0])
        color("LightGray") wall_mount();
}
else if (part == "preview") {
    // Layout verification view: back cover with posts + board models
    // sitting on their posts. Look from above (camera +Z) to see the
    // BACK VIEW of the cavity with connector positions labeled.
    //
    // Color legend:
    //   Silver  = Mini-HDMI       Orange = FPC ZIF
    //   DimGray = USB-C           Light  = I2C / FFC
    //   Black   = GPIO            Red    = Mounting holes (driver)
    //   Dark    = SoC (below PCB) Copper = Heat-pipe + evaporator
    //   DarkBox = Blower fan      Silver = Condenser fins
    //   Cyan    = Airflow (+y, up through fins → top vents)
    //
    // Boards are drawn semi-transparent so the mounting posts beneath
    // them remain visible — this lets you sanity-check hole alignment.
    color([0.4, 0.45, 0.5]) back_cover();
    driver_board_model();
    pi_board_model();
    if (enable_fan) {
        heat_pipe_model();
        fin_stack_model();
        fan_model();
    }
    // Cavity wall outline (front frame minus its bezel face) for
    // spatial reference. Drawn very faint and offset down so it doesn't
    // hide the boards.
    %color([0.5, 0.5, 0.5, 0.2])
        translate([0, 0, back_wall])
            difference() {
                rounded_rect(total_w, total_h, 4, inner_depth);
                translate([side_wall, side_wall, -0.1])
                    cube([total_w - 2*side_wall,
                          total_h - 2*side_wall,
                          inner_depth + 0.2]);
            }

    // ── Directional / wall annotations (back-view orientation) ──
    label_z = back_wall + inner_depth + 1;
    label_color = "Yellow";

    // Outer-wall labels around the cavity edges
    color(label_color) translate([total_w / 2, total_h + 4, label_z])
        linear_extrude(0.4)
            text("TOP wall", size=3, halign="center");
    color(label_color) translate([total_w / 2, -7, label_z])
        linear_extrude(0.4)
            text("BOTTOM wall (Type-C / SD / touch FFC slots)",
                 size=3, halign="center");
    color(label_color) translate([-12, total_h / 2, label_z])
        rotate([0, 0, 90])
        linear_extrude(0.4)
            text("LEFT (Pi side)", size=3, halign="center");
    color(label_color) translate([total_w + 12, total_h / 2, label_z])
        rotate([0, 0, -90])
        linear_extrude(0.4)
            text("RIGHT (outer / HDMI cable)", size=3, halign="center");

    // Bottom-wall slot positions (visualized as thin colored bars
    // just below the cavity) — gives a quick sanity check that
    // SD / cable / touch FFC slots don't conflict.
    bar_y = -3;
    bar_z = back_wall + 0.1;
    // SD slot
    color("Cyan")
    translate([side_wall + 10 + (pi_short - sd_slot_w) / 2 + sd_slot_offset_x,
               bar_y, bar_z])
        cube([sd_slot_w, 1, 0.5]);
    // Cable cutout
    color("Magenta")
    translate([(total_w - cable_cut_w) / 2 + cable_cut_offset,
               bar_y, bar_z])
        cube([cable_cut_w, 1, 0.5]);
    // Touch FFC slot
    bx_local_p = total_w - side_wall - board_w - hdmi_plug_gap;
    color("Yellow")
    translate([bx_local_p + board_w - 10 - touch_slot_w / 2,
               bar_y, bar_z])
        cube([touch_slot_w, 1, 0.5]);
}
