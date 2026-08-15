# PCRAS-GDMS Optimization Tool — User Manual

---

## Quick Start: Your First Optimization in 5 Minutes

### Step 1: Launch the App

**If you have MATLAB:**
```matlab
cd('PCRAS-GDMS')
PCRAS_Tool
```

**If you received the .exe:**
Double-click `PCRAS_Optimization_Tool.exe` (first launch may take ~30 seconds to unpack the Runtime).

### Step 2: Load Your Data

1. Click the **Data Import** tab.
2. Click **Browse...** and select your Excel file (`.xlsx`, `.xls`, or `.csv`).
   - The file must have at least 2 numeric columns: one for depth, one for signal intensity.
3. Set **Depth column (Z)** and **Signal column (I)** to the correct column numbers (default: 1 and 2).
4. Click **Load Data**.
5. You should see a blue line appear in the preview plot. If not, check your column numbers.

### Step 3: Set Up Layer Structure

1. Click the **Layers & Bounds** tab.
2. Choose **Uniform layers (quick)** for equal-thickness layers, or **Manual array input** to type specific values.
3. Set the **Number of layers** and **Default thickness per layer**, then click **Apply Layer Settings**.
4. Verify the **Current thickness array** shown below looks correct.

### Step 4: Check Model Parameters

1. Click the **Model Params** tab.
2. Verify the MRI parameters (`w`, `dr`, `lambda`, `inddis`, `cons`) match your experimental conditions.
3. Set **firstlayer_c**: `1` if the first layer contains element A, `0` if it is a zero-concentration layer.
4. Adjust sputtering rates `q_A` and `q_B` to match your instrument calibration.
5. Choose the **Sigma model** appropriate for your sample (see [Sigma Model Selection Guide](#sigma-model-selection-guide)).

### Step 5: Run Optimization

1. Click the **Run & Results** tab.
2. Click **START OPTIMIZATION**.
3. Watch the convergence curve update in real time. The progress bar shows current iteration, elapsed time, and ETA.
4. When complete, results appear in the **Optimization Results** panel.
5. Click **Export Results** to save everything to an Excel or MAT file.

---

## Interface Reference: Every Button and Field Explained

---

### Tab 1: Data Import

| Element | What It Does |
|---------|-------------|
| **Browse...** | Opens a file picker to select your experimental data file (.xlsx/.xls/.csv) |
| **File path** | Shows the selected file path. You can also type/paste a path directly. |
| **Depth column (Z)** | Which column in the Excel file contains depth values (1 = column A, 2 = column B, ...) |
| **Signal column (I)** | Which column contains signal intensity values |
| **Sheet name** | Excel sheet name. Leave empty to use the first sheet. |
| **Sampling interval (inddis)** | Step size for the interpolated depth grid (nm). Smaller = finer grid but slower computation. Must be ≤ `w` and ≤ `lambda`. |
| **Start point** | Index of the first data point used for error calculation. Increase if the first few data points are noisy (e.g., surface transient). |
| **End drop points** | Number of data points to discard at the end. Useful for trimming unstable tail regions or substrate signal. |
| **Load Data** | Reads the file, interpolates to a uniform grid, clips outliers, and displays the preview plot. |
| **Data Preview plot** | Shows the loaded experimental data after preprocessing. |
| **Reference Parameters** | Reference values shown alongside optimized results for comparison. Purely informational — they do NOT affect optimization. Useful for tracking how far the optimizer moves from your initial estimates. |

---

### Tab 2: Model Params

#### MRI Parameters

| Parameter | Symbol | Physical Meaning | Typical Range |
|-----------|--------|------------------|---------------|
| **Mixing parameter w** | $w$ | Atomic mixing length (nm). Characterizes the depth scale of collision-cascade-induced atomic relocation. Ions impact the surface and displace atoms within ~$w$ of the surface. Larger $w$ → broader interfaces in the fitted profile. | 0.5 – 5 |
| **Depth resolution dr** | $\Delta r$ | Radial integration step for the crater effect calculation (normalized unit). Controls the precision of the numerical integration over the crater radius. Smaller = more precise but proportionally slower. | 0.001 – 0.01 |
| **Information depth lambda** | $\lambda$ | Effective escape depth of sputtered atoms (nm). Sputtered atoms originate from a subsurface zone, not just the top atomic layer. Larger $\lambda$ → deeper information origin → more broadened profiles. | 0.5 – 5 |
| **Sampling interval inddis** | $\Delta z$ | Depth grid resolution (nm). Same value as in Tab 1. Changing here syncs to Tab 1 automatically. **Critical**: must be ≤ `w` and ≤ `lambda` for numerical stability. | 0.1 – 5 |
| **Truncation range cons** | $c_{cons}$ | Multiplier defining the Gaussian convolution window as $\pm c_{cons} \cdot \sigma(z)$. A value of 5 means the window spans $\pm 5\sigma$, capturing 99.9999% of the Gaussian area. Larger = more accurate but slower. | 3 – 10 |

#### CRA (Crater Effect) Parameters — These Are Optimized

The crater geometry correction is based on Liu et al. (2026), which characterized how sputtering flux varies across the curved crater bottom.

| Parameter | Symbol | Physical Meaning | Typical Bounds |
|-----------|--------|------------------|----------------|
| **b_FR** | $b_{FR}$ | Crater flux exponent. Controls the curvature of the sputtering flux distribution $F_R(r)$ across the crater radius. Higher values → steeper flux drop-off from crater center to edge → stronger crater effect correction. | [0.01, 10] |
| **p_FR** | $p_{FR}$ | Crater shape exponent. Determines the crater bottom profile. $p_{FR} = 1$ gives approximately uniform flux; $p_{FR} > 1$ means enhanced sputtering at the crater center; $p_{FR} < 1$ means more sputtering at the edge. | [0, 10] |

**Physical intuition**: A curved crater bottom means that at any given sputtering time, atoms from the crater edge come from a shallower depth than atoms from the center. The CRA model integrates over all radial positions, weighted by the local flux $F_R(r)$, to reconstruct the true depth-concentration profile from the measured (crater-averaged) signal.

#### Sigma (Interface Roughness) Model — These Are Optimized

Interface roughness arises from sputter-induced topography evolution. As sputtering proceeds, the initially smooth surface develops roughness due to statistical fluctuations in the ion impact process (Lian et al., 2019).

| Parameter | Symbol | Physical Meaning | Typical Bounds |
|-----------|--------|------------------|----------------|
| **sigma_0** | $\sigma_0$ | Base interface roughness at the surface (nm). Represents the intrinsic interface width at $z = 0$ — includes the initial surface roughness and any pre-existing interface broadening. | [0.1, 10] |
| **sigma_k** | $\sigma_k$ | Roughness growth rate with depth (nm/nm). Positive → roughness accumulates as sputtering deepens. Physically, this represents the cumulative effect of ion bombardment statistics. | [0, 1] |
| **sigma_c** | $\sigma_c$ | Exponent parameter for the Exponential sigma model. Controls how rapidly roughness growth accelerates (or decelerates) with depth. | [-10, 10] |

**Sigma Model dropdown** — Choose how roughness evolves with depth:

| Model | Formula | When to Use |
|-------|---------|-------------|
| **Linear** | $\sigma(z) = \sigma_0 + \sigma_k \cdot z$ | Default choice. Works for most multilayer systems where roughness accumulates steadily. |
| **Constant** | $\sigma(z) = 0.1$ | Use when all interfaces are known to have identical, minimal roughness (e.g., atomically sharp epitaxial layers). |
| **Sqrt** | $\sigma(z) = \sqrt{\sigma_0 + \sigma_k \cdot z^2}$ | Use when roughness growth slows with depth (roughness "saturates"). Common in thick films. |
| **Exponential** | $\sigma(z) = \sigma_k \cdot \sigma_0^{\sigma_c \cdot z}$ | Use when roughness accelerates with depth (e.g., columnar growth, shadowing effects). All three parameters ($\sigma_0$, $\sigma_k$, $\sigma_c$) are optimized. |

**Recommendation**: Start with **Linear**. If the fit quality is poor at deeper interfaces, try **Sqrt** or **Exponential**.

#### Sputtering Rates

Preferential sputtering (Lian et al., 2019) means different elements sputter at different rates. The sputtering rate ratio $r = q_A / q_B$ is the key parameter governing mass conservation and surface composition evolution during analysis.

| Parameter | Meaning | Notes |
|-----------|---------|-------|
| **q_A** | Sputtering rate of element A (nm/s or a.u.) | Calibrated from your instrument or a reference material. Together with q_B, controls the preferential sputtering effect. |
| **q_B** | Sputtering rate of element B (nm/s or a.u.) | If $q_A = q_B$, there is no preferential sputtering and the model reduces to pure MRI. |
| **q_A/q_B bound coefficients** | Multipliers for the optimization search range around q_A and q_B | Default [0.8, 1.2] = $\pm 20\%$ range around nominal values. Widen if your rate calibration is uncertain. |
| **firstlayer_c** | Concentration of element A in the topmost layer | `1` = pure A (A-on-B multilayer); `0` = pure B (B-on-A multilayer). Wrong setting causes complete fit failure. |

---

### Tab 3: Layers & Bounds

| Element | What It Does |
|---------|-------------|
| **Layer mode** | **Uniform layers (quick)**: All layers have the same thickness. Set count + thickness. **Manual array input**: Type a MATLAB-style array like `[30 8 16 25 40]`. |
| **Number of layers** | How many alternating layers in your film (only for Uniform mode). The concentration alternates between `firstlayer_c` and `1-firstlayer_c` each layer. |
| **Default thickness per layer** | Thickness of each layer in nm (only for Uniform mode). |
| **Apply Layer Settings** | Generates the `obj_tn` array and updates the bound preview. |
| **Bound type** | How optimization bounds are generated from nominal values: **Percentage-relative** (recommended): bounds = nominal × coefficient. **Absolute-relative**: bounds = nominal ± offset. **Absolute**: fixed bounds for all layers. |
| **Lower/Upper coeff/offset** | The coefficient or offset used by the bound type above. |
| **sigma_0 / sigma_k / sigma_c / b_FR / p_FR bounds** | Individual [low, high] search ranges for each optimized parameter. |
| **Sync Bounds** | Copies bound values from the Model Params tab to this tab. |
| **Refresh Bound Preview** | Shows the full generated `lb` and `ub` vectors. **Always click this before running** to verify bounds are sensible. |

---

### Tab 4: Optimization

| Element | What It Does |
|---------|-------------|
| **Algorithm** | **SFOA** (Starfish Optimization): nature-inspired, no extra toolbox needed. Recommended for most cases. **PSO** (Particle Swarm): MATLAB built-in, requires Global Optimization Toolbox. |
| **Population size (Npop)** | Number of candidate solutions. Larger = better exploration but linearly slower. Recommended: 30–100. With many layers (>20), use 80–150. |
| **Max iterations (Max_it)** | Maximum optimization steps. Recommended: 500–2000. More layers need more iterations. |
| **SFOA: GP** | Exploration/exploitation balance. 0.5 = balanced. >0.5 = wider search (good for rough landscapes). <0.5 = faster convergence (good for smooth problems). |
| **PSO: FunctionTolerance** | PSO stops if improvement is below this threshold. (PSO only) |
| **PSO: MaxStallIterations** | PSO stops after this many iterations without improvement. (PSO only) |
| **b_FR/p_FR decimal places** | Rounding precision for CRA parameters. Usually 1 (one decimal place). Increase to 2–3 for high-precision work. |
| **Interpolation method** | `spline` (smooth, recommended), `linear`, `pchip`, `cubic`. |
| **Signal clip upper/lower** | Signal values outside this range are clamped. Default [0, 1] for normalized data. |
| **Random seed** | Set a number for reproducible results. 0 = random each run. |
| **Verbose console output** | If checked, prints every iteration to the MATLAB console. |
| **Save/Load Configuration** | Save all UI settings to a `.mat` file. Load to restore. Also auto-saved on app close. |
| **Reset to Defaults** | Restores factory settings. |

---

### Tab 5: Run & Results

| Element | What It Does |
|---------|-------------|
| **START OPTIMIZATION** | Begins the optimization. Disables itself during the run. |
| **STOP** | Requests early termination. Takes effect at the next iteration (within 1–2 seconds). |
| **Export Results** | Saves fit data, optimized parameters, layer thicknesses, and convergence curve to Excel (`.xlsx`) or MAT (`.mat`) file. |
| **Clear Results** | Clears all plots and result text. |
| **Progress: Iteration / ETA / Elapsed** | Live progress during optimization. Text-based progress bar `[####......]`, current iteration count, elapsed time, and estimated time remaining. |
| **Convergence Curve plot** | Updates in real time during optimization. Y-axis is error (%). Should decrease and asymptotically flatten. |
| **Fit Comparison plot** | Appears after optimization completes. Blue = experiment, Red = fitted model, Green = difference. |
| **Run Log** | Text output showing optimization progress and any errors. |
| **Optimization Results** | Final numerical results: all 7 optimized base parameters + layer thicknesses + comparison with reference values. |

---

## Parameter Reference: Complete List

### Fixed Parameters (Set by User, Not Optimized)

| # | Parameter | Tab | Physical Meaning | Default |
|---|-----------|-----|------------------|---------|
| 1 | `w` | Model Params | Atomic mixing length (nm) — depth scale of collisional mixing | 1.0 |
| 2 | `dr` | Model Params | Crater radial integration step — numerical precision for CRA | 0.001 |
| 3 | $\lambda$ (lambda) | Model Params | Information depth (nm) — effective escape depth of sputtered atoms | 1.0 |
| 4 | `inddis` ($\Delta z$) | Data Import | Depth sampling interval (nm) — numerical grid resolution | 1.0 |
| 5 | `cons` | Model Params | Gaussian window truncation multiplier ($\pm c_{cons} \cdot \sigma$) | 5.0 |
| 6 | `firstlayer_c` | Model Params | Element A concentration in topmost layer (0 or 1) | 1 |
| 7 | Sigma model | Model Params | Roughness evolution function (Linear/Constant/Sqrt/Exponential) | Linear |

### Optimized Parameters (Adjusted by Algorithm)

| # | Parameter | Symbol | Physical Meaning | Bounds Source |
|---|-----------|--------|------------------|---------------|
| 1 | **sigma_0** | $\sigma_0$ | Base interface roughness at surface (nm) | sigma_0 bound [low, high] |
| 2 | **sigma_k** | $\sigma_k$ | Roughness growth rate with depth (nm/nm) | sigma_k bound [low, high] |
| 3 | **sigma_c** | $\sigma_c$ | Exponential sigma model exponent | sigma_c bound [low, high] |
| 4 | **b_FR** | $b_{FR}$ | Crater flux exponent — flux curvature across crater | b_FR bound [low, high] |
| 5 | **p_FR** | $p_{FR}$ | Crater shape exponent — crater bottom profile | p_FR bound [low, high] |
| 6 | **q_A** | $q_A$ | Sputtering rate of element A | coeff × q_A nominal |
| 7 | **q_B** | $q_B$ | Sputtering rate of element B | coeff × q_B nominal |
| 8–(7+L) | **obj_tn[]** | $t_1, ..., t_L$ | Layer thicknesses (nm), $L$ = number of layers | bound type × nominal |

### Derived (Auto-Calculated)

| Parameter | Formula | Meaning |
|-----------|---------|---------|
| Substrate thickness | $\max(z_{data}) - \sum t_i$ | Automatically added to satisfy mass conservation |
| Sputtering rate ratio | $r = q_A / q_B$ | Key driver of preferential sputtering effect |
| Depth resolution DR$(z)$ | $\sqrt{(2\sigma(z))^2 + (1.67\lambda)^2 + (1.67w/r)^2}$ | Total depth resolution at depth $z$ |

---

## Sigma Model Selection Guide

Choosing the right sigma model is important for physically meaningful results:

| Your Sample Type | Recommended Model | Why |
|-----------------|-------------------|-----|
| Thin multilayers (<100 nm total) with sharp interfaces | **Linear** | Roughness typically grows steadily in thin films |
| Single-crystal or epitaxial multilayers | **Constant** | Interfaces are nearly atomically flat |
| Thick films (>500 nm) where roughness saturates | **Sqrt** | Roughness growth slows at large depths |
| Polycrystalline films with columnar growth | **Exponential** | Roughness can accelerate due to shadowing |
| Unknown / first attempt | **Linear** | Simplest model, works for most cases |

**How to evaluate your choice**: After running the optimization, look at the **Fit Comparison plot**:
- Good fit (green difference line near zero) → model choice is appropriate
- Poor fit at deep interfaces but good at shallow ones → try **Sqrt** or **Exponential**
- Poor fit everywhere → check `w`, `lambda`, and `firstlayer_c` settings first

---

## Distribution: Which .exe to Give People

### For people WITHOUT MATLAB:

Give them **one** file:

```
General/PCRAS_Optimization_Tool_Installer.exe   (2.5 MB)
```

They double-click it, it downloads MATLAB Runtime automatically (~1 GB, one-time), installs, and the app runs. **They do NOT need MATLAB at all.**

### For people WITH MATLAB (R2018b or later):

Give them the **Design/** folder:

```
Design/
├── PCRAS_Tool.m
├── P_MRICRAS_func.m
├── SFOA.m
├── mainSFOA.m
├── compile_PCRAS.m
├── README.md
└── USER_MANUAL.md
```

They run `PCRAS_Tool` directly in MATLAB.

---

## DIY: What to Share If Someone Wants to Modify the Code

Share the **entire `PCRAS-GDMS/` folder**:

```
PCRAS-GDMS/
├── PCRAS_Tool.m              ← Main GUI (edit this for UI changes)
├── P_MRICRAS_func.m             ← Forward model (edit this for physics)
├── SFOA.m                       ← Optimization algorithm (edit this for algorithm)
├── compile_PCRAS.m           ← Compiler script (auto-syncs to Design/ and General/)
├── README.md                    ← Scientific documentation
├── USER_MANUAL.md               ← This file
├── compiled/                    ← Standalone .exe output
└── compiled_installer/          ← Runtime-included installer output
```

**Minimum to run/modify** (source only):
```
PCRAS_Tool.m
P_MRICRAS_func.m
SFOA.m
```

**To rebuild the .exe** after making changes, run:
```matlab
compile_PCRAS
```
This also auto-syncs the updated files to `Design/` and `General/`.

---

## Tips & Troubleshooting

| Issue | Solution |
|-------|----------|
| Optimization takes too long | Reduce population size (try 20–30) or max iterations (try 300–500). Increase `inddis` for fewer data points. |
| Convergence curve is flat | The algorithm may be stuck in a local minimum. Try: increasing population size, switching SFOA → PSO (or vice versa), widening parameter bounds, or changing the random seed. |
| Error "sum(obj_tn) > max(depth)" | Your layer thicknesses exceed the data depth range. Reduce layer thickness or decrease number of layers. |
| `inddis` must not be > `w` or `lambda` | If $\Delta z > w$ or $\Delta z > \lambda$, the MRI convolution becomes numerically unstable. Keep $\Delta z \leq \min(w, \lambda)$. |
| `firstlayer_c` wrong | Check your data: does the signal start high (element A, set to 1) or low (element B, set to 0)? Wrong setting causes a complete fit failure. |
| Poor fit at deep interfaces | Try **Sqrt** or **Exponential** sigma model. Or increase `w` and `lambda` to allow more broadening. |
| Sputtering rates seem unrealistic | Widen the q_A/q_B bound coefficients in Tab 2, or fix q_A and q_B (set narrow bounds) if you have good calibration data. |
| Results differ between runs | Set a specific **Random seed** (e.g., 42) for reproducibility. |
| Settings lost on restart | Auto-save is enabled! Config is stored in `PCRAS_Tool_autosave.mat`. To start fresh, delete this file or click **Reset to Defaults**. |
| App window too large for screen | Resize it — the layout is responsive. Or reduce your display scaling. |

---

## References

1. **Lian, X. et al. (2019).** Preferential sputtering and mass conservation in AES and SIMS depth profiling. — Theoretical foundation for preferential sputtering ($q_A$, $q_B$, $r = q_A/q_B$) and mass conservation in depth profiling.

2. **Liu, Y. et al. (2026).** Influences of sputtered crater geometry on glow discharge spectrometry depth profile. — Experimental and theoretical characterization of crater shape effects ($b_{FR}$, $p_{FR}$, $F_R(r)$) on GDMS depth resolution.
