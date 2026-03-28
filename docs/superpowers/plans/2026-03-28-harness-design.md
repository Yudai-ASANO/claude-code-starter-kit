# Harness Design Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Claude Code Starter Kit にハーネスエンジニアリングパターン（Planner→Generator→Evaluator）を導入し、技術スタック固有フックをプロジェクトレベルに分離する。

**Architecture:** 5つのコンポーネントを追加（qa-reviewer agent, harness-init feature, /init-harness command, pre-commit-gate feature, post-test-analysis feature）し、2つの JS/TS 固有フィーチャを削除して /init-harness テンプレートに移行する。既存の feature registry パターン、hook fragment assembly、wizard フローに沿って実装する。

**Tech Stack:** Bash 4+, jq, ShellCheck (CI validation)

**Spec:** `docs/superpowers/specs/2026-03-28-harness-design-spec.md`

---

## File Structure

### New Files
```
agents/qa-reviewer.md                          # G1: 厳格な評価器エージェント
commands/init-harness.md                        # G2b: /init-harness スラッシュコマンド
commands/templates/typescript.json              # G2b: TypeScript テンプレート
commands/templates/javascript.json              # G2b: JavaScript テンプレート
commands/templates/php.json                     # G2b: PHP テンプレート
commands/templates/swift.json                   # G2b: Swift テンプレート
commands/templates/kotlin.json                  # G2b: Kotlin テンプレート
commands/templates/generic.json                 # G2b: Generic (Makefile) テンプレート
features/harness-init/feature.json              # G2: フィーチャメタデータ
features/harness-init/hooks.json                # G2: SessionStart フック定義
features/harness-init/scripts/detect-stack.sh   # G2: スタック検出スクリプト
features/pre-commit-gate/feature.json           # G3: フィーチャメタデータ
features/pre-commit-gate/hooks.json             # G3: PreToolUse フック定義
features/pre-commit-gate/scripts/pre-commit-gate.sh  # G3: 検証ゲートスクリプト
features/post-test-analysis/feature.json        # G5: フィーチャメタデータ
features/post-test-analysis/hooks.json          # G5: PostToolUse フック定義
features/post-test-analysis/scripts/analyze-test.sh  # G5: テスト分析スクリプト
```

### Modified Files
```
commands/orchestrate.md                         # G1b: Generator + repair loop 追加
lib/features.sh                                 # Feature registry 更新
wizard/wizard.sh                                # ENABLE_* フラグ追加/削除
i18n/en/strings.sh                              # 英語 i18n 文字列
i18n/ja/strings.sh                              # 日本語 i18n 文字列
profiles/standard.conf                          # デフォルト値
```

### Deleted Files
```
features/prettier-hooks/feature.json
features/prettier-hooks/hooks.json
features/console-log-guard/feature.json
features/console-log-guard/hooks.json
```

---

### Task 1: qa-reviewer エージェント作成 (G1)

**Files:**
- Create: `agents/qa-reviewer.md`

- [ ] **Step 1: qa-reviewer.md を作成**

```markdown
---
name: qa-reviewer
description: Strict evidence-based evaluator. Grades implementation against sprint contract criteria using verifier command outputs. Use after implementation sprints in /orchestrate workflow. Does NOT review source code directly.
tools: Read, Grep, Glob, Bash
model: opus
permissionMode: plan
---

You are a strict QA evaluator. You grade implementations against sprint contract criteria.

HARD SCOPE — you MUST follow these rules:
- You receive ONLY orchestrator-collected evidence (verifier outputs, build logs, lint results)
- You NEVER read source code or git diff directly
- You NEVER issue vague judgments like "looks good" or "generally fine"
- Every criterion gets PASS or FAIL based on verifier output vs expected result

When invoked with a sprint contract and evidence bundle:

1. For each criterion in the sprint contract:
   - Compare the verifier command's actual output/exit code against expected
   - Mark PASS if actual matches expected, FAIL otherwise
2. Produce a grading report in this format:

## QA Evaluation Report

### Sprint Contract: [task name]
| # | Criterion | Verifier | Expected | Actual | Verdict |
|---|-----------|----------|----------|--------|---------|
| 1 | ... | ... | ... | ... | PASS/FAIL |

### Overall: PASS/FAIL (N/M failed)

3. If any criterion FAILs:
   - Provide repair instructions scoped to the failing criterion
   - Reference the failing verifier output, NOT source code
   - Do NOT guess file paths — describe the expected behavior

## Approval Criteria

- PASS: All criteria met
- FAIL: Any criterion not met — provide repair instructions

## What You Do NOT Do

- Inspect source code
- Read git diff
- Suggest code quality improvements
- Comment on style or patterns
- Issue subjective assessments
```

- [ ] **Step 2: ShellCheck は不要（Markdown ファイル）。ファイル存在を確認**

Run: `test -f agents/qa-reviewer.md && echo "OK" || echo "MISSING"`
Expected: OK

- [ ] **Step 3: コミット**

