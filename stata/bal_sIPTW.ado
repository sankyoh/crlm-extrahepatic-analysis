capture drop bal_sIPTW
program define bal_sIPTW
    version 15.1

    syntax varlist(min=2), wt(name) [file_name(string) replace]

    // --- 入力変数の取得 ---
    local expv : word 1 of `varlist'
    local covars : list varlist - expv
    local weight `wt'
    local file_name "`file_name'"
    local replaceopt "`replace'"

    // --- 前提チェック ---
    confirm var `expv'
    foreach v of local covars {
        confirm var `v'
    }
    confirm var `weight'

    // --- バランステーブル（重みなし） ---
    display as text "-------------------------------------------------------------"
    display as text "[1] Covariate Balance (Unweighted)"
    display as text "-------------------------------------------------------------"
    covbal `expv' `covars'

    matrix unwt = r(table)
    mata: st_matrix("unwt_smd_vr", st_matrix("unwt")[., (7,8)])

    // --- バランステーブル（重みあり） ---
    display as text ""
    display as text "[2] Covariate Balance (Weighted with `weight')"
    display as text "-------------------------------------------------------------"
    covbal `expv' `covars', wt(`weight')

    matrix wt = r(table)
    mata: st_matrix("wt_smd_vr", st_matrix("wt")[., (7,8)])

    // --- 行ラベルと列ラベルの付与 ---
    local rowlabels ""
    local i = 1
    foreach v of local covars {
        local vlabel : variable label `v'
        if "`vlabel'" == "" local vlabel = "`v'"
        local rowlabels `rowlabels' "`vlabel'"
        local ++i
    }

    local n_unwt = rowsof(unwt_smd_vr)
    local n_wt   = rowsof(wt_smd_vr)
    local trimmed_unwt ""
    local trimmed_wt   ""
    local j = 1
    foreach lbl of local rowlabels {
        if `j' <= `n_unwt' local trimmed_unwt `trimmed_unwt' "`lbl'"
        if `j' <= `n_wt'   local trimmed_wt   `trimmed_wt' "`lbl'"
        local ++j
    }

    matrix rownames unwt_smd_vr = `trimmed_unwt'
    matrix colnames unwt_smd_vr = SMD VR

    matrix rownames wt_smd_vr = `trimmed_wt'
    matrix colnames wt_smd_vr = SMD VR

    // --- 表示 ---
    display as text ""
    display as text "[3] Extracted SMD and VR (Unweighted)"
    matlist unwt_smd_vr, names

    display as text ""
    display as text "[4] Extracted SMD and VR (Weighted)"
    matlist wt_smd_vr, names

    // --- Excel出力（オプション） ---
    if "`file_name'" != "" {
        local outname "./excel/`file_name'_smdvr.xlsx"
        quietly putexcel set "`outname'", sheet("SMD_VR") `replaceopt'
		quietly putexcel A1 = "Unweighted"
        quietly putexcel A2 = matrix(unwt_smd_vr), names
		quietly putexcel E1 = "Weighted with `weight'"
        quietly putexcel E2 = matrix(wt_smd_vr), names
        display as result "SMD/VR matrices saved to: `outname'"
    }

end
