# Analysis code for colorectal liver metastases with extrahepatic disease

English | [日本語](README_JP.md)

This directory contains research analysis code selected from an existing project and prepared for publication on GitHub and Zenodo. Initial preparation date: 2026-09-08. User-specific paths and internal links have been removed from the public copies without modifying the source files. No patient-level datasets are included.

Dataset preparation and cleaning code is excluded from the public release. The standard Stata workflow starts from separately prepared, private analysis inputs. Multiple imputation and estimation of propensity scores and weights are included as statistical analysis methods.

## Contents

| Location | Contents |
| --- | --- |
| [stata/](stata/README.md) | Multiple imputation with 22 imputed datasets, propensity scores and weighting, balance assessment, descriptive statistics, Cox and Weibull analyses, and Kaplan–Meier curves using prepared inputs. The current survival script includes both regression and descriptive survival procedures. |
| [r/](r/README.md) | RMST analyses at 36 and 60 months using the first imputed dataset to compare groups B and C in the primary tumor surgery subgroup. |
| [python/historical/](python/historical/README.md) | Supporting code extracted from notebooks for historical averaging of covariate balance tables. The original selection ranges and known limitations are documented. |
| [codebook/](codebook/README.md) | Codebook in Markdown and CSV covering all 124 columns in the source Excel file and 43 distinct Stata analysis variables. No patient values or frequency tables are included. |

## Scope of the analyses

Group B comprises patients who underwent liver resection without resection of extrahepatic disease; group C comprises patients who underwent neither liver nor extrahepatic resection. The Stata code includes analyses of the overall B/C cohort, the primary tumor surgery subgroup, and the lung-only extrahepatic disease subgroup. The lung-only subgroup corresponds to the source-data category `EHD分類2 == "M1 (Lung)"`; it does not include every patient with lung metastases, such as those with metastases in multiple extrahepatic organs.

The current Stata survival script includes Cox and Weibull proportional hazards models, time ratios from a Weibull accelerated failure time (AFT) model, and unweighted and weighted Kaplan–Meier (KM) curves, median survival, log-rank tests, and survival estimates at 36 and 60 months where supported by follow-up. The KM and related descriptive procedures use the first imputed dataset; regression estimates are pooled across the 22 imputed datasets. The current script is called by `master.do`. The earlier version in `stata/historical/` is retained for reference and is no longer needed to generate KM outputs.

The R restricted mean survival time (RMST) code is an existing verification analysis using only `_mi_m=1`. Pooling RMST across the 22 imputed datasets is not implemented, and its interval estimates do not account for between-imputation variability. Each folder's README documents known issues, including correspondence with the final manuscript, cohort restrictions and weight recalculation in R, and the naming of covariate balance measures.

## Reproducibility checks and known limitations

The checks below were performed on 2026-09-14 using prepared private datasets. The Stata verification environment was Stata 19.5 with the external command `covbal` 1.1.1. Dataset preparation and cleaning were outside the scope of these checks. Users must separately obtain the required input data and software environment to reproduce numerical results.

The imputation and propensity-score/weight comparisons below refer to the earlier full-workflow check. After the KM sections were enabled, the current survival script was also run separately for all three cohorts using the stored imputed and weighted datasets. That additional check did not rerun imputation or propensity-score estimation.

| Analysis or output | Verified scope and limitations |
| --- | --- |
| Multiple imputation, propensity scores, weights, and Cox/Weibull analyses | The standard workflow completed successfully for the overall cohort, the primary tumor surgery subgroup, and the lung-only subgroup. All variable values in the regenerated imputed datasets and propensity-score/weighted datasets—six datasets across the three cohorts—matched the corresponding stored datasets exactly. |
| KM curves, median survival, and related outputs | These procedures are enabled in the current [survival script](stata/anSurv01mi.do), which is called by the standard `master.do`. They use the first imputed dataset. After the sections were enabled, successful execution of the current script was confirmed for all three cohorts using the stored imputed and weighted datasets. See the [Stata README](stata/README.md) for the current workflow. |
| Final covariate balance table | **The current public code alone cannot fully reproduce the stored final table.** The two CA19-9 rows for the overall cohort are outside the range used by the Python code to average the 22 imputed datasets. The corresponding final-table values match the first imputed dataset and do not match the 22-dataset averages. Final processing performed in Excel, including sign changes and reciprocals of variance ratios, is also absent from the public code. |
| RMST in R | The included code uses the first imputed dataset (`_mi_m=1`). Required R packages were unavailable in the verification environment, so execution and numerical agreement were not verified in these checks. See the [R README](r/README.md) for environment setup instructions. RMST pooling across the 22 imputed datasets is not implemented. |

