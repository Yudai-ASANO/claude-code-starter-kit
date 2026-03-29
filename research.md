# Research: Claude Code から Gemini CLI への調査タスク委譲

## Date: 2026-03-29

## Scope

Claude Code の出力精度を高めるために、Web 検索や大規模コード調査などの調査タスクを Gemini CLI に委譲する方法を調査する。

## 統合方式の比較

| 方式 | 複雑度 | メリット | デメリット |
|------|--------|----------|-----------|
| **A. Bash サブエージェント** (`gemini -p "..."`) | 最低 | セットアップ不要、既存 Codex パターン踏襲 | ステートレス、MCP ツール発見なし |
| **B. MCP サーバー** (`gemini-mcp-tool` 等) | 低〜中 | 構造化ツール I/F、ツール発見対応 | 追加依存、メンテ必要 |
| **C. カスタム MCP サーバー** | 高 | 完全制御、自動相談、履歴管理 | 自前メンテ |

## 方式 A: Bash サブエージェント（推奨）

### 概要

既存の Codex CLI 委譲パターンをそのまま Gemini CLI に適用する。最もシンプルで、starter-kit のアーキテクチャと整合性が高い。

### Gemini CLI の基本情報

- **リポジトリ**: https://github.com/google-gemini/gemini-cli (99.4k stars)
- **インストール**: `npm install -g @google/gemini-cli` / `brew install gemini-cli`
- **無料枠**: 60 req/min, 1,000 req/day（Google アカウント認証）
- **モデル**: Gemini 3（1M トークンコンテキスト）
- **組込ツール**: `google_web_search`, `web_fetch`, `read_file`, `write_file`, `run_shell_command`
- **Google 検索グラウンディング**: デフォルト有効。ハルシネーション約40%削減

### 非対話モード（委譲に必須）

```bash
# 基本（stdout にテキスト出力）
gemini -p "プロンプト"

# JSON 出力（プログラマティック解析用）
gemini -p "プロンプト" --output-format json | jq '.response'

# stdin パイプ
cat error.log | gemini -p "このエラーの原因は？"
git diff | gemini -p "変更内容を要約して"

# ファイル参照（@ 構文）
gemini -p "このファイルをレビューして @src/auth.ts"

# サンドボックス実行
gemini --sandbox -p "このコードベースのセキュリティ問題を分析して"
```

**JSON 出力構造**: `response`（回答）, `stats`（トークン使用量）, `error`（エラー）

**注意**: Issue #4665 — 非対話モードで非 LLM 出力が stdout に混入する問題が報告されている。`--output-format json` 使用時は `2>/dev/null` でフィルタが必要な場合あり。

### Codex CLI との対応表

| 目的 | Codex CLI | Gemini CLI |
|------|-----------|------------|
| 読み取り分析 | `codex exec --full-auto --sandbox read-only "prompt"` | `gemini --sandbox -p "prompt" --output-format json` |
| コードレビュー | `codex exec --full-auto -p review "prompt"` | `gemini --sandbox -p "Review: prompt" --output-format json` |
| デバッグ | `codex exec --full-auto -p debug "prompt"` | `gemini -p "Debug: prompt" --output-format json` |
| Web 検索調査 | ❌ 非対応 | `gemini -p "調査: prompt" --output-format json` |
| 大規模コード調査 | `codex exec --full-auto "prompt"` | `gemini -p "prompt @file1 @file2" --output-format json` |

### Claude Code からの呼び出しパターン

```
ユーザー → Claude Code（司令塔・設計・統合）
  ↓
  Bash(gemini --sandbox -p "..." --output-format json) → Gemini CLI（調査・検索）
  ↓
  Claude Code（検証・統合・回答）
```

