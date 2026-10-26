# sonar-task.pbl Architecture

## Overview

`sonar-task.pbl` is a general-purpose decision task simulator using the sonar cover story.
All task behavior is driven by a JSON config file (`sonar-task.json`).
Two display panels are available and can be used independently or together:

- **Narrowband panel** — waterfall frequency-stripe display (2000×1000 bg)
- **Bearing panel** — heading display (2000×200 bg) with sonar stripes overlaid at angular positions

---

## Config structure (`sonar-task.json`)

```json
{
  "task_id":   "my-task",
  "display":   "narrowband",     // "narrowband" | "bearing" | "both"
  "audio":     false,
  "vessels": [
    { "id": 1, "name": "Alpha", "sig": [50,125,340,1200,1541],
      "thumb": "img/thumbnails/thumb_v1.png", "sound": "sounds/sub_nuke.ogg",
      "bearing": null },
    { "id": 2, "name": "Bravo", "sig": [40,135,320,1100,1490],
      "thumb": "img/thumbnails/thumb_v2.png", "sound": "sounds/sub_diesel.ogg",
      "bearing": null }
  ],
  "blocks": [ ... ]
}
```

### Block fields

```json
{
  "id":           "round1",
  "label":        "Round 1",
  "instructions": "...",
  "trials":       20,
  "base_rate":    0.5,            // P(vessel 1). null = equal across N vessels.

  "signal_mode":  "clean",
  // "clean"   — exact base signature
  // "jitter"  — Gaussian frequency shift (signal_params.jitter_sd)
  // "noisy"   — adds K random bands (signal_params.n_noise_min/max)
  // "mimic"   — mixes bands from alt vessel (signal_params.n_mimic)
  // "prob"    — each band shown with probability p (signal_params.p_show)
  // "combo"   — jitter + noisy combined
  // "sequence"— fixed trial sequence (signal_params.sequence list)

  "signal_params": {
    "jitter_sd":   20,            // percent of narrowband row width (Hz span), not band f
    "jitter_trunc_sd": 1.5,
    "n_noise_min": 1,  "n_noise_max": 3,
    "n_mimic":     2,
    "p_show":      0.75,
    "sequence":    []   // list of vessel IDs if signal_mode=="sequence"
  },

  // Exact class counts in vessels[] order (preferred over vessel_rates).
  // Builds a shuffled case list; sum becomes trials.
  "vessel_counts": [5, 10, 5],

  // How many times to present each base case (identical forced sig).
  "repetitions": 2,

  // Optional per-case noise profiles. When set, overrides block signal_params
  // for listed fields; unspecified fields inherit the block. Each profile needs
  // count = exact # of base cases (before repetitions). Sum(counts) must equal
  // sum(vessel_counts) when both are set. Implies the case-list path.
  // CSV visual_sd reflects the case jitter (via gCurrentJitter).
  "noise_profiles": [
    { "jitter_sd": 5,  "count": 12 },
    { "jitter_sd": 20, "count": 13 }
  ],

  "response_mode": "choice",
  // "choice"     — click one of N vessel thumbnails (or bearing sectors)
  // "gonogo"     — timeout-based: respond within window or trial is a no-go.
  //                No explicit defer button; silence = withhold.
  //                Used for CPT/vigilance: many no-signal trials, occasional signal.
  // "nway"       — N labeled buttons (e.g. 4-armed bandit sectors)
  // "rating"     — confidence slider 0-100 after choice
  // "defer"      — adds explicit Defer button alongside choices (for VoI / BART-style)

  "n_responses":   2,             // how many choice options (ignored for gonogo)

  "gonogo": {
    "go_vessel":       1,         // which vessel id requires a response (signal)
    "response_window": 1000,      // ms to respond before trial expires as no-go
    "iti":             1000,      // inter-trial interval ms (blank screen)
    "n_targets":       null,      // if set, exactly this many target trials in block
    "catch_rate":      0.75       // fraction of trials that are no-signal (no-go) trials
  },

  "interference": {
    "enabled":   false,
    "type":      "none",
    // "none"
    // "stroop"   — signal feature conflicts with response label
    //              (e.g. vessel named "Alpha" displayed with Beta's stripe pattern)
    // "simon"    — response location conflicts with stimulus location
    //              (bearing panel: correct response button is on opposite side to contact)
    // "flanker"  — flanking distractors shown around target stripe
    // "oddball"  — rare deviant vessel among standard repeated vessels;
    //              participant responds only to deviant (P300-style)
    // "posner"   — spatial cue (valid or invalid) appears before stimulus at a bearing;
    //              tests spatial attention allocation
    // "bst"      — Bivalent Shape Task analog: TWO conflict dimensions simultaneously.
    //              Correct response = narrowband frequency identity (vessel A vs B).
    //              Congruent/incongruent bearing ALSO present on bearing panel.
    //              Gives 4 trial types: freq-C/bearing-C, freq-C/bearing-I,
    //              freq-I/bearing-C, freq-I/bearing-I.
    //              Key manipulation: "bivalent" vessels appear in both congruent and
    //              incongruent bearing roles across block (vs. "univalent" = always consistent).
    //              Requires display=="both".
    "congruent_rate":  0.5,       // fraction of trials where cue/label is congruent
    "bst_bivalent_rate": 0.5,     // for bst: fraction of vessels that are bivalent (appear in both roles)
    "cue_validity":    0.80,      // for posner: P(cue correctly indicates target location)
    "cue_lead_ms":     200,       // for posner: SOA between cue onset and target onset
    "oddball_rate":    0.10,      // for oddball: P(target is deviant)
    "oddball_vessel":  2          // for oddball: which vessel id is the deviant
  },

  "defer": {
    "enabled":     false,
    "mechanic":    "relook",      // "relook" | "sequential" | "pre-purchase"
    "max_defers":  3,             // max defers per trial before forced choice
    "cost_points": 0,             // point cost per defer
    "relook_new_noise": true      // relook: redraw noise but keep same vessel
  },

  "feedback":      "accuracy",
  // "accuracy"      — CORRECT / INCORRECT text
  // "payoff"        — show +/- points from payoff table
  // "probabilistic" — show feedback on feedback_prob fraction of trials
  // "none"          — no feedback

  "feedback_prob": 1.0,           // fraction of trials that get feedback (for "probabilistic")

  "payoff": {
    "hit":  10,   // correct detection (said signal, signal present)
    "miss": -5,   // missed detection (said no-signal, signal present)
    "fa":   -3,   // false alarm (said signal, signal absent)
    "cr":    0    // correct rejection (said no-signal, signal absent)
  },

  "show_score":    false,         // display running point total on screen

  "rule": {
    "type":       "none",         // "none" | "reversal" | "wcst" | "probabilistic"
    "correct_to_reverse": 10,     // for reversal: switch correct vessel after N correct
    "p_correct":  0.80            // for probabilistic: P(feedback is veridical)
  },

  "active_sonar": {
    "enabled":       false,
    "button_label":  "PING",
    "detection_prob": 0.15,       // P(detected and penalized per ping)
    "detection_penalty": -20,     // points lost if detected
    "max_pings":     5,           // max pings per trial (null = unlimited)
    "ping_reveals":  "update"     // "update" = new noise draw; "enhance" = reduce noise bands
  }
}
```

