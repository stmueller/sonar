# Sonar Simulator - Paused State

## Goal
Build `simulator.pbl` in `/home/home/smueller/Dropbox/Research/pebl/pebl/demo/sonar/` —
a live scrolling sonar waterfall display simulator showing all 3 frequency rows animating
simultaneously. Not a test/task — just a visual demo of what the sonar display looks like.

## What Already Exists

### Key files
- `sonar.pbl` — stripe pixel-generation functions (SetPixelsRGBA approach, used for sonar2afc)
- `sonartest.pbl` — static snapshot test (bg + stripes, no scroll)
- `scroll_test.pbl` — working 2-copy scroll loop for row 2 only (uses pre-rendered png files)
- `sonar2afc_scroll.pbl` — full 2AFC task with scrolling (in progress, separate from this)

### Image assets
- `img/waterfall_bg.png` — 2000×1000 px background image with 3 row panels
- `img/stripes/stripe_r{R}_f{FFFF}_v{VV}.png` — per-frequency stripe images, 40×283 RGBA
  - Row 1: 7 freqs (0, 40, 80, 120, 160, 200, 240 Hz), 8 variants each
  - Row 2: 13 freqs (250..730 Hz step 40), 8 variants each
  - Row 3: 26 freqs (750..1750 Hz step 40), 8 variants each
- `img/waterfall_rownoise_NN.png` — 20 green semi-transparent noise overlays, 2000×291 RGBA

### Manifest
`img/stripes/manifest.json` — array of {fname, freq, row, flo, fhi, x_content, v}
- `x_content` = pixel offset within content area (0..1949), left edge of 40px stripe

## Display Geometry (native bg coords, 2000×1000)
- Row heights: rowH = 291 px
- Row 1 top: y=60,  center y=205.5  (0–250 Hz)
- Row 2 top: y=381, center y=526.5  (250–750 Hz)
- Row 3 top: y=702, center y=847.5  (750–1750 Hz)
- Content area: x=50, width=1950
- Zoom at runtime: `gZoom = gVideoWidth / 2000.0 * 0.5`

## Architecture Planned for simulator.pbl

### Approach
- Static `waterfall_bg.png` added to gWin at zoom
- 3 viewport canvases (one per row), positioned over each row's content area
  - vpW = Round(1950 * gZoom), vpH = Round(291 * gZoom)
  - Viewport X center: bg_screen_left + Round((50 + 975) * gZoom)  [center of content]
  - Viewport Y centers: bgTop + Round((60+145)*gZoom), etc.
- For each target frequency in signature:
  - Find its row viewport
  - x_center_in_vp = Round((x_content + 20) * gZoom)  [20 = half stripe width]
  - Maintain 2 copies (copy0, copy1) as MakeImage objects inside that viewport
  - Shared y0/y1 scroll state (same vpH so same offsets for all rows)
- Single `ScrollTick` event moves all copies; on recycle picks random variant

### Signature for demo
Hardcode: 5 frequencies + their pre-computed row/x data:
```
freq 60  -> nearest 40Hz:   row=1, x_content=312, base=stripe_r1_f0040
freq 125 -> nearest 120Hz:  row=1, x_content=936, base=stripe_r1_f0120
freq 275 -> nearest 290Hz:  row=2, x_content=156, base=stripe_r2_f0290
freq 1100-> nearest 1110Hz: row=3, x_content=702, base=stripe_r3_f1110
freq 1450-> nearest 1430Hz: row=3, x_content=1325,base=stripe_r3_f1430
```

### Data structures
- `gVps` — list of 3 viewport canvas objects [vp1, vp2, vp3]
- `gFreqEntries` — list of [vp_idx, x_vp, base_path, obj_copy0, obj_copy1]
  one entry per signature frequency
- `gCopyY` — [y0, y1] shared scroll y positions (viewport-relative centers)
  y0 = Round(vpH/2), y1 = Round(vpH/2) + vpH at start

### ScrollTick logic
1. y0 -= 1; y1 -= 1
2. if y0 + Round(vpH/2) < 0: recycle
   - loop gFreqEntries: RemoveObject(copy0, vp); load new random variant; AddObject; Move to y1+vpH
   - y0 = y1; y1 = y0_new + vpH
3. else: loop gFreqEntries: Move(copy0, x_vp, y0); Move(copy1, x_vp, y1)
4. ResetCanvas on all viewports only on recycle
5. Draw()
6. Re-register timer event

## Next Steps When Resuming
1. Write `simulator.pbl` per architecture above
2. Run `bin/pebl-validator demo/sonar/simulator.pbl` to check syntax
3. User runs `bin/pebl2 demo/sonar/simulator.pbl` to test visually
4. If viewport clipping works correctly, integrate scroll into sonar2afc_scroll.pbl

## Open Questions
- Does ResetCanvas on recycle cause flash? (Known issue from scroll_test work)
  Mitigation: only recycle one frequency's copy0 per tick instead of all at once?
- Noise overlay: noise images (2000×291) cover full row width; could add one per row viewport
  to overlay the stripe. Need separate scrolling noise copies too.
- Run time: scroll at 1px/200ms = 5px/sec. vpH = Round(291*0.5)=145px. Full cycle=29sec. Good.