**委譲指示テンプレート**:
```bash
# Web 検索調査
gemini --sandbox -p "TASK: 以下について最新情報を調査してください。
QUERY: <検索クエリ>
OUTPUT: 調査結果を構造化して、ソースURL付きで返してください。
FORMAT: Markdown" --output-format json 2>/dev/null | jq -r '.response'

# コードベース調査
gemini --sandbox -p "TASK: 以下のコードベースを分析してください。
CONTEXT: $(pwd) のリポジトリ
FOCUS: <調査対象>
OUTPUT: 発見事項を箇条書きで返してください。" --output-format json 2>/dev/null | jq -r '.response'
```

## 方式 A の実装方法（starter-kit feature として）

### ディレクトリ構造

```
features/gemini-cli/
  ├── feature.json           # メタデータ
  ├── hooks.json             # パーミッション + フック定義
  ├── CLAUDE.md.partial.en   # 英語ドキュメント
  └── CLAUDE.md.partial.ja   # 日本語ドキュメント
```

### feature.json

```json
{
  "name": "gemini-cli",
  "displayName": "Gemini CLI Integration",
  "description": "Delegate research and web search tasks to Google Gemini CLI",
  "category": "integration",
  "default": false,
  "dependencies": [],
  "conflicts": []
}
```

### hooks.json（パーミッション）

```json
{
  "permissions": {
    "allow": [
      "Bash(gemini --sandbox -p *)",
      "Bash(gemini -p *)",
      "Bash(gemini --sandbox -p * --output-format json *)",
      "Bash(gemini -p * --output-format json *)"
    ]
  }
}
```

### CLAUDE.md.partial に記載する委譲ルール

```markdown
## Gemini CLI サブエージェント運用

### アーキテクチャ
Claude Code（司令塔） → Bash(gemini ...) → Gemini CLI（調査実行） → Claude Code（検証・統合）

### 委譲の判断基準

#### Gemini CLI に委譲する条件（以下のいずれかを満たす場合）
- Web 検索が必要な調査タスク（最新情報、ライブラリ比較、ベストプラクティス）
- 大規模コードベースの網羅的な分析（1M トークンコンテキスト活用）
- ハルシネーション防止が重要な事実確認（Google 検索グラウンディング）
- 外部ドキュメントの要約・分析

#### Claude が直接実行する条件
- コード生成・編集（Claude の方が精度が高い）
- git 操作、設定ファイル編集
- ユーザーとの対話・質疑応答
- テスト駆動開発（TDD）ワークフロー

### コマンドパターン

| 目的 | コマンド |
|------|---------|
| Web 検索調査 | `gemini --sandbox -p "調査: <query>" --output-format json` |
| コード分析 | `gemini --sandbox -p "分析: <prompt> @<file>" --output-format json` |
| 事実確認 | `gemini --sandbox -p "確認: <claim>" --output-format json` |
| ドキュメント要約 | `gemini --sandbox -p "要約: <topic>" --output-format json` |

### 委譲ルール
1. 指示文は自己完結的に構成する（Gemini はステートレス）
2. Claude は Gemini の出力をそのまま返さない（必ず検証・統合）
3. JSON 出力を使用し、構造化されたデータとして受け取る
4. サンドボックスモードをデフォルトで使用する
```

## 方式 B: MCP サーバー（代替案）

### 利用可能な既存 MCP サーバー

| 名前 | ソース | セットアップ | 特徴 |
|------|--------|-------------|------|
| `gemini-mcp-tool` | PyPI/npm | `claude mcp add gemini-cli -- npx -y gemini-mcp-tool` | ask-gemini, sandbox, ping |
| `claude-gemini-mcp-slim` | GitHub | Python venv + pip install | スマートモデル選択、1M コンテキスト |
| `mcp-server-gemini` | npm | npm install | テキスト生成、画像分析、トークンカウント |
| `gemini-search-mcp` | PyPI | pip install | 検索特化 |

### MCP 方式のメリット・デメリット

**メリット**:
- 構造化されたツールインターフェース（型安全）
- Claude Code のツール発見機能と統合
- 呼び出しが `mcp__gemini__ask_gemini("query")` のように明示的

**デメリット**:
- 追加の依存関係（npm/pip パッケージ）
- MCP サーバーのメンテナンスが必要
- サーバープロセスのライフサイクル管理
- Bash 方式より複雑

