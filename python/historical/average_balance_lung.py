"""Historical notebook code exported without outputs or metadata.

The original numerical selections and averaging behavior are preserved.
See README.md for provenance, row-range limitations, and private-output handling.
"""

import argparse
import pandas as pd
import numpy as np
from pathlib import Path

# ====== 設定ここから ======
# Excelファイルを置いているフォルダ
# FOLDER is supplied by the required private_folder command-line argument.

# ファイル名のパターン mimi_stbw_1_smdvr.xlsx ～ mimi_stbw_22_smdvr.xlsx
FILE_PREFIX = "mimi_stbw_"
FILE_SUFFIX = "_smdvr.xlsx"
FIRST_IDX = 1
LAST_IDX = 22

SHEET_NAME = "SMD_VR"   # シート名
# F3:G23 → 行3～23、列F～G
# pandasのilocは0始まりなので、行2～22、列5～6になる
ROW_START = 2   # 0ベースで2 → Excelの3行目
ROW_END = 22    # スライスは終端を含まないので 23 → 3〜23行目
COL_START = 5   # 0ベースで5 → F列
COL_END = 7     # スライスは終端を含まないので 7 → F〜G列

# 結果を書き出すファイル名
# OUTPUT_FILE is assigned inside main() in the supplied private folder.
# ====== 設定ここまで ======

def main(private_folder):
    FOLDER = private_folder
    OUTPUT_FILE = FOLDER / "mean_F3_G23.xlsx"
    arrays = []

    for i in range(FIRST_IDX, LAST_IDX + 1):
        file_path = FOLDER / f"{FILE_PREFIX}{i}{FILE_SUFFIX}"
        if not file_path.exists():
            print(f"※ ファイルがありません: {file_path}")
            continue

        print(f"読み込み中: {file_path}")
        # シート全体を読み込んでから F3:G23 に相当する部分だけ切り出し
        df = pd.read_excel(file_path, sheet_name=SHEET_NAME, header=None)

        # F3:G23 → ilocで行2〜22、列5〜6
        sub = df.iloc[ROW_START:ROW_END, COL_START:COL_END]

        # 数値に変換（文字列が混じってたら NaN にする）
        sub_numeric = sub.apply(pd.to_numeric, errors="coerce")

        arrays.append(sub_numeric.to_numpy(dtype=float))

    if len(arrays) == 0:
        print("有効なファイルが1つもありませんでした。")
        return

    # 形状：(ファイル数, 行数, 列数) の3次元配列にスタック
    stack = np.stack(arrays, axis=0)

    # ファイル方向（axis=0）に平均をとる（NaNは無視）
    mean_array = np.nanmean(stack, axis=0)

    # DataFrame に戻す（行数21, 列2）
    mean_df = pd.DataFrame(mean_array)

    # 結果をExcelへ書き出し（A1:B21に対応）
    mean_df.to_excel(OUTPUT_FILE, index=False, header=False)

    print("完了しました。出力ファイル:")
    print(OUTPUT_FILE)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Historical cell-wise mean of balance exports; see README.md for limitations."
    )
    parser.add_argument(
        "private_folder",
        type=Path,
        help="Private folder containing the 22 balance Excel files; output is written here.",
    )
    args = parser.parse_args()
    main(args.private_folder)
