#!/bin/bash
# shellcheck disable=SC2034
# 日本語ウィザード文字列

# Banner
STR_BANNER="Claude Code スターターキット"
STR_BANNER_SUB="インタラクティブ環境セットアップ"

# Step 3: Codex CLI
STR_CODEX_TITLE="OpenAI Codex CLI をタスク委譲に使用しますか？"
STR_CODEX_YES="はい - CLAUDE.md に Codex CLI 委譲ルールを追加"
STR_CODEX_NO="いいえ - スキップ（後から追加可能）"

# Step 3.5: New /init
STR_NEW_INIT_TITLE="Claude Code の新しい /init 対話モードを有効にしますか？"
STR_NEW_INIT_DESC="有効にすると、/init で CLAUDE.md だけでなく skills や hooks の初期セットアップ提案も行えるようになります。既定で有効です。"
STR_NEW_INIT_YES="はい - /init を対話型フローで使う"
STR_NEW_INIT_NO="いいえ - 従来の /init 挙動のままにする"

# Step 4: Editor
STR_EDITOR_TITLE="使用しているエディタを選択してください（git push レビューフック用）："
STR_EDITOR_VSCODE="VS Code"
STR_EDITOR_CURSOR="Cursor"
STR_EDITOR_ZED="Zed"
STR_EDITOR_NEOVIM="Neovim"
STR_EDITOR_NONE="なし / エディタ連携をスキップ"

STR_CONFIRM_STATUSLINE="ステータスライン"

# Step 5: Hooks
STR_HOOKS_TITLE="有効にするフックを選択してください（番号をスペース区切りで入力）："
STR_HOOKS_SAFETY_NET="Safety Net - 破壊的な git/ファイルシステムコマンドをブロック (cc-safety-net)"
STR_HOOKS_AUTO_UPDATE="自動アップデート - セッション開始時にスターターキットを自動更新"
STR_HOOKS_GIT_PUSH="Git Push レビュー - push 前に一時停止してレビュー"
STR_HOOKS_DOC_BLOCK="ドキュメントブロッカー - 不要な .md/.txt ファイルの作成を防止"
STR_HOOKS_HARNESS_INIT="ハーネス初期化 - 技術スタックを検出し /init-harness を提案"
STR_HOOKS_PRE_COMMIT_GATE="コミット前検証ゲート - git commit 前に検証を実行（アドバイザリーモード）"
STR_HOOKS_POST_TEST_ANALYSIS="テスト失敗分析 - テスト失敗時にサマリーを出力（オプトイン）"
STR_HOOKS_MEMORY="メモリ永続化 - セッション状態の保存/復元"
STR_HOOKS_COMPACT="戦略的コンパクト - 論理的なタイミングで /compact を提案"
STR_HOOKS_PR_LOG="PR 作成ログ - PR 作成後に URL をログ"
STR_HOOKS_PRE_COMMIT="コンパクト前自動コミット - compact 前に変更を自動コミット"
STR_HOOKS_DOC_SIZE="ドキュメントサイズガード - CLAUDE.md/AGENTS.md の肥大化を警告"
STR_HOOKS_CHECK_CODEX_AFTER_PLAN="Codex After Plan - プラン/設計ファイル変更時にデザインレビューを提案"
STR_HOOKS_CHECK_CODEX_BEFORE_WRITE="Codex Write Counter - 5ファイル書き込みごとにデザインレビューを提案"
STR_HOOKS_ERROR_TO_CODEX="Error to Codex - コマンド失敗時に Codex デバッグを提案"

# Step 6: Plugins
STR_PLUGINS_TITLE="インストールするプラグインを選択してください（番号をスペース区切りで入力）："
STR_PLUGINS_NOTE="注意: プラグインはセットアップ後に Claude Code セッション内でインストールします。"

# Step 7: Attribution
STR_COMMIT_TITLE="Claude Code の帰属表示："
STR_COMMIT_YES="コミットとPRに Claude Code の帰属表示を含める"
STR_COMMIT_NO="コミットとPRの帰属表示を含めない"

