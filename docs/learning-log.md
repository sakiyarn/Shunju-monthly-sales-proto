# 学習ログ（Master移植）

参照: `docs/dashboard-linkage-scope.md`（Master実装済み / Dashboard連動のみ）

## 使い方
- 1セクションごとに「開始時」と「終了時」を1回ずつ記録
- 1回5分タスクで進め、詰まった点は短く残す
- スコープ外の発見は「影響メモ」に書き、実装しない

---

## セクション開始テンプレ（コピペ）
### 基本情報
- 日付:
- 対象セクション: Sx
- ブランチ:
- 目的（1行）:

### In Scope
- 

### Out of Scope
- 

### 影響調査のみ
- 

### 今日の最初の1手
- 

---

## セクション終了テンプレ（コピペ）
### できるようになったこと
- 

### つまずいたこと
- 

### 解決できたこと
- 

### 次回の自分へのメモ
- 

### 変更ファイル（最終）
- 

### 受け入れ確認
- [ ] 主要操作が意図どおり動作
- [ ] Out of Scope変更なし
- [ ] lint/testの結果を確認
- [ ] PR本文に手動確認を書いた

---

## 実績ログ

### S2（Dashboard案件連動）
#### 開始
- 日付: 2026-03-09
- 対象セクション: S2
- ブランチ: codex/master-s2-dashboard-project-sync
- 目的: Dashboard案件一覧を固定配列からMaster実データ連動へ変更

#### 終了
- できるようになったこと:
  - Controller -> props -> defineProps の流れを実装で確認できた
  - GitHub PR作成とCI修正の流れを実施できた
- つまずいたこと:
  - defineProps / Record / Array の意味
  - Vueのコメント記法の違い
- 解決できたこと:
  - props.projects.map(...) への置換
  - RuboCopエラーの行番号特定（--format emacs）
- 次回メモ:
  - routes -> controller -> defineProps の順で読む
  - スコープ外変更はコミットに入れない

### S1(Dashboard案件連動)
#### 開始
- 日付: 2026-03-010
- 対象セクション: S1
- ブランチ: codex/master-s1-users-crud
- 目的: Dashboardにスタッフが連動するように実装
- display_orderガードは既存実装でOKだった

