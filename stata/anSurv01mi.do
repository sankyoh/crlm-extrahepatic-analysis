/*******************************************************************************
2025/08/06
Survival analysis code.

// 引数1=dtaファイル
// 引数2=アウトカム OS/PFS　など
// 引数3=曝露変数
// 引数4=重み

*******************************************************************************/
***** Setup
use `1', clear

cap mkdir surv_graph
local today `5' // 日付でも良いけれど、ループさせるときには識別させるための利用

// くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 //
// くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 //
// くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 くコ:彡 //

********************************************************************************
***** Setting Arguments

* 引数2の設定（アウトカム）
// OS or RFS
local osrfs `2'
if ("`2'"=="") {
	local osrfs os
}

// Graphのラベル用
if ("`osrfs'"=="os") {
	local ytitle "Overall survival probability"
}
if ("`osrfs'"=="rfs") {
	local ytitle "Relapse free suvival probability"
}

* 引数3の設定（曝露変数）
local expv `3'
if ("`3'"=="") {
	local expv ope_type
}

// 曝露変数のvalue labelの内容を取得する。
local valuelabelname: value label `expv'

// value labelの内容を取得してlocalマクロに格納
local label0: label (`valuelabelname') 0
local label1: label (`valuelabelname') 1

* 引数4の設定（調整のための重み）
local weight `4'
if ("`4'"=="") {
	local weight ovwt3
}

* 生存時間
local survtime time_`osrfs'_m

* グラフ保存フォルダ名
local folder surv_graph

********************************************************************************
***** Crude analysis
mi stset `survtime', fail(event_`osrfs'==1)

* Cox PH model
mi estimate, dots esampvaryok eform:stcox i.`expv', vce(robust)

* 比例ハザード性の確認
stphplot, by(`expv') name(phplot_`osrfs'_`expv'_wt0, replace)
graph export "./`folder'/phpplot_`today'_`osrfs'_`expv'_wt0.png", replace as(png)
// graph save   "./graph/phpplot_`today'_`osrfs'_`expv'_wt0.gph", replace

* 比例ハザード性が崩れていたので、パラメトリックモデルで推定する
mi estimate, dots esampvaryok eform:streg i.trt, vce(robust) distribution(weibull)

* Weibull AFT model：生存時間比と95%信頼区間
mi estimate, dots esampvaryok eform("Time ratio"): streg i.trt, vce(robust) distribution(weibull) time

* 記述統計量的な解析（用は mi estimate が効かない分析）は、補完セットのうち1個だけを使う。
preserve
gen mim = _mi_m
mi unset
keep if mim==1

stset `survtime', fail(event_`osrfs'==1)

* MSTを先に算出してグラフで利用
stsum if `expv'==1
local high_p50 = `r(p50)'

* MSTの算出
stsum if `expv'==0
stsum if `expv'==1

