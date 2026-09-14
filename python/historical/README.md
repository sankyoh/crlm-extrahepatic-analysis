# Historical averaging of covariate-balance exports

English | [日本語](README_JP.md)

These scripts preserve Python code from three analysis notebooks. They are
archival support code, not a verified current method for summarizing balance.
The notebooks, their saved outputs and metadata, and the Excel workbooks are
not included.

Stata computes the SMD and variance ratio for each imputation using `covbal`.
These Python scripts average the already computed, weighted results. They do
not clean patient datasets, fit outcome models, or calculate RMST. They remain
included when the dataset-cleaning code is excluded.

Saved execution records for the three source notebooks show all 22 files read
without missing-file messages and successful output. The stored mean outputs
correspond to the assembled balance workbook: all selected all-cohort cells
match, and all surgery/lung SMD cells match. Three variance-ratio cells in each
of surgery and lung are reciprocals in the assembled table. That workbook
contains sign-reversal and reciprocal formulas, but no formula that averages
the 22 imputations. This supports their role in table preparation; it does not
establish exact reproduction of every row of the final manuscript table.

## Provenance and unchanged numerical selections

Source paths below are relative to the original private project; the source
notebooks were read without modification.

| Released script | Original notebook | Preserved `iloc` row slice | Actual Excel cells | Output rows |
| --- | --- | --- | --- | --- |
| `average_balance_surgery.py` | `stata/excel/surgery_only/Cell_mean_of_22files.ipynb` | `2:25` | F3:G25 | 23 |
| `average_balance_lung.py` | `stata/excel/lung_only/Cell_mean_of_22files.ipynb` | `2:22` | F3:G22 | 20 |
| `average_balance_all.py` | `stata/excel/mimi_stbw/Cell_mean_of_22files.ipynb` | `2:23` | F3:G23 | 21 |

Each script expects `mimi_stbw_1_smdvr.xlsx` through
`mimi_stbw_22_smdvr.xlsx`, reads sheet `SMD_VR` with `header=None`, and selects
columns `5:7` (Excel F and G). These settings are copied unchanged.

The current Stata master writes all-cohort balance exports to `excel/all`,
whereas the historical all-cohort notebook was stored under `excel/mimi_stbw`.
The released `average_balance_all.py` is the latter notebook's code; renaming it
does not establish that its row selection matches current `excel/all` exports.
The command-line folder is explicit so that users choose the intended private
inputs. Current Stata surgery and lung folders are `excel/surgery_only` and
`excel/lung_only`, respectively.

## Running on private exports

Python requires `numpy`, `pandas`, and `openpyxl`. No dependency versions were
pinned in the notebooks. Install the packages separately; the notebook's
installation cell has been removed from the executable scripts.

```text
python -m pip install numpy pandas openpyxl
python python/historical/average_balance_surgery.py PRIVATE_SURGERY_FOLDER
python python/historical/average_balance_lung.py PRIVATE_LUNG_FOLDER
python python/historical/average_balance_all.py PRIVATE_ALL_FOLDER
```

Run from the repository root and replace each placeholder with an authorized
private folder, preferably outside the repository. Quote paths containing
spaces. Each script writes `mean_F3_G23.xlsx` to its input folder and overwrites
an existing file with that name. Inputs and generated outputs must remain
private and excluded from Git. Only the source code is supplied here.

## Historical limitations

- The surgery and lung scripts retain comments and the output filename that
  refer to F3:G23, even though their actual row slices differ as shown above.
  The surgery script produces 23 rows and the lung script 20 rows when all
  selected rows exist. Their original comments describing 21 output rows also
  remain unchanged. Neither comments nor filenames determine the selection.
- Selection is by fixed row and column position. The scripts do not verify
  variable names, row alignment, or whether every intended current balance
  measure is included. They do not confirm that columns F and G retain the
  same meaning in a different export version. Check the input workbook layout
  before interpreting a result.
- The all-cohort script selects 21 rows. The current 23-row Stata balance
  export therefore has two terminal CA19-9 category rows outside this slice.
  This historical selection alone cannot reproduce all rows of that table.
- Missing files are reported and skipped. A run can therefore average fewer
  than 22 imputations. Nonnumeric cells are converted to `NaN`, and `nanmean`
  ignores these values, so the contributing file count can vary by cell.
  Differently shaped selected arrays can fail when stacked; an all-missing
  cell remains missing.
- The calculation is the unweighted arithmetic mean of corresponding cells.
  It does not pool estimates using Rubin's rules, account for imputation
  uncertainty, or establish satisfactory balance in every imputation.
- These exact row ranges and behaviors have been preserved for provenance.
  No patient-data analysis or numerical reproduction was run during the initial
  release preparation on 2026-09-08. The scripts were checked by Python syntax parsing only.

## Release-copy transformations

Code cells were exported to plain Python. Notebook outputs and metadata were
omitted. The notebook installation cell was replaced by the documented manual
installation command above, including the imported `numpy` dependency.
Machine-specific personal folder paths were removed and replaced by the
required `private_folder` command-line argument. Input-folder and output-path
setup now occurs inside `main(private_folder)`; the existing output basename
is preserved. A short archival-status docstring and command-line help were
added. All original numerical constants, file-selection logic, missing-file
handling, numeric coercion, averaging, and Excel export options are retained.