```bash
git add agents/qa-reviewer.md
git commit -m "feat: add qa-reviewer agent for evidence-based sprint contract evaluation"
```

---

### Task 2: /orchestrate コマンドに Generator ステージ追加 (G1b)

**Files:**
- Modify: `commands/orchestrate.md`

- [ ] **Step 1: orchestrate.md の feature ワークフローを更新**

`commands/orchestrate.md` の feature ワークフロー部分を以下に置き換える：

```markdown
### feature
Full feature implementation workflow with harness pattern:
```
planner -> [Generator: tdd-guide] -> qa-reviewer -> code-reviewer + security-reviewer
```

#### Phase 1: Planning
planner produces:
- Implementation plan
- **Executable Sprint Contract** (acceptance criteria with verifier commands)

Sprint Contract format:
```markdown
## Sprint Contract
### Acceptance Criteria
| # | Criterion | Verifier Command | Expected Result |
|---|-----------|-----------------|-----------------|
| 1 | Feature works | npm test -- --grep "feature" | exit 0 |
| 2 | Types clean | npx tsc --noEmit | exit 0 |
```

#### Phase 2: Generation
Generator (tdd-guide) receives the plan + sprint contract and implements.
Generator does NOT produce the evidence bundle.

#### Phase 3: Evidence Collection (orchestrator)
The orchestrator (you) collects evidence by running each verifier command
from the sprint contract. Evidence is raw command output, not filtered.

Evidence format:
```markdown
## Evidence (collected by orchestrator)
### Criterion 1: [name]
Command: [verifier command]
Exit code: [actual]
Stdout: [last 20 lines]
```

#### Phase 4: Evaluation
qa-reviewer receives sprint contract + evidence and produces a grading report.

**Repair Loop:**
- If FAIL: repair instructions → Generator re-implements → re-collect evidence → re-evaluate
- Max 3 iterations, then escalate to user

#### Phase 5: Review (after qa-reviewer PASS)
Run in parallel:
- code-reviewer (quality)
- security-reviewer (security)
```

- [ ] **Step 2: ファイル内容を確認**

Run: `grep -c "Sprint Contract" commands/orchestrate.md`
Expected: 数値（0でない）

- [ ] **Step 3: コミット**

```bash
git add commands/orchestrate.md
git commit -m "feat: add Generator stage and repair loop to /orchestrate feature workflow"
```

---

### Task 3: harness-init フィーチャ作成 (G2)

**Files:**
- Create: `features/harness-init/feature.json`
- Create: `features/harness-init/hooks.json`
- Create: `features/harness-init/scripts/detect-stack.sh`

- [ ] **Step 1: feature.json を作成**

```json
{
  "name": "harness-init",
  "displayName": "Harness Init Detection",
  "description": "Detects project tech stack and suggests /init-harness setup",
  "category": "harness",
  "default": true,
  "dependencies": [],
  "conflicts": []
}
```

- [ ] **Step 2: hooks.json を作成**

```json
{
  "hooks": {
    "SessionStart": [{
      "matcher": "*",
      "hooks": [{
        "type": "command",
        "command": "__HOME__/.claude/hooks/harness-init/detect-stack.sh"
      }]
    }]
  }
}
```

- [ ] **Step 3: detect-stack.sh を作成**

```bash
#!/bin/bash
set -euo pipefail

# Get project root
project_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

# Compute repo identity hash
repo_hash="$(printf '%s' "$project_root" | shasum | cut -d' ' -f1)"

# Suggested repos tracking file
suggested_file="${HOME}/.claude/.harness-init-suggested"

# Check if already suggested for this repo
if [[ -f "$suggested_file" ]] && grep -q "$repo_hash" "$suggested_file" 2>/dev/null; then
  exit 0
fi

# Check if project already has hooks configured
if [[ -f "${project_root}/.claude/settings.json" ]]; then
  if jq -e '.hooks | length > 0' "${project_root}/.claude/settings.json" >/dev/null 2>&1; then
    # Has hooks — record and exit silently
    mkdir -p "$(dirname "$suggested_file")"
    printf '%s\n' "$repo_hash" >> "$suggested_file"
    exit 0
  fi
fi

# Detect tech stack
stack=""
if [[ -f "${project_root}/package.json" ]] && [[ -f "${project_root}/tsconfig.json" ]]; then
  stack="TypeScript"
elif [[ -f "${project_root}/package.json" ]]; then
  stack="JavaScript"
elif [[ -f "${project_root}/composer.json" ]]; then
  stack="PHP"
elif [[ -f "${project_root}/Package.swift" ]]; then
  stack="Swift"
elif [[ -f "${project_root}/build.gradle" ]] || [[ -f "${project_root}/build.gradle.kts" ]]; then
  stack="Kotlin"
elif [[ -f "${project_root}/Cargo.toml" ]]; then
  stack="Rust"
elif [[ -f "${project_root}/go.mod" ]]; then
  stack="Go"
elif [[ -f "${project_root}/Makefile" ]]; then
  stack="Generic"
fi

# No stack detected — exit silently
if [[ -z "$stack" ]]; then
  exit 0
fi

# Record this repo as suggested
mkdir -p "$(dirname "$suggested_file")"
printf '%s\n' "$repo_hash" >> "$suggested_file"

# Output suggestion to stdout (injected into Claude's context)
printf '[harness] %s project detected. Run /init-harness to set up verification hooks.\n' "$stack"
```