* Graphを作成
sts graph, by(`expv') /*plotopts(lwidth(thick))*/ ci ///　ciを付けないときはthickで太くしたほうが良いかも。
	ci1opts(lcolor(none) fcolor(stblue%20)) ///
	ci2opts(lcolor(none) fcolor(stred%10))  ///
	risktable(, format(%9.0f) rowtitle(`label0')  failevents format(%9.1f) size(small) group(#1) title("At risk", size(small))) /// ここのrowtitleはexposure=1のもの
	risktable(, format(%9.0f) rowtitle(`label1') failevents size(small) group(#2)) ///
	xtitle("Months") ytitle("`ytitle'") title("Kaplan-Meier Curve", size(small)) ///
	censored(single) ///
	legend(position(12)) ///
	/* addplot(function y=`high_p50', horizontal range(0 0.5) lcolor(gs8) lpattern(shortdash) || ///
		function y=0.5, range(0 `high_p50') lcolor(gs8) lpattern(shortdash) legend(row(1) ///
			order(1 "`label0'" 3 "`label1'"))) */ ///
			legend(row(1) order(1 "`label0'" 3 "`label1'")) ///
	name(KMC_`osrfs'_`expv'_wt0, replace)
	
* Graphを出力
graph export "./`folder'/KMC_`today'_`osrfs'_`expv'_wt0.png", replace as(png)
graph save   "./`folder'/KMC_`today'_`osrfs'_`expv'_wt0.gph", replace
	
* Log-rank Test
sts test `expv'

* 36ヶ月、60ヶ月のSurvivalと信頼区間
qui su _t 
if (`r(max)' <= 36) {
	local maxtime = int(`r(max)')
	di "`r(max)'"
	di "`maxtime'"
	sts list, by(`expv') risktable(`maxtime')
}
else if (36 < `r(max)' & `r(max)'<60) {
	local maxtime = int(`r(max)')
	di "`r(max)'"
	di "`maxtime'"
	sts list, by(`expv') risktable(36 `maxtime')
}
else if (60 <= `r(max)') {
	di "`r(max)'"
	di "`maxtime'"
	sts list, by(`expv') risktable(36 60)
}
restore

*******************************************************************************/
***** Weighting analysis

mi stset `survtime' [pw=`weight'], fail(event_`osrfs'==1)


* Cox比例ハザードモデル
mi estimate, dots esampvaryok eform:stcox i.`expv', vce(robust)

* 比例ハザード性の確認
stphplot, by(`expv') name(phplot_`osrfs'_`expv'_wt1, replace)
graph export "./`folder'/phpplot_`today'_`osrfs'_`expv'_wt1.png", replace as(png)
// graph save   "./Graph/phpplot_`today'_`osrfs'_`expv'_wt1.gph", replace

* 比例ハザード性が崩れていたので、パラメトリックモデルで推定する
mi estimate, dots esampvaryok eform:streg i.trt, vce(robust) distribution(weibull)

* Weibull AFT model：生存時間比と95%信頼区間
mi estimate, dots esampvaryok eform("Time ratio"): streg i.trt, vce(robust) distribution(weibull) time

* 記述統計量的な解析（用は mi estimate が効かない分析）は、補完セットのうち1個だけを使う。
preserve
gen mim = _mi_m
mi unset
keep if mim==1

stset `survtime' [iw=`weight'], fail(event_`osrfs'==1)

* MSTを先に算出してグラフで利用
stsum if `expv'==1
local high_p50 = `r(p50)'

* MSTの算出
stsum if `expv'==0
stsum if `expv'==1

* Graphを作成
sts graph, by(`expv') /*plotopts(lwidth(thick))*/ ci ///　ciを付けないときはthickで太くしたほうが良いかも。
	ci1opts(lcolor(none) fcolor(stblue%20)) ///
	ci2opts(lcolor(none) fcolor(stred%10)) ///
	risktable(, format(%9.1f) rowtitle(`label0')  failevents format(%9.1f) size(small) group(#1) title("At risk", size(small))) ///
	risktable(, format(%9.1f) rowtitle(`label1') failevents size(small) group(#2)) ///
	xtitle("Months") ytitle("Overall survival probability") title("Kaplan-Meier Curve", size(small)) ///
	censored(single) ///
	legend(position(12)) ///
	/* addplot(function y=`high_p50', horizontal range(0 0.5) lcolor(gs8) lpattern(shortdash) || ///
		function y=0.5, range(0 `high_p50') lcolor(gs8) lpattern(shortdash) legend(row(1) ///
			order(1 "`label0'" 3 "`label1'"))) */ ///
			legend(row(1) order(1 "`label0'" 3 "`label1'")) ///
	name(KMC_`osrfs'_`expv'_wt1, replace)
	
* Graphを出力
graph export "./`folder'/KMC_`today'_`osrfs'_`expv'_wt1.png", replace as(png)
graph save   "./`folder'/KMC_`today'_`osrfs'_`expv'_wt1.gph", replace

* Log-rank Test
sts test `expv'

* 36ヶ月、60ヶ月のSurvivalと信頼区間
qui su _t 
if (`r(max)' <= 36) {
	local maxtime = int(`r(max)')
	di "`r(max)'"
	di "`maxtime'"	
	sts list, by(`expv') risktable(`maxtime')
}
else if (36 < `r(max)' & `r(max)'<60) {
	local maxtime = int(`r(max)')
	di "`r(max)'"
	di "`maxtime'"
	sts list, by(`expv') risktable(36 `maxtime')
}
else {
	di "`r(max)'"
	di "`maxtime'"
	sts list, by(`expv') risktable(36 60)
}
restore

exit