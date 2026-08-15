# PCRAS-app

**Automated Quantitative Fitting of GDS Depth Profiles with Preferential Sputtering and Crater Effects**

PCRAS-app is an automated fitting software package developed for quantitative analysis of **Glow Discharge Spectroscopy (GDS)** depth profiles. The software implements the proposed **PCRAS model** and integrates intelligent optimization algorithms for automated parameter fitting.

The model explicitly considers **preferential sputtering** together with the physical effects described by the MRI-CRAS framework, enabling quantitative reconstruction and analysis of GDS depth profiles affected by composition-dependent sputtering and crater-induced distortion.

---

## Overview

Quantitative interpretation of GDS depth profiles can be complicated by several physical effects, including atomic mixing, surface roughness, limited information depth, preferential sputtering, and crater evolution during sputtering.

PCRAS-app provides an automated fitting framework that combines the PCRAS forward model with intelligent optimization algorithms. The current implementation includes:

* **Particle Swarm Optimization (PSO)**
* **Starfish Optimization Algorithm (SFOA)**

These algorithms automatically search the user-defined parameter space and determine the model parameters that provide the best agreement with the experimental depth profile.

The software is designed to minimize the amount of manual parameter adjustment required during depth-profile analysis while retaining physically meaningful model parameters.

---

## Key Features

### Automated parameter optimization

The software requires only:

1. Experimental GDS depth-profile data
2. User-defined fitting ranges for the model parameters

The optimization procedure automatically searches the parameter space and provides:

* Optimized model parameters
* Reconstructed depth profile
* Fitting error
* Relevant fitting information for subsequent analysis

### Flexible parameter constraints

When a model parameter is known independently, its lower and upper bounds can be set to the same value:

```text
Lower bound = Upper bound
```

The parameter is then fixed during optimization.

This feature allows experimentally known or independently determined parameters to be incorporated directly into the fitting procedure and can substantially reduce the computational cost of optimization.

### Physically meaningful parameter extraction

In addition to reproducing the measured depth profile, the forward-model fitting procedure enables the extraction of parameters that are not directly obtained from the raw GDS signal, including, depending on the selected model and fitting configuration:

* Initial surface roughness
* Information depth
* Annealing-related coefficients
* Parameters associated with preferential sputtering
* Parameters describing crater-induced distortion

Thus, the software can be used not only for profile reconstruction but also for quantitative analysis of material-related parameters.

---

## Optimization Algorithms

PCRAS-app currently provides two intelligent optimization algorithms.

### Particle Swarm Optimization (PSO)

Particle Swarm Optimization is a population-based stochastic optimization algorithm inspired by the collective behavior of social organisms. PSO has previously been applied to automated fitting of the MRI model for GDS depth profiles.

### Starfish Optimization Algorithm (SFOA)

The Starfish Optimization Algorithm is a recently proposed population-based optimization method. It has previously been applied to automated fitting of the MRI-CRAS model for GDS depth-profile analysis.

In PCRAS-app, both PSO and SFOA can be used to optimize the parameters of the PCRAS model.

---

## Input and Output

### Input

The software requires:

* Experimental GDS depth-profile data
* User-defined parameter bounds
* Selected optimization algorithm
* Optimization settings

The experimental profile should provide the measured signal as a function of sputtered depth.

### Output

The software provides:

* Optimized model parameters
* Calculated/fitted depth profile
* Fitting error
* Optimization results

The optimized parameters can subsequently be used for quantitative interpretation of the GDS depth profile.

---

## Workflow

The general fitting procedure is:

```text
Experimental GDS depth profile
            │
            ▼
   Define fitting parameters
       and parameter bounds
            │
            ▼
    Select optimization method
         (PSO / SFOA)
            │
            ▼
     Automated optimization
            │
            ▼
     PCRAS forward modeling
            │
            ▼
       Parameter update
            │
            ▼
       Convergence / stop
            │
            ▼
   Optimized model parameters
            │
            ├── Fitted depth profile
            └── Fitting error
```

---

## Software Structure

The repository is organized as follows:

```text
PCRAS_app/
│
├── README.md
│
├── src/
│   ├── compile_PMRICRAS.m
│   ├── mainSFOA.m
│   ├── P_MRICRAS_func.m
│   ├── PMRICRAS_Tool.m
│   └── SFOA.m
│
├── examples/
│   └── sample_data.xlsx
│
└── docs/
    └── USER_MANUAL.md
```

The exact directory structure may vary between software releases.

### Source code

The source code contains the implementation of the PCRAS model and the optimization algorithms used by the software.

### Examples

Representative sample data are provided for testing the software and reproducing representative fitting procedures.

### Documentation

The user manual provides detailed instructions for installation, interface operation, parameter settings, and data analysis.

---

## Installation

A Windows installation package is provided with the software distribution.

For users who prefer to work directly with the source code, the MATLAB implementation is also provided in this repository.

Please refer to the **User Manual** for detailed installation and usage instructions.

---

## Usage

A typical analysis consists of the following steps:

1. Prepare the experimental GDS depth-profile data.
2. Launch PCRAS-app.
3. Import the experimental depth profile.
4. Define the fitting range of each model parameter.
5. Select the optimization algorithm (PSO or SFOA).
6. Start the automated fitting procedure.
7. Examine the optimized parameters and reconstructed profile.
8. Evaluate the fitting error and the physical meaning of the obtained parameters.

Detailed instructions and descriptions of the graphical user interface are provided in [`USER_MANUAL.md`](docs/USER_MANUAL.md).

---

## Reproducibility

The complete software source code and user documentation are publicly available to facilitate reproducibility and further development of the proposed method.

Representative input data are also provided in the repository for testing and demonstration purposes.

For reproducible analysis, users are encouraged to record:

* Software version
* Optimization algorithm
* Parameter bounds
* Population size
* Number of iterations
* Experimental input data

---

## Related Publication

This software accompanies the following research work:

> **[Insert the final title of the associated publication here]**

The theoretical formulation of the PCRAS model, its validation, and the corresponding GDS depth-profile analysis are described in the associated publication.

Previous applications of intelligent optimization algorithms to automated GDS depth-profile fitting are discussed in the corresponding references of the publication.

---

## Citation

If you use PCRAS-app or the PCRAS model in your research, please cite the associated publication:

```text
[Insert the final bibliographic information here]
```

A software-specific citation will be provided if a DOI or archived software release is available.

---

## License

PCRAS-app is released under the **MIT License**.

See [`LICENSE`](LICENSE) for the full license text.

---

## Contact

For questions, bug reports, or suggestions concerning the software, please use the **GitHub Issues** page of this repository.

---

## Acknowledgements

This software was developed as part of the research on quantitative reconstruction and analysis of GDS depth profiles, with particular emphasis on preferential sputtering and crater-induced distortion.

