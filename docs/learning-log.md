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

### S1（Dashboardメンバーフィルタ連動）
#### 開始
- 日付: 2026-03-12
- 対象セクション: S1
- ブランチ: codex/dashboard-s1-users-linkage
- 目的: Dashboardの固定members配列をS1 usersデータ連動へ置換

#### 終了
- できるようになったこと:
  - PagesControllerでusersをpropsとして渡し、DashboardでdefinePropsで受け取る流れを実装できた
  - members / executives / allPeople の役割を理解して、重複を避ける実装にできた
  - CIエラー時に原因特定し、amend後のforce-with-lease pushまで対応できた
- つまずいたこと:
  - filterをサーバー側/フロント側どちらで使うべきか
  - `=` と `===` の違い
  - GitHub上のコミット名修正がローカルのみで止まる点
- 解決できたこと:
  - users props追加（projectsと同じ方針で実装）
  - メンバーフィルタ件数11件、重複なし、ON/OFF正常を確認
  - `git push --force-with-lease` でPR履歴を正しく更新
- 次回メモ:
  - データ取得ルールはController、表示分類はVueで分担する
  - 学習メモはコード内コメントではなくlearning-logへ記録する