---

## Display geometry

### Narrowband panel (existing)
- Background: `img/waterfall_bg.png` 2000×1000 native
- 3 frequency rows: 0-250 Hz (row1), 250-750 Hz (row2), 750-1750 Hz (row3)
- Stripes: pre-rendered PNGs, 80×283 native, placed by frequency→x mapping
- Zoom: `gVideoWidth / 2000.0 * 0.5`

### Bearing panel (new)
- Background: `img/heading_bg.png` 2000×200 native — same zoom as narrowband
- Sits above narrowband when `display=="both"`; full-width otherwise
- A contact at bearing B degrees maps to an x-position within the 2000px content:
  `x_native = 50 + Round(B / 360.0 * 1950)`
- Same stripe PNGs are overlaid at that x position (row determined by frequency as usual,
  but compressed into the 200px height — only row1 stripes used by default)
- Multiple contacts = multiple stripes at different x positions
- Response sectors: bearing panel divided into N equal sectors, click selects vessel/arm

---

## Module map (functions in sonar-task.pbl)

### Config / init
- `ReadConfig(path)`            — reads JSON, returns config list
- `ParseVessels(cfg)`           — extracts vessel list from config
- `ParseBlocks(cfg)`            — extracts block list
- `InitDisplay(cfg, vessels)`   — loads all images, sets layout globals, returns display_objs
- `InitScoreState()`            — returns fresh score property object

