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
// 2D footprint of the concentric-ring intake grille (mirrors fan_grille_cut):
// annular slots minus the four radial spoke bridges.
module grille2d() {
    step = fan_grille_rib + 1.4;
    n = fan_grille_rings;
    spoke_w = fan_grille_rib + 0.4;
    difference() {
        for (i = [0 : n - 1]) {
            r_out = fan_grille_d/2 - i * step;
            r_in  = r_out - 1.4;
            if (r_in > 0) difference() { circle(r = r_out); circle(r = r_in); }
        }
        for (a = [45 : 90 : 359])
            rotate(a) translate([-spoke_w/2, 0]) square([spoke_w, fan_grille_d/2 + 1]);
    }
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
    win_w = screen_w - 2*bezel_inset;           // 261
    win_h = screen_h - 2*bezel_inset;           // 61
    win_x = (total_w - win_w) / 2;              // centred
    win_y = (total_h - win_h) / 2;
    rrect_outline(total_w, total_h, 4);                 // outer
    rect_outline(win_x, win_y, win_w, win_h);           // display window
    for (p = join_positions) ring(p[0], p[1], join_boss_d);   // internal corner bosses
    leader(join_positions[2][0], join_positions[2][1], join_positions[2][0]-14, join_positions[2][1]-7,
           str("4x internal boss O", join_boss_d, " (M3 self-tap, holds back cover)"));
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
    for (p = join_positions) { hole_at(p[0], p[1], join_screw_d); ring(p[0], p[1], join_cbore_d); }
    translate([fan_cx, fan_cy]) outline2d() grille2d();   // ring-and-spoke intake grille
    hole_at(fan_cx, fan_cy, 4);                            // central hub hole
    ring(fan_cx, fan_cy, fan_grille_d);                   // grille envelope Ø ref
    hdim(0, total_w, total_h, total_h + 9, str(total_w));
    hdim(vx0, vx1, total_h, total_h + 19, str("VESA ", mount_spacing_x));
    vdim(vy0, vy1, vx0, -9, str(mount_spacing_y));
    hdim(0, fan_cx, 0, -9, str(fan_cx));
    leader(vx1, vy1, vx1+12, vy1+8, str("4x O", mount_insert_d, " (M3 insert)"));
    leader(join_positions[2][0], join_positions[2][1], join_positions[2][0]-14, join_positions[2][1]-7,
           str("4x M3 join, csk O", join_cbore_d, " (into front-frame bosses)"));
    leader(fan_cx, fan_cy, fan_cx+20, fan_cy+12,
           str("fan grille O", fan_grille_d, " (", fan_grille_rings, " rings + 4 spokes)"));
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

// ─────────────────────────────────────────────────────────────
// SHEET: COOLER — heat pipe (bent, off-the-shelf) + stock heatsink
// A DIY-kit part: nothing is 3D-printed here, so the drawing is a
// BEND / ROUTING TEMPLATE (developed length + bend table) plus the
// heatsink extrusion spec — not a printed-part three-view.
// All geometry is reconstructed from the frozen model constants that
// enclosure.scad exposes (soc_gx, hp_lane_y, fin_cx …); the local
// derived values below MIRROR heat_pipe_model()/fin_stack_model().
// ─────────────────────────────────────────────────────────────
hp_z_back  = back_wall + 0.5;                       // back routing plane ≈ 2.5
hp_z_front = back_wall + board_back_gap + 1.4 + 1.5; // SoC-die press plane ≈ 6.9
hp_x_drop  = side_wall + 10 + pi_short + 8;          // z-drop x ≈ 50 (clear of Pi)
hp_x_turn  = fan_cx - fan_w/2 - 5;                   // climb x ≈ 115 (left of blower)
hp_y_into  = fin_y0 + 3;                             // enters fin base ≈ 44
hp_base_t  = 1.5;                                    // heatsink base plate thickness

// Pipe centreline nodes in the enclosure XY plane (viewed from the back).
// P0 evaporator → P1 after y-jog → P2 z-drop point → P3 after back run →
// P4 after climb → P5 into fin base.
hp_nodes = [
    [soc_gx,    soc_gy],       // P0  evaporator pad centre (on SoC die)
    [soc_gx,    hp_lane_y],    // P1  jog up to the clear lane
    [hp_x_drop, hp_lane_y],    // P2  drop to back plane here
    [hp_x_turn, hp_lane_y],    // P3  end of back-plane run
    [hp_x_turn, hp_y_into],    // P4  climb to fin level
    [fin_cx + fin_w/2, hp_y_into],  // P5  through the heatsink to its far edge
];
function _seg(i) = norm(hp_nodes[i+1] - hp_nodes[i]);
hp_dev = _seg(0)+_seg(1)+_seg(2)+_seg(3)+_seg(4) + (hp_z_front-hp_z_back);

// rounded 6mm-wide pipe footprint (bends carry a radius, like the real pipe)
module pipe_path2d() {
    for (i = [0 : len(hp_nodes)-2])
        hull() {
            translate(hp_nodes[i])   circle(d = hp_w);
            translate(hp_nodes[i+1]) circle(d = hp_w);
        }
}
module pipe_centerline() {
    for (i = [0 : len(hp_nodes)-2])
        hull() { translate(hp_nodes[i]) circle(LT); translate(hp_nodes[i+1]) circle(LT); }
}
// a small filled bend flag with a callout label
module bend_flag(p, tx, ty, label) {
    translate(p) circle(d = 2.4);
    leader(p[0], p[1], tx, ty, label);
}

// PLAN — the bending/routing template (looking at the back cover)
module cooler_plan() {
    // pipe body outline + centreline
    outline2d() pipe_path2d();
    pipe_centerline();
    // 吸热盘 cold-plate footprint (14x14); the 6mm pipe (pipe_path2d) is
    // embedded in a groove in its bottom, flush, running along y here.
    rect_outline(soc_gx - 7, soc_gy - 7, 14, 14);
    // heatsink block footprint + groove + fin lines
    hb_x = fin_cx - fin_w/2;
    rect_outline(hb_x, fin_y0, fin_w, fin_len);
    rect_outline(hb_x, hp_y_into - hp_w/2, fin_w, hp_w);        // pipe groove (full width)
    pitch = fin_w / n_fins;
    for (i = [0 : n_fins-1])
        vline(fin_y0 + 1, fin_y0 + fin_len - 1, hb_x + i*pitch + pitch/2);
    // node / segment dimensions (developed run)
    vdim(soc_gy, hp_lane_y, soc_gx, soc_gx - 10, str(hp_lane_y - soc_gy));      // jog 8
    hdim(soc_gx, hp_x_drop, hp_lane_y, hp_lane_y - 8, str(hp_x_drop - soc_gx)); // front run 23
    hdim(hp_x_drop, hp_x_turn, hp_lane_y, hp_lane_y - 16, str(hp_x_turn - hp_x_drop)); // back run 65
    vdim(hp_lane_y, hp_y_into, hp_x_turn, hp_x_turn + 26, str(hp_y_into - hp_lane_y));  // climb 8
    hdim(hp_x_turn, fin_cx + fin_w/2, hp_y_into, hp_y_into + 22, str(fin_cx + fin_w/2 - hp_x_turn)); // into/through fins
    hdim(hb_x, hb_x + fin_w, fin_y0 + fin_len, fin_y0 + fin_len + 15, str("heatsink ", fin_w));
    vdim(fin_y0, fin_y0 + fin_len, hb_x + fin_w, hb_x + fin_w + 10, str(fin_len));
    // bend + feature callouts
    bend_flag(hp_nodes[1], soc_gx + 3, hp_lane_y + 9, "B1 90");
    bend_flag(hp_nodes[2], hp_x_drop + 4, hp_lane_y + 10, "B2 Z-DROP");
    bend_flag(hp_nodes[3], hp_x_turn - 20, hp_lane_y - 4, "B3 90");
    bend_flag(hp_nodes[4], hp_x_turn - 20, hp_y_into + 6, "B4 90");
    leader(soc_gx, soc_gy, soc_gx + 10, soc_gy - 15,
           str("cold plate 14x14 (pipe embedded flush in bottom groove)"));
    leader(fin_cx - fin_w/4, hp_y_into, fin_cx + 6, hp_y_into - 12,
           str("groove ", hp_w, "x", hp_t, " (pipe epoxied)"));
}

// DEPTH elevation (X–Z), shows the single out-of-plane z-drop step
module cooler_depth() {
    zs = 1;                       // 1:1
    bz = 0;                       // baseline (back-cover inner face) local y
    function EZ(z) = bz + z*zs;
    // back-cover wall slab (ground reference)
    color("black") rect_outline(soc_gx - 12, EZ(0), (fin_cx+18) - (soc_gx-12), back_wall);
    // pipe as a 3mm(hp_t)-thick band along X (bottom on z_front then z_back)
    pts = [ [soc_gx, hp_z_front], [hp_x_drop, hp_z_front],
            [hp_x_drop, hp_z_back], [fin_cx, hp_z_back] ];
    for (i = [0 : len(pts)-2])
        hull() {
            translate([pts[i][0],   EZ(pts[i][1]) + hp_t/2])   circle(d = hp_t);
            translate([pts[i+1][0], EZ(pts[i+1][1]) + hp_t/2]) circle(d = hp_t);
        }
    // SoC-end stack (XZ cross-section): chip · cold plate with the 6mm pipe
    // embedded FLUSH in its bottom groove. Pipe bottom + plate bottom are
    // coplanar → one continuous contact plane on the die (no air gap).
    zf = EZ(hp_z_front);
    ctop = zf + hp_t + 1;                                        // cold-plate top
    rect_outline(soc_gx - 5, zf - 1.6, 10, 1.6);                 // SoC die (chip)
    rect_outline(soc_gx - hp_w/2, zf, hp_w, hp_t);              // heat pipe 6x3, flush bottom
    rect_outline(soc_gx - 7, zf, 4, hp_t);                     // plate rail (left of groove)
    rect_outline(soc_gx + 3, zf, 4, hp_t);                     // plate rail (right of groove)
    rect_outline(soc_gx - 7, zf + hp_t, 14, 1);                // plate top (over the pipe)
    hline(soc_gx - 9, soc_gx + 9, zf);                          // emphasise the flush plane
    leader(soc_gx - 5, zf - 0.8, soc_gx - 21, zf - 5, "SoC die");
    leader(soc_gx - 9, zf, soc_gx - 24, zf + 4, "flush contact plane");
    leader(soc_gx + 7, ctop - 0.5, soc_gx + 22, zf + 9,
           "cold plate (pipe embedded flush in bottom)");
    // heatsink base + fins in elevation
    hb_x = fin_cx - fin_w/2;
    rect_outline(hb_x, EZ(hp_z_back), fin_w, hp_base_t);
    pitch = fin_w / n_fins;
    for (i = [0 : n_fins-1])
        rect_outline(hb_x + i*pitch + pitch/2 - fin_t/2, EZ(hp_z_back) + hp_base_t, fin_t, fin_h);
    // dims
    vdim(EZ(0), EZ(hp_z_front + hp_t + 1), soc_gx - 7, soc_gx - 16,
         str("stack top ", hp_z_front + hp_t + 1, " (screen back ~11)"));
    vdim(EZ(hp_z_back), EZ(hp_z_front), hp_x_drop, hp_x_drop + 14,
         str("drop ", hp_z_front - hp_z_back));
    vdim(EZ(hp_z_back), EZ(hp_z_back + hp_base_t + fin_h), fin_cx + fin_w/2,
         fin_cx + fin_w/2 + 10, str("fins ", hp_base_t + fin_h));
    view_label((soc_gx + fin_cx)/2, EZ(0) - 8, "DEPTH (X-Z) — z-drop step");
}

// 放热段 condenser extrusion end-profile (Y–Z look): width, fins, base groove
module cooler_heatsink() {
    pitch = fin_w / n_fins;
    rect_outline(0, 0, fin_w, hp_base_t);                      // base
    for (i = [0 : n_fins-1])
        rect_outline(i*pitch + pitch/2 - fin_t/2, hp_base_t, fin_t, fin_h);   // fins
    // groove in the base underside (pipe seat)
    rect_outline(fin_w/2 - hp_w/2, -hp_t, hp_w, hp_t);
    hdim(0, fin_w, hp_base_t + fin_h, hp_base_t + fin_h + 8, str(fin_w));
    vdim(0, hp_base_t + fin_h, fin_w, fin_w + 10, str(hp_base_t + fin_h));
    vdim(-hp_t, 0, 0, -8, str(hp_base_t));
    leader(fin_w/2, -hp_t, fin_w/2 + 10, -hp_t - 6, str("groove ", hp_w, "x", hp_t));
    leader(pitch/2, hp_base_t + fin_h, -6, hp_base_t + fin_h + 4,
           str(n_fins, " fins x", fin_h, "h @ ", pitch, " pitch"));
    view_label(fin_w/2, hp_base_t + fin_h + 16, "CONDENSER PROFILE (finned)");
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

// COOLER assembly sheet: routing template + depth step + heatsink profile + table
module cooler_sheet() {
    color("black") translate([20, 22]) {
        // PLAN routing/bend template (top)
        cooler_plan();
        view_label((soc_gx + fin_cx)/2, fin_y0 + fin_len + 18, "PLAN — bend / routing template");
        // DEPTH elevation (below the plan), aligned in X
        translate([0, -34]) cooler_depth();
        // HEATSINK end-profile (to the right)
        translate([fin_cx + 55, fin_y0]) cooler_heatsink();
        // bend / cut table + title block, bottom-left
        translate([soc_gx - 12, -74]) {
            rect_outline(0, 0, 176, 22);
            translate([3, 17.5]) text("INFO-PI  |  HEAT-PIPE COOLER — 3 parts (DIY kit, no CNC / no solder)",
                                      size = 3.0, valign = "center");
            translate([3, 12.6]) text(str("1) cold plate 14x14 (pipe embedded flush in bottom)   ·   2) heat pipe O6 -> flat ",
                                          hp_w, "x", hp_t, ", developed ~", round(hp_dev), " mm"),
                                      size = 2.1, valign = "center");
            translate([3, 8.0]) text(str("3) condenser (finned): Al ", fin_w, "x", fin_len, "x",
                                         hp_base_t + fin_h, ", ", n_fins, " fins x", fin_h, "h @ ",
                                         fin_w/n_fins, " pitch, groove ", hp_w, "x", hp_t),
                                     size = 2.2, valign = "center");
            translate([3, 3.4]) text("bends: B1/B3/B4 = 90 in-plane · B2 = z-crank (step back 4.4) · pipe epoxied into both grooves · 1:1 (mm)",
                                     size = 2.0, valign = "center");
        }
    }
}

if (sheet == "front")       three_view("front");
else if (sheet == "back")   three_view("back");
else if (sheet == "wall")   three_view("wall");
else if (sheet == "cooler") cooler_sheet();
