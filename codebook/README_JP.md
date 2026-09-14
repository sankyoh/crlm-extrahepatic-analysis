# 公開用コードブック

[English](README.md) | 日本語

作成日: 2026-09-08。患者単位のデータは含みません。

## 収載範囲

元Excelの全124列と、解析系のStataデータ9本に存在する43種類の変数を、データセット本体から読み取って作成しました。変数・値ラベルは保存されたメタデータから抽出し、変数の作成・変換・欠測処理は原プロジェクトのStataコードと照合しています。実測値の一覧、例示レコード、ID値、日付、自由記載内容、最小最大値、欠測数・カテゴリ頻度は収載していません。

データセット整理・クリーニングのコードは公開範囲から除外しています。この辞書に現れる `crDataICL01*.do` や `map2cat` は定義の根拠とした原プロジェクトの処理を指し、公開フォルダに同梱されているという意味ではありません。標準のStata実行手順には、符号化・集団選択・補完前欠測指標の作成が済んだ `df01mi*.dta` の3集団分が必要です。

| ファイル | 内容 |
| --- | --- |
| [analysis_variables.csv](analysis_variables.csv) | 43種類の解析変数。日本語定義、単位、元列、符号化、欠測処理、所在データ |
| [stata_dataset_schema.csv](stata_dataset_schema.csv) | Stata 9本の各列の順序・保存型・表示形式・保存ラベル。合計321行のメタデータ |

公開するCSVは上記2本で、UTF-8（BOM付き）です。1行は解析変数またはデータセットの列の説明であり、患者のレコードではありません。

変数の定義・符号化・欠測処理は `analysis_variables.csv`、解析の各段階におけるデータセットの構造は `stata_dataset_schema.csv` を参照してください。以下の元Excel列一覧は変数の由来を説明する参考資料であり、元Excelの読込み・クリーニングは公開する実行手順に含まれません。

## 元資料と版の確認

- 原プロジェクトの `stata/` にあった元Excelの第1シートを列定義の基準としています。見出し空欄のAL列も保持しています。元Excelを読み込むコードは公開対象外です。
- プロジェクト直下の同名Excelには追加の列一覧シートがあり、ファイル全体は異なります。両方の第1シートは、読み取った全セル値が一致することを確認しました。書式・数式文字列・Excel内部メタデータの同一性を示すものではありません。
- `df01mi*.dta` は補完準備後、`df02mi*.dta` は22セットの多重代入後、`df03mi*.dta` はPSと重みの作成後です。各段階で全体、`_surgery`、`_lung` の3本を対象にしました。
- R用に保存された `df03mi_surgery.dta` は、Stataフォルダの同名データとバイト単位で一致しました。コードブックは共通です。
- 試験用・MNAR・surgery+lungの未完了データ、解析結果Excel、ログ、RDSはこのコードブックの別データセットとして収載していません。

## 読み方と注意点

`_mi_m=0` は未補完データ、`1`〜`22` は補完番号です。複数補完分の行を独立した患者として数えません。`_mi_id` は補完間対応を管理する内部ID、`id` は元データの識別用項目「全体通し番号」です。いずれも値・対応表は非公開です。

6つの補完対象（grade、primary_n、tumor_count_cat、tumor_size_cat、cea_cat、ca199_cat）には、保存された値ラベル内に旧 `missing` コードが残っています。これらは補完準備時点で Stata の `.` に戻されています。ラベルが存在することと、そのコードがデータに現れることは別です。`ras_mut=2` の Unknown はカテゴリとして残っています。

`*_mind` は補完前のシステム欠損 `.` を `== .` で検出する指標です。拡張欠損 `.a`〜`.z` はこの条件に含まれません。手術あり集団は原発巣手術日が空欄・非切除・`-` ではない記録、肺群は `ehd2=0` の記録から作成されます。肺群は多臓器転移を含む「肺転移のある全例」と同義ではありません。

`event_os` は元見出しとコードコメントで 0=生存／打切り、1=死亡と確認しました。元Stataコードは `evnet_os` と `event_os` に綴りの不一致があり、読み取ったデータには利用可能な値ラベル定義がありません。コードブックには定義根拠を明記しました。`ras_mut` の保存変数ラベルはK-Rasですが、元列はRAS/RAF変異を含むため、ラベルをそのまま医学的定義とみなしません。

単位・起算日・分類の臨床的な詳細が元データとコードから確定しない項目は「未定義」としています。実測値から意味や許容範囲を推測していません。未使用の元Excel列は見出し情報のみの定義が多く、独立した収集マニュアルに代わるものではありません。