### Signal generation
- `GenerateSignal(vessel_id, mode, params, vessels)` — dispatches to:
  - `MakeCleanSig(baseSig)`
  - `MakeJitteredSig(baseSig, sd)`           (existing)
  - `MakeNoisySig(baseSig, nMin, nMax)`      (extended from existing)
  - `MakeMimicSig(baseSig, altSig, nMimic)`  (existing)
  - `MakeProbSig(baseSig, p_show)`           (existing)
  - `MakeComboSig(baseSig, sd, nMin, nMax)`  (new: jitter + noise)

### Case list / scheduling
- `BuildVesselIdSchedule(blockCfg, vessels)` — exact counts from `vessel_counts`, shuffled
- `BuildNoiseProfileSchedule(blockCfg, nCases)` — exact counts from `noise_profiles`, shuffled
- `BuildTrialCaseList(blockCfg, vessels)` — vessel + optional noise profile → forced `sig`
- `ApplyTrialCase` / `ClearTrialCaseForce` — pin/restore vessel, sig, and per-case jitter (`gCurrentJitter` → CSV `visual_sd`)
- `CopySignalParams` / `OverlaySignalParams` — inherit block params, overlay profile fields

### Display rendering
- `RenderNarrowband(sig, display_objs)` — places stripes on waterfall, returns img list
- `RenderBearing(contacts, display_objs)` — places stripe(s) on heading_bg at bearing x
- `ClearDisplay(img_list, win)`         — removes all stripe objects
- `ShowActiveSonarPulse(win, disp)`     — flash animation, then reveal

### Interference / timing manipulation
- `ApplyInterference(block_cfg, vessel_id, display_objs, win)` — dispatches by type:
  - `"stroop"`: renders conflicting label/name on vessel thumbnail before display
  - `"simon"`: places target stripe on opposite side from correct response button
  - `"flanker"`: renders N-1 distractor stripes flanking the target stripe
  - `"oddball"`: most trials are standard vessel; rare deviant requires response
  - `"posner"`: shows cue (highlight at a bearing) for `cue_lead_ms`, then target;
    valid/invalid controlled by `cue_validity`
- Returns `[congruent, cue_valid]` flags for logging

### Response collection
- `CollectResponse(block_cfg, display_objs, vessels)` — dispatches by response_mode:
  - choice/nway: `WaitForClickOnTarget(buttons, ids)`
  - gonogo: `WaitForMouseButton()` with `response_window` timeout;
    timeout = no-go (correct rejection or miss depending on trial type);
    no explicit button — silence is the withhold response.
    Used for CPT, vigilance, oddball: many catch trials, sparse targets.
  - defer: returns `[resp, n_defers]`; inner loop calls `GenerateSignal` again per defer
  - rating: choice first, then slider

### Feedback / scoring
- `ApplyFeedback(result, block_cfg, score_state, win, fonts)` — dispatches by feedback type
- `ScoreTrial(result, block_cfg)` — returns `[correct, points, outcome_label]`
  - outcome_label: "hit" | "miss" | "fa" | "cr" | "deferred" | "detected"
- `UpdateScoreState(score_state, outcome, points)` — mutates running totals

### Rule engine
- `ApplyRule(block_cfg, score_state, vessels)` — checks reversal/WCST conditions,
  returns possibly-swapped correct vessel id

### Active sonar
- `DoPing(block_cfg, score_state, display_objs, vessel_id, win)`:
  - Runs ShowActiveSonarPulse
  - Rolls detection_prob → if detected: applies penalty, returns ["detected", penalty]
  - Otherwise: returns ["ok", new_sig] with updated/enhanced signal

### Block / trial runner
- `RunTrial(block_cfg, vessels, display_objs, score_state)` → returns trial_result list:
  `[vessel_id, response, rt, n_defers, n_pings, sig, correct, outcome, points, abstime]`
- `RunBlock(block_cfg, vessels, display_objs, dataFile, score_state)` — trial loop
- `ShowBlockInstructions(block_cfg, win, fonts, display_objs)`

### Data logging
- `LogTrial(dataFile, subnum, block_cfg, trial_num, trial_result, sig)` — writes one CSV row
- CSV columns:
  `subnum, task_id, block_id, trial, vessel_id, vessel_name, response, correct,
   outcome, points, cumulative_score, n_defers, n_pings, rt_ms, abstime,
   base_sig, actual_sig, n_shown, n_extra, n_missing`

### Top-level
- `Start(p)` — thin orchestrator:
  1. InitializeUpload / GetSubNum
  2. ReadConfig → ParseVessels, ParseBlocks
  3. InitDisplay
  4. GetNewDataFile
  5. InitScoreState
  6. loop blocks: ShowBlockInstructions → RunBlock
  7. FileClose / UploadFile / debrief