- [ ] **Step 4: スクリプトに実行権限を付与**

Run: `chmod +x features/harness-init/scripts/detect-stack.sh`

- [ ] **Step 5: ShellCheck 検証**

Run: `shellcheck -S warning features/harness-init/scripts/detect-stack.sh`
Expected: エラーなし

- [ ] **Step 6: JSON 検証**

Run: `jq . features/harness-init/feature.json && jq . features/harness-init/hooks.json`
Expected: 正常な JSON 出力

- [ ] **Step 7: コミット**

```bash
git add features/harness-init/
git commit -m "feat: add harness-init feature for tech stack detection and /init-harness suggestion"
```

---

### Task 4: /init-harness コマンドとテンプレート作成 (G2b)

**Files:**
- Create: `commands/init-harness.md`
- Create: `commands/templates/typescript.json`
- Create: `commands/templates/javascript.json`
- Create: `commands/templates/php.json`
- Create: `commands/templates/swift.json`
- Create: `commands/templates/kotlin.json`
- Create: `commands/templates/generic.json`

- [ ] **Step 1: init-harness.md スラッシュコマンドを作成**

```markdown
# Init Harness

Generate project-level verification hooks in `.claude/settings.json` based on the detected tech stack.

## Usage

`/init-harness` — Detect stack and generate hooks
`/init-harness --reset` — Delete manifest and regenerate from scratch
`/init-harness --reinstall-managed` — Reinstall previously removed managed hooks
`/init-harness --with-console-guard` — Include console.log detection (JS/TS only)

## Procedure

### Step 1: Detect Tech Stack

Check these files in the project root (in order):
- `package.json` + `tsconfig.json` → use `commands/templates/typescript.json`
- `package.json` (no tsconfig) → use `commands/templates/javascript.json`
- `composer.json` → use `commands/templates/php.json`
- `Package.swift` → use `commands/templates/swift.json`
- `build.gradle` or `build.gradle.kts` → use `commands/templates/kotlin.json`
- `Cargo.toml` → use `commands/templates/generic.json` (Rust uses cargo conventions)
- `go.mod` → use `commands/templates/generic.json` (Go uses go conventions)
- `Makefile` → use `commands/templates/generic.json`

If no match, inform the user and stop.

### Step 2: Handle Flags

- `--reset`: Delete `.claude/.harness-manifest.json` if it exists, then proceed as fresh install
- `--reinstall-managed`: Read manifest, clear all tombstone entries (hooks with id in manifest but missing from settings.json), then proceed with merge
- `--with-console-guard`: Add console.log guard hook entry to the template before merging (JS/TS stacks only)

### Step 3: Read Template

Read the selected template from `commands/templates/`. Template hooks have `_id` fields for manifest tracking.

### Step 4: Idempotent Merge

Read or create `.claude/.harness-manifest.json`:
```json
{
  "managed_hooks": [],
  "stack": "",
  "version": ""
}
```

For each hook entry in the template:
1. Compute `command_hash` (SHA-256 of the command string): `printf '%s' "$command" | shasum -a 256 | cut -d' ' -f1`
2. Check the `_id` against the manifest:
   - **id in manifest AND in settings.json** → Replace the entry (update)
   - **id in manifest but NOT in settings.json** → Skip (user deleted = tombstone)
   - **id NOT in manifest** → Append to settings.json (new hook)
3. Hooks without `_id` (user-added) → Preserve untouched

### Step 5: Preview and Confirm

Show the unified diff of proposed changes to `.claude/settings.json`.
Ask: "Apply these changes? [Y/n]"

### Step 6: Write

Write the merged `.claude/settings.json` and update `.claude/.harness-manifest.json`.
Strip `_id` fields from the written settings.json (they are only for manifest tracking).

## Arguments

$ARGUMENTS — flags passed to the command
```