Rの現行RMST解析は `_mi_m=1` を使用し、原データで3項目が観測された集団へ制限します。R側でPSと重みを再計算するため、ここに記載した保存Stata重みそのものを単純に使用する解析ではありません。詳細は [Rの解説](../r/README_JP.md) を参照してください。

## 解析変数一覧

| 変数 | 定義 | 符号化 |
| --- | --- | --- |
| id | 元データの識別用項目「全体通し番号」。値・対応表は非公開。 |  |
| sex | 性別。元Excel見出しにより 0=女性、1=男性。 | 0=女性; 1=男性 |
| age | 元データに記録された年齢。基準日時の詳細はコードから確定できない。 |  |
| age_cat | 年齢の2区分。元Excelカテゴリを符号化。 | 0=69歳以下; 1=70歳以上 |
| side | 原発巣の左右区分。 | 0=Left; 1=Right |
| grade | 原発巣の分化度。 | 0=Well; 1=Moderate; 2=poor/mucinous; 3=missing |
| primary_n | 原発巣リンパ節転移区分。 | 0=N-; 1=N+; 2=missing |
| ehd3 | 傾向スコアに用いる肝外転移部位の3区分。 | 0=M1 (Lung/LN/others); 1=M1 (Peri); 2=multiple |
| trt | 治療群。0=C群（肝・肝外とも非切除）、1=B群（肝切除・肝外非切除）。それ以外はmap2catで欠損、MI前に除外。 | 0=Group C; 1=Group B |
| ras_mut | 元ExcelのRAS/RAF変異区分。保存ラベルはK-Rasだが入力はRAS/RAFを含む。 | 0=野生型; 1=RAS/RAF変異; 2=Unknown |
| recu_6m | 肝転移の同時性・異時性。元見出しでは6か月以内の再発を同時性とする。 | 0=Synchronous; 1=Metachronous |
| tumor_count | 摘出個数も踏まえて調整された肝腫瘍個数。 |  |
| tumor_count_cat | 肝腫瘍個数のカテゴリ。元Excelの見出し空欄AL列を使用。 | 0=1; 1=2-4; 2=5以上; 3=missing |
| max_tumor | 最大肝腫瘍径。文字列「不明」を空欄に変換後、数値化。 |  |
| max_tumor_seq | 元Excelで「最大腫瘍径（数列）」と命名された数値列。max_tumorとの具体的な相違は未定義。 |  |
| tumor_size_cat | 最大肝腫瘍径のカテゴリ。元カテゴリを符号化し、連続値からの再計算はしていない。 | 0=≤ 5cm; 1=> 5cm; 2=missing |
| cea | 肝転移診断時CEA。 |  |
| cea_cat | 肝転移診断時CEAのカテゴリ。閾値10。 | 0=10未満; 1=10以上; 2=missing |
| ca199 | 肝転移診断時CA19-9。 |  |
| ca199_cat | 肝転移診断時CA19-9のカテゴリ。閾値37 U/mL。 | 0=≤37; 1=>37; 2=missing |
| event_os | 全生存のイベント指標。0=生存／打切り、1=死亡。 | 0=生存／打切り; 1=死亡 |
| time_os_d | 記録済み生存期間（日）。crDataICL02_miでNelson–Aalen計算に使用。起算日の詳細は入力データ定義で確認が必要。 |  |
| time_os_m | 記録済み生存期間（月）。Stata生存解析とRのRMSTで使用。日数から月数への変換は公開コード内では行わない。 |  |
| grade_mind | 多重代入前のgrade欠測指標。元カテゴリの欠測コードを . に戻した後、grade==. で生成。1=システム欠損 .、0=それ以外。拡張欠損 .a〜.z はこの条件に含まない。補完後も保持。 | 0=not system-missing dot; 1=system-missing dot before MI |
| primary_n_mind | 多重代入前のprimary_n欠測指標。元カテゴリの欠測コードを . に戻した後、primary_n==. で生成。1=システム欠損 .、0=それ以外。拡張欠損 .a〜.z はこの条件に含まない。補完後も保持。 | 0=not system-missing dot; 1=system-missing dot before MI |
| tumor_count_cat_mind | 多重代入前のtumor_count_cat欠測指標。元カテゴリの欠測コードを . に戻した後、tumor_count_cat==. で生成。1=システム欠損 .、0=それ以外。拡張欠損 .a〜.z はこの条件に含まない。補完後も保持。 | 0=not system-missing dot; 1=system-missing dot before MI |
| tumor_size_cat_mind | 多重代入前のtumor_size_cat欠測指標。元カテゴリの欠測コードを . に戻した後、tumor_size_cat==. で生成。1=システム欠損 .、0=それ以外。拡張欠損 .a〜.z はこの条件に含まない。補完後も保持。 | 0=not system-missing dot; 1=system-missing dot before MI |
| cea_cat_mind | 多重代入前のcea_cat欠測指標。元カテゴリの欠測コードを . に戻した後、cea_cat==. で生成。1=システム欠損 .、0=それ以外。拡張欠損 .a〜.z はこの条件に含まない。補完後も保持。 | 0=not system-missing dot; 1=system-missing dot before MI |
| ca199_cat_mind | 多重代入前のca199_cat欠測指標。元カテゴリの欠測コードを . に戻した後、ca199_cat==. で生成。1=システム欠損 .、0=それ以外。拡張欠損 .a〜.z はこの条件に含まない。補完後も保持。 | 0=not system-missing dot; 1=system-missing dot before MI |
| opeday | 原発巣手術日の文字列。手術あり集団の選択に使用。実日付は非公開。 |  |
| ehd2 | 肝外転移部位の4区分。肺群は ehd2==0 のみ。 | 0=M1 (Lung); 1=M1 (Peri); 2=M1 (LN/others); 3=multiple |
| na_os | time_os_dとevent_osから作成したNelson–Aalen累積ハザード。多重代入モデルに使用。 |  |
| _mi_id | Stataが作成した補完間の観測対応ID。元idとは別。値は非公開。 |  |
| _mi_miss | Stata MIの内部管理用欠測指標。通常は解析共変量として使用しない。 |  |
| _mi_m | Stata flongの補完番号。0=未補完、1〜22=各補完セット。行を独立した患者数として数えない。 | 0=original; 1..22=imputation index |
| ps | 各補完セットで通常のlogistic回帰により推定したP(trt=1)。共変量と6欠測指標を使用。 |  |
| mp | 共変量なしのlogistic trtから得た周辺治療確率。保存されたStata重みの安定化分子。 |  |
| stbw | 安定化IPTW。trt=1ではmp/ps、trt=0では(1-mp)/(1-ps)。 |  |
| ovwt | Overlap weight。trt=1では1-ps、trt=0ではps。現行masterの生存解析はstbwを指定。 |  |
| sum_ow | 各補完セット・治療群内でのovwtの合計。 |  |
| w_now | 群内の合計を1にしたoverlap weight。ovwt/sum_ow。 |  |
| n_g | 各補完セット・治療群の行数。 |  |
| w_sow_g | 群内の合計をn_gにしたoverlap weight。ovwt*n_g/sum_ow。 |  |

