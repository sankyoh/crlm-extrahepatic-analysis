* Run from the public repository's stata directory.
* Supply the three authorized, cleaned, pre-imputation private datasets below.
* Input definitions, including precreated missingness indicators: ../codebook/README.md

if c(stata_version) < 18 {
    display as error "Stata 18 or later is required for the dtable step."
    exit 9
}

capture confirm file "master.do"
if _rc {
    display as error "Set the working directory to the repository's stata directory."
    exit 601
}
capture confirm file "bal_sIPTW.ado"
if _rc {
    display as error "The local helper bal_sIPTW.ado is missing."
    exit 601
}
foreach input in df01mi.dta df01mi_surgery.dta df01mi_lung.dta {
    capture confirm file "`input'"
    if _rc {
        display as error "Private cleaned input `input' is required; it is not distributed."
        exit 601
    }
}

capture which covbal
if _rc {
    display as error "Install the external Stata command covbal before running this code."
    exit 199
}

adopath ++ "."
set more off
capture mkdir "excel"
capture mkdir "excel/all"
capture mkdir "excel/surgery_only"
capture mkdir "excel/lung_only"
capture mkdir "graph"
capture mkdir "surv_graph"

do "master.do"
