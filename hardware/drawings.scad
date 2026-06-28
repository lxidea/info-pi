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
wm_plate_t = 4;                  // wall plate thickness (mirrors wall_mount)

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
// ── FACE views (FRONT VIEW / 主视图): outline + holes + in-plane dims ──
// These no longer carry the title block — three_view() adds it once.

module face_front() {
    win_x = side_wall + bezel_inset;            // 4
    win_y = side_wall + bezel_inset;            // 4
    win_w = screen_w - 2*bezel_inset;           // 261
    win_h = screen_h - 2*bezel_inset;           // 61
    rrect_outline(total_w, total_h, 4);                 // outer
    rect_outline(win_x, win_y, win_w, win_h);           // display window
    hdim(0, total_w, total_h, total_h + 9, str(total_w));
    vdim(win_y, win_y+win_h, win_x, -9, str(win_h));
    hdim(win_x, win_x+win_w, win_y+win_h, total_h + 19, str(win_w));
    leader(win_x, win_y, win_x-12, win_y-6,
           str("bezel ", bezel_inset+side_wall, " border"));
}

module face_back() {
    cx = total_w/2; cy = total_h/2;
    vx0 = cx - mount_spacing_x/2; vx1 = cx + mount_spacing_x/2;   // 99 / 174
    vy0 = cy - mount_spacing_y/2; vy1 = cy + mount_spacing_y/2;   // 19 / 54
    rrect_outline(total_w, total_h, 4);
    for (hx=[vx0,vx1], hy=[vy0,vy1]) hole_at(hx, hy, mount_insert_d);
    hole_at(fan_cx, fan_cy, fan_grille_d);
    hdim(0, total_w, total_h, total_h + 9, str(total_w));
    hdim(vx0, vx1, total_h, total_h + 19, str("VESA ", mount_spacing_x));
    vdim(vy0, vy1, vx0, -9, str(mount_spacing_y));
    hdim(0, fan_cx, 0, -9, str(fan_cx));
    leader(vx1, vy1, vx1+12, vy1+8, str("4x O", mount_insert_d, " (M3 insert)"));
    leader(fan_cx, fan_cy, fan_cx+20, fan_cy+12, str("fan grille O", fan_grille_d));
}

module face_wall() {
    cx = wm_w/2;
    key_y = wm_h - 9;
    bot_y = 9;
    vx0 = cx - mount_spacing_x/2; vx1 = cx + mount_spacing_x/2;
    vcy = wm_h/2;
    vy0 = vcy - mount_spacing_y/2; vy1 = vcy + mount_spacing_y/2;
    gx = cx + (fan_cx - total_w/2);
    gy = vcy + (fan_cy - total_h/2);
    rrect_outline(wm_w, wm_h, 8);
    hole_at(cx, key_y, wm_key_d);
    rect_outline(cx - wm_key_slot_w/2, key_y - wm_key_slot_h, wm_key_slot_w, wm_key_slot_h);
    hole_at(cx, bot_y, mount_hole_d);
    for (hx=[vx0,vx1], hy=[vy0,vy1]) { hole_at(hx, hy, mount_hole_d); ring(hx, hy, wm_standoff_d); }
    ring(gx, gy, fan_grille_d + 6);
    hdim(0, wm_w, wm_h, wm_h + 9, str(wm_w));
    hdim(vx0, vx1, wm_h, wm_h + 19, str("VESA ", mount_spacing_x));
    vdim(vy0, vy1, vx0, -9, str(mount_spacing_y));
    leader(cx, key_y, cx+18, key_y+6, str("keyhole O", wm_key_d));
    leader(vx1, vy1, vx1+12, vy1+8, str("O", wm_standoff_d, " standoff h", wm_standoff_h));
    leader(cx, bot_y, cx+16, bot_y-3, str("O", mount_hole_d, " anti-rot"));
    leader(gx, gy, gx+22, gy-13, str("grille relief O", fan_grille_d + 6));
}

// 2D silhouette outline of a (rotated) part, for the elevation views.
module outline2d() { difference() { children(); offset(-LT) children(); } }
module view_label(x, y, txt) {
    translate([x, y]) text(txt, size = TXT*1.05, halign = "center", valign = "center");
}

// ── THREE-VIEW sheet (first-angle): FRONT (face) + TOP below + SIDE right ──
module three_view(p) {
    W = (p == "wall") ? wm_w : total_w;
    H = (p == "wall") ? wm_h : total_h;
    D = (p == "front") ? front_wall + inner_depth + 2
      : (p == "back")  ? back_wall + fan_t
      :                  wm_plate_t + wm_standoff_h;
    title = (p == "front") ? "FRONT FRAME (1/3)"
          : (p == "back")  ? "BACK COVER (2/3)" : "WALL MOUNT (3/3)";
    sub   = (p == "front") ? str("window 261x61 · wall ", front_wall)
          : (p == "back")  ? str("VESA ", mount_spacing_x, "x", mount_spacing_y,
                                 " · grille O", fan_grille_d)
          :                  str("stand-off frame · ", wm_standoff_h, "mm air gap");
    ty = -42 - D;            // TOP view sits below the face
    tx = W + 40;             // SIDE view sits to the right of the face

    color("black") {
        // FRONT VIEW (face) at origin
        if (p == "front")     face_front();
        else if (p == "back") face_back();
        else                  face_wall();
        view_label(W/2, H + 30, "FRONT VIEW");

        // TOP VIEW — XZ silhouette, below, aligned in X
        translate([0, ty])
            outline2d() projection(cut=false) rotate([-90, 0, 0])
                part_solid(p);
        vdim(ty, ty + D, 0, -10, str(D));
        view_label(W/2, ty - 7, "TOP VIEW");

        // SIDE VIEW — YZ silhouette, right, aligned in Y
        translate([tx, 0])
            outline2d() projection(cut=false) rotate([0, 90, 0])
                part_solid(p);
        hdim(tx, tx + D, 0, -10, str(D));
        view_label(tx + D/2, H + 9, "SIDE VIEW");

        // title block well below the TOP view + its label
        translate([0, ty - 30]) {
            rect_outline(0, 0, 168, 16);
            translate([3, 11]) text(str("INFO-PI  |  ", title), size = 3.4, valign = "center");
            translate([3, 5.2]) text(str(W, " x ", H, " x ", D, " mm  ·  1st-angle 3-view  ·  1:1 (mm)  ·  ", sub),
                                     size = 2.4, valign = "center");
        }
    }
}

if (sheet == "front")     three_view("front");
else if (sheet == "back") three_view("back");
else if (sheet == "wall") three_view("wall");
