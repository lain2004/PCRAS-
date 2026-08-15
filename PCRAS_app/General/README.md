# PCRAS-GDMS Parameter Optimization Tool

[![MATLAB](https://img.shields.io/badge/MATLAB-R2018b%2B-orange)](https://www.mathworks.com/)
[![License](https://img.shields.io/badge/License-MIT-blue)](LICENSE)

A MATLAB-based graphical tool for optimizing **PMRI-CRAS** (Progressive Mixing-Roughness-Information with **CRA**ter effect correction) model parameters for GDMS (Glow Discharge Mass Spectrometry) depth profiling of multilayer thin films. Integrates the Starfish Optimization Algorithm (SFOA) and Particle Swarm Optimization (PSO) to fit experimental depth-concentration data.

---

## Table of Contents

- [Features](#features)
- [Scientific Background](#scientific-background)
  - [The GDMS Depth Profiling Problem](#the-gdms-depth-profiling-problem)
  - [PMRI Model: Preferential Sputtering, Mixing, Roughness, Information Depth](#pmri-model-preferential-sputtering-mixing-roughness-information-depth)
  - [CRA Model: Crater Geometry Correction](#cra-model-crater-geometry-correction)
  - [Mass Conservation](#mass-conservation)
  - [Full Forward Model Pipeline](#full-forward-model-pipeline)
- [Core Variables Glossary](#core-variables-glossary)
- [System Requirements](#system-requirements)
- [Quick Start](#quick-start)
- [User Interface Guide](#user-interface-guide)
- [Optimized Parameters](#optimized-parameters)
- [Algorithms](#algorithms)
- [Configuration Management](#configuration-management)
- [Standalone Executable](#standalone-executable)
- [File Structure](#file-structure)
- [References](#references)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Features

- **All-in-one GUI** — No command-line interaction required; all parameters adjustable through an intuitive 5-tab interface
- **Dual-algorithm support** — SFOA (Starfish Optimization, no toolbox needed) and PSO (Particle Swarm, requires Global Optimization Toolbox)
- **Real-time convergence visualization** — Error curve updates iteration-by-iteration via persistent line handle (no flicker)
- **Live progress tracking** — `[##########..........] Iter: 600/1200 (50.0%)` with elapsed time and ETA
- **Interruptible execution** — STOP button halts optimization at next iteration checkpoint
- **Configuration persistence** — Auto-save on close / auto-load on open; manual save/load supported
- **Result export** — Excel (4 sheets) or MAT format; includes fit comparison, optimized params, layer thicknesses, convergence curve
- **Flexible bound settings** — Three modes: percentage-relative, absolute-relative, absolute
- **Four sigma models** — Linear, Constant, Square-root, Exponential — all fully wired to the forward model
- **Standalone executable** — Compile to self-contained `.exe` for distribution to users without MATLAB

---

## Scientific Background

### The GDMS Depth Profiling Problem

Glow Discharge Mass Spectrometry (GDMS) measures elemental signal intensity $I(z)$ as a function of sputtering depth $z$ in multilayer thin films. The measured profile is **not** the true concentration profile $C_{true}(z)$ — it is broadened by multiple physical effects:

1. **Preferential sputtering** — Different elements sputter at different rates ($q_A \neq q_B$), causing surface composition to deviate from bulk stoichiometry during analysis.
2. **Atomic mixing** — Collision cascades in the sputter crater intermix atoms across layer boundaries.
3. **Surface roughness** — Sputtering progressively roughens the crater bottom, blurring interfaces.
4. **Information depth** — Sputtered atoms escape from a finite depth range, not just the top monolayer.
5. **Crater geometry** — Non-uniform sputtering flux across the curved crater bottom means atoms from different radial positions originate from different depths.

The PMRI-CRAS model deconvolves these effects by forward-modeling the measured signal from an assumed layer structure and optimizing the model parameters to match experiment.

### PMRI Model: Preferential Sputtering, Mixing, Roughness, Information Depth

The PMRI model [1] describes how the true concentration profile $C_0(z)$ is degraded by four sequential broadening mechanisms:

#### Step 1: Concentration Profile Construction

Given $L$ alternating layers with thicknesses $t_1, t_2, ..., t_L$ and first-layer concentration $c_1$:

$$C_0(z) = \begin{cases} c_1 & \text{if layer index is odd} \\ 1 - c_1 & \text{if layer index is even} \end{cases}$$

Interface positions: $z_k = \sum_{j=1}^{k} t_j$, with $z_0 = 0$, $z_L = \sum t_j$.

#### Step 2: Roughness Broadening (σ)

Interface roughness is modeled as depth-dependent Gaussian broadening. The roughness parameter σ evolves with depth according to the selected sigma model:

$$\sigma(z) = \begin{cases} \sigma_0 + \sigma_k \cdot z & \text{Linear (default)} \\ 0.1 & \text{Constant} \\ \sqrt{\sigma_0 + \sigma_k \cdot z^2} & \text{Square-root} \\ \sigma_k \cdot \sigma_0^{\sigma_c \cdot z} & \text{Exponential} \end{cases}$$

The concentration after roughness broadening $C_\sigma(z)$ is computed by convolving $C_0(z)$ with a depth-dependent Gaussian kernel of width $\sigma(z)$, truncated at $\pm c_{cons} \cdot \sigma(z)$:

$$C_\sigma(z) = \frac{\int_{z-c_{cons}\sigma}^{z+c_{cons}\sigma} C_0(z') \cdot g(z-z', \sigma(z)) \, dz'}{\int_{z-c_{cons}\sigma}^{z+c_{cons}\sigma} g(z-z', \sigma(z)) \, dz'}$$

where $g(x, \sigma) = \frac{1}{\sigma\sqrt{2\pi}} \exp\left(-\frac{x^2}{2\sigma^2}\right)$ is the normalized Gaussian.

#### Step 3: Atomic Mixing (w)

Collisional mixing in the crater is modeled by a differential equation driven by the sputtering rate ratio $r = q_A / q_B$:

$$\frac{dC_w}{dz} = \frac{C_\sigma(z + w) - r \cdot C_w(z) / (C_w(z) \cdot (r-1) + 1)}{w}$$

with the normalized output:

$$I_{MRI}(z) = \frac{C_w(z) \cdot q_A}{C_w(z) \cdot q_A + (1 - C_w(z)) \cdot q_B}$$

The mixing length $w$ represents the depth scale over which collision cascades homogenize the composition.

#### Step 4: Information Depth (λ)

Atoms are not ejected exclusively from the top monolayer — they escape from a finite depth range characterized by the information depth $\lambda$. This is modeled as an exponential decay convolution:

$$I_{\lambda}(z) = \frac{\int_0^\infty I_{MRI}(z') \cdot \exp(-|z - z'| / \lambda) \, dz'}{\int_0^\infty \exp(-|z - z'| / \lambda) \, dz'}$$

### CRA Model: Crater Geometry Correction

The sputtering crater in GDMS is not flat-bottomed — it has a curved profile that causes atoms at different radial positions to originate from different depths. The CRA (CRater effect) model [2] corrects for this by integrating over the crater radius.

#### Crater Flux Function

The sputtering flux distribution across the crater radius $r \in [0, 1]$ is described by:

$$F_R(r) = \frac{(b_{FR} + 2) \cdot (1 + (p_{FR} - 1) \cdot r^{b_{FR}})}{b_{FR} + 2 \cdot p_{FR}}$$

- **$b_{FR}$** (flux exponent): Controls the curvature of the flux distribution. Higher values → steeper flux gradient from crater center to edge.
- **$p_{FR}$** (crater shape exponent): Determines the overall crater profile shape. $p_{FR} = 1$ → uniform flux; $p_{FR} > 1$ → enhanced sputtering at crater center.

#### Weighted Intensity Distribution

The angular acceptance of the mass spectrometer is modeled by:

$$W(r) = \frac{1}{r + 1}$$

This accounts for the fact that atoms sputtered from the crater edge are detected with different efficiency than those from the center.

#### Crater Integration

For each depth $z$, the apparent depth at radial position $r$ is:

$$z_{module}(r) = z \cdot F_R(r)$$

The final modeled signal is the weighted average over all radial positions:

$$I_{model}(z) = \frac{\sum_{r} W(r) \cdot r \cdot q_{ave}(r,z) \cdot F_R(r) \cdot I_{\lambda}(r,z) \cdot \Delta r}{\sum_{r} W(r) \cdot r \cdot q_{ave}(r,z) \cdot F_R(r) \cdot \Delta r}$$

where $q_{ave}(r,z) = I_{\lambda}(r,z) \cdot q_A + (1 - I_{\lambda}(r,z)) \cdot q_B$ is the local average sputtering rate.

### Mass Conservation

A critical physical constraint in depth profiling is mass conservation [1]: the total amount of each element must be preserved during sputtering. In the model, this is enforced by:

1. **Layer thickness constraint**: $\sum_{i=1}^{L} t_i \leq \max(z_{data})$
   - If this is violated, the forward model returns zero (invalid configuration).
   - The "substrate" layer thickness is auto-calculated as $t_{sub} = \max(z_{data}) - \sum t_i$.

2. **Sputtering rate ratio**: The preferential sputtering effect is governed by $r = q_A / q_B$. When $r \neq 1$, the surface composition deviates from the bulk — this is the essence of preferential sputtering.

3. **Additional thickness correction**: An integral correction term tracks the mass balance throughout the depth profile.

### Full Forward Model Pipeline

```
Experimental Data                    Layer Structure
       │                                   │
       ▼                                   ▼
  Interpolation ─────────────────► Concentration Profile C₀(z)
       │                                   │
       ▼                                   ▼
  Preprocessing              Roughness Broadening (σ model)
  (NaN removal, clipping)              │
       │                                ▼
       ▼                           Mixing (w)
  fit_data ◄────────────────────          │
                                        ▼
                              Information Depth (λ)
                                        │
                                        ▼
                              Crater Integration (b_FR, p_FR)
                                        │
                                        ▼
                              I_model(z) ──► Compare with fit_data
```

---

## Core Variables Glossary

### Fixed Parameters (Set by User)

| Variable | Symbol | Physical Meaning | Typical Range | Default |
|----------|--------|------------------|---------------|---------|
| **inddis** | $\Delta z$ | Depth sampling interval (nm). Defines the numerical grid resolution. | 0.1 – 5 | 1.0 |
| **w** | $w$ | Atomic mixing length (nm). Characteristic depth of collision-cascade-induced mixing. Larger → broader interfaces. | 0.5 – 5 | 1.0 |
| **dr** | $\Delta r$ | Radial integration step for crater calculation (normalized). Smaller → more precise crater integration. | 0.0005 – 0.01 | 0.001 |
| **lambda** | $\lambda$ | Information depth (nm). Effective escape depth of sputtered atoms. Larger → deeper information origin. | 0.5 – 5 | 1.0 |
| **cons** | $c_{cons}$ | Truncation multiplier for Gaussian convolution window ($\pm c_{cons} \cdot \sigma$). Larger → more accurate but slower. | 3 – 10 | 5.0 |
| **firstlayer_c** | $c_1$ | Concentration of element A in the topmost layer. `1` = pure A; `0` = pure B. | $\{0, 1\}$ | 1 |
| **startpoint** | — | Index of first data point used for error calculation. | $\geq 1$ | 1 |
| **endpoint** | — | Index of last data point after dropping end points. | $\leq N_{data}$ | auto |

### Optimized Parameters (Adjusted by Algorithm)

| Index | Variable | Symbol | Physical Meaning | Typical Bounds |
|-------|----------|--------|------------------|----------------|
| $x_1$ | **sigma_0** | $\sigma_0$ | Base interface roughness at the surface (nm). Represents the intrinsic interface width at $z = 0$. | [0.1, 10] |
| $x_2$ | **sigma_k** | $\sigma_k$ | Roughness growth rate with depth. Positive → roughness accumulates during sputtering. | [0, 1] |
| $x_3$ | **sigma_c** | $\sigma_c$ | Exponent parameter for the Exponential sigma model. Controls acceleration of roughness growth. | [-10, 10] |
| $x_4$ | **b_FR** | $b_{FR}$ | Crater flux exponent. Controls curvature of the sputtering flux distribution $F_R(r)$. Higher → steeper flux gradient from center to edge. | [0.01, 10] |
| $x_5$ | **p_FR** | $p_{FR}$ | Crater shape exponent. Determines the crater bottom profile. $p_{FR}=1$ = uniform; $p_{FR}>1$ = center-enhanced. | [0, 10] |
| $x_6$ | **q_A** | $q_A$ | Sputtering rate of element A (nm/s or a.u.). Governs preferential sputtering via the ratio $r = q_A/q_B$. | $\approx$ nominal $\pm$ 20% |
| $x_7$ | **q_B** | $q_B$ | Sputtering rate of element B. Together with $q_A$, controls mass conservation and preferential sputtering. | $\approx$ nominal $\pm$ 20% |
| $x_{8:7+L}$ | **obj_tn** | $t_1, ..., t_L$ | Layer thicknesses (nm). $L$ = number of layers. The substrate thickness is auto-computed. | $\sum t_i < \max(z)$ |

### Derived Variables (Auto-Computed Inside the Model)

| Variable | Formula | Meaning |
|----------|---------|---------|
| $r$ | $q_A / q_B$ | Sputtering rate ratio — the key driver of preferential sputtering |
| $C_\sigma(z)$ | MRI convolution | Concentration after roughness broadening |
| $C_w(z)$ | Mixing ODE solution | Concentration after atomic mixing |
| $I_{MRI}(z)$ | MRI output normalization | Intensity after full MRI processing |
| $I_\lambda(z)$ | Exponential decay convolution | Intensity after information depth broadening |
| $F_R(r)$ | Crater flux function | Relative sputtering flux at radial position $r$ |
| $W(r)$ | Weighted intensity distribution | Angular acceptance weighting |
| $q_{ave}(z)$ | $I \cdot q_A + (1-I) \cdot q_B$ | Local average sputtering rate |
| $z_{module}(r)$ | $z \cdot F_R(r)$ | Effective depth at radial position $r$ |
| $t_{sub}$ | $\max(z) - \sum t_i$ | Substrate thickness (auto-calculated for mass conservation) |
| DR$(z)$ | $\sqrt{(2\sigma(z))^2 + (1.67\lambda)^2 + (1.67w/r)^2}$ | Total depth resolution at depth $z$ |

### Optimization Objective

Given experimental data $\{(z_i, I_i^{exp})\}_{i=1}^N$:

$$\text{RMSE}(\theta) = \sqrt{\frac{1}{N} \sum_{i=1}^N \left(I_i^{exp} - I_i^{model}(\theta)\right)^2} \times 100\%$$

The optimization vector is:

$$\theta = [\underbrace{\sigma_0, \sigma_k, \sigma_c}_{\text{Sigma (3)}}, \underbrace{b_{FR}, p_{FR}}_{\text{CRA (2)}}, \underbrace{q_A, q_B}_{\text{Rates (2)}}, \underbrace{t_1, t_2, ..., t_L}_{\text{Layer thicknesses (L)}}]$$

Total dimension: $nD = 7 + L$, where $L$ is the number of layers.

---

## System Requirements

| Component | Minimum Version |
|-----------|----------------|
| MATLAB | R2018b or later |
| Toolboxes | *(none required for GUI + SFOA mode)* |
| Global Optimization Toolbox | Only if using PSO algorithm |
| MATLAB Compiler | Only for standalone `.exe` generation |

### For Standalone Executable Users

If you received the compiled `.exe`:
- Download and install **MATLAB Runtime** (free) from [MathWorks MCR page](https://www.mathworks.com/products/compiler/mcr/)
- Match the Runtime version to the version used during compilation (shown in the installer filename)

---

## Quick Start

1. **Launch the tool**:
   ```matlab
   cd('PCRAS-GDMS')
   PCRAS_Tool
   ```

2. **Load your data**: Go to **Data Import** tab → Browse for your Excel file → Set column indices → Click **Load Data**

3. **Set up layers**: Go to **Layers & Bounds** tab → Set number of layers and thickness → Click **Apply Layer Settings**

4. **Review model parameters**: Go to **Model Params** tab → Adjust MRI/CRA parameters as needed

5. **Run optimization**: Go to **Run & Results** tab → Click **START OPTIMIZATION**

6. **Export results**: After completion, click **Export Results** to save to Excel or MAT file

---

## User Interface Guide

### 1. Data Import

| Field | Description | Default |
|-------|-------------|---------|
| File path | Path to Excel/CSV file with experimental data | *(browse to select)* |
| Depth column (Z) | Column index for depth values | 1 |
| Signal column (I) | Column index for signal intensity values | 2 |
| Sheet name | Excel sheet name (empty = first sheet) | *(empty)* |
| Sampling interval (inddis) | Interpolation step size for depth axis | 1 |
| Start point | First data point index for error calculation | 1 |
| End drop points | Number of points to discard at the end | 0 |

**Data preprocessing pipeline:**
1. Read Excel file → 2. Remove NaN/Inf values → 3. Interpolate to uniform depth grid → 4. Clip signal to [lower, upper] range → 5. Store for optimization

### 2. Model Parameters

#### MRI Parameters

| Parameter | Symbol | Description | Default |
|-----------|--------|-------------|---------|
| Mixing parameter | `w` | Atomic mixing length | 1.0 |
| Depth resolution | `dr` | Radial step for crater integration | 0.001 |
| Information depth | `lambda` | Effective escape depth of sputtered atoms | 1.0 |
| Truncation range | `cons` | Sigma multiplier for Gaussian convolution window | 5.0 |

#### CRA Parameters [Optimized]

| Parameter | Symbol | Description | Bounds |
|-----------|--------|-------------|--------|
| Flux exponent | `b_FR` | Exponent in crater flux function $F_R(r)$ | [0.01, 10] |
| Crater shape exponent | `p_FR` | Exponent in crater shape function | [0, 10] |

#### Sigma Model [Optimized]

Four interface roughness models are available (all fully wired to the forward model):

1. **Linear**: $\sigma(z) = \sigma_0 + \sigma_k \cdot z$ — roughness grows linearly with depth *(default, most common)*
2. **Constant**: $\sigma(z) = 0.1$ — fixed roughness, all interfaces have identical width
3. **Square-root**: $\sigma(z) = \sqrt{\sigma_0 + \sigma_k \cdot z^2}$ — sub-linear growth, roughness increase slows with depth
4. **Exponential**: $\sigma(z) = \sigma_k \cdot \sigma_0^{\sigma_c \cdot z}$ — accelerating growth, roughness increases rapidly

#### Sputtering Rates [Partially Optimized]

| Parameter | Description | Default |
|-----------|-------------|---------|
| `q_A` | Sputtering rate of material A | 8.83 |
| `q_B` | Sputtering rate of material B | 6.98 |
| `firstlayer_c` | Concentration of element A in first layer (0 or 1) | 1 |

### 3. Layers & Bounds

#### Layer Thickness Configuration

- **Uniform layers (quick)**: Set number of layers and per-layer thickness; all layers get equal thickness
- **Manual array input**: Enter a MATLAB array expression (e.g., `[30 8 16 25 40 20 32 15]`)

#### Bound Types

| Type | Description | Formula |
|------|-------------|---------|
| Percentage-relative | Bounds are percentage of nominal value | `lb = coeff_low × nominal`, `ub = coeff_high × nominal` |
| Absolute-relative | Bounds are offset from nominal value | `lb = nominal - offset_low`, `ub = nominal + offset_high` |
| Absolute | Fixed absolute bounds for all layers | `lb = 0`, `ub = 50` |

Individual bounds can be set for each optimized parameter (sigma_0, sigma_k, sigma_c, b_FR, p_FR).

### 4. Optimization Settings

| Setting | Description | Default |
|---------|-------------|---------|
| Algorithm | SFOA or PSO | SFOA |
| Population size (Npop) | Number of candidate solutions | 60 |
| Max iterations (Max_it) | Maximum optimization iterations | 1200 |
| SFOA: GP | Exploration/exploitation balance (0=exploit, 1=explore) | 0.5 |
| PSO: FunctionTolerance | Convergence tolerance | 1e-20 |
| PSO: MaxStallIterations | Stall limit before termination | 1200 |
| b_FR/p_FR precision | Decimal places for CRA parameters | 1 |
| Interpolation method | Method for data resampling | spline |
| Random seed | Seed for reproducibility (0=random) | 0 |

### 5. Run & Results

The results tab provides:

- **Progress bar** — `[##########....................] Iter: 600/1200 (50.0%)`
- **Elapsed time** — HH:MM:SS format
- **ETA** — Estimated time remaining based on current progress rate
- **Convergence curve** — Real-time semi-log plot of error vs. iteration
- **Fit comparison** — Three-line plot: experiment (blue), fitted (red), difference (green)
- **Results panel** — Full breakdown of optimized parameters with reference comparison
- **Export** — Save results as `.xlsx` (4 sheets: fit comparison, params, thicknesses, convergence) or `.mat`

---

## Algorithms

### SFOA (Starfish Optimization Algorithm)

A nature-inspired metaheuristic that mimics the predatory behavior of starfish:

- **Exploration phase**: Random perturbation using trigonometric functions (cos/sin) to search broadly
- **Exploitation phase**: Uses difference vectors from 5 randomly selected individuals (mimicking a starfish's 5 arms) for local refinement
- **Regeneration**: The last individual undergoes exponential decay to escape local optima
- **Adaptive balance**: The GP parameter (default 0.5) controls the exploration/exploitation ratio, transitioning from exploration to exploitation as iterations progress

### PSO (Particle Swarm Optimization)

Standard MATLAB `particleswarm` implementation from the Global Optimization Toolbox:

- Population-based stochastic optimization
- Each particle updates its velocity based on personal and global best positions
- Supports early stopping via `MaxStallIterations` and `FunctionTolerance`

---

## Configuration Management

### Auto-Save / Auto-Load

- On app close → writes `PCRAS_Tool_autosave.mat` (gitignored)
- On app open → automatically restores previous session
- Includes all UI settings: file path, parameters, bounds, algorithm settings

### Manual Save/Load

- **Save Current Configuration**: Export settings to a named `.mat` file
- **Load Configuration File**: Restore settings from a saved file
- **Reset to Defaults**: Restore factory defaults

---

## Standalone Executable

### Building the .exe

If you have MATLAB Compiler:

```matlab
cd('PCRAS-GDMS')
compile_PCRAS
```

This script:
1. Builds standalone `.exe` (requires MATLAB Runtime) → `compiled/`
2. Builds web installer (auto-downloads Runtime) → `compiled_installer/`
3. Auto-syncs source files to `Design/` for developers
4. Auto-syncs `.exe` + docs + sample data to `General/` for end users

### Distributing to Users

**For users WITHOUT MATLAB**: Provide the web installer from `General/PCRAS_Optimization_Tool_Installer.exe` (~2.5 MB). On first run, it automatically downloads and installs MATLAB Runtime (~1 GB, one-time).

**For users WITH MATLAB**: Provide the source files from `Design/` — they run `PCRAS_Tool` directly.

---

## File Structure

```
PCRAS-GDMS/
├── PCRAS_Tool.m              # Main GUI application (~1338 lines)
├── P_MRICRAS_func.m             # PMRI-CRA forward model
├── SFOA.m                       # Starfish Optimization Algorithm + PSO wrapper
├── mainSFOA.m                   # Original CLI version (no GUI)
├── compile_PCRAS.m           # Build script + auto-sync to distribution folders
├── README.md                    # This file (scientific documentation)
├── USER_MANUAL.md               # User manual (quick-start, button reference, tuning guide)
├── PROJECT_PROGRESS.md          # Development history and progress tracker
├── .gitignore
├── 深度浓度-清洁版数据.xlsx      # Sample experimental data
├── PCRAS_Tool_autosave.mat   # Auto-saved session config (gitignored)
│
├── General/                     # Distribution: for non-MATLAB end users
│   ├── PCRAS_Optimization_Tool_Installer.exe
│   ├── PCRAS_Optimization_Tool.exe
│   ├── README.md
│   ├── USER_MANUAL.md
│   └── sample_data.xlsx
│
├── Design/                      # Distribution: for developers with MATLAB
│   ├── PCRAS_Tool.m
│   ├── P_MRICRAS_func.m
│   ├── SFOA.m
│   ├── mainSFOA.m
│   ├── compile_PCRAS.m
│   ├── README.md
│   └── USER_MANUAL.md
│
├── compiled/                    # Build output: standalone .exe (gitignored)
└── compiled_installer/          # Build output: web installer (gitignored)
```

---

## References

1. **Lian, X. et al. (2019).** Preferential sputtering and mass conservation in AES and SIMS depth profiling. — Establishes the theoretical foundation for preferential sputtering correction ($q_A$, $q_B$, $r = q_A/q_B$) and mass conservation constraints in depth profiling.

2. **Liu, Y. et al. (2026).** Influences of sputtered crater geometry on glow discharge spectrometry depth profile. — Characterizes how crater shape ($b_{FR}$, $p_{FR}$) and flux distribution $F_R(r)$ affect GDMS depth resolution, forming the basis for the CRA crater correction model.

If you use this tool in your research, please cite both the tool and the underlying model papers.

---

## Troubleshooting

| Issue | Solution |
|-------|----------|
| **"Data load failed"** | Check that your Excel file has numeric columns and the column indices are correct |
| **"Layer thickness sum exceeds data range"** | Ensure `sum(obj_tn) < max(depth_data)` — mass conservation constraint |
| **Stop button not responding** | Wait for current iteration to complete (check happens once per iteration) |
| **PSO requires Global Optimization Toolbox** | Switch to SFOA algorithm or install the toolbox |
| **Convergence is slow** | Reduce population size or max iterations; increase `inddis` for fewer data points |
| **Empty result / NaN error** | Verify `inddis` is not larger than `w` or `lambda`; check `firstlayer_c` matches your data |
| **Compiled .exe won't start** | Install the matching MATLAB Runtime version; first launch may take ~30 seconds |
| **App window is too large/small** | Resize the window — layout is responsive |

---

## License

MIT License — see LICENSE file for details.

*This tool is provided as open-source software to support reproducible research in GDMS depth profiling of multilayer thin films.*
