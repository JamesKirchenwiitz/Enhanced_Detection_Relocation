# edet — Earthquake Detection (Template Matching)

Scripts for building a seismic catalog into a set of templates, running multistation template matching against continuous waveform data, and combining/visualizing the results.

## Workflow

The scripts are meant to be run in order:

1. `get.cat.py` → 2. `hpc.detect.3sta.local.csh` → 3. `combine.lcurve.bytemp.csh` → 4. `plot.wf.mag.match.csh`

---

### 1. `get.cat.py`

Queries the USGS earthquake catalog (rectangular or radius search) for events matching a set of parameters (region, time range, magnitude, etc.).

**Output:** a CSV of catalog events, written as `getcatpy.<input>.csv`. This file is the template list that feeds template matching in the next step.

```bash
python get.cat.py [options]
```

---

### 2. `hpc.detect.3sta.local.csh`

Runs multistation template matching: scans continuous waveform data for each event in the catalog CSV, using 3 nearby stations per template.

**Input:** a `getcatpy.<label>.csv` file produced by step 1. The `<label>` is passed as the argument.

**Output:** one file of matches per template.

```bash
hpc.detect.3sta.local.csh <label>
```

**Example:** if your catalog file is `getcatpy.2023feb09.csv`, run:

```bash
hpc.detect.3sta.local.csh 2023feb09
```

---

### 3. `combine.lcurve.bytemp.csh`

Combines all per-template match files from step 2 into a single master file.

```bash
combine.lcurve.bytemp.csh <label>
```

**Example:** continuing with `2023feb09`, this produces:

```
2023feb09.combine.bytemp.txt
```

---

### 4. `plot.wf.mag.match.csh`

Generates diagnostic plots for a template and its matches: waveforms annotated with magnitude and cross-correlation values, alongside a magnitude-over-time plot for the detected sequence.

```bash
plot.wf.mag.match.csh <label>
```

---

## Notes

- Run the scripts in the order above — each step consumes the output of the one before it.
- Use the same `<label>` (e.g. `2023feb09`) consistently across steps 2–4 so file names line up correctly.