---

## Task taxonomy: config recipes

Status key: ✅ implemented | 🟡 JSON-only (no new code needed) | ❌ needs new code | 🚫 out of scope

| Task | response_mode | Status | Notes |
|------|--------------|--------|-------|
| Classic 2-AFC | choice | ✅ | `2afc.json`; `collect_confidence` supported |
| SDT with payoff/bias | choice | ✅ | `sdt-payoff.json`; set `base_rate`, `feedback: payoff` |
| Go/No-Go (CPT/vigilance) | gonogo | ✅ | `gonogo.json` |
| Simon interference | simon | ✅ | `simon.json` |
| Posner spatial cueing | cued | ✅ | `cued.json`; bearing cue + cue_validity |
| Reversal learning | reversal | ✅ | `reversal.json` |
| Probabilistic reversal | reversal | ✅ | `prob-reversal.json`; p_flip_feedback |
| 2-armed bandit | bandit | ✅ | `bandit.json` |
| Optimal stopping / secretary | secretary | ✅ | `secretary.json`; nContacts 1–5, 0/1 target |
| Directional inference (urns) | urns | ✅ | `urns.json`; sequential draws, draw cost |
| Confidence rating (post-response) | choice | ✅ | `collect_confidence: 1` in any choice block |
| SDT with payoff + confidence | choice | 🟡 | combine `feedback: payoff` + `collect_confidence: 1` |
| Probability matching | choice | ✅ | `probability-matching.json`; `base_rate: 0.7`, `feedback: accuracy`; DV = choice proportion |
| Gain/loss framing | choice | ✅ | `gain-loss.json`; two blocks with mirror payoff tables |
| N-AFC (3+ options) | choice | ✅ | `nafc.json`; 3 vessels; choice iterates vessel list automatically |
| WCST / probabilistic reversal | reversal | ✅ | `prob-reversal.json`; same reversal code, `p_flip_feedback` controls reliability |
| Noisy signal discrimination | choice | 🟡 | vary `signal_mode`: jitter/noisy/mimic/prob/combo — no new JSON yet |
| Explore-exploit (horizon) | bandit | ✅ | `horizon.json`; short (1-trial) vs long (6-trial) horizon blocks |
| Ellsberg ambiguity | choice | ✅ | `ellsberg.json`; known (50%) vs unknown (~35%, unlabeled) base_rate blocks |
| BST (bivalent stroop) | simon | 🟡 | extend `simon.json`: some vessels appear on both sides across blocks; congruence already logged |
| Sustained attention (CPT-AX) | gonogo | 🟡 | requires trial-history tracking (A→X sequence); minor code addition needed |
| Oddball (Simon-variant) | simon | ✅ | `oddball.json`; 9 congruent bearings + 1 incongruent per vessel; DV = RT cost on incongruent trials |
| Flanker interference | choice | ❌ | needs distractor stripes flanking target; no rendering code |
| Stroop-like | choice | ❌ | needs conflicting vessel label rendering |
| IGT analog | bandit | ❌ | needs hidden loss schedules + deck-switching logic beyond current bandit |
| BART | — | ❌ | cover story unresolved; pump/explode mechanic not implemented |
| SDT with defer / relook | choice | ❌ | redraw signal on defer, accumulate evidence; mechanic not implemented |
| Multi-cue / multi-attribute | choice | ❌ | needs `display: both` + cue_weights; design problem for incommensurable features |
| Decoy / attraction effect | choice | ❌ | needs incommensurable attribute display; not a natural fit for perceptual signals |
| Recognition memory | — | 🚫 | not relevant to sonar paradigm |
| Scrolling simulator | — | ❌ | separate `simulator.pbl`; paused (see SIMULATOR_STATE.md) |

---

## Additional block fields for extended task coverage

