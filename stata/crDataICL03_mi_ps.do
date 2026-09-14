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
	local in_file df02mi
}
else {
	local in_file `1'
}

if ("`2'"==""){
	local out_file df03mi
}
else {
	local out_file `2'
}

use `in_file', clear
keep if trt != .

local expv trt
local covs1 sex age_cat side i.grade primary_n i.ehd3 i.ras_mut recu_6m ///
	i.tumor_count_cat i.tumor_size_cat i.cea_cat i.ca199_cat
local minds grade_mind primary_n_mind tumor_count_cat_mind tumor_size_cat_mind cea_cat_mind ca199_cat_mind

****** 効率化のため ChatGPT利用


********************************************************************************
***** stabilized weight calculation

*  expv ~ covars

// set trace on
// set tracedepth 1
qui {
* 傾向スコア算出
mi xeq: logistic `expv' `covs1' `minds' ; predict ps, pr
// mi xeq: sort `expv';  by `expv': su ps // for debug
label variable ps   "Propensity Score"

* 周辺確率算出
logistic `expv'
predict mp, pr
label variable mp   "Marginal Prob."
}

********************************************************************************

* stabilized IPTW
gen     stbw =     mp/ps     if `expv'==1
replace stbw = (1-mp)/(1-ps) if `expv'==0
label variable stbw "sIPTW"

* overlap weight (original)
gen     ovwt = 1-ps if `expv'==1
replace ovwt = ps   if `expv'==0
label variable ovwt "overlap weight (Li,2018)"

* Normalized OW（群内合計=1）：w_now // Fan Liの個人サイトによる
mi xeq: sort `expv';by `expv': egen double sum_ow = total(ovwt)
gen double w_now = ovwt / sum_ow
label var w_now "Normalized overlap weight (groupwise sum=1)"

// mi xeq: sort `expv'; by `expv': tabstat w_now, s(sum) // debug：各群で合計1

* Standardized overlap weight 群合計=n_group に標準化
mi xeq: sort `expv'; by `expv': gen   long n_g     = _N
gen double w_sow_g = ovwt * n_g / sum_ow
label var w_sow_g "Standardized OW (group sum = n_group)"

// mi xeq: sort `expv'; by `expv': tabstat w_sow_g, s(sum) // debug：各群で元のサンプルサイズに一致


* 確認
mi xeq 15: sort `expv';by `expv':tabstat stbw ovwt  w_now w_sow_g ps, s(sum mean sd max min) c(s)
mi xeq 15: sort `expv';by `expv':corr stbw ovwt  w_now w_sow_g ps



********************************************************************************
***** Closing

label data "ICL >- mi >- ps+wgt"
compress
save `out_file', replace

gen mim = _mi_m
mi unset
keep if mim==1
label data "_mi_m==1, ps+wgt, for test"
save "test_`out_file'", replace