# Step 8: Confirm
STR_CONFIRM_TITLE="設定サマリー"
STR_CONFIRM_LANGUAGE="言語"
STR_CONFIRM_NEW_INIT="新しい /init"
STR_CONFIRM_CODEX="Codex CLI"
STR_CONFIRM_EDITOR="エディタ"
STR_CONFIRM_HOOKS="フック"
STR_CONFIRM_PLUGINS="プラグイン"
STR_CONFIRM_COMMIT="Claude Code 帰属"
STR_CONFIRM_DEPLOY="$HOME/.claude にデプロイしますか？"
STR_CONFIRM_YES="はい、今すぐデプロイ"
STR_CONFIRM_EDIT="設定を変更（ウィザードを再実行）"
STR_CONFIRM_SAVE="設定を保存して終了（後でデプロイ）"
STR_CONFIRM_CANCEL="キャンセル"

# General
STR_ENABLED="有効"
STR_DISABLED="無効"
STR_YES="はい"
STR_NO="いいえ"
STR_NONE="なし"
STR_SELECTED="選択済み"
STR_CHOICE="選択"
STR_RECOMMENDED="推奨"
STR_TOGGLE_HINT="番号=切替, a=全選択, n=全解除, Enter=確定"

# Saved config detection
STR_SAVED_CONFIG_FOUND="前回の設定が見つかりました。"
STR_SAVED_CONFIG_REUSE="前回の設定を使用する（確認画面へ）"
STR_SAVED_CONFIG_FRESH="最初からやり直す（すべて再設定）"

# Deploy
STR_DEPLOY_PLUGINS_HINT="プラグインをインストールするには 'claude' を起動して以下を実行："
STR_DEPLOY_PLUGINS_INSTALLING="プラグインをインストール中..."
STR_DEPLOY_PLUGINS_INSTALLED="プラグイン："
STR_DEPLOY_PLUGINS_ALREADY="インストール済み："
STR_DEPLOY_PLUGINS_UPDATED="プラグイン更新："
STR_DEPLOY_PLUGINS_FAILED="プラグインのインストールに失敗："
STR_DEPLOY_PLUGINS_SKIP="プラグインのインストールをスキップ（Claude Code CLI が利用不可）"

# Post-deploy: CLI install
STR_CLI_INSTALLING="Claude Code CLI をインストール中..."
STR_CLI_INSTALLED="Claude Code CLI をインストールしました"
STR_CLI_INSTALL_FAILED="インストールに失敗しました。手動でインストールしてください："
STR_CLI_ALREADY="Claude Code CLI はインストール済みです"
STR_CLI_PATH_WARN="インストールは完了しましたが 'claude' が PATH に見つかりません。ターミナルを再起動してください。"

# Post-deploy: WSL hint

# Post-deploy: WSL final message
STR_FINAL_WSL_NEXT="Claude Code は WSL 内で実行します。使い方："
STR_FINAL_WSL_STEP1="1. ターミナル（Windows Terminal）を開き、ドロップダウンから Ubuntu を選択"
STR_FINAL_WSL_STEP2="2. プロジェクトに移動: cd /path/to/your/project"
STR_FINAL_WSL_STEP3="3. 実行: claude"

# Post-deploy: Native Windows (Git Bash)
STR_FINAL_MSYS_NEXT="Claude Code を使い始めるには："
STR_FINAL_MSYS_STEP1="1. この Git Bash ウィンドウを閉じて、もう一度 Git Bash を開く"
STR_FINAL_MSYS_STEP1_HINT="   開き方: デスクトップを右クリック →「Git Bash Here」/ または Windows キー →「Git Bash」と入力"
STR_FINAL_MSYS_STEP2="2. 作業フォルダに移動: cd ~/Documents/my-project"
STR_FINAL_MSYS_STEP3="3. 実行: claude"