```json
{
  "phase": "test",
  // "test" (default) | "study" — study blocks present stimuli with no response collected.
  // Test blocks following a study block can reference studied items for recognition tasks.

  "base_rate_known": true,
  // false = Ellsberg ambiguity: participant never learns the true base rate.
  // Omit base_rate from block config to instantiate this condition.

  "rating_timing": "post",
  // "post" (default) — confidence rating after outcome feedback (post-decision wager)
  // "pre"            — confidence rating before outcome is shown (calibration paradigm)

  "hud": {
    "show_score":          false,
    "show_trials_remaining": false,
    "show_n_pings":        false
  },
  // HUD elements shown in header area during block.
  // trials_remaining enables horizon-task strategy shifts.

  "cue_weights": null,
  // For multi-attribute tasks: list of per-vessel per-cue validity weights.
  // e.g. [[0.8, 0.6], [0.6, 0.8]] = vessel1 more diagnostic on cue1, vessel2 on cue2.
  // null = all cues fully diagnostic (default).

  "study_items": null
  // For recognition: list of vessel ids (or "all") presented in the study phase.
  // Test phase compares response against whether item was studied.
}
```

### Defer mechanic variants

| `defer.mechanic` | Description |
|---|---|
| `"relook"` | Redraw noise/signal for same vessel; participant pays cost after seeing result |
| `"sequential"` | Each defer adds one new independent observation (accumulating evidence); response locked until defer or decide |
| `"pre-purchase"` | Show cost first, participant buys look before seeing anything; models VoI and Ellsberg |

### Go/No-Go and CPT implementation notes

The existing battery (gonogo, pcpt, pcpt-ax) uses `WaitForLayoutResponse(gLayout, timeout_ms)`
which returns `"<timeout>"` when no key/click arrives within the window.
The sonar task does not use the Layout system, so the timeout mechanic uses:

```
## Register a timer event that fires after response_window ms
RegisterEvent("<TIMER>", 1, GetTime() + response_window_ms, "<GEQ>", "SetTimeout", [])
resp <- WaitForMouseButton()   ## or WaitForAnyKeyPress()
## If SetTimeout fired first, gTimedOut == 1; ignore the response
```

- **Signal trials**: vessel present, correct response = click within window (hit), no click = miss
- **Catch trials** (`gonogo.catch_rate`): no vessel / noise only, correct response = silence (CR), click = FA
- **CPT variant**: long block with mostly catch trials; `n_targets` controls exact target count
- **CPT-AX variant**: implement as sequence mode — target is only defined by A→X sequence across consecutive trials; requires `trial_history` tracking in score_state

### Oddball implementation notes

- Standard trials (majority): one vessel repeated; participant withholds response
- Deviant trials (`oddball_rate`): different vessel; participant responds
- Deviant is defined by `interference.oddball_vessel` — a different frequency signature than the standard
- The sonar cover story maps naturally: passive sonar shows the same contact repeatedly; an unexpected vessel signature is the oddball
- Log `is_oddball` flag per trial; key DV is RT difference (oddball RT - standard RT = oddball cost)

### Notes on tasks not directly implementable

- **Intertemporal discounting** (delay discounting): requires real time delays or described delays; outside the sonar display's natural cover story. Recommend implementing as a separate task.
- **Multi-attribute utility with independent cue correlations**: fully supported via `cue_weights` + `display: "both"` — bearing panel carries one cue set, narrowband the other.
- **Probability matching**: implement as repeated single-cue SDT with `signal_mode: "sequence"` and a history display strip (add HUD element `show_history: true`).

---

## Implementation order

**Phase 1 — working modular 2-AFC (foundation)**
1. `GenerateSignal` dispatcher + `MakeComboSig`
2. `ScoreTrial` + `ApplyFeedback` (accuracy + payoff)
3. `RunTrial` + `RunBlock` extracted from current `Start()`
4. `ReadConfig` from JSON; `Start()` becomes thin orchestrator

**Phase 2 — timing and inhibition tasks**
5. Go/No-Go timeout mechanic (`gonogo` response_mode, `response_window`)
6. Oddball: deviant vessel + catch trial structure
7. Posner: cue display at bearing + SOA + validity flag

**Phase 3 — interference tasks**
8. Simon: stimulus location vs. response button location conflict
9. Flanker: distractor stripes flanking target
10. Stroop-like: conflicting vessel label rendering

**Phase 4 — learning and feedback**
11. Rule engine: reversal (correct_to_reverse), then probabilistic feedback
12. WCST: multi-dimensional rule with shift

**Phase 5 — information and value**
13. Defer mechanic: relook, then sequential, then pre-purchase
14. Active sonar ping + detection risk
15. Payoff scoring: hit/miss/fa/cr table + running score HUD

**Phase 6 — display and response extensions**
16. Bearing display (`RenderBearing` using `heading_bg.png`)
17. N-way response + bandit sector layout
18. Rating response mode (pre and post)
19. Multi-attribute: `cue_weights`, `display: "both"`
