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
	local graph_file CommSup_
}
else {
	local graph_file `2'
}

use `in_file', clear

local in_file df03mi

local expv trt
local wt   stbw
local ps ps

preserve 
keep if _mi_m==1

capture mkdir graph

********************************************************************************
***** 曝露の値ラベル文字列をローカルマクロに格納

local label0 : label (`expv') 0
local label1 : label (`expv') 1

* 確認
// di "`label0'"   // → expv0
// di "`label1'"   // → expv1

********************************************************************************
***** Descriptive Statistics
bys `expv': su `wt'
bys `expv': tabstat `wt', s(sum)

********************************************************************************
***** Common support
* 傾向スコアについて 全摘出術（ope_type==0）のヒストグラムを作成
histogram `ps' if `expv'==0, ///
	width(0.05) start(0) percent ///
	color(blue%30)horizontal yscale(range(0.7 1)) ///
	ylabel(, nogrid) xscale(reverse) ///
	xlabel(, grid) xline(0, lcolor(black)) ///
	title("`label0'") legend(off) name(his0, replace) ///
	plotregion(margin(zero) ilcolor(black))

* 傾向スコアについて、部分切除（ope_type==1）のヒストグラムを作成
histogram `ps' if `expv'==1, ///
	width(0.05) start(0) percent ///
	color(red%30)horizontal yscale(off) yscale(range(0.7 1)) ///
	ylabel(, nogrid) ///
	xlabel(, grid) xline(0, lcolor(black)) ///
	title("`label1'") legend(off) name(his1, replace) ///
	plotregion(margin(zero) ilcolor(black))
	
*2つのグラフを統合
graph combine his0 his1, imargin(zero) name(comb_hist, replace) xcommon
graph export "./graph/`graph_file'unwt.png", as(png) name(comb_hist) replace

********************************************************************************
***** Common support (Overlap weight 2)

// histogramコマンドは、整数の重み（fweight）しか受け付けないので、無理に整数にする。
// 10^k倍した重みでは、絶対値を出すと大きく異なった値になるものお、Percentなら特に問題ない。
local k = 5
gen histwgt = round(10^(`k')*`wt', 1)

* 傾向スコアについて 全摘出術（ope_type==0）のヒストグラムを作成
histogram `ps' [fw=histwgt] if `expv'==0, ///
	width(0.05) start(0) percent ///
	color(blue%30)horizontal yscale(range(0 1)) ///
	ylabel(, nogrid) xscale(reverse) ///
	xlabel(, grid) xline(0, lcolor(black)) ///
	title("`label0'") legend(off) name(his0_wt, replace) ///
	plotregion(margin(zero) ilcolor(black))

* 傾向スコアについて、部分切除（ope_type==1）のヒストグラムを作成
histogram `ps' [fw=histwgt] if `expv'==1, ///
	width(0.05) start(0) percent ///
	color(red%30)horizontal yscale(off) yscale(range(0 1)) ///
	ylabel(, nogrid) ///
	xlabel(, grid) xline(0, lcolor(black)) ///
	title("`label1'") legend(off) name(his1_wt, replace) ///
	plotregion(margin(zero) ilcolor(black))
	
*2つのグラフを統合
graph combine his0_wt his1_wt, imargin(zero) name(comb_hist_wt, replace) xcommon
graph export "./graph/`graph_file'`wt'.png", as(png) name(comb_hist_wt) replace
