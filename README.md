# Computational Intelligence — Fuzzy Controllers & TSK Models

**Course:** Computational Intelligence (Υπολογιστική Νοημοσύνη)  
**Department:** Electrical & Computer Engineering, AUTH  
**Academic Year:** 2024–2025  
**Author:** Danai Zacharioudaki  

---

## Overview

This repository contains four assignments covering the design and application of fuzzy logic systems and TSK (Takagi-Sugeno-Kang) neuro-fuzzy models. Topics range from classical FLC controller design to data-driven regression and classification using ANFIS-style architectures.

All implementations are done in **MATLAB**, using the Fuzzy Logic Toolbox and related utilities.

---

## Assignments

### 1 · Fuzzy Speed Control of a Worktable Mechanism
**`1_Fuzzy-Speed-Control-Worktable/`**

Design of a fuzzy PI controller (FZ-PI) for the speed control of a high-precision DC motor–driven worktable mechanism.

- Modelling the plant transfer function and designing a linear PI controller as a baseline
- Designing an FZ-PI controller with 7 linguistic values per input (E, ΔE) and 9 for the output (ΔU)
- Scaling/normalisation of error signals to [−1, 1]
- Rule base design based on closed-loop meta-rules
- Comparison of FLC vs linear controller step responses
- Closed-loop simulation under step and ramp reference signals

**Tools:** `newfis`, `addmf`, `addvar`, `addrule`, `evalfis`, `gensurf`, MATLAB Control Toolbox

---

### 2 · Car Control with a Fuzzy Logic Controller
**`2_Car-Control-FLC/`**

Design of a Mamdani-type FLC to navigate a vehicle to a desired position while avoiding static obstacles.

- 3 inputs: vertical distance dᵥ, horizontal distance d_H, heading angle θ
- Output: change in heading Δθ
- Membership functions: trapezoidal/triangular (S, M, L for distances; N, ZE, P for angles)
- Rule base designed from expert knowledge (trial and error)
- Simulation of vehicle trajectories for 3 initial headings (0°, +45°, −45°)
- Operators: Mamdani implication, max-min composition, COA defuzzification

**Tools:** MATLAB FIS Editor, `evalfis`, custom simulation loop

---

### 3 · TSK Regression — Function Approximation
**`3_TSK-Regression/`**

Application of TSK neuro-fuzzy models to multivariate nonlinear regression using two UCI datasets.

**Part A — Airfoil Self-Noise dataset (1503 samples, 6 features):**
- Training of 4 TSK models varying output type (Singleton / Polynomial) and number of MFs (2 or 3 per input)
- Hybrid learning: backpropagation for MF parameters + least squares for output parameters
- Evaluation metrics: RMSE, NMSE, NDEI, R²

**Part B — Superconductivity dataset (21263 samples, 81 features):**
- Feature selection (Relief / mRMR / FMI) to address the rule explosion problem
- Subtractive Clustering (SC) for input space partitioning
- Grid search + 5-fold cross-validation to optimise (number of features, cluster radius rₐ)
- Final model training and evaluation on held-out test set

**Tools:** MATLAB Fuzzy Toolbox (`anfis`, `genfis2`), `cvpartition`

---

### 4 · TSK Classification
**`4_TSK-Classification/`**

Application of TSK neuro-fuzzy models to binary/multi-class classification using two UCI datasets.

**Part A — Haberman's Survival dataset (306 samples, 3 features):**
- Training of 4 TSK models: class-independent vs class-dependent Subtractive Clustering, two cluster radii each
- Singleton output type with output rounding for class assignment
- Evaluation: error matrix, Overall Accuracy (OA), Producer's Accuracy (PA), User's Accuracy (UA), κ̂

**Part B — Epileptic Seizure Recognition dataset (11500 samples, 179 features):**
- Class-dependent subtractive clustering applied separately per class
- Feature selection + grid search + 5-fold cross-validation
- Final TSK model evaluation with full confusion matrix and accuracy metrics

**Tools:** MATLAB Fuzzy Toolbox (`anfis`, `genfis2`), `cvpartition`, `confusionmat`

---

## Repository Structure

```
.
├── 1_Fuzzy-Speed-Control-Worktable/
├── 2_Car-Control-FLC/
├── 3_TSK-Regression/
├── 4_TSK-Classification/
├── README.md
└── .gitignore
```

---

## Key Concepts

| Concept | Used In |
|---|---|
| Mamdani FLC, COA defuzzification | Assignments 1, 2 |
| FZ-PI controller design | Assignment 1 |
| TSK (Takagi-Sugeno-Kang) models | Assignments 3, 4 |
| ANFIS hybrid learning | Assignments 3, 4 |
| Subtractive Clustering | Assignments 3, 4 |
| Feature selection (Relief, mRMR, FMI) | Assignments 3, 4 |
| Grid search + k-fold cross-validation | Assignments 3, 4 |
| Classification metrics (OA, PA, UA, κ̂) | Assignment 4 |

---

## Requirements

- MATLAB (R2020b or later recommended)
- Fuzzy Logic Toolbox
- Control System Toolbox (Assignment 1)
- Statistics and Machine Learning Toolbox (Assignments 3, 4)