## Gemini CLI の利点（Claude の弱点を補完）

| 能力 | Claude Code | Gemini CLI |
|------|-------------|------------|
| Web 検索 | WebSearch ツール（制限あり） | Google 検索グラウンディング（組込） |
| コンテキスト窓 | 200K（Opus） | 1M トークン |
| グラウンディング | なし | Google 検索による事実確認 |
| 無料枠 | なし（API 課金） | 1,000 req/day |
| コード生成品質 | 高い | 中〜高 |
| ツール使用 | 高度（MCP, hooks） | 基本的（組込ツール） |

**相互補完の構図**: Claude Code がコード生成・編集・統合に集中し、Gemini CLI が Web 検索・大規模調査・事実確認を担当する。

## 制約・リスク

1. **レート制限**: 無料枠 60 req/min, 1,000 req/day（ヘビーユースでは API キー必要）
2. **Node.js 20+ 依存**: Gemini CLI の実行に Node.js 20 以上が必要
3. **stdout 汚染**: Issue #4665 — 非対話モードで非 LLM 出力が混入する場合あり
4. **認証管理**: Google アカウント認証のセットアップが必要（初回のみ）
5. **セキュリティ**: API キーを Bash コマンドに含めない（`GEMINI_API_KEY` 環境変数使用）
6. **ステートレス**: 各呼び出しは独立。コンテキストの引き継ぎは手動

## 計画フェーズへの推奨事項

### 推奨実装アプローチ

**方式 A（Bash サブエージェント）を推奨**。理由:
1. 既存の Codex CLI パターンと完全に整合
2. 追加依存なし（gemini-cli のみ）
3. starter-kit の feature システムにそのまま載る
4. シンプルで保守性が高い

### 実装ステップ（概要）

1. `features/gemini-cli/` ディレクトリ作成
2. `feature.json`, `hooks.json`, `CLAUDE.md.partial.{en,ja}` 作成
3. `lib/features.sh` に feature 登録
4. `wizard/wizard.sh` に `ENABLE_GEMINI_CLI` 追加
5. i18n 文字列追加（`i18n/{en,ja}/strings.sh`）
6. オプション: `lib/gemini-setup.sh` で認証チェック
7. テスト: fresh install / update / saved config の 3 パス検証

### Codex CLI との同時有効化

Codex CLI と Gemini CLI は競合しない（目的が異なる）:
- **Codex CLI**: コード生成・レビュー・デバッグ（実装系）
- **Gemini CLI**: Web 検索・調査・事実確認（調査系）

両方有効化時の委譲優先度ルールを CLAUDE.md.partial に明記する。

### 追加検討事項

- `--output-format json` のパース失敗時のフォールバック
- dry-run モードでの Gemini CLI 存在チェック
- `--yolo` フラグは非推奨（`--approval-mode=yolo` を使用）

## 参考リンク

- [Gemini CLI GitHub](https://github.com/google-gemini/gemini-cli)
- [Gemini CLI 公式サイト](https://geminicli.com/)
- [Headless モードリファレンス](https://geminicli.com/docs/cli/headless/)
- [Automation チュートリアル](https://geminicli.com/docs/cli/tutorials/automation/)
- [CLI リファレンス](https://geminicli.com/docs/cli/cli-reference/)
- [Google 検索グラウンディング](https://ai.google.dev/gemini-api/docs/google-search)
- [Gemini CLI as Subagent for Claude Code](https://aicodingtools.blog/en/claude-code/gemini-cli-as-subagent-of-claude-code)
- [egghead チュートリアル](https://egghead.io/create-a-gemini-cli-powered-subagent-in-claude-code~adkge)
- [Awesome Claude Code Subagents](https://github.com/VoltAgent/awesome-claude-code-subagents)
- [gemini-mcp-tool (PyPI)](https://pypi.org/project/gemini-cli-mcp-tool/)
- [claude-gemini-mcp-slim](https://github.com/cmdaltctr/claude-gemini-mcp-slim)
