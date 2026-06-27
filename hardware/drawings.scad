// ═══════════════════════════════════════════════════════════
// Info-Pi enclosure — per-part dimensioned PLAN drawings (1:1)
// ═══════════════════════════════════════════════════════════
// Generates a flat, dimensioned top-view shop drawing for ONE part.
//   openscad -o drawings/back_cover_DIM.svg -D 'sheet="back"' drawings.scad
// sheet = "front" | "back" | "wall"
//
// It `include`s enclosure.scad purely to reuse its frozen dimension
// constants (total_w, mount_spacing_x, fan_grille_d, …). The guard in
// enclosure.scad suppresses that file's own render when DRAW_SHEET is set.
// All geometry here is reconstructed as clean 2D primitives so the holes,
// cut-outs and dimension lines read clearly — this is the drawing, not the
// model. The STL/DXF/SVG ortho exports (export.sh) come from the model.
// ═══════════════════════════════════════════════════════════

sheet = is_undef(sheet) ? "back" : sheet;   // -D 'sheet="…"'
DRAW_SHEET = sheet;                           // tells enclosure.scad to hush
include <enclosure.scad>;

// ── mirrored wall_mount() locals (KEEP IN SYNC with enclosure.scad) ──
wm_w   = mount_spacing_x + 40;   // 115
wm_h   = 105;                    // taller stand-off frame (keyhole/anti-rot clear enclosure)
wm_key_d = 9;
wm_key_slot_w = 4.5;
wm_key_slot_h = 14;
wm_standoff_d = 9;               // air-gap stand-off OD
wm_standoff_h = 8;               // air gap so the fan grille can breathe

// ── drafting primitives (everything is filled 2D; thin rects = lines) ──
LT   = 0.3;    // line thickness
TXT  = 3.2;    // dimension text height
TICK = 3;      // dim tick length
$fn  = 64;

module hline(x0, x1, y) translate([min(x0,x1), y - LT/2]) square([abs(x1-x0), LT]);
module vline(y0, y1, x) translate([x - LT/2, min(y0,y1)]) square([LT, abs(y1-y0)]);
module dtick(x, y) translate([x, y]) rotate(45) square([LT, TICK], center=true);

// horizontal dimension: feature points at y=yf, dim line at y=yd
module hdim(x0, x1, yf, yd, label) {
    vline(yf, yd, x0); vline(yf, yd, x1);     // extension lines
    hline(x0, x1, yd);                         // dimension line
    dtick(x0, yd); dtick(x1, yd);
    translate([(x0+x1)/2, yd + 1.6])
        text(label, size=TXT, halign="center", valign="bottom");
}
// vertical dimension: feature points at x=xf, dim line at x=xd
module vdim(y0, y1, xf, xd, label) {
    hline(xf, xd, y0); hline(xf, xd, y1);
    vline(y0, y1, xd);
    dtick(xd, y0); dtick(xd, y1);
    translate([xd + 1.6, (y0+y1)/2]) rotate(90)
        text(label, size=TXT, halign="center", valign="bottom");
}
// hole: ring outline + center cross at the given centre
module hole_at(cx, cy, d) {
    translate([cx, cy]) {
        difference() { circle(d = d + 2*LT); circle(d = d); }
        hline(cx*0 - d*0.7, d*0.7, 0); vline(-d*0.7, d*0.7, 0);   // center cross
    }
}
// plain ring outline (no centre cross) — for stand-off OD / relief windows
module ring(cx, cy, d) {
    translate([cx, cy]) difference() { circle(d = d + 2*LT); circle(d = d); }
}
module leader(cx, cy, tx, ty, label) {
    hull() { translate([cx,cy]) circle(LT); translate([tx,ty]) circle(LT); }
    translate([tx + (tx>=cx?1:-1)*1.2, ty])
        text(label, size=TXT*0.92, halign=(tx>=cx?"left":"right"), valign="center");
}

// rounded-rect OUTLINE (frame of 4 thin bars + corner arcs)
module rrect_outline(w, h, r) {
    difference() {
        offset(r) offset(-r) square([w, h]);          // outer rounded
        offset(r-LT) offset(-(r-LT)) translate([LT,LT]) square([w-2*LT, h-2*LT]);
    }
}
module rect_outline(x, y, w, h) {
    translate([x,y]) difference() { square([w,h]); translate([LT,LT]) square([w-2*LT,h-2*LT]); }
}

// title block (drawn well below the part, clear of the lower dim bands)
module title_block(name, w, h, extra) {
    translate([0, -44]) {
        rect_outline(0, 0, 168, 16);
        translate([3, 11]) text(str("INFO-PI  |  ", name), size=3.4, valign="center");
        translate([3, 5.2]) text(str("Outline ", w, " x ", h, " mm   ·   Scale 1:1 (mm)   ·   ", extra),
                                 size=2.6, valign="center");
    }
}