# Final message
STR_FINAL_TITLE="セットアップ完了！"
STR_FINAL_NEXT="Claude Code を使い始めるには："
STR_FINAL_STEP1="1. ターミナルを再起動（または新しいタブを開く）"
STR_FINAL_STEP2="2. プロジェクトディレクトリに移動"
STR_FINAL_STEP3="3. 実行: claude"
STR_FINAL_ENJOY="Happy coding!"
STR_FINAL_RESTART_WARN="重要: セットアップで追加された設定を反映するため、ターミナルの再起動が必要です。"
STR_FINAL_RESTART_HINT="現在のターミナルを閉じて、新しいターミナルを開いてから claude を実行してください。"
# Post-deploy: Codex CLI setup
STR_CODEX_SETUP_TITLE="Codex CLI のセットアップ"
STR_CODEX_SETUP_NOTE="※ Codex CLI はインストールと認証（ChatGPT ログインまたは OpenAI API キー）が必要です"
STR_CODEX_CLI_INSTALLING="Codex CLI をインストール中..."
STR_CODEX_CLI_INSTALLED="Codex CLI をインストールしました"
STR_CODEX_CLI_ALREADY="Codex CLI はインストール済みです"
STR_CODEX_CLI_FAILED="Codex CLI のインストールに失敗しました。後で手動でインストールしてください："
STR_CODEX_AUTH_CHECKING="Codex CLI の認証状態を確認中..."
STR_CODEX_AUTH_NOT_LOGGED_IN="Codex CLI は未認証です。認証方法を選択してください"
STR_CODEX_AUTH_REQUIRED="推奨は ChatGPT ログインです。OpenAI API キー認証は任意です"
STR_CODEX_AUTH_CHATGPT="ChatGPT でログインする（推奨）"
STR_CODEX_AUTH_DEVICE="Device Code でログインする"
STR_CODEX_AUTH_SKIP="スキップ（後で設定する）"
STR_CODEX_AUTH_SKIPPED="Codex CLI の認証をスキップしました。後で以下を実行してください："
STR_CODEX_API_KEY_PROMPT="OpenAI API キーでログインする（sk-... で始まるキー）"
STR_CODEX_API_KEY_SKIP="スキップ（後で設定する）"
STR_CODEX_API_KEY_HINT="API キーは https://platform.openai.com/api-keys で取得できます"
STR_CODEX_API_KEY_SAVED="OpenAI API キーを設定しました"
STR_CODEX_API_KEY_ALREADY="OpenAI API キーが見つかりました"
STR_CODEX_API_KEY_VERIFYING="API キーを検証中..."
STR_CODEX_API_KEY_VALID="API キーの検証に成功しました"
STR_CODEX_API_KEY_INVALID="API キーの検証に失敗しました。キーが正しいか確認してください"
STR_CODEX_API_KEY_RETRY="再入力しますか？"
STR_CODEX_API_KEY_RETRY_YES="はい、再入力する"
STR_CODEX_API_KEY_RETRY_NO="いいえ、後で設定する"
STR_CODEX_API_KEY_SKIPPED="API キー認証をスキップしました。後で以下を実行してください："
STR_CODEX_API_KEY_SMOKE_TESTING="OpenAI API キー認証の疎通を確認中..."
STR_CODEX_API_KEY_SMOKE_OK="OpenAI API キー認証の確認に成功しました"
STR_CODEX_API_KEY_SMOKE_FAILED="OpenAI API キー認証の確認に失敗しました。キーまたは API アクセス権を見直してください"
STR_CODEX_LOGIN_RUNNING="Codex CLI にログイン中..."
STR_CODEX_LOGIN_CHATGPT_RUNNING="ChatGPT で Codex CLI にログイン中..."
STR_CODEX_LOGIN_DEVICE_RUNNING="Device Code で Codex CLI にログイン中..."
STR_CODEX_LOGIN_DONE="Codex CLI のログインに成功しました"
STR_CODEX_LOGIN_ALREADY="Codex CLI はログイン済みです"
STR_CODEX_LOGIN_CHATGPT_FAILED="ChatGPT ログインに失敗しました。手動で実行してください："
STR_CODEX_LOGIN_DEVICE_FAILED="Device Code ログインに失敗しました。手動で実行してください："
STR_CODEX_LOGIN_FAILED="Codex CLI のログインに失敗しました。手動で実行してください："
STR_CODEX_RESTART_HINT="Claude Code が起動中の場合は、再起動して Codex CLI の変更を反映してください"
STR_CODEX_SETUP_DONE="Codex CLI のセットアップが完了しました"
STR_CODEX_SETUP_INCOMPLETE="Codex CLI のセットアップは未完了です。後で残りの手順を実行してください"
STR_CODEX_SETUP_CONFIRM="Codex CLI のセットアップを開始しますか？（CLI インストール + 認証）"
STR_CODEX_SETUP_CONFIRM_YES="はい、セットアップする"
STR_CODEX_SETUP_CONFIRM_NO="いいえ、スキップする"
STR_CODEX_SETUP_SKIPPED="Codex CLI のセットアップをスキップしました"

