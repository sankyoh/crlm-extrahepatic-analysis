# Stata Analysis Code

English | [日本語](README_JP.md)

These are public copies of existing code comparing group B (liver resection without resection of extrahepatic disease) with group C (neither liver nor extrahepatic resection) in patients with colorectal liver metastases and extrahepatic disease. Patient data are not distributed.

## Included analyses

`master.do` starts from private, prepared and cleaned datasets and sequentially runs multiple imputation, propensity score and weight estimation, covariate balance and overlap assessment, descriptive statistics, and survival analyses. It covers three populations: the overall cohort, the primary tumor surgery subgroup, and the lung-only extrahepatic disease subgroup. Five data preparation and cleaning files (four `crDataICL01*.do` files and `map2cat.ado`) are excluded from the public release.

- `crDataICL02_mi.do`: Creates 22 multiply imputed datasets. Retained as a statistical method for handling missing data, using the random seed from the source code.
- `crDataICL03_mi_ps.do`: Estimates propensity scores and weights within each imputed dataset using logistic regression with missingness indicators. Retained as a statistical method for confounding adjustment.
- `anEvalPS01_covbal.do` and `bal_sIPTW.ado`: Use the external Stata command `covbal` to calculate standardized mean differences (SMDs) and variance ratios before and after weighting in each of the 22 imputed datasets, and export them to Excel.
- `anEvalPS02_overlap.do` and `anDes01.do`: Produce overlap plots and descriptive statistics.
- `anSurv01mi.do`: Runs unweighted and weighted Cox, Weibull proportional hazards (PH), and Weibull accelerated failure time (AFT) models, pooling estimates across 22 imputed datasets. It also produces unweighted and weighted Kaplan–Meier (KM) curves, median survival, log-rank tests, and survival estimates at 36 and 60 months (or the earlier available follow-up time), using the first imputed dataset.

Python is not required for the SMD and variance ratio calculations above. The existing [supporting Python scripts](../python/historical/README.md) perform subsequent averaging of values in the Excel files exported by Stata for individual imputed datasets; they are not called by `master.do`. See the [repository overview](../README.md) for an explanation that also covers the separate balance assessment in R.

The combined primary tumor surgery and lung-only subgroup was exploratory; its propensity score estimation had been disabled in the original `master.do` because it did not converge. The public version excludes data preparation, multiple imputation, and the already disabled estimation calls for this combined subgroup.

## Environment and inputs

Stata 18 or later is required because `anDes01.do` uses `dtable`. The exact Stata version used for the original analyses and the versions of external commands were not established during the initial static review on 2026-09-08. See the [repository overview](../README.md) for the environment and scope of the execution checks performed on 2026-09-14. Make the external command `covbal` available separately. The launcher checks for missing dependencies but does not install them automatically.

1. Create a private working copy and set Stata's working directory to its `stata` folder.
2. Place the following three prepared and cleaned, pre-imputation datasets in this folder. Use only datasets that you are authorized to access.

   | File | Population |
   |---|---|
   | `df01mi.dta` | Overall cohort |
   | `df01mi_surgery.dta` | Primary tumor surgery subgroup |
   | `df01mi_lung.dta` | Lung-only extrahepatic disease subgroup |

3. Match the input variable names, coding, types, and units to the [codebook](../codebook/README.md). The former missing-value categories for the six imputed variables must already have been converted to Stata system missing values (`.`), and the pre-imputation missingness indicators `grade_mind`, `primary_n_mind`, `tumor_count_cat_mind`, `tumor_size_cat_mind`, `cea_cat_mind`, and `ca199_cat_mind` must already exist. These preparation steps are not included in the public code.
4. Run `do run_public.do`.

`run_public.do` checks the presence or requirements of the three inputs, `master.do`, the local helper `bal_sIPTW.ado`, external commands, and the Stata version. It does not automatically validate input contents or coding. It adds the local helpers to the search path, creates the Excel and graph output folders, and runs `master.do`. As in the source code, rerunning the scripts overwrites intermediate datasets and outputs with the same names. The three input datasets are not saved or modified.

Intermediate `.dta` files, test data containing the first imputed dataset, and generated Excel files and graphs are not intended for public release. If the inputs contain patient identifiers or surgery dates, these remain in intermediate datasets, so generated outputs must not be published without review. The patient-level Excel export code at the end of `master.do` has been removed from the public version.

## Versions and known limitations

- In the current public `anSurv01mi.do`, the two previously commented-out blocks for unweighted and weighted KM curves, median survival, log-rank tests, and survival estimates have been enabled. These procedures now run for all three populations through `master.do`, together with the Cox and Weibull PH/AFT models.
- `historical/anSurv01mi.do` is retained for reference. It is an earlier version saved in the source project's RMST working folder and predates the addition of AFT models. It is not called by `master.do` and is no longer needed to generate KM curves and related outputs in the standard workflow.
- The lung-only subgroup corresponds to `EHD分類2 == "M1 (Lung)"` in the source data and `ehd2==0` in the analysis data. It does not include all patients with lung metastases when other extrahepatic organs are also involved. Subgroup selection must be completed during private input preparation.
- Overlap plots, descriptive statistics, and KM curves and related outputs in both survival-script versions use the first imputed dataset (`_mi_m == 1`). They should not be interpreted as estimates pooled across all 22 imputed datasets. The Cox and Weibull PH/AFT models use `mi estimate` to pool regression estimates.
- `event_os` is defined as 0 = alive/censored and 1 = death. Because the source preparation code contains an inconsistent spelling in an outcome label name, the codebook records the basis for this definition.
- For the three included populations, the model specifications, weight formulas, random seeds, patient selection within the analysis code, and handling of missing values and perfect prediction are retained from the source code. Enabling the descriptive survival blocks expands the outputs of the standard workflow. See the [repository overview](../README.md) for the execution checks and remaining limitations.