// ─────────────────────────────────────────────────────────────
// SHEET: FRONT FRAME (front face plan)
// ─────────────────────────────────────────────────────────────
module sheet_front() {
    win_x = side_wall + bezel_inset;            // 4
    win_y = side_wall + bezel_inset;            // 4
    win_w = screen_w - 2*bezel_inset;           // 261
    win_h = screen_h - 2*bezel_inset;           // 61
    color("black") {
        rrect_outline(total_w, total_h, 4);                 // outer
        rect_outline(win_x, win_y, win_w, win_h);           // display window
        // dimensions
        hdim(0, total_w, total_h, total_h + 8, str(total_w));
        vdim(0, total_h, total_w, total_w + 8, str(total_h));
        hdim(win_x, win_x+win_w, win_y, -8, str(win_w));
        vdim(win_y, win_y+win_h, win_x, -8, str(win_h));
        leader(win_x, win_y+win_h, win_x-14, win_y+win_h+6,
               str("bezel ", bezel_inset+side_wall, " border"));
        title_block("FRONT FRAME (1/3)", total_w, total_h,
                    str("window ", win_w, "x", win_h, " · wall ", front_wall));
    }
}

// ─────────────────────────────────────────────────────────────
// SHEET: BACK COVER (outer face plan — through-features only)
// ─────────────────────────────────────────────────────────────
module sheet_back() {
    cx = total_w/2; cy = total_h/2;
    vx0 = cx - mount_spacing_x/2; vx1 = cx + mount_spacing_x/2;   // 99 / 174
    vy0 = cy - mount_spacing_y/2; vy1 = cy + mount_spacing_y/2;   // 19 / 54
    color("black") {
        rrect_outline(total_w, total_h, 4);
        // VESA 4-hole pattern (M3 insert)
        for (hx=[vx0,vx1], hy=[vy0,vy1]) hole_at(hx, hy, mount_insert_d);
        // fan intake grille (Ø outer)
        hole_at(fan_cx, fan_cy, fan_grille_d);
        // overall (W above, H right)
        hdim(0, total_w, total_h, total_h + 9, str(total_w));
        vdim(0, total_h, total_w, total_w + 9, str(total_h));
        // VESA pattern (X above, Y right) and datum offsets (X below, Y left)
        hdim(vx0, vx1, vy1, total_h + 19, str("VESA ", mount_spacing_x));
        vdim(vy0, vy1, vx1, total_w + 19, str(mount_spacing_y));
        hdim(0, vx0, vy0, -9, str(vx0));
        vdim(0, vy0, vx0, -9, str(vy0));
        leader(vx0, vy1, vx0-12, vy1+8, str("4x O", mount_insert_d, " (M3 insert)"));
        // grille (X below row 2, Y left row 2)
        hdim(0, fan_cx, -3, -18, str(fan_cx));
        vdim(0, fan_cy, -3, -18, str(fan_cy));
        leader(fan_cx, fan_cy, fan_cx+20, fan_cy-12, str("fan grille O", fan_grille_d));
        title_block("BACK COVER (2/3)", total_w, total_h,
                    str("VESA ", mount_spacing_x, "x", mount_spacing_y, " · grille O", fan_grille_d));
    }
}

// ─────────────────────────────────────────────────────────────
// SHEET: WALL MOUNT plate
// ─────────────────────────────────────────────────────────────
module sheet_wall() {
    cx = wm_w/2;
    key_y = wm_h - 9;
    bot_y = 9;
    vx0 = cx - mount_spacing_x/2; vx1 = cx + mount_spacing_x/2;
    vcy = wm_h/2;
    vy0 = vcy - mount_spacing_y/2; vy1 = vcy + mount_spacing_y/2;
    gx = cx + (fan_cx - total_w/2);          // grille relief window, mapped from enclosure
    gy = vcy + (fan_cy - total_h/2);
    color("black") {
        rrect_outline(wm_w, wm_h, 8);
        // keyhole (round + slot)
        hole_at(cx, key_y, wm_key_d);
        rect_outline(cx - wm_key_slot_w/2, key_y - wm_key_slot_h, wm_key_slot_w, wm_key_slot_h);
        // bottom anti-rotation screw
        hole_at(cx, bot_y, mount_hole_d);
        // VESA holes (through, countersunk) + stand-off OD rings
        for (hx=[vx0,vx1], hy=[vy0,vy1]) { hole_at(hx, hy, mount_hole_d); ring(hx, hy, wm_standoff_d); }
        // grille relief window
        ring(gx, gy, fan_grille_d + 6);
        // dims
        hdim(0, wm_w, wm_h, wm_h + 9, str(wm_w));
        vdim(0, wm_h, wm_w, wm_w + 9, str(wm_h));
        hdim(vx0, vx1, vy1, wm_h + 19, str("VESA ", mount_spacing_x));
        vdim(vy0, vy1, vx0, -9, str(mount_spacing_y));
        leader(cx, key_y, cx+18, key_y+6, str("keyhole O", wm_key_d));
        leader(vx0, vy1, vx0-12, vy1+8,
               str("4x O", mount_hole_d, " c'sunk / O", wm_standoff_d, " standoff h", wm_standoff_h));
        leader(cx, bot_y, cx+16, bot_y-3, str("O", mount_hole_d, " anti-rot"));
        leader(gx, gy, gx+22, gy-13, str("grille relief O", fan_grille_d + 6));
        title_block("WALL MOUNT (3/3)", wm_w, wm_h,
                    str("stand-off frame · ", wm_standoff_h, "mm air gap · keyhole O", wm_key_d));
    }
}

if (sheet == "front")     sheet_front();
else if (sheet == "back") sheet_back();
else if (sheet == "wall") sheet_wall();
