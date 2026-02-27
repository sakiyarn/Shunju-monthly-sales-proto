# S8影響メモ（役員原価のS7同型移行）

## 対象
- セクション8（役員原価）をS7同型UI（暦年/決算年度12か月表示、キーボード操作、未保存可視化）へ移行。
- 保存先は `staff_monthly_results` を継続利用し、`user_id + work_month` 単位で一括保存する。

## 判定
- S8の対象ユーザーは `roles.name = "代表"` かつ `users.is_active = true`。
- `system_role` は判定条件に使わない。
- 入力刻みはS7と同じ。
  - 役員報酬: 1000円単位
  - 法定福利費: 1000円単位
  - 福利厚生費: 10円単位
  - 役員賞与: 1000円単位

## S6連動時の注意点
- S8の社内原価(h)は `s6BusinessDaysForMonth` を参照して計算する。
- S6に営業日数が保存されていない月は既存仕様どおり `1` 日として計算される。
- そのため、S8表示中の月にS6未保存月が含まれる場合、社内原価(h)は暫定値になる。

## executive_adjustments との関係
- `executive_adjustments` との同期は今回実施しない。
- 現時点では `staff_monthly_results`（個票）と `executive_adjustments`（集計）が独立して存在する。
- 将来的に `executive_adjustments` を個票から再計算する方式へ統一する余地がある。

## 今回の実装スコープ外
- S9/S10保存API化。
- S7/S8共通コンポーネント化。
- `Index.vue` 肥大化の解消リファクタ。
