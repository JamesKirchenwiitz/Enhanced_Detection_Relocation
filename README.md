# Earthquake Detection & Relocation Workflow

### Code accompanying:

An Advanced Detection and Relocation Workflow for Characterizing Seismicity Associated with Hydraulic Fracturing in the Eagle Ford Shale Play, Texas James C. Kirchenwitz, Michael R. Brudzinski, Keiana Mazzio, Mehrnaz Khalkhali (_In Prep_)

### Overview

This repository contains a general-purpose workflow for detecting and precisely relocating earthquakes using template matching and double-difference relocation. Starting from a sparse seismic catalog and continuous waveform data, the workflow expands the catalog well beyond what standard detection methods find, then relocates events with high enough precision to resolve fault geometry at depth.

It was developed and tested on hydraulic-fracturing-induced seismicity in the Karnes Trough Fault Zone (KTFZ) of the Eagle Ford Shale, Texas, but the underlying steps — template matching, pick correction, absolute location, double-difference relocation, and fault-plane fitting — are not specific to that dataset. The workflow is meant to be applied to any region with a moderately dense seismic network and a starting catalog, induced or tectonic.

The repository is set up so that the exact parameters, thresholds, and inputs used in the paper are preserved and clearly labeled, so anyone can reproduce our results directly — while also making it straightforward to swap in your own catalog, stations, and region to run the workflow on your own data.

What the Workflow Does

1. The workflow runs in six general steps. Each is written to work on any region/catalog, with the parameters used in the paper documented alongside the code so our results can be reproduced exactly.

2. Catalog retrieval — Pull an existing earthquake catalog and phase picks for your region and time period of interest. This is your starting point — it can be small; the point of the workflow is to expand it.

3. Multistation template matching — Use each catalog event as a "template" and scan continuous waveform data for waveforms that match it, using multiple stations.
  
4. Because match quality (correlation coefficient) varies template to template, the workflow determines a statistically-derived, template-specific detection threshold automatically rather than relying on one fixed cutoff for the whole catalog.

5. Pick correction & propagation — Automated arrival-time picks are often unreliable, so this step corrects picks on template events and propagates accurate timing to every matched event using waveform cross-correlation.

6. Preliminary absolute location — Compute an initial location for every newly detected event using the corrected picks and a 1-D velocity model for your region.

7. Double-difference relocation (HypoDD) — Refine all hypocenters together, using both catalog timing and cross-correlation-derived differential times, to dramatically sharpen the relative positions of nearby events.

8. Fault geometry analysis: Can fit the relocated hypocenters to planar fault structures using RANSAC regression, which is robust to the vertical scatter/noise common in relocated depth estimates.

A single-template and a multi-template ("mults") mode are both included. The latter lets you combine and relocate several nearby template families relative to one another, which is useful for resolving fault segments that individual templates alone can't distinguish.

## Workflow Summary of Steps:
![Flow Chart](https://github.com/JamesKirchenwiitz/Detection-and-Relocation-Workflow/blob/main/workflow.png)

### Applying This to Your Own Data

To run this workflow on a different region, you'll generally need to supply:

A starting earthquake catalog with phase picks for your area of interest
Continuous waveform data from at least 3 nearby stations
A local 1-D velocity model for absolute location and HypoDD

See the paper's Data Collection and Workflow Development sections for the specific inputs and parameter choices we used, which are documented in the code as a reference configuration.
