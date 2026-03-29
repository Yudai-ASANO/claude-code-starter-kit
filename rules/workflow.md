# Auto-Orchestration Rules (IMPORTANT)

IMPORTANT: 以下の条件に該当するタスクを受けた場合、必ず `/orchestrate` コマンドのワークフローに従って自動的に実行すること。ユーザーが `/orchestrate` を明示的に呼ばなくても、条件に合致すれば自動で開始する。

| タスク種別 | ワークフロー |
|-----------|-------------|
| 機能実装・新機能追加 | `/orchestrate feature` |
| バグ修正 | `/orchestrate bugfix` |
| リファクタリング | `/orchestrate refactor` |
| セキュリティ修正 | `/orchestrate security` |

## 除外条件（直接実行してよい）

- 1ファイル・数行の修正
- 設定ファイル編集（JSON, YAML, TOML）
- ドキュメント・README の編集
- git 操作（コミット、ブランチ、マージ）
- 質問への回答・説明・調査
