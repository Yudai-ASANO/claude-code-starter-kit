[更新履歴 (CHANGELOG)](CHANGELOG.md)

# Claude Code Starter Kit

[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Platform: macOS/Linux/Windows](https://img.shields.io/badge/Platform-macOS%20%7C%20Linux%20%7C%20Windows-blue.svg)](#セットアップ)

Claude Code の開発環境を対話型ウィザードで一括構築するシェルベースのツールキット。エージェント、ルール、コマンド、スキル、フック、プラグインを `~/.claude/` にデプロイし、セキュリティ・品質・生産性のベースラインを整える。

### 動作要件

- **Bash 4+**（macOS デフォルトの `/bin/bash` は 3.2 だが、Bash 4+ がインストール済みなら自動検出して再実行）
- **git**, **jq**, **curl**（未インストールの場合はセットアップ時に自動インストールを試行）
- macOS / Linux / WSL / MSYS(Git Bash)

## 目次

- [セットアップ](#セットアップ)
- [Agents](#agents)
- [Commands](#commands)
- [Skills](#skills)
- [Features / Hooks](#features--hooks)
- [Plugins](#plugins)
- [Rules](#rules)
- [Memory](#memory)
- [カスタマイズ](#カスタマイズ)
- [ディレクトリ構成](#ディレクトリ構成)
- [開発者向け](#開発者向け)
- [ライセンス](#ライセンス)

---

## セットアップ

### 対話モード（デフォルト）

```bash
git clone https://github.com/cloudnative-co/claude-code-starter-kit.git
cd claude-code-starter-kit
./setup.sh
```

ウィザードが言語・エディタ・フック・プラグイン等を順番に質問し、選択に応じて `~/.claude/` にファイルをデプロイする。

### 非対話モード

```bash
# デフォルト設定で一括セットアップ
./setup.sh --non-interactive

# オプション指定
./setup.sh --non-interactive --language=ja --editor=vscode

# 保存済み設定ファイルの再利用
./setup.sh --non-interactive --config=./my-config.conf
```

### 更新

```bash
# 既存環境を最新キットに更新（3-way merge で設定を保持）
./setup.sh --update

# 更新内容の事前プレビュー（ファイル変更なし）
./setup.sh --update --dry-run
```

更新時は `~/.claude.backup.<timestamp>` に自動バックアップが作成される。設定の競合は対話的に確認され、`[RK]`（現在の設定を保持して記憶）/ `[RU]`（キットの設定を使用して記憶）で判定を記憶できる。

### アンインストール

```bash
./uninstall.sh
```

マニフェスト（`~/.claude/.starter-kit-manifest.json`）に記録されたファイルのみを削除。手動追加のファイルは保持される。

---

## Agents

特定の役割に特化した AI エージェント定義。Claude Code が必要に応じて自動的に使い分ける。

| エージェント | 役割 |
|---|---|
| **planner** | 複雑な機能・リファクタリングの実装計画を立案 |
| **architect** | システム設計・スケーラビリティ・技術的意思決定 |
| **tdd-guide** | テスト駆動開発（RED → GREEN → REFACTOR）の強制 |
| **code-reviewer** | コード品質・セキュリティ・保守性のレビュー |
| **security-reviewer** | セキュリティ脆弱性の検出と修復 |
| **build-error-resolver** | TypeScript / ビルドエラーの段階的修正 |
| **e2e-runner** | Playwright によるエンドツーエンドテスト |
| **refactor-cleaner** | デッドコードの検出・削除・統合 |
| **doc-updater** | ドキュメントとコードマップの更新 |
| **qa-reviewer** | スプリント契約基準に基づく実装の厳密評価 |

---

## Commands

Claude Code のチャットで `/コマンド名` と入力して使うスラッシュコマンド。

| コマンド | 説明 | ユースケース |
|---|---|---|
| `/plan` | 要件整理・リスク評価・段階的実装計画の立案 | 新機能実装、大規模なアーキテクチャ変更、複数ファイルに影響する作業の開始前 |
| `/tdd` | テスト先行 → 最小実装 → リファクタリングの TDD サイクル実行 | 新しい関数・コンポーネントの追加、重要なビジネスロジックの構築、バグ修正 |
| `/code-review` | セキュリティと品質の包括的レビュー | コミット前の品質確認、認証情報露出・入力検証漏れ等の脆弱性スキャン |
| `/build-fix` | ビルドエラーをグループ化して優先度順に段階修正 | `tsc` や bundler のビルドエラー発生時、型エラーの一括修正 |
| `/e2e` | Playwright による E2E テストの生成・実行 | ログイン・支払い等の重要ユーザーフロー検証、本番デプロイ前の統合テスト |
| `/verify` | ビルド・型チェック・リント・テスト・git status の包括検証 | PR 作成前・デプロイ前の最終チェック |
| `/checkpoint` | ワークフロー中の進捗ポイントを作成・検証 | 実装フェーズの区切りでの状態保存、不具合発生時のロールバック判定 |
| `/orchestrate` | 複数エージェントを連携させた順序付きワークフロー実行 | 大規模機能実装、セキュリティ監査を含む複合的な作業 |
| `/research` | 関連ファイルの徹底調査・依存関係マッピング・既存パターン認識 | 既存アーキテクチャの理解が必要な場合、複雑な機能実装前の事前調査 |
| `/refactor-clean` | デッドコード分析 → テスト検証 → 安全な削除 | 不要な関数・ファイル・依存関係の整理、コードベースのスリム化 |
| `/test-coverage` | カバレッジ分析と不足テストの生成（80%+ 目標） | カバレッジ不足箇所の特定、品質基準達成の確認 |
| `/eval` | 評価駆動開発：受け入れ基準の定義・実行・レポート生成 | 受け入れ基準が複雑な機能、リグレッション確認が重要な場合 |
| `/init-harness` | テックスタック検出 → プロジェクト固有の検証フック自動生成 | プロジェクト初期化時、ビルド・テスト・リントの自動検証を設定したい場合 |
| `/learn` | セッションから再利用可能なパターンを抽出・保存 | 非自明な問題解決方法やライブラリの癖を発見した際、将来のセッション高速化 |
| `/handover` | セッション状態を文書化して引き継ぎドキュメントを生成 | セッション切り替え時の進捗保存、別の開発者やセッションへの文脈引き継ぎ |
| `/update-docs` | package.json / .env.example からドキュメント自動同期 | 開発環境セットアップガイドやランブックの更新 |
| `/update-codemaps` | ソースコード構造を分析しアーキテクチャドキュメントを生成 | リポジトリ構造の可視化、新規メンバーへのオンボーディング |
| `/update-kit` | スターターキットを手動で最新版に更新 | 新機能やバグ修正の反映、自動更新が無効な環境での手動更新 |
| `/update-kit-dry-run` | `/update-kit` の変更内容をプレビュー（変更なし） | 大規模なキット更新前の影響範囲確認 |

---

## Skills

特定ドメインの知識・ベストプラクティスを提供するスキルモジュール。`~/.claude/skills/` にデプロイされる。

| スキル | 説明 |
|---|---|
| **coding-standards** | TypeScript / JavaScript / React / Node.js 向けコーディング規約とパターン |
| **backend-patterns** | Node.js / Express / Next.js API のバックエンドアーキテクチャパターン |
| **frontend-patterns** | React / Next.js の状態管理・パフォーマンス最適化・UI パターン |
| **security-review** | 認証・入力処理・シークレット管理・API エンドポイントのセキュリティチェックリスト |
| **tdd-workflow** | テスト駆動開発ワークフロー（80%+ カバレッジ強制） |
| **eval-harness** | Claude Code セッション向け評価フレームワーク（EDD 原則） |
| **verification-loop** | 包括的な検証システム |
| **strategic-compact** | 論理的な間隔での手動コンテキスト圧縮を提案 |
| **continuous-learning** | セッションから再利用可能パターンを自動抽出・保存 |
| **prompt-patterns** | Claude Code を効果的に使うプロンプトパターン集 |
| **clickhouse-io** | ClickHouse クエリ最適化・分析ワークロード向けパターン |
| **project-guidelines-example** | プロジェクト固有スキルのテンプレート |

---

## Features / Hooks

自動実行される安全装置・自動化機能。`features/*/hooks.json` の定義が `settings.json` にマージされる。

| フィーチャー | 種別 | 説明 |
|---|---|---|
| **safety-net** | PreToolUse | 破壊的コマンド（`git reset --hard`, `rm -rf` 等）を実行前にブロック |
| **auto-update** | SessionStart | セッション開始時にキットの最新版を自動チェック・適用（24h キャッシュ） |
| **pre-compact-commit** | PreCompact | コンテキスト圧縮前に未コミット変更を自動コミットし作業消失を防止 |
| **memory-persistence** | PreCompact | セッション状態をファイルに保存し、圧縮やセッション跨ぎで記憶を保持 |
| **strategic-compact** | PreCompact | 適切なタイミングでコンテキスト圧縮を提案 |
| **git-push-review** | PreToolUse | `git push` 前にエディタで差分確認を促す |
| **doc-blocker** | PreToolUse | 不要な .md / .txt ファイルの作成をブロック |
| **doc-size-guard** | PostToolUse | CLAUDE.md / AGENTS.md のサイズ超過とパス参照の破損を検出 |
| **pr-creation-log** | PostToolUse | PR 作成後に URL を記録しレビューコマンドを提示 |
| **pre-commit-gate** | PreToolUse | `git commit` 前に検証を実行（デフォルトは advisory） |
| **post-test-analysis** | PostToolUse | テスト失敗時にサマリーを出力（opt-in） |
| **harness-init** | PostToolUse | テックスタックを検出し `/init-harness` セットアップを提案 |
| **statusline** | statusLine | モデル名・コンテキスト使用量・レート制限を Braille Dots パターンで表示 |
| **codex-cli** | 設定 | OpenAI Codex CLI へのタスク委譲を有効化 |
| **check-codex-after-plan** | PostToolUse | プラン更新時に Codex デザインレビューを提案 |
| **check-codex-before-write** | PostToolUse | 5 ファイル書き込みごとに Codex レビューを提案 |
| **error-to-codex** | PostToolUse | コマンド失敗時に Codex デバッグを提案 |

---

## Plugins

`config/plugins.json` で定義される外部プラグイン。ウィザードまたは非対話モードで選択・インストールされる。

| プラグイン | マーケットプレイス | 説明 |
|---|---|---|
| security-guidance | claude-plugins-official | セキュリティベストプラクティスと脆弱性検出 |
| commit-commands | claude-plugins-official | Git コミット・PR ワークフローコマンド |
| pr-review-toolkit | claude-plugins-official | 専門エージェントによる包括的 PR レビュー |
| feature-dev | claude-plugins-official | アーキテクチャ重視の機能開発ガイド |
| code-review | claude-plugins-official | プルリクエストのコードレビュー |
| claude-md-management | claude-plugins-official | CLAUDE.md の監査・改善 |
| superpowers | claude-plugins-official | ブレスト・TDD・デバッグ等のスキルシステム |
| code-simplifier | claude-plugins-official | コード簡素化・リファクタリング支援 |
| document-skills | anthropic-agent-skills | ドキュメント作成・編集（DOCX, PDF, PPTX, XLSX） |
| example-skills | anthropic-agent-skills | Anthropic 公式のクリエイティブ・技術・エンタープライズスキル集 |

同名プラグインが複数マーケットプレイスに存在する場合は `name@marketplace` 形式で指定する。

---

## Rules

Claude Code の振る舞いを規定するルールファイル。`~/.claude/rules/` にデプロイされる。

| ルール | 内容 |
|---|---|
| **coding-style.md** | イミュータビリティ、ファイル分割、エラーハンドリング、入力バリデーション |
| **git-workflow.md** | Conventional Commits、PR ワークフロー、TDD アプローチ |
| **testing.md** | 80%+ カバレッジ必須、単体・統合・E2E テスト、TDD 強制 |
| **security.md** | プロンプトインジェクション防御、シークレット保護、MCP サーバーセキュリティ |
| **anti-patterns.md** | ハルシネーション防止、スコープ規律、完了整合性、ループ防止 |
| **patterns.md** | API レスポンス形式、Repository パターン、カスタムフック |
| **performance.md** | モデル選択戦略、コンテキストウィンドウ管理、Ultrathink 活用 |
| **agents.md** | エージェント使い分けガイド、並列実行、マルチパースペクティブ分析 |
| **permissions-guide.md** | ワイルドカード許可 / 明示的拒否の原則、サンドボックスモード |
| **hooks.md** | フック種別（PreToolUse, PostToolUse, Stop）と設定方法 |

---

## Memory

`memory/` にはベストプラクティスやアーキテクチャの参照情報が格納される。Claude Code のメモリシステム（`~/.claude/memory/`）にデプロイされ、セッション横断で知識を保持する。

| ファイル | 内容 |
|---|---|
| **MEMORY.md** | メモリシステムのインデックス |
| **architecture.md** | アーキテクチャパターンの参照情報 |
| **best-practices.md** | 開発ベストプラクティス集 |
| **context-engineering.md** | コンテキストエンジニアリング手法 |
| **settings-reference.md** | Claude Code 設定リファレンス |

---

## カスタマイズ

| やりたいこと | 方法 |
|---|---|
| エージェント追加 | `~/.claude/agents/` に `.md` ファイルを作成 |
| ルール追加 | `~/.claude/rules/` に `.md` ファイルを作成 |
| コマンド追加 | `~/.claude/commands/` に `.md` ファイルを作成 |
| スキル追加 | `~/.claude/skills/{name}/` に `SKILL.md` + `references/` 等を作成 |
| フック変更 | `~/.claude/settings.json` の `hooks` セクションを編集 |
| CLAUDE.md 編集 | `<!-- END STARTER-KIT-MANAGED -->` マーカー以降のユーザーセクションに記述 |

CLAUDE.md はキット管理セクション（`<!-- BEGIN/END STARTER-KIT-MANAGED -->`）とユーザーセクションに分離されている。キット更新時は管理セクションのみ上書きされ、ユーザーセクションは保持される。

---

## ディレクトリ構成

```
claude-code-starter-kit/
├── setup.sh                  # メインセットアップ（ウィザード + デプロイ）
├── install.sh                # ワンライナーインストール用ブートストラップ
├── install.ps1               # Windows PowerShell エントリポイント（WSL / Git Bash）
├── uninstall.sh              # マニフェストベースのアンインストール
├── wizard/
│   ├── wizard.sh             # CLI パーサー + 対話型プロンプト
│   └── defaults.conf         # デフォルト設定値
├── lib/
│   ├── colors.sh             # 色付き表示ユーティリティ
│   ├── detect.sh             # OS / WSL / MSYS 自動検出
│   ├── prerequisites.sh      # 依存ツールの確認・インストール
│   ├── features.sh           # フィーチャーフラグ管理
│   ├── template.sh           # CLAUDE.md テンプレートエンジン
│   ├── json-builder.sh       # settings.json 組み立て（deep merge）
│   ├── deploy.sh             # ビルド + デプロイ関数
│   ├── snapshot.sh           # デプロイ済みファイルのスナップショット
│   ├── merge.sh              # 3-way マージユーティリティ
│   ├── update.sh             # 更新モードのロジック
│   ├── dryrun.sh             # ドライラン実装
│   └── codex-setup.sh        # Codex CLI セットアップ
├── config/
│   ├── settings-base.json    # settings.json のベーステンプレート
│   ├── permissions.json      # パーミッション定義（allow / deny / セキュリティ硬化）
│   └── plugins.json          # プラグイン・マーケットプレイス定義（10 プラグイン）
├── features/                 # フック・設定フラグメント（17 機能）
│   ├── safety-net/
│   ├── auto-update/
│   ├── pre-compact-commit/
│   ├── memory-persistence/
│   ├── strategic-compact/
│   ├── git-push-review/
│   ├── doc-blocker/
│   ├── doc-size-guard/
│   ├── pr-creation-log/
│   ├── pre-commit-gate/
│   ├── post-test-analysis/
│   ├── harness-init/
│   ├── statusline/
│   ├── codex-cli/
│   ├── check-codex-after-plan/
│   ├── check-codex-before-write/
│   └── error-to-codex/
├── i18n/
│   ├── en/                   # 英語（strings.sh + CLAUDE.md.base）
│   └── ja/                   # 日本語
├── agents/                   # エージェント定義（10 種）
├── rules/                    # コーディングルール（10 種）
├── commands/                 # スラッシュコマンド（19 個）
│   └── templates/            # init-harness 用テックスタックテンプレート
├── skills/                   # スキルモジュール（12 個）
├── memory/                   # ベストプラクティス記憶
├── profiles/
│   └── standard.conf         # Standard プロファイル設定
├── tests/                    # シェルスクリプトテスト
│   ├── run-unit-tests.sh
│   ├── run-scenarios.sh
│   ├── helpers.sh
│   ├── unit/                 # ユニットテスト
│   └── fixtures/             # テストフィクスチャ
└── docs/                     # 補足ドキュメント
```

---

## 開発者向け

### 静的解析

```bash
# 全スクリプトの ShellCheck（CI と同じ severity: warning）
shellcheck -S warning setup.sh install.sh uninstall.sh lib/*.sh wizard/wizard.sh
```

### テスト

```bash
# ユニットテスト
bash tests/run-unit-tests.sh

# シナリオテスト
bash tests/run-scenarios.sh
```

### 新機能の追加手順

1. `features/<name>/feature.json` と `hooks.json` を作成（フックは `"hooks": {}` 内にネスト）
2. `wizard/wizard.sh` に変数初期化・`_CONFIG_ALLOWED_KEYS`・`save_config()` を追加
3. `i18n/en/strings.sh` と `i18n/ja/strings.sh` に `STR_*` 文字列を追加
4. 外部スクリプトがある場合は `deploy_hook_scripts()` に追加
5. `uninstall.sh` に標準ディレクトリ外のクリーンアップを追加
6. 3 パスで動作検証: fresh install / `setup.sh --update` / 保存済み config の再利用
7. `CHANGELOG.md` を更新

---

## ライセンス

[MIT](LICENSE)
