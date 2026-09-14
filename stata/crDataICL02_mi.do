/*******************************************************************************

肝外転移を伴う大腸癌肝転移の肝切除戦略
Study analysis code.

主要仮説
P: データベース上のCRLM with EHM患者
E: 「肝切除-肝外非切除」がB群 = 86
C: 「肝非切除-肝外非切除」がC群 = 149
O: OS

*******************************************************************************/
// 引数の処理
if ("`1'"==""){
	local in_file df01mi
}
else {
	local in_file `1'
}

if ("`2'"==""){
	local out_file df02mi
}
else {
	local out_file `2'
}

use `in_file', clear

* 共変量セット（PSモデル用）
local covs1 sex age_cat side i.grade primary_n i.ehd i.ras_mut recu_6m ///
           i.tumor_count_cat i.tumor_size_cat i.cea_cat i.ca199_cat

/*******************************************************************************

Multiple Imputaiton

*******************************************************************************/
* Group Cのみ欠損している変数について、MIで対応する。
// Group B/Cの両方で欠損している変数は、欠損カテゴリとして扱う。
// replace primary_n       = . if primary_n       == 2
// replace tumor_count_cat = . if tumor_count_cat == 3
// replace tumor_size_cat  = . if tumor_size_cat  == 2

keep if trt!=.

* Nelson–Aalen を作る
stset time_os_d, failure(event_os)
sts gen na_os = na
stset, clear

* 欠損のあるカテゴリ変数を登録
mi set flong
mi register imputed grade primary_n tumor_size_cat tumor_count_cat cea_cat ca199_cat

* 欠損の無い（あるいは解析で使う）変数を登録
mi register regular trt sex age_cat side ehd3 ras_mut recu_6m ///
                   na_os event_os

* 連鎖方程式（mlogit）で代入
* 代入モデルには trt と アウトカム情報（time_os_d event_os）も入れて"整合性"を確保
mi impute chained ///
    (ologit, augment) grade ///
    (mlogit, augment) primary_n tumor_size_cat tumor_count_cat cea_cat ca199_cat = ///
    trt sex age_cat side ehd3 ras_mut recu_6m na_os event_os, ///
    add(22) rseed(19271105)
	
// qui mi estimate:logit trt `covs1'
// how_many_imputations // imputatin = 22

compress
label data "ICL -> MI"
save `out_file', replace

exit
