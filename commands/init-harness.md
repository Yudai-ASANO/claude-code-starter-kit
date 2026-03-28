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