- [ ] **Step 2: typescript.json テンプレートを作成**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "_id": "harness:typescript:prettier",
        "matcher": "tool == 'Edit' && tool_input.file_path matches '\\.(ts|tsx|js|jsx)$'",
        "hooks": [{
          "type": "command",
          "command": "#!/bin/bash\ninput=$(cat)\nfile_path=$(printf '%s' \"$input\" | jq -r '.tool_input.file_path // \"\"')\nif [ -n \"$file_path\" ] && [ -f \"$file_path\" ]; then\n  npx prettier --write \"$file_path\" 2>/dev/null >&2\nfi\nprintf '%s\\n' \"$input\""
        }]
      },
      {
        "_id": "harness:typescript:tsc-check",
        "matcher": "tool == 'Edit' && tool_input.file_path matches '\\.(ts|tsx)$'",
        "hooks": [{
          "type": "command",
          "command": "#!/bin/bash\ninput=$(cat)\nnpx tsc --noEmit 2>&1 | tail -3 >&2\nprintf '%s\\n' \"$input\""
        }]
      }
    ]
  }
}
```

- [ ] **Step 3: javascript.json テンプレートを作成**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "_id": "harness:javascript:prettier",
        "matcher": "tool == 'Edit' && tool_input.file_path matches '\\.(js|jsx)$'",
        "hooks": [{
          "type": "command",
          "command": "#!/bin/bash\ninput=$(cat)\nfile_path=$(printf '%s' \"$input\" | jq -r '.tool_input.file_path // \"\"')\nif [ -n \"$file_path\" ] && [ -f \"$file_path\" ]; then\n  npx prettier --write \"$file_path\" 2>/dev/null >&2\nfi\nprintf '%s\\n' \"$input\""
        }]
      }
    ]
  }
}
```

- [ ] **Step 4: php.json テンプレートを作成**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "_id": "harness:php:cs-fixer",
        "matcher": "tool == 'Edit' && tool_input.file_path matches '\\.php$'",
        "hooks": [{
          "type": "command",
          "command": "#!/bin/bash\ninput=$(cat)\nfile_path=$(printf '%s' \"$input\" | jq -r '.tool_input.file_path // \"\"')\nif [ -n \"$file_path\" ] && [ -f \"$file_path\" ] && command -v php-cs-fixer >/dev/null 2>&1; then\n  php-cs-fixer fix \"$file_path\" --quiet 2>&1 >&2\nfi\nprintf '%s\\n' \"$input\""
        }]
      }
    ]
  }
}
```

- [ ] **Step 5: swift.json テンプレートを作成**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "_id": "harness:swift:swiftlint",
        "matcher": "tool == 'Edit' && tool_input.file_path matches '\\.swift$'",
        "hooks": [{
          "type": "command",
          "command": "#!/bin/bash\ninput=$(cat)\nfile_path=$(printf '%s' \"$input\" | jq -r '.tool_input.file_path // \"\"')\nif [ -n \"$file_path\" ] && [ -f \"$file_path\" ] && command -v swiftlint >/dev/null 2>&1; then\n  swiftlint lint --path \"$file_path\" --quiet 2>&1 | head -5 >&2\nfi\nprintf '%s\\n' \"$input\""
        }]
      }
    ]
  }
}
```

