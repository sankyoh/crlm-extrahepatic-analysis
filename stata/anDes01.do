/*******************************************************************************
2025/08/01

by 
P: 
E: 
C: 
O: 

*******************************************************************************/
***** Setup

// 引数の処理
if ("`1'"==""){
	local in_file df03mi.dta
}
else {
	local in_file `1'
}

if ("`2'"==""){
	local out_file des_tab_wt
}
else {
	local out_file `2'
}

use `in_file', clear

// local macro
local expv trt
local wt   stbw
local ps ps

// MIなので、全セット出す事ができないので、一つめのみでやっている。
gen mim = _mi_m
mi set, clear

preserve 
keep if mim==1

capture mkdir graph

********************************************************************************

* des_vars = 記述統計量で示す変数リスト（i.もつける）
local des_vars ///
	i.sex i.age_cat i.side i.grade i.primary_n i.ehd3 i.ras_mut i.recu_6m i.tumor_count_cat i.tumor_size_cat i.cea_cat i.ca199_cat

* iqr_vars = 記述統計の表でIQRを示す変数
local iqr_vars

// くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 //
// くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 //
// くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 //


* 記述統計の表（重み付けなし）
dtable `des_vars', ///
		by(`expv', nototals tests) ///
		column(by(hide)) /// 
		sample(, place(seplabels)) ///
		///
		define(iqi = q1 q3, delimiter(", ")) ///
		sformat("[%s]" iqi) /// 
		///	
		nformat(%16.2fc mean sd q1 q2 q3) ///
		continuous(, test(regress)) ///
		continuous(`iqr_vars', statistic(q2 iqi)) ///
		factor(,test(pearson)) ///
		///
		note(Mean(SD) or N(%)) ///
		note(Median[IQR]) ///
		///
		export("./excel/`out_file'0.xlsx", as(xlsx) replace)
		
* 記述統計の表（重み付けあり）
foreach w of local wt {
	svyset _n [pw=`w']
	dtable `des_vars', ///
			by(`expv', nototals tests) ///
			column(by(hide)) /// 
			sample(, place(seplabels)) ///
			///
			define(iqi = q1 q3, delimiter(", ")) ///
			sformat("[%s]" iqi) /// 
			///	
			nformat(%16.2fc mean sd q1 q2 q3 fvfreq fvper) ///
			continuous(, test(regress)) ///
			continuous(`iqr_vars', statistic(q2 iqi)) ///
			factor(,test(pearson)) ///
			///
			note(Mean(SD) or N(%)) ///
			note(Median[IQR]) ///
			///
			svy ///
			///
			export("./excel/`out_file'1_`w'.xlsx", as(xlsx) replace)
	
	// dtableだと重み合計が整数になるので、小数点下の値を表示させるために必要
	bys `expv': tabstat `w' , s(sum)
}		

		
		