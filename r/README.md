# Supplementary RMST verification in R

English | [日本語](README_JP.md)

This folder contains the implemented restricted mean survival time (RMST)
verification workflow. It uses **only the first of 22 imputed datasets**
(`_mi_m = 1`). It does not pool multiple imputations and must not be described as
the final pooled RMST analysis. The source project records this workflow as
provisional.

## Contents and input

- `scripts/run_wrmst_analysis.R`: unweighted and stabilized inverse probability
  of treatment weighted Kaplan-Meier RMST at 36 and 60 months, with contrasts
  defined as group B minus group C, plus diagnostic exports.
- `scripts/install_packages.R`: installs missing R packages from CRAN.

The private input is the Stata-produced `df03mi_surgery.dta`. No dataset is
included. The main script lists and checks its required variables. It reads
`trt = 1` as group B, `trt = 0` as group C, `time_os_m` in months, and
`event_os = 1` as death. `id` is used for a uniqueness check and is not printed.

The script retains cohort assertions for the original workflow: B83/C89 before
restriction and B83/C79 after restricting to patients whose original Primary N,
liver lesion count, and maximum liver lesion diameter were observed. It is not
a general-purpose analysis of arbitrarily sized datasets. Existing imputations
were generated before this restriction; imputation is not rerun in R.

## Running the code

Install R, make `Rscript` available, and run these commands from the repository
root. Replace `PRIVATE_INPUT.dta` and `PRIVATE_OUTPUT` with paths to the authorized
private input and a private output directory, preferably outside the repository.
Both paths are required. Quote paths containing spaces.

```text
Rscript --vanilla r/scripts/install_packages.R
Rscript --vanilla r/scripts/run_wrmst_analysis.R PRIVATE_INPUT.dta PRIVATE_OUTPUT 2000 20260904
```

The optional third and fourth arguments are bootstrap repetitions and random
seed. Defaults are 2,000 and 20260904; computation uses one core. No analysis is
run merely by installing packages.

**Every generated file remains private.** Runtime CSV files, warning/session
logs, and `adjustedsurv_m1.rds` must remain excluded from Git. The RDS contains
patient-level analysis information; the survival-curve export uses observed
event times. Existing output files with the same names are overwritten, so use
a new private output directory for each run. Repository ignore rules are a
backstop; they do not make generated outputs suitable for publication.

## Recorded software environment

The source run recorded the following environment on 2026-09-04:

| Component | Version |
| --- | --- |
| R | 4.5.1 |
| haven | 2.5.5 |
| survival | 3.8-3 |
| survRM2 | 1.0-4 |
| adjustedCurves | 0.11.4 |
| cobalt | 5.0.0 |

Platform: Windows 11 x64; R platform `x86_64-w64-mingw32/x64`; locale `C`;
system code page 65001. These are recorded versions, not a lockfile.
The installer installs currently available missing packages and does not pin or
restore these versions or their dependencies. Reproducing the historical
environment requires matching versions separately.

## Interpretation and known limitations

- Confidence intervals and p-values omit between-imputation uncertainty.
- The R stabilized-weight numerator uses the treatment proportion in the
  restricted cohort. The saved Stata weights used the full-cohort proportion;
  direct differences therefore do not establish failure of the PS calculation.
- The recorded PS model converged but produced a warning about fitted
  probabilities numerically equal to zero or one. Restriction did not establish
  that separation or positivity concerns were resolved. No weight trimming or
  truncation is applied.
- Bootstrap refits the PS model and weights. Some requested replicates were
  unavailable for RMST contrasts; reasons were not classified in the historical
  workflow. The output records usable counts by restriction time. Late follow-up
  was sparse and needs consideration before interpreting 60-month estimates.
- Group RMST intervals use bootstrap standard errors with a normal
  approximation; contrast intervals use percentile bootstrap. These procedures
  are retained from the implemented workflow.
- Legacy `smd_*` output fields retain their original names. The `cobalt` call
  does not set `binary="std"`; not every returned difference can be assumed to
  be standardized. Confirm the measure before using SMD thresholds in a paper.
- The clinical outcome origin, covariate measurement timing, and explanation
  for the restriction require confirmation against study materials before
  final manuscript interpretation.

## Release-copy changes and verification

The release copy replaces collaborator-specific labels and local variable
names with neutral reference wording, requires explicit input/output arguments,
and adds comments documenting provisional status and private outputs. Numerical
calculations, cohort assertions, the historical reference comparison, and model
settings are retained. The package installer is unchanged.

The preparation review on 2026-09-08 inspected the scripts and checked their R syntax only.
It did not rerun the patient-data analysis or verify numerical reproduction.
Optional Windows launching and spreadsheet-presentation scripts are omitted;
they are not required for the R analysis exports.