- [ ] **Step 6: kotlin.json テンプレートを作成**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "_id": "harness:kotlin:ktlint",
        "matcher": "tool == 'Edit' && tool_input.file_path matches '\\.(kt|kts)$'",
        "hooks": [{
          "type": "command",
          "command": "#!/bin/bash\ninput=$(cat)\nfile_path=$(printf '%s' \"$input\" | jq -r '.tool_input.file_path // \"\"')\nif [ -n \"$file_path\" ] && [ -f \"$file_path\" ] && command -v ktlint >/dev/null 2>&1; then\n  ktlint \"$file_path\" 2>&1 | head -5 >&2\nfi\nprintf '%s\\n' \"$input\""
        }]
      }
    ]
  }
}
```

- [ ] **Step 7: generic.json テンプレートを作成**

```json
{
  "hooks": {}
}
```

Note: Generic template is empty — Makefile/Cargo/Go projects define their own conventions. The `/init-harness` command informs the user that no default hooks are available and suggests manual configuration.

- [ ] **Step 8: 全 JSON テンプレートの検証**

Run: `for f in commands/templates/*.json; do echo "--- $f ---"; jq . "$f" || echo "INVALID: $f"; done`
Expected: 全ファイルが正常な JSON 出力

- [ ] **Step 9: コミット**

```bash
git add commands/init-harness.md commands/templates/
git commit -m "feat: add /init-harness command and tech-stack templates for project-level hooks"
```

---

### Task 5: pre-commit-gate フィーチャ作成 (G3)

**Files:**
- Create: `features/pre-commit-gate/feature.json`
- Create: `features/pre-commit-gate/hooks.json`
- Create: `features/pre-commit-gate/scripts/pre-commit-gate.sh`

- [ ] **Step 1: feature.json を作成**

```json
{
  "name": "pre-commit-gate",
  "displayName": "Pre-Commit Verification Gate",
  "description": "Runs verification before git commit (advisory by default)",
  "category": "harness",
  "default": true,
  "dependencies": [],
  "conflicts": []
}
```

- [ ] **Step 2: hooks.json を作成**

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "tool == \"Bash\" && tool_input.command matches \"git commit\"",
      "hooks": [{
        "type": "command",
        "command": "__HOME__/.claude/hooks/pre-commit-gate/pre-commit-gate.sh"
      }]
    }]
  }
}
```

- [ ] **Step 3: pre-commit-gate.sh を作成**

```bash
#!/bin/bash
set -euo pipefail

# Read tool event from stdin
input="$(cat)"

# --- Determine verification commands ---
declare -a verify_cmds=()
declare -a verify_names=()

# Priority 1: explicit env vars
if [[ -n "${VERIFY_TEST:-}" ]]; then
  verify_cmds+=("$VERIFY_TEST")
  verify_names+=("test")
fi
if [[ -n "${VERIFY_LINT:-}" ]]; then
  verify_cmds+=("$VERIFY_LINT")
  verify_names+=("lint")
fi
if [[ -n "${VERIFY_TYPE:-}" ]]; then
  verify_cmds+=("$VERIFY_TYPE")
  verify_names+=("type")
fi

# Priority 2: auto-detect (only if no env vars set)
if [[ ${#verify_cmds[@]} -eq 0 ]]; then
  # Detect package manager
  pkg_runner="npm"
  if [[ -f "pnpm-lock.yaml" ]]; then
    pkg_runner="pnpm"
  elif [[ -f "yarn.lock" ]]; then
    pkg_runner="yarn"
  fi

  # package.json scripts
  if [[ -f "package.json" ]]; then
    if jq -e '.scripts.test' package.json >/dev/null 2>&1; then
      verify_cmds+=("$pkg_runner test")
      verify_names+=("test")
    fi
    if jq -e '.scripts.lint' package.json >/dev/null 2>&1; then
      verify_cmds+=("$pkg_runner run lint")
      verify_names+=("lint")
    fi
  fi

  # Makefile
  if [[ -f "Makefile" ]] && grep -q '^test:' Makefile 2>/dev/null; then
    verify_cmds+=("make test")
    verify_names+=("test")
  fi

  # composer.json
  if [[ -f "composer.json" ]] && jq -e '.scripts.test' composer.json >/dev/null 2>&1; then
    verify_cmds+=("composer test")
    verify_names+=("test")
  fi

  # Cargo.toml
  if [[ -f "Cargo.toml" ]]; then
    verify_cmds+=("cargo test")
    verify_names+=("test")
  fi

  # go.mod
  if [[ -f "go.mod" ]]; then
    verify_cmds+=("go test ./...")
    verify_names+=("test")
  fi

  # Justfile
  if [[ -f "Justfile" ]] && grep -q '^test' Justfile 2>/dev/null; then
    verify_cmds+=("just test")
    verify_names+=("test")
  fi
fi

# No commands found — pass through silently
if [[ ${#verify_cmds[@]} -eq 0 ]]; then
  printf '%s' "$input"
  exit 0
fi

# --- Run verifiers with output bounding and exit code preservation ---
_gate_tmp_dir="/tmp/.claude-gate-$$"
mkdir -p "$_gate_tmp_dir"
# shellcheck disable=SC2064
trap "rm -rf '$_gate_tmp_dir'" EXIT

declare -a failed_names=()

for i in "${!verify_cmds[@]}"; do
  cmd="${verify_cmds[$i]}"
  name="${verify_names[$i]}"
  tmp_out="${_gate_tmp_dir}/${name}.out"

  if eval "$cmd" > "$tmp_out" 2>&1; then
    : # pass
  else
    failed_names+=("$name")
  fi
done

# --- Report results ---
if [[ ${#failed_names[@]} -eq 0 ]]; then
  # All passed — silent
  printf '%s' "$input"
  exit 0
fi

# Build summary
failed_str=""
for i in "${!verify_names[@]}"; do
  name="${verify_names[$i]}"
  code=0
  for fn in "${failed_names[@]}"; do
    if [[ "$fn" == "$name" ]]; then code=1; break; fi
  done
  if [[ -n "$failed_str" ]]; then failed_str+=", "; fi
  failed_str+="${name}(${code})"
done

if [[ "${HARNESS_GATE_MODE:-}" == "strict" ]]; then
  echo "[gate] Verification failed: ${failed_str}. Commit blocked (strict mode)." >&2
  printf '%s' "$input"
  exit 1
else
  echo "[gate] Verification failed: ${failed_str}. Advisory mode — commit proceeds." >&2
  printf '%s' "$input"
  exit 0
fi
```

- [ ] **Step 4: 実行権限を付与**

Run: `chmod +x features/pre-commit-gate/scripts/pre-commit-gate.sh`

- [ ] **Step 5: ShellCheck 検証**

Run: `shellcheck -S warning features/pre-commit-gate/scripts/pre-commit-gate.sh`
Expected: エラーなし

- [ ] **Step 6: JSON 検証**

Run: `jq . features/pre-commit-gate/feature.json && jq . features/pre-commit-gate/hooks.json`
Expected: 正常な JSON 出力

- [ ] **Step 7: コミット**

```bash
git add features/pre-commit-gate/
git commit -m "feat: add pre-commit-gate feature with advisory-default verification"
```

---

### Task 6: post-test-analysis フィーチャ作成 (G5)

**Files:**
- Create: `features/post-test-analysis/feature.json`
- Create: `features/post-test-analysis/hooks.json`
- Create: `features/post-test-analysis/scripts/analyze-test.sh`

- [ ] **Step 1: feature.json を作成**

```json
{
  "name": "post-test-analysis",
  "displayName": "Post-Test Failure Analysis",
  "description": "Analyzes test failures and outputs summary (opt-in, failure-only)",
  "category": "harness",
  "default": false,
  "dependencies": [],
  "conflicts": []
}
```

- [ ] **Step 2: hooks.json を作成**

```json
{
  "hooks": {
    "PostToolUse": [{
      "matcher": "tool == 'Bash' && tool_output.exit_code != null && tool_output.exit_code != 0",
      "hooks": [{
        "type": "command",
        "command": "__HOME__/.claude/hooks/post-test-analysis/analyze-test.sh",
        "timeout": 5000
      }]
    }]
  }
}
```

- [ ] **Step 3: analyze-test.sh を作成**

```bash
#!/bin/bash
set -euo pipefail

# Read tool event from stdin
input="$(cat)"

# Extract command
command_str="$(printf '%s' "$input" | jq -r '.tool_input.command // ""' 2>/dev/null)" || command_str=""

# Check if command matches a test runner pattern
is_test_runner=false
case "$command_str" in
  *"npm test"*|*"npx jest"*|*"npx vitest"*|*"npx mocha"*)
    is_test_runner=true ;;
  *"pnpm test"*|*"pnpm exec vitest"*|*"yarn test"*)
    is_test_runner=true ;;
  *"npm run test"*)
    is_test_runner=true ;;
  *"pytest"*|*"python -m pytest"*|*"python3 -m pytest"*)
    is_test_runner=true ;;
  *"swift test"*|*"xcodebuild test"*)
    is_test_runner=true ;;
  *"gradlew test"*|*"gradle test"*)
    is_test_runner=true ;;
  *"make test"*|*"make ci-test"*|*"just test"*)
    is_test_runner=true ;;
  *"cargo test"*|*"go test"*)
    is_test_runner=true ;;
  jest|vitest|mocha)
    is_test_runner=true ;;
esac

# Not a test runner — pass through silently
if [[ "$is_test_runner" != "true" ]]; then
  printf '%s' "$input"
  exit 0
fi

# Extract test output for analysis
test_output="$(printf '%s' "$input" | jq -r '.tool_output.output // ""' 2>/dev/null)" || test_output=""

# Count failures and extract names (best effort, varies by runner)
fail_count=0
failed_names=""

# Try common failure patterns
if printf '%s' "$test_output" | grep -qE '[0-9]+ failed'; then
  fail_count="$(printf '%s' "$test_output" | grep -oE '[0-9]+ failed' | head -1 | grep -oE '[0-9]+')" || fail_count=0
fi

# Extract up to 3 failed test names
failed_names="$(printf '%s' "$test_output" | grep -E '(FAIL|FAILED|Error|✗|✘|×)' | head -3 | sed 's/^[[:space:]]*//' | tr '\n' ', ' | sed 's/, $//')" || failed_names=""

