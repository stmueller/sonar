# PEBL Sonar Task Simulator

JSON-driven decision-making experiments using a sonar (narrowband waterfall / bearing) cover story. This is a PEBL experiment, not a standalone application: it runs under [PEBL](https://github.com/stmueller/pebl).

## Layout

| Path | Role |
|------|------|
| `sonar-task.pbl` | Experiment engine |
| `config/` | Task recipes (2AFC, go/no-go, Simon, bandit, …) |
| `params/` | PEBL parameter schema (`task` = config name or `askuser`) |
| `img/` | Waterfall/heading backgrounds, stripes, noise, thumbnails |
| `sounds/` | Background bed and vessel clips |
| `archive/` | Earlier 2AFC scripts and scrolling simulator |
| `SONAR_TASK_ARCHITECTURE.md` | Config schema and task taxonomy |
| `SIMULATOR_STATE.md` | Notes on the paused scrolling waterfall demo |

## Run

Requires a PEBL 2.x binary (`pebl2`) from a PEBL install or a sibling checkout of `pebl`.

```bash
# from this directory
/path/to/pebl2 sonar-task.pbl

# sibling checkout example
../pebl/bin/pebl2 sonar-task.pbl
```

With no `--pfile`, the `task` parameter defaults to `askuser` and you pick a file from `config/`. To pin a recipe:

```bash
../pebl/bin/pebl2 sonar-task.pbl --pfile sonar-task.pbl.par.json
```

Set `"task"` in `params/sonar-task.pbl.par.json` to a config stem (e.g. `2afc`, `gonogo`).

Data files are written under `data/` (gitignored).

## Trial scheduling (case list)

Blocks can pin an exact design instead of sampling each trial independently:

| Field | Role |
|-------|------|
| `vessel_counts` | Exact class counts in `vessels[]` order → shuffled case list |
| `repetitions` | Replay each base case with the same forced signature |
| `noise_profiles` | Per-case `signal_params` overrides (e.g. mix of low/high `jitter_sd`); each entry needs `count`; inherits unspecified fields from block `signal_params` |

If `noise_profiles` is omitted, the block’s single `signal_params` applies to every trial (legacy behavior). See `SONAR_TASK_ARCHITECTURE.md` and `config/nafc_study1.json` (`block-threshold`). Quick local check: set `task` to `nafc-threshold-mini-demo` (9 trials, one block) or run the full shortened study via `nafc-study1-demo`.

## Audio and animation

`sonar-task.pbl` currently exposes `useAudio` and `useWaterfallAnimation` parameters; wiring those to playback and the scrolling simulator is in progress. Archive scripts under `archive/` show the earlier audio + scroll patterns.

Background bed: `sounds/FX_BBbgnd.ogg` is a 20 s seamless loop (Vorbis). Play it with `SetPlayRepeats(snd, -1)` then `PlayBackground(snd)` so it runs for the whole session without a 45-minute WAV. Vessel clips are already short `.ogg` files. WAV masters are gitignored.
