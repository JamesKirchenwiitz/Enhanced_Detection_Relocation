# proc — Relocation (HypoDD)

Scripts for taking a set of template matches and running them through the full double-difference relocation pipeline: pulling matches, retrieving waveforms, cross-correlating and aligning them, computing preliminary locations, and relocating with HypoDD.

There are two entry points, depending on whether you're relocating a single template or a combined group of templates:

- **`runme.csh`** — runs the full pipeline for one template
- **`runme.mult.csh`** — runs the full pipeline for a multi-template ("mult") combination

Both scripts are orchestrators: they call out to a series of helper scripts in order, each of which can also be run manually/skipped if its output already exists (see comments in each script).

---

## `runme.csh` — Single-Template Relocation

```bash
runme.csh <template_epoch>
```

**`<template_epoch>`** is the epoch time of the template event (e.g. `1738207596`).

### Pipeline steps

| Step | Script | Purpose |
|---|---|---|
| 1 | `get.matches.csh <temp> <combine_file>` | Pulls matches for the template from the combined match file, filtered to a minimum magnitude/quality cutoff. Writes `matches.<temp>.txt`. |
| 2 | `get.sac.csh <temp>` | Retrieves SAC waveform files for the template and its matches. *(Skip if SAC files already exist.)* |
| 3 | `wfcorr.multi.csh <temp>` | Cross-correlates waveforms across matches. *(Skip if `tempcor`/lag files already exist.)* |
| 4 | `align.csh <temp>` | Aligns waveforms using the cross-correlation lag times. *(Skip if already aligned.)* |
| 5 | `wfcorr.multi.csh <temp>` (again) | Re-runs cross-correlation on the now-aligned waveforms for improved precision. |
| 6 | `eloc2phawei.csh <temp>` | Computes preliminary absolute locations for the template and matches. |
| 7 | `dt.cc.uneven.csh <temp>` | Builds the differential-time (`dt.cc`) input file for HypoDD from the cross-correlation results. |
| 8 | `hypodd.csh <temp>` | Runs HypoDD double-difference relocation. |
| 9 | `mapx.hypodd.csh <temp>` | Generates map-view plots of the relocated events. |

**Optional/manual checks** (commented out by default): `plot.wf.mag.match.temp.chas.ws.csh <temp> <station>` can be run after steps 2 and 4 to visually confirm waveform alignment before proceeding.

**Note on template numbers/labels:** in `matches.<temp>.txt`, the last field (`$7`) is the template ID — this is how matches for a specific template are pulled from a larger combined match file (e.g. `karnescluster2.combine.bytemp.txt`) via `awk`.

---

## `runme.mult.csh` — Multi-Template Relocation

```bash
runme.mult.csh <mult_id>
```

**`<mult_id>`** is the chronological ID assigned to a specific multi-template combination (edit `multi.temp.list` to define which templates/epoch times belong to a given `<mult_id>` before running).

### Pipeline steps

| Step | Script | Purpose |
|---|---|---|
| 1 | `multi.temp.csh <mult>` | Builds the combined match file for the set of templates defined in `multi.temp.list`. Produces `matches.combine.<mult>.txt`, which is copied/renamed to `matches.<mult>.txt`. |
| 2 | `eloc2phawei.multi.csh <mult>` | Computes preliminary absolute locations for the combined template group. *(SAC files are assumed to already exist from prior single-template runs — `get.sac.csh` is not re-run.)* |
| 3 | `dt.cc.picks.csh <mult>` | Builds the differential-time input file for HypoDD from picks across the combined template group. |
| 4 | `hypodd.csh <mult>` | Runs HypoDD double-difference relocation on the combined catalog. |
| 5 | `mapx.hypodd.multi.abs.csh <mult>` | Map-view plot of relocated events (absolute locations). |
| 6 | `mapx.hypodd.multi.abs.tempnum.csh <mult>` | Map-view plot labeled by template number. |
| 7 | `mapx.hypodd.multi.abs.tn.coupe.csh <mult>` | Map-view plot with cross-section ("coupe") by template number. |
| 8 | `map.hypodd.multi.wide.csh <mult>` | Wide-area map-view plot of relocated events. |

**Optional/skippable:** `wfcorr.multi.multi.csh <mult>` (cross-correlation across the combined group) is commented out by default — only needed if you're relocating a fresh combination of templates whose pairwise correlations haven't been computed yet.

---

## Notes

- Use the same `<template_epoch>` / `<mult_id>` consistently across a run so intermediate file names (`matches.*.txt`, `loc.*`, etc.) line up correctly.
- Existing `loc.<temp>` / `loc.<mult>` directories are removed (`\rm -r`) before each run to avoid mixing results from a previous attempt.
- Steps marked "skip if X already exists" are safe to comment out on repeat runs once the relevant intermediate files have been generated once.