# Build summary
if [[ "$fail_count" -gt 0 ]] || [[ -n "$failed_names" ]]; then
  summary="[test] "
  if [[ "$fail_count" -gt 0 ]]; then
    summary+="${fail_count} failed"
  else
    summary+="Tests failed"
  fi
  if [[ -n "$failed_names" ]]; then
    summary+=": ${failed_names}"
  fi
  # Output to stderr only (OUTPUT DISCIPLINE: stdout = pass-through only)
  echo "$summary" >&2
fi

# Pass through input on stdout
printf '%s' "$input"
exit 0
```

- [ ] **Step 4: 実行権限を付与**

Run: `chmod +x features/post-test-analysis/scripts/analyze-test.sh`

- [ ] **Step 5: ShellCheck 検証**

Run: `shellcheck -S warning features/post-test-analysis/scripts/analyze-test.sh`
Expected: エラーなし

- [ ] **Step 6: JSON 検証**

Run: `jq . features/post-test-analysis/feature.json && jq . features/post-test-analysis/hooks.json`
Expected: 正常な JSON 出力

- [ ] **Step 7: コミット**

```bash
git add features/post-test-analysis/
git commit -m "feat: add post-test-analysis feature (opt-in, failure-only, stderr output)"
```

---

### Task 7: prettier-hooks と console-log-guard の削除

**Files:**
- Delete: `features/prettier-hooks/feature.json`
- Delete: `features/prettier-hooks/hooks.json`
- Delete: `features/console-log-guard/feature.json`
- Delete: `features/console-log-guard/hooks.json`

- [ ] **Step 1: prettier-hooks ディレクトリを削除**

Run: `rm -rf features/prettier-hooks/`

- [ ] **Step 2: console-log-guard ディレクトリを削除**

Run: `rm -rf features/console-log-guard/`

- [ ] **Step 3: 削除を確認**

Run: `test ! -d features/prettier-hooks && test ! -d features/console-log-guard && echo "OK" || echo "STILL EXISTS"`
Expected: OK

- [ ] **Step 4: コミット**

```bash
git add -A features/prettier-hooks/ features/console-log-guard/
git commit -m "refactor: remove prettier-hooks and console-log-guard (moved to /init-harness templates)"
```

---

### Task 8: lib/features.sh の Feature Registry 更新

**Files:**
- Modify: `lib/features.sh:19-59`

- [ ] **Step 1: _FEATURE_FLAGS から prettier-hooks と console-log-guard を削除し、新フィーチャを追加**

`lib/features.sh` の `_FEATURE_FLAGS` 連想配列を以下のように修正:

削除する行:
```
  [prettier-hooks]=ENABLE_PRETTIER_HOOKS
  [console-log-guard]=ENABLE_CONSOLE_LOG_GUARD
