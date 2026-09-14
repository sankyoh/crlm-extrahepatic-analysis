/*******************************************************************************

肝外転移を伴う大腸癌肝転移の肝切除戦略
Study analysis code.

主要仮説
P: データベース上のCRLM with EHM患者
E: 「肝切除-肝外非切除」がB群 = 86
C: 「肝非切除-肝外非切除」がC群 = 149
O: OS

*******************************************************************************/
***** Setup

// 引数の処理
if ("`1'"==""){
	local in_file df03mi
}
else {
	local in_file `1'
}

if ("`2'"==""){
	local out_folder all
}
else {
	local out_folder `2'
}

use `in_file', clear
cap mkdir "./excel/`out_folder'"



local expv trt
local covs1 sex age_cat side i_grade0 i_grade1 i_grade2 primary_n i_ehd0 i_ehd1 i_ehd2 i_ras_mut0 i_ras_mut1 i_ras_mut2 recu_6m ///
	i_tumor_count_cat0 i_tumor_count_cat1 i_tumor_count_cat2 ///
	i_tumor_size_cat0 i_tumor_size_cat1 ///
	i_cea_cat0 i_cea_cat1 ///
	i_ca199_cat0 i_ca199_cat1
	
if ("`in_file'"=="df03mi_lung.dta") {
	local covs1 sex age_cat side i_grade0 i_grade1 i_grade2 primary_n i_ras_mut0 i_ras_mut1 i_ras_mut2 recu_6m ///
		i_tumor_count_cat0 i_tumor_count_cat1 i_tumor_count_cat2 ///
		i_tumor_size_cat0 i_tumor_size_cat1 ///
		i_cea_cat0 i_cea_cat1 ///
		i_ca199_cat0 i_ca199_cat1
}
	
local max_mi_id 22 // 補完セットを何個作成したか？
local wtlist stbw // w_sow_g stbw // ovwt w_now w_sow_g // 調整のための重みリスト



***** Generate Dummy variables
cap rename ehd3 ehd
cap drop ehd2

local cat_vars grade primary_n ehd ras_mut tumor_count_cat tumor_size_cat cea_cat ca199_cat

foreach x of local cat_vars {
	xi i.`x', noomit
	local torename "`_dta[__xi__Vars__To__Drop__]'"
	local i=0
	foreach v of local torename {
		rename `v' i_`x'`i++'
	}
}

********************************************************************************
***** Covariate Balance table

// ssc install covbal

foreach wt of local wtlist {
	forvalues x =1/`max_mi_id' {
		preserve
		keep if _mi_m == `x'
		bal_sIPTW `expv' `covs1', wt(`wt') file_name("`out_folder'/mimi_`wt'_`x'") replace
		restore
	}
}