## 元Excelの列一覧

| 列 | 元見出し | 解析変数 |
| --- | --- | --- |
| A | 全体通し番号 | id |
| B | 肝転移切除/ 非切除 |  |
| C | 肝転移の切除分類 |  |
| D | 性別男：1 or 女：0 | sex |
| E | 年齢 | age |
| F | 年齢 2 | age_cat |
| G | 原発巣手術日 | opeday |
| H | 原発巣　 整理 |  |
| I | Sidedness | side |
| J | 壁深逹度 |  |
| K | 原発巣術式　　 　（自由記載） |  |
| L | 分化度 2 | grade |
| M | Primary N+ | primary_n |
| N | 病理v  (v0-3) |  |
| O | 病理ly  (ly0-3) |  |
| P | 切除断端浸潤　 　SM+：1 |  |
| Q | 遠隔転移　 肝, 肺, 卵巣, 腹膜, etc |  |
| R | 肝転移時の 遠隔転移臓器数 |  |
| S | EHD (single/multiple) |  |
| T | EHD分類１ |  |
| U | EHD分類2 | ehd2 |
| V | EHD分類3 | ehd3 |
| W | 肝外病変の治療 |  |
| X | 肝外病変の治療 2 |  |
| Y | 治療の組み合わせ | trt |
| Z | 肺, 卵巣, 腹膜, etc |  |
| AA | 肝転移時の肝外病変 |  |
| AB | 肝外病変の治療 （自由記載） |  |
| AC | 原発巣特記事項　 （自由記載） |  |
| AD | MSI |  |
| AE | RAS/RAF変異 | ras_mut |
| AF | 同時性:0 or 異時性:1 |  |
| AG | 6ヶ月以内の再発は 同時性0, 異時性1 | recu_6m |
| AH | 原発巣と肝転移の同時切除（1: あり） |  |
| AI | 単発0 or 多発1 |  |
| AJ | 腫瘍個数（画像） |  |
| AK | 腫瘍個数（摘出個数も踏まえ調整） | tumor_count |
| AL |  | tumor_count_cat |
| AM | Tumor burden score |  |
| AN | Tumor burden score grade |  |
| AO | 両葉病変：１ （多発の場合） |  |
| AP | 最大腫瘍径　 (cm) | max_tumor |
| AQ | 最大腫瘍径　 (数列 ) | max_tumor_seq |
| AR | Chemo前の最大腫瘍径 (Staging用） |  |
| AS | 前-後 |  |
| AT | 腫瘍径 分類 | tumor_size_cat |
| AU | 旧H分類 |  |
| AV | novel H分類 |  |
| AW | Grade分類 |  |
| AX | 肝転移診断時CEA | cea |
| AY | 肝転移診断時CEA分類 | cea_cat |
| AZ | 肝転移診断時のCA19-9 (U/mL) | ca199 |
| BA | 肝転移診断時CA19-9 分類 | ca199_cat |
| BB | BC risk score |  |
| BC | 術前化学療法　あり：１ |  |
| BD | NAC or Conversion |  |
| BE | 術前化学療法の理由 |  |
| BF | 術前化学療法の理由 2 |  |
| BG | 術前化学療法Regimen |  |
| BH | 術前化学療法　(Kur or 期間） |  |
| BI | 分子標的薬 |  |
| BJ | 分子標的　分類 |  |
| BK | 術前化学療法Regimen 2 |  |
| BL | 術前化学療法　(Kur or 期間） 2 |  |
| BM | 分子標的薬 2 |  |
| BN | BMI |  |
| BO | 身長(cm) |  |
| BP | 体重（kg） |  |
| BQ | DM |  |
| BR | T.Bil (mg/dl) |  |
| BS | PT (%) |  |
| BT | Alb (g/dl) |  |
| BU | ICG-R15 (%) |  |
| BV | 肝手術日 |  |
| BW | 肝切除術式                  Hr0, S, 1, 2, 3 |  |
| BX | 切除領域　　　　　　（自由記載） |  |
| BY | 複合術式　　　　　　（自由記載） |  |
| BZ | Major Hx Hr2以上 |  |
| CA | Anatomical resection |  |
| CB | PSH vs Major Hx |  |
| CC | 開腹: 0 or 腹腔鏡: 1 |  |
| CD | RFA併用：１ |  |
| CE | 手術情報補足コメント　　（自由記載） |  |
| CF | 手術時間（分） |  |
| CG | 出血量(ml) |  |
| CH | 輸血の有無 |  |
| CI | 摘出病変個数 |  |
| CJ | 根治度 |  |
| CK | 根治度 2 |  |
| CL | 根治度 3 |  |
| CM | 術後合併症　　　　　　　　（CD分類） |  |
| CN | 術後合併症分類 |  |
| CO | 合併症の種類 1 |  |
| CP | 合併症の種類 2 |  |
| CQ | 合併症の種類 3 |  |
| CR | 術後補助療法　　あり：１ |  |
| CS | 補助療法　　Regimen |  |
| CT | 術後補助療法　(Kur or 期間） |  |
| CU | 分子標的薬 4 |  |
| CV | 補足事項　　　　　　　　　　　　　　　（自由記載、Regimen変更など） 2 |  |
| CW | 再発確認日 |  |
| CX | 再発確認日（数列） |  |
| CY | 最終予後確認日 |  |
| CZ | 最終予後確認日（数列） |  |
| DA | 再発あり：１ |  |
| DB | 再発解析の除外 |  |
| DC | 肝外再発あり |  |
| DD | 再発迄 日数 |  |
| DE | DFS日数 |  |
| DF | Disease free survival |  |
| DG | 再発分類 |  |
| DH | 再発治療分類 |  |
| DI | 再発部位１ |  |
| DJ | 再発治療１ |  |
| DK | 再発部位2 |  |
| DL | 再発治療2 |  |
| DM | 再発部位　　　（自由記載） |  |
| DN | 再発治療　　　（自由記載） |  |
| DO | 最終予後確認日 2 |  |
| DP | 生存：0 死亡：１ | event_os |
| DQ | 生存日数 | time_os_d |
| DR | 生存月数 | time_os_m |
| DS | 再発後生存日数 |  |
| DT | 死亡原因（自由記載） |  |