```

追加する行（`[error-to-codex]=ENABLE_ERROR_TO_CODEX` の後に）:
```
  [harness-init]=ENABLE_HARNESS_INIT
  [pre-commit-gate]=ENABLE_PRE_COMMIT_GATE
  [post-test-analysis]=ENABLE_POST_TEST_ANALYSIS
```

- [ ] **Step 2: _FEATURE_HAS_SCRIPTS に新フィーチャを追加**

`[error-to-codex]=true` の後に追加:
```
  [harness-init]=true
  [pre-commit-gate]=true
  [post-test-analysis]=true
```

- [ ] **Step 3: _FEATURE_ORDER を更新**

`_FEATURE_ORDER` 配列の `prettier-hooks console-log-guard` を削除し、末尾に新フィーチャを追加:

変更前:
```
  safety-net doc-blocker prettier-hooks console-log-guard
```

変更後:
```
  safety-net doc-blocker
```

末尾に追加（`error-to-codex` の後）:
```
  harness-init pre-commit-gate post-test-analysis
```

- [ ] **Step 4: ShellCheck 検証**

Run: `shellcheck -S warning lib/features.sh`
Expected: エラーなし

- [ ] **Step 5: コミット**

```bash
git add lib/features.sh
git commit -m "refactor: update feature registry — remove JS/TS hooks, add harness features"
```

---

### Task 9: wizard/wizard.sh の更新

**Files:**
- Modify: `wizard/wizard.sh`

- [ ] **Step 1: 変数初期化を更新（行 38-39 付近）**

削除:
```bash
ENABLE_PRETTIER_HOOKS="${ENABLE_PRETTIER_HOOKS:-}"
ENABLE_CONSOLE_LOG_GUARD="${ENABLE_CONSOLE_LOG_GUARD:-}"
```

追加（同じ場所に）:
```bash
ENABLE_HARNESS_INIT="${ENABLE_HARNESS_INIT:-}"
ENABLE_PRE_COMMIT_GATE="${ENABLE_PRE_COMMIT_GATE:-}"
ENABLE_POST_TEST_ANALYSIS="${ENABLE_POST_TEST_ANALYSIS:-}"
```

- [ ] **Step 2: _CONFIG_ALLOWED_KEYS を更新（行 136 付近）**

文字列内の `ENABLE_PRETTIER_HOOKS ENABLE_CONSOLE_LOG_GUARD` を `ENABLE_HARNESS_INIT ENABLE_PRE_COMMIT_GATE ENABLE_POST_TEST_ANALYSIS` に置き換える。

- [ ] **Step 3: _CONFIG_SAVE_KEYS を更新（行 198-199 付近）**

`ENABLE_PRETTIER_HOOKS ENABLE_CONSOLE_LOG_GUARD` を `ENABLE_HARNESS_INIT ENABLE_PRE_COMMIT_GATE ENABLE_POST_TEST_ANALYSIS` に置き換える。

- [ ] **Step 4: HOOK_KEYS 配列を更新（行 442-443 付近）**

削除:
```bash
  "ENABLE_PRETTIER_HOOKS"
  "ENABLE_CONSOLE_LOG_GUARD"
```

追加（配列末尾、`"ENABLE_ERROR_TO_CODEX"` の後に）:
```bash
  "ENABLE_HARNESS_INIT"
  "ENABLE_PRE_COMMIT_GATE"
  "ENABLE_POST_TEST_ANALYSIS"
```

- [ ] **Step 5: _init_hook_labels() 内の HOOK_LABELS を更新（行 465-466 付近）**

削除:
```bash
    "$STR_HOOKS_PRETTIER"
    "$STR_HOOKS_CONSOLE"
```

追加（配列末尾、`"${STR_HOOKS_ERROR_TO_CODEX:...}"` の後に）:
```bash
    "${STR_HOOKS_HARNESS_INIT:-Harness Init - Detect tech stack and suggest /init-harness}"
    "${STR_HOOKS_PRE_COMMIT_GATE:-Pre-Commit Gate - Run verification before git commit (advisory)}"
    "${STR_HOOKS_POST_TEST_ANALYSIS:-Post-Test Analysis - Analyze test failures (opt-in)}"
```

- [ ] **Step 6: _apply_hooks_csv() を更新（行 493-494 付近）**

削除:
```bash
      prettier)   ENABLE_PRETTIER_HOOKS="true" ;;
      console)    ENABLE_CONSOLE_LOG_GUARD="true" ;;
```

追加:
```bash
      harness-init)         ENABLE_HARNESS_INIT="true" ;;
      pre-commit-gate)      ENABLE_PRE_COMMIT_GATE="true" ;;
      post-test-analysis)   ENABLE_POST_TEST_ANALYSIS="true" ;;
```

- [ ] **Step 7: ShellCheck 検証**

Run: `shellcheck -S warning wizard/wizard.sh`
Expected: エラーなし

- [ ] **Step 8: コミット**

```bash
git add wizard/wizard.sh
git commit -m "refactor: update wizard — remove JS/TS hook flags, add harness feature flags"
```

---

### Task 10: i18n 文字列の更新

**Files:**
- Modify: `i18n/en/strings.sh`
- Modify: `i18n/ja/strings.sh`

- [ ] **Step 1: i18n/en/strings.sh を更新**

削除:
```bash
STR_HOOKS_PRETTIER="Prettier Auto-format - Format JS/TS files after edits"
STR_HOOKS_CONSOLE="Console.log Guard - Warn about console.log statements"
```

追加:
```bash
STR_HOOKS_HARNESS_INIT="Harness Init - Detect tech stack and suggest /init-harness"
STR_HOOKS_PRE_COMMIT_GATE="Pre-Commit Gate - Run verification before git commit (advisory)"
STR_HOOKS_POST_TEST_ANALYSIS="Post-Test Analysis - Analyze test failures (opt-in)"
```

- [ ] **Step 2: i18n/ja/strings.sh を更新**

削除:
```bash
STR_HOOKS_PRETTIER="Prettier 自動フォーマット - JS/TS ファイルを編集後にフォーマット"
STR_HOOKS_CONSOLE="Console.log ガード - console.log の警告"
```

追加:
```bash
STR_HOOKS_HARNESS_INIT="ハーネス初期化 - 技術スタックを検出し /init-harness を提案"
STR_HOOKS_PRE_COMMIT_GATE="コミット前検証ゲート - git commit 前に検証を実行（アドバイザリーモード）"
STR_HOOKS_POST_TEST_ANALYSIS="テスト失敗分析 - テスト失敗時にサマリーを出力（オプトイン）"
```

- [ ] **Step 3: ShellCheck 検証**

Run: `shellcheck -S warning i18n/en/strings.sh i18n/ja/strings.sh`
Expected: エラーなし

- [ ] **Step 4: コミット**

```bash
git add i18n/en/strings.sh i18n/ja/strings.sh
git commit -m "feat: update i18n strings for harness features (en/ja)"
```

---

### Task 11: profiles/standard.conf のデフォルト値更新

**Files:**
- Modify: `profiles/standard.conf`

- [ ] **Step 1: standard.conf を更新**

削除:
```
ENABLE_PRETTIER_HOOKS=true
ENABLE_CONSOLE_LOG_GUARD=true
```

追加（ファイル末尾付近の ENABLE_* セクションに）:
```
ENABLE_HARNESS_INIT=true
ENABLE_PRE_COMMIT_GATE=true
ENABLE_POST_TEST_ANALYSIS=false
```

- [ ] **Step 2: コミット**

```bash
git add profiles/standard.conf
git commit -m "refactor: update standard profile — add harness defaults, remove JS/TS defaults"
```

---

### Task 12: ShellCheck 全体検証とテスト

- [ ] **Step 1: 全シェルスクリプトを ShellCheck で検証**

Run: `shellcheck -S warning setup.sh install.sh uninstall.sh lib/*.sh wizard/wizard.sh`
Expected: エラーなし

- [ ] **Step 2: 新しいフィーチャスクリプトを個別検証**

Run: `shellcheck -S warning features/harness-init/scripts/detect-stack.sh features/pre-commit-gate/scripts/pre-commit-gate.sh features/post-test-analysis/scripts/analyze-test.sh`
Expected: エラーなし

- [ ] **Step 3: 全 JSON ファイルの検証**

Run: `for f in features/*/feature.json features/*/hooks.json commands/templates/*.json config/*.json; do jq . "$f" > /dev/null || echo "INVALID: $f"; done`
Expected: 出力なし（全て有効な JSON）

- [ ] **Step 4: dry-run テスト**

Run: `bash setup.sh --dry-run --non-interactive --language=en`
Expected: エラーなく完了。新フィーチャが設定に含まれていることを確認。

- [ ] **Step 5: 最終コミット（検証パス後のみ）**

```bash
git add -A
git status
# 全変更が含まれていることを確認してからコミット
git commit -m "chore: verify harness design implementation — ShellCheck + dry-run pass"
```