# Update mode
STR_UPDATE_TITLE="Claude Code Starter Kit を更新中"
STR_UPDATE_SETTINGS="settings.json を確認中..."
STR_UPDATE_SETTINGS_UPDATED="settings.json を更新しました"
STR_UPDATE_SETTINGS_UNCHANGED="settings.json に変更なし（kit 側の変更なし）"
STR_UPDATE_SETTINGS_MERGING="settings.json をマージ中（あなたと kit の両方に変更あり）..."
STR_UPDATE_SETTINGS_MERGED="settings.json のマージが完了しました"
STR_UPDATE_CLAUDEMD="CLAUDE.md を確認中..."
STR_UPDATE_FILE_CHANGED="ファイルがあなたによって変更されています"
STR_UPDATE_SNAPSHOT="スナップショットを更新中..."
STR_UPDATE_SNAPSHOT_DONE="スナップショットを更新しました"
STR_UPDATE_SKIPPED_TITLE="スキップしたファイル（ユーザーが変更済み）:"
STR_UPDATE_COMPLETE="更新完了"
STR_UPDATE_V1_WARN="使える starter-kit snapshot が見つかりませんでした。現在の ~/.claude 状態から移行アップデートを起動します。"
STR_UPDATE_MIGRATION_BOOTSTRAP="現在の ~/.claude 状態から最初のスナップショットを作成し、より安全な update path に移行します。"
# メジャーアップグレード + スキップ通知
STR_MAJOR_UPGRADE_WARN="メジャーバージョンのアップグレードを検出しました"
STR_MAJOR_UPGRADE_BACKUP="更新前にバックアップが作成されます。必要に応じて復元できます。"
STR_UPDATE_SKIPPED_HINT="スキップされたファイルにはあなたの変更が保持されています。次回の update で受け入れるかリセットすると kit 更新が適用されます。"
# マージ競合プロンプト
STR_MERGE_SCALAR_CONFLICT="キーが競合しています:"
STR_MERGE_SCALAR_YOUR_VALUE="あなたの値 :"
STR_MERGE_SCALAR_KIT_VALUE="kit の値  :"
STR_MERGE_SCALAR_PROMPT="[K] あなたの値を維持 / [U] kit の値を使用 / [RK] 維持して記憶 / [RU] kit を使用して記憶:"
STR_MERGE_ARRAY_CONFLICT="配列が競合しています:"
STR_MERGE_ARRAY_YOURS="あなた"
STR_MERGE_ARRAY_KITS="kit"
STR_MERGE_ARRAY_ENTRIES="件"
STR_MERGE_ARRAY_PROMPT="[K] あなたの値を維持 / [U] kit の値を使用 / [D] 差分表示 / [RK] 維持して記憶 / [RU] kit を使用して記憶:"
STR_MERGE_ARRAY_REPROMPT="[K] あなたの値を維持 / [U] kit の値を使用 / [RK] 維持して記憶 / [RU] kit を使用して記憶:"
STR_MERGE_ARRAY_KIT_REMOVED="kit が削除した配列項目:"
STR_MERGE_ARRAY_KEEP_REMOVE="[K] 維持（あなたの値）/ [R] 削除（kit の選択）:"
STR_MERGE_REMEMBERED_KEEP="→ あなたの値を維持"
STR_MERGE_REMEMBERED_KIT="→ kit の値を使用"
STR_MERGE_OBJECT_CONFLICT_KIT_WINS="（両方がオブジェクト）— kit のバージョンを使用"
STR_MERGE_PREFS_CLEARED="マージ設定をクリアしました"
STR_MERGE_FILE_DELETED="あなたが削除したファイル:"
STR_MERGE_FILE_RESTORE_PROMPT="[R] 復元 / [S] スキップ ?"
STR_MERGE_3WAY_STARTING="3-way マージを開始:"

