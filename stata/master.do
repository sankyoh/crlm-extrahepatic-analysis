
/*******************************************************************************

肝外転移を伴う大腸癌肝転移の肝切除戦略
Study analysis code.

主要仮説
P: データベース上のCRLM with EHM患者
E: 「肝切除-肝外非切除」がB群 = 86
C: 「肝非切除-肝外非切除」がC群 = 149
O: OS

*******************************************************************************/

* 非公開の整理・クリーニング済みデータを入力する。
// df01mi.dta         = 全体
// df01mi_surgery.dta = 原発巣手術あり
// df01mi_lung.dta    = 肺限定
// 入力は多重代入前で、カテゴリ符号化と6つの欠測指標の作成を完了しておく。
// 変数定義は ../codebook/README.md を参照。データ整理コード・実データは同梱しない。


* 多重代入を行う
// df01mi.dta -> df02mi.dta
// df01mi_surgery.dta -> df02mi_surgery.dta
// df02mi.dta = 多重代入を実施済みのデータセット
// 引数1: 入力するデータセット
// 引数2: 出力するデータセット
do crDataICL02_mi df01mi.dta          df02mi.dta
do crDataICL02_mi df01mi_surgery.dta  df02mi_surgery.dta 
do crDataICL02_mi df01mi_lung.dta     df02mi_lung.dta 


* 傾向スコア算出を行う
// df02mi.dta -> df03mi.dta, test_df03.dta
// df02mi_surgery.dta -> df03mi_surgery.dta test_df03mi_surgery.dta
// df03mi.dta = 多重代入の各補完セットに傾向スコアを算出した。
// test_df03.dta = テスト用に補完セットを1つだけ抽出したもの
// 引数1: 入力するデータセット
// 引数2: 出力データセット
do crDataICL03_mi_ps df02mi.dta          df03mi.dta
do crDataICL03_mi_ps df02mi_surgery.dta  df03mi_surgery.dta
do crDataICL03_mi_ps df02mi_lung.dta     df03mi_lung.dta

********************************************************************************

* 傾向スコアの評価を行う（コモンサポート）
// コモンサポートのグラフを生成する。
// 引数1: 入力するデータセット
// 引数2: 出力グラフ画像ファイルの語幹
do anEvalPS02_overlap df03mi.dta          CommSup_
do anEvalPS02_overlap df03mi_surgery.dta  CommSup_surg
do anEvalPS02_overlap df03mi_lung.dta     CommSup_lung

* 傾向スコアの評価を行う（共変量バランス）
// 共変量バランスの表を、多重代入した補完セット分作る。
// SMD・分散比はStataのbal_sIPTW -> covbalで計算する。
// 22補完セットのExcel表を平均する既存Pythonは ../python/historical/ に保存。
// 引数1: 入力するデータセット
// 引数2: 出力Excelファイルのサブフォルダ名 ./excel/`2'/mimi_
do anEvalPS01_covbal df03mi.dta          all
do anEvalPS01_covbal df03mi_surgery.dta  surgery_only
do anEvalPS01_covbal df03mi_lung.dta     lung_only

* 記述統計量の算出（共変量バランス表に付ける）
// 引数1: 入力するデータセット
// 引数2: 出力するExcelファイルの語幹
do anDes01 df03mi.dta          des_tab_wt
do anDes01 df03mi_surgery.dta  des_tab_surgery_wt
do anDes01 df03mi_lung.dta     des_tab_lung_wt

********************************************************************************

* 生存時間分析
// 引数1=dtaファイル
// 引数2=アウトカム OS/PFS
// 引数3=曝露変数
// 引数4=重み
// 引数5=グラフ名に付け加える文字
do anSurv01mi df03mi          os  trt stbw stbw
do anSurv01mi df03mi_surgery  os  trt stbw surg_stbw
do anSurv01mi df03mi_lung     os  trt stbw lung_stbw

