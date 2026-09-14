# Public data dictionary

English | [日本語](README_JP.md)

Prepared on 2026-09-08. No patient-level data are included.

## Scope

This dictionary was created by reading all 124 columns of the source Excel workbook and the 43 distinct variables present in nine Stata datasets used in the analysis workflow. Variable and value labels were extracted from stored metadata, and variable creation, transformations, and missing-value handling were checked against the original project's Stata code. Lists of observed values, example records, identifier values, dates, free-text contents, minimum or maximum values, missing-value counts, and category frequencies are not included.

Dataset preparation and cleaning code is excluded from the release. References in this dictionary to `crDataICL01*.do` or `map2cat` identify original-project procedures used as evidence for definitions; they do not mean that those procedures are included in the public folder. The standard Stata workflow requires the three cohorts' `df01mi*.dta` files after coding, cohort selection, and creation of pre-imputation missingness indicators have been completed.

| File | Contents |
| --- | --- |
| [analysis_variables.csv](analysis_variables.csv) | 43 distinct analysis variables: Japanese definitions, units, source columns, coding, missing-value handling, and datasets containing each variable |
| [stata_dataset_schema.csv](stata_dataset_schema.csv) | Column order, storage types, display formats, and stored labels for nine Stata datasets; 321 metadata rows in total |

The two CSV files use UTF-8 with a byte order mark (BOM). Each row describes an analysis variable or a dataset column; it is not a patient record. The CSV metadata retain their original Japanese definitions and labels. English translations of the analysis-variable definitions and coding are provided below, followed by the source-column reference table.

Use `analysis_variables.csv` for variable definitions, coding, and missing-value handling, and `stata_dataset_schema.csv` for the structure of the datasets at each analysis stage. The source-column table below provides context for the variables' origins; importing or cleaning the source workbook is outside the released workflow.

## Source materials and version checks

- The first sheet of the source Excel workbook in the original project's `stata/` folder is the reference for column definitions. Column AL, which has no heading, is retained. Code that imports the source Excel workbook is excluded from the release.
- The identically named Excel workbook in the project root has an additional sheet listing columns, so the complete files differ. All cell values read from the first sheets of the two workbooks were confirmed to match. This does not establish equality of formatting, formula strings, or internal Excel metadata.
- `df01mi*.dta` files are ready for imputation; `df02mi*.dta` files contain 22 imputations; and `df03mi*.dta` files include propensity scores (PS) and weights. The all-cohort, `_surgery`, and `_lung` files were included at each stage.
- The `df03mi_surgery.dta` file saved for R was byte-for-byte identical to the file with the same name in the Stata folder. They share this codebook.
- Test datasets, MNAR datasets, incomplete surgery-plus-lung datasets, analysis-result workbooks, logs, and RDS files are not included as separate datasets in this dictionary.

## Reading the dictionary and important qualifications

`_mi_m=0` denotes the original unimputed data, and `1` through `22` denote imputation indices. Rows across imputations must not be counted as independent patients. `_mi_id` is the internal identifier linking observations across imputations, while `id` is the source dataset's overall sequential identifier. Neither identifier values nor linkage tables are public.

Stored value labels for the six imputed variables (`grade`, `primary_n`, `tumor_count_cat`, `tumor_size_cat`, `cea_cat`, and `ca199_cat`) retain legacy `missing` codes. These codes were converted back to Stata `.` during imputation preparation. The presence of a label does not mean that its code occurs in the data. `ras_mut=2`, labelled Unknown, remains a category.

`*_mind` indicators detect pre-imputation system-missing values `.` using `== .`. Extended missing values `.a` through `.z` do not be used in this analysis. The surgery cohort is derived from records whose primary-tumor surgery date is neither blank, designated as no resection, nor `-`. The lung cohort is derived from records with `ehd2=0`; it is not synonymous with all patients with lung metastases, including those with multiple metastatic organ sites.

The source heading and code comments establish `event_os` as 0=alive/censored and 1=death. The dictionary states the evidence for its definition. The stored variable label for `ras_mut` is K-Ras, but its source column includes RAS/RAF mutations; the stored label should not be treated as the clinical definition without qualification.

Items whose units, time origins, or clinical classification details cannot be established from the source data and code are marked as undefined. Meanings and permissible ranges have not been inferred from observed values. Many unused source Excel columns are defined only by their headings; this dictionary does not replace an independent data-collection manual.