The exact agreement of all variable values refers specifically to the imputed and propensity-score/weighted datasets described above. These checks did not establish agreement with every number in the manuscript or its tables and figures, nor did they validate the study methodology as a whole.

## How the covariate balance table is produced

| Step | Implementation |
| --- | --- |
| Calculate unweighted and weighted standardized mean differences (SMDs) and variance ratios for each imputed dataset | Stata: `anEvalPS01_covbal.do` → `bal_sIPTW.ado` → external command `covbal`. Produces 22 Excel files for each cohort. |
| Average weighted SMDs and variance ratios across the 22 imputed datasets | Supporting code in `python/historical/`. This step does not clean patient data. |
| Generate descriptive statistics accompanying the table | Stata: `anDes01.do`, using `dtable` on the first imputed dataset. |
| Assess balance for the separate RMST verification using the first imputed dataset | R: `cobalt::bal.tab()` within `run_wrmst_analysis.R`, exporting diagnostic CSV files. |

The source project retains the Stata outputs for each imputed dataset, the Python averages, and the R diagnostic CSV files. The stored Excel workbook used to prepare the final balance table contains formulas for sign changes and reciprocals, but no formulas averaging the 22 imputed datasets. No implementation other than Python was identified in the project for computing the existing 22-dataset averages. The R diagnostics for the first imputed dataset cannot substitute for that averaged table.

## Running the code

The actual data must be obtained separately and used in a private environment with appropriate access authorization. This public directory alone is insufficient to reproduce numerical results. See the [codebook](codebook/README.md) for input column names and coding.

- Stata: In a private working copy, place the prepared `df01mi.dta`, `df01mi_surgery.dta`, and `df01mi_lung.dta` files in the `stata` folder, set that folder as the working directory, and run `do run_public.do`. The required pre-imputation variable definitions and missingness indicators must already be present. See the [Stata README](stata/README.md) for input requirements and external commands.
- R: Follow the [R README](r/README.md), explicitly specifying the input `.dta` file and a private output directory.
- Historical Python code: Consult the documented ranges and limitations in its [README](python/historical/README.md) before use.

Execution generates intermediate datasets and results, overwriting existing outputs with the same names as in the original workflow. Generated datasets, RDS files, logs, Excel files, and curve outputs containing event times are separate from the public codebook and must remain private.

The `.gitignore` file explicitly allows individual files reviewed for publication, helping prevent accidental inclusion of data and outputs. Review the contents of any additional public files before updating this allowlist. Ignore rules do not protect files that are force-added or already tracked.

## Citation and publication metadata

The repository is hosted at [sankyoh/crlm-extrahepatic-analysis](https://github.com/sankyoh/crlm-extrahepatic-analysis). The software author is Toshiharu Mitsuhashi ([ORCID: 0000-0001-9940-0570](https://orcid.org/0000-0001-9940-0570)). Citation metadata is provided in [CITATION.cff](CITATION.cff). If you use this code in research, please cite this software.

A Zenodo record, DOI, and release have not yet been created. The version and release date will be added when the first release is prepared, and the DOI will be added after it is issued by Zenodo. Once available, please cite the DOI of the specific software version used in your analysis.

The initial preparation on 2026-09-08 covered code selection, preparation of public copies, codebook creation, and static review. Results and limitations of the subsequent execution checks on 2026-09-14 are described above under “Reproducibility checks and known limitations.”

## License

The code and accompanying documentation in this repository are available under the [MIT License](LICENSE). Copyright (c) 2026 Toshiharu Mitsuhashi.
