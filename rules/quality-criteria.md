# Quality Evaluation Criteria (IMPORTANT)

IMPORTANT: コード変更の完了を宣言する前に、以下の基準を必ず自己評価すること。

| 基準 | チェック内容 |
|------|------------|
| Correctness | 要件通りに動作するか。スタブやモックで誤魔化していないか |
| Completeness | エッジケース（null, empty, boundaries, errors）を含めて全要件を満たすか |
| Code quality | 読みやすく保守しやすいか。プロジェクトの規約に従っているか |
| Safety | セキュリティ問題がないか。認証情報の漏洩がないか。適切なエラーハンドリングがあるか |
| Testing | 変更がテストされているか。既存テストが壊れていないか |
| Evidence | 実行した verifier / test / lint コマンドとその結果を示したか |

1つでも不合格の場合、「完了」と報告してはならない。具体的な不合格理由を示して修正すること。