The current R RMST analysis uses `_mi_m=1` and restricts the cohort to patients with three variables observed in the original data. PS and weights are recalculated in R; the analysis does not simply use the saved Stata weights described here. See the [R README](../r/README.md) for details.

## Analysis variables

Coding descriptions below are English translations where needed. Stored label strings and Japanese definitions remain available in the CSV files.

| Variable | Definition | Coding |
| --- | --- | --- |
| id | Overall sequential identifier in the source data. Values and linkage tables are not public. |  |
| sex | Sex: 0=female and 1=male, as specified in the source Excel heading. | 0=female; 1=male |
| age | Age recorded in the source data. Details of the reference date cannot be established from the code. |  |
| age_cat | Two age categories, coded from the source Excel categories. | 0=69 years or younger; 1=70 years or older |
| side | Primary-tumor sidedness. | 0=Left; 1=Right |
| grade | Primary-tumor differentiation. | 0=Well; 1=Moderate; 2=poor/mucinous; 3=missing |
| primary_n | Primary-tumor lymph-node metastasis category. | 0=N-; 1=N+; 2=missing |
| ehd3 | Three categories of extrahepatic metastatic sites used in the propensity score. | 0=M1 (Lung/LN/others); 1=M1 (Peri); 2=multiple |
| trt | Treatment group: 0=group C (neither hepatic nor extrahepatic resection), 1=group B (hepatic resection without extrahepatic resection). Other categories are set to missing by map2cat and excluded before MI. | 0=Group C; 1=Group B |
| ras_mut | RAS/RAF mutation category from the source Excel workbook. The stored label is K-Ras, but the input includes RAS/RAF. | 0=wild type; 1=RAS/RAF mutation; 2=Unknown |
| recu_6m | Synchronous/metachronous liver metastases. The source heading classifies recurrence within 6 months as synchronous. | 0=Synchronous; 1=Metachronous |
| tumor_count | Liver-tumor count adjusted with reference to the number of resected lesions. |  |
| tumor_count_cat | Liver-tumor count category, using source Excel column AL, which has no heading. | 0=1; 1=2-4; 2=5 or more; 3=missing |
| max_tumor | Maximum liver-tumor diameter. Converted to numeric after replacing the source string meaning unknown with a blank. |  |
| max_tumor_seq | Numeric source Excel column named maximum tumor diameter (numeric series). Its specific difference from max_tumor is undefined. |  |
| tumor_size_cat | Maximum liver-tumor diameter category, coded from the source category without recalculation from continuous values. | 0=≤ 5cm; 1=> 5cm; 2=missing |
| cea | CEA at liver-metastasis diagnosis. |  |
| cea_cat | CEA category at liver-metastasis diagnosis, with a threshold of 10. | 0=less than 10; 1=10 or greater; 2=missing |
| ca199 | CA19-9 at liver-metastasis diagnosis. |  |
| ca199_cat | CA19-9 category at liver-metastasis diagnosis, with a threshold of 37 U/mL. | 0=≤37; 1=>37; 2=missing |
| event_os | Overall-survival event indicator: 0=alive/censored, 1=death. | 0=alive/censored; 1=death |
| time_os_d | Recorded survival time in days. Used to calculate the Nelson–Aalen estimate in crDataICL02_mi. Details of the time origin require confirmation against the input-data definition. |  |
| time_os_m | Recorded survival time in months. Used in Stata survival analyses and R RMST analyses. The public code does not convert days to months. |  |
| grade_mind | Pre-MI missingness indicator for grade. Generated with grade==. after converting the original category's missing code back to .; 1=system-missing ., 0=otherwise. Extended missing values .a–.z do not meet this condition. Retained after imputation. | 0=not system-missing dot; 1=system-missing dot before MI |
| primary_n_mind | Pre-MI missingness indicator for primary_n. Generated with primary_n==. after converting the original category's missing code back to .; 1=system-missing ., 0=otherwise. Extended missing values .a–.z do not meet this condition. Retained after imputation. | 0=not system-missing dot; 1=system-missing dot before MI |
| tumor_count_cat_mind | Pre-MI missingness indicator for tumor_count_cat. Generated with tumor_count_cat==. after converting the original category's missing code back to .; 1=system-missing ., 0=otherwise. Extended missing values .a–.z do not meet this condition. Retained after imputation. | 0=not system-missing dot; 1=system-missing dot before MI |
| tumor_size_cat_mind | Pre-MI missingness indicator for tumor_size_cat. Generated with tumor_size_cat==. after converting the original category's missing code back to .; 1=system-missing ., 0=otherwise. Extended missing values .a–.z do not meet this condition. Retained after imputation. | 0=not system-missing dot; 1=system-missing dot before MI |
| cea_cat_mind | Pre-MI missingness indicator for cea_cat. Generated with cea_cat==. after converting the original category's missing code back to .; 1=system-missing ., 0=otherwise. Extended missing values .a–.z do not meet this condition. Retained after imputation. | 0=not system-missing dot; 1=system-missing dot before MI |
| ca199_cat_mind | Pre-MI missingness indicator for ca199_cat. Generated with ca199_cat==. after converting the original category's missing code back to .; 1=system-missing ., 0=otherwise. Extended missing values .a–.z do not meet this condition. Retained after imputation. | 0=not system-missing dot; 1=system-missing dot before MI |
| opeday | Primary-tumor surgery date stored as a string. Used to select the surgery cohort. Actual dates are not public. |  |
| ehd2 | Four categories of extrahepatic metastatic sites. The lung cohort includes only ehd2==0. | 0=M1 (Lung); 1=M1 (Peri); 2=M1 (LN/others); 3=multiple |
| na_os | Nelson–Aalen cumulative hazard derived from time_os_d and event_os. Used in the multiple-imputation model. |  |
| _mi_id | Stata-generated identifier linking observations across imputations, distinct from the original id. Values are not public. |  |
| _mi_miss | Missingness indicator used internally by Stata MI. Normally not used as an analysis covariate. |  |
| _mi_m | Imputation index in Stata flong format: 0=unimputed, 1–22=individual imputed datasets. Rows must not be counted as independent patients. | 0=original; 1..22=imputation index |
| ps | P(trt=1) estimated by ordinary logistic regression in each imputed dataset, using covariates and six missingness indicators. |  |
| mp | Marginal treatment probability from logistic trt without covariates. The stabilization numerator of the saved Stata weights. |  |
| stbw | Stabilized IPTW: mp/ps for trt=1 and (1-mp)/(1-ps) for trt=0. |  |
| ovwt | Overlap weight: 1-ps for trt=1 and ps for trt=0. Survival analyses in the current master specify stbw. |  |
| sum_ow | Sum of ovwt within each imputed dataset and treatment group. |  |
| w_now | Overlap weight normalized to sum to 1 within each group: ovwt/sum_ow. |  |
| n_g | Number of rows within each imputed dataset and treatment group. |  |
| w_sow_g | Overlap weight normalized to sum to n_g within each group: ovwt*n_g/sum_ow. |  |