# Fresh install 安全性プロンプト
STR_FRESH_MERGE_SETTINGS="既存の settings.json と kit デフォルトをマージしています..."
STR_FRESH_MERGE_SETTINGS_DONE="設定をマージしました（既存キーを保持、kit 追加分を採用）"
STR_FRESH_DIR_EXISTS="既存ディレクトリを検出:"
STR_FRESH_DIR_PROMPT="[O] 全上書き / [N] 新規のみ / [S] スキップ ?"
STR_FRESH_SKIPPED="スキップ（ユーザーファイルを保持）"
STR_FRESH_NEW_ONLY="新規ファイルのみコピー（既存を保持）"
STR_EXISTING_CLAUDE_MERGE_NOTE="既存の設定はマージされます（上書きではありません）。他のファイルは個別に確認します。"

# Dry-run
STR_DRYRUN_TITLE="ドライラン サマリ"
STR_DRYRUN_CREATED="作成されるファイル:"
STR_DRYRUN_MODIFIED="変更されるファイル:"
STR_DRYRUN_MERGED="マージされるファイル:"
STR_DRYRUN_DELETED="削除されるファイル:"
STR_DRYRUN_SKIPPED="スキップ（ユーザー所有のまま保持）:"
STR_DRYRUN_EXTERNAL="外部操作:"
STR_DRYRUN_NO_CHANGES="変更は検出されませんでした。これはドライランです。"
STR_DRYRUN_WOULD_CHANGE="上記の変更が適用されます。これはドライランのため、実際のファイルは変更されていません。"
STR_DRYRUN_SETTINGS_NEW="新規 settings.json が作成されます:"
STR_DRYRUN_SETTINGS_DIFF="settings.json の差分（現在 → シミュレーション後）:"
STR_DRYRUN_OFFER="デプロイ前に変更内容をプレビューしますか？（ドライラン）"
STR_DRYRUN_OFFER_EXISTING="既存の設定が検出されました。デプロイ前にプレビューすることを推奨します。（ドライラン）"
STR_DRYRUN_RUNNING="ドライランを実行中..."
STR_DRYRUN_PROCEED="実際のデプロイを続行しますか？"

# CLAUDE.md section-aware
STR_CLAUDEMD_MIGRATION="既存の CLAUDE.md に kit マーカーがありません。既存の内容はユーザー設定セクションとして保持されます。"
STR_CLAUDEMD_MIGRATION_PROMPT="[M] マージ（kit セクション追加 + 既存保持） / [S] スキップ ?"
STR_CLAUDEMD_MIGRATION_SKIP="CLAUDE.md のマイグレーションをスキップしました（非対話モード）。対話モードで再実行してください。"
STR_CLAUDEMD_KIT_UPDATED="CLAUDE.md の kit セクションを更新しました"
STR_CLAUDEMD_KIT_UNCHANGED="CLAUDE.md の kit セクションに変更なし"
STR_CLAUDEMD_KIT_CONFLICT="CLAUDE.md の kit セクション: ユーザーと kit の両方に変更があります"
STR_CLAUDEMD_KIT_CONFLICT_PROMPT="[U] 新しい kit を使用 / [K] 現在のまま / [D] 差分表示 ?"
STR_CLAUDEMD_USER_PRESERVED="CLAUDE.md のユーザーセクションを保持しました"

STR_EXISTING_CLAUDE_WARN="starter kit の更新モードではない既存の Claude Code 設定を検出しました。"
STR_EXISTING_CLAUDE_BACKUP="この実行では、starter kit 管理ファイルを変更する前に ~/.claude 全体をバックアップします。"
STR_EXISTING_CLAUDE_REWRITE="その後、CLAUDE.md や settings.json など starter kit 管理ファイルを再生成します。"
STR_EXISTING_CLAUDE_SIDE_EFFECTS="選択内容によっては shell RC、Codex CLI などの外部副作用も実行される場合があります。"
STR_EXISTING_CLAUDE_NONINTERACTIVE="非対話モードが指定されているため、そのまま続行します。"
STR_EXISTING_CLAUDE_CONFIRM="バックアップ付き再構成フローを続行しますか？ [y/N]"
STR_EXISTING_CLAUDE_CANCEL="既存の ~/.claude 設定を変更する前にセットアップを中止しました。"

STR_MIGRATION_HOOKS_TO_PROJECT="prettier-hooks と console-log-guard はプロジェクトレベルの設定に移行しました。\n   プロジェクトで /init-harness を実行して同等のフックを設定してください。"

# Errors