## Source Excel columns

The headings below are English translations of the source headings. Exact original headings are retained in the [Japanese version](README_JP.md).

| Column | Source heading (English translation) | Analysis variable |
| --- | --- | --- |
| A | Overall sequential identifier | id |
| B | Liver-metastasis resection / no resection |  |
| C | Liver-metastasis resection classification |  |
| D | Sex: male 1 or female 0 | sex |
| E | Age | age |
| F | Age 2 | age_cat |
| G | Primary-tumor surgery date | opeday |
| H | Primary tumor, organized |  |
| I | Sidedness | side |
| J | Depth of wall invasion |  |
| K | Primary-tumor surgical procedure (free text) |  |
| L | Differentiation 2 | grade |
| M | Primary N+ | primary_n |
| N | Pathological v (v0-3) |  |
| O | Pathological ly (ly0-3) |  |
| P | Resection-margin involvement: SM+ 1 |  |
| Q | Distant metastases: liver, lung, ovary, peritoneum, etc. |  |
| R | Number of distant metastatic organs at liver-metastasis diagnosis |  |
| S | EHD (single/multiple) |  |
| T | EHD classification 1 |  |
| U | EHD classification 2 | ehd2 |
| V | EHD classification 3 | ehd3 |
| W | Treatment of extrahepatic lesions |  |
| X | Treatment of extrahepatic lesions 2 |  |
| Y | Treatment combination | trt |
| Z | Lung, ovary, peritoneum, etc. |  |
| AA | Extrahepatic lesions at liver-metastasis diagnosis |  |
| AB | Treatment of extrahepatic lesions (free text) |  |
| AC | Primary-tumor notes (free text) |  |
| AD | MSI |  |
| AE | RAS/RAF mutations | ras_mut |
| AF | Synchronous 0 or metachronous 1 |  |
| AG | Recurrence within 6 months: synchronous 0, metachronous 1 | recu_6m |
| AH | Simultaneous resection of primary tumor and liver metastases (1: yes) |  |
| AI | Single 0 or multiple 1 |  |
| AJ | Tumor count (imaging) |  |
| AK | Tumor count (adjusted with reference to resected lesion count) | tumor_count |
| AL |  | tumor_count_cat |
| AM | Tumor burden score |  |
| AN | Tumor burden score grade |  |
| AO | Bilobar lesions: 1 (for multiple lesions) |  |
| AP | Maximum tumor diameter (cm) | max_tumor |
| AQ | Maximum tumor diameter (numeric series) | max_tumor_seq |
| AR | Maximum tumor diameter before chemotherapy (for staging) |  |
| AS | Before-after |  |
| AT | Tumor-diameter classification | tumor_size_cat |
| AU | Former H classification |  |
| AV | Novel H classification |  |
| AW | Grade classification |  |
| AX | CEA at liver-metastasis diagnosis | cea |
| AY | CEA classification at liver-metastasis diagnosis | cea_cat |
| AZ | CA19-9 at liver-metastasis diagnosis (U/mL) | ca199 |
| BA | CA19-9 classification at liver-metastasis diagnosis | ca199_cat |
| BB | BC risk score |  |
| BC | Preoperative chemotherapy: yes 1 |  |
| BD | NAC or Conversion |  |
| BE | Reason for preoperative chemotherapy |  |
| BF | Reason for preoperative chemotherapy 2 |  |
| BG | Preoperative chemotherapy regimen |  |
| BH | Preoperative chemotherapy (courses or duration) |  |
| BI | Molecularly targeted agent |  |
| BJ | Molecularly targeted therapy classification |  |
| BK | Preoperative chemotherapy regimen 2 |  |
| BL | Preoperative chemotherapy (courses or duration) 2 |  |
| BM | Molecularly targeted agent 2 |  |
| BN | BMI |  |
| BO | Height (cm) |  |
| BP | Weight (kg) |  |
| BQ | DM |  |
| BR | T.Bil (mg/dl) |  |
| BS | PT (%) |  |
| BT | Alb (g/dl) |  |
| BU | ICG-R15 (%) |  |
| BV | Liver surgery date |  |
| BW | Liver-resection procedure: Hr0, S, 1, 2, 3 |  |
| BX | Resected region (free text) |  |
| BY | Combined surgical procedures (free text) |  |
| BZ | Major Hx: Hr2 or greater |  |
| CA | Anatomical resection |  |
| CB | PSH vs Major Hx |  |
| CC | Open 0 or laparoscopic 1 |  |
| CD | Combined use of RFA: 1 |  |
| CE | Additional surgical information (free text) |  |
| CF | Operating time (minutes) |  |
| CG | Blood loss (ml) |  |
| CH | Blood transfusion status |  |
| CI | Number of resected lesions |  |
| CJ | Curability |  |
| CK | Curability 2 |  |
| CL | Curability 3 |  |
| CM | Postoperative complications (CD classification) |  |
| CN | Postoperative-complication classification |  |
| CO | Complication type 1 |  |
| CP | Complication type 2 |  |
| CQ | Complication type 3 |  |
| CR | Postoperative adjuvant therapy: yes 1 |  |
| CS | Adjuvant-therapy regimen |  |
| CT | Postoperative adjuvant therapy (courses or duration) |  |
| CU | Molecularly targeted agent 4 |  |
| CV | Additional notes (free text, regimen changes, etc.) 2 |  |
| CW | Date recurrence was confirmed |  |
| CX | Date recurrence was confirmed (numeric series) |  |
| CY | Last outcome ascertainment date |  |
| CZ | Last outcome ascertainment date (numeric series) |  |
| DA | Recurrence: yes 1 |  |
| DB | Exclusion from recurrence analysis |  |
| DC | Extrahepatic recurrence present |  |
| DD | Days to recurrence |  |
| DE | DFS days |  |
| DF | Disease free survival |  |
| DG | Recurrence classification |  |
| DH | Recurrence-treatment classification |  |
| DI | Recurrence site 1 |  |
| DJ | Recurrence treatment 1 |  |
| DK | Recurrence site 2 |  |
| DL | Recurrence treatment 2 |  |
| DM | Recurrence site (free text) |  |
| DN | Recurrence treatment (free text) |  |
| DO | Last outcome ascertainment date 2 |  |
| DP | Alive 0, death 1 | event_os |
| DQ | Survival days | time_os_d |
| DR | Survival months | time_os_m |
| DS | Survival days after recurrence |  |
| DT | Cause of death (free text) |  |
