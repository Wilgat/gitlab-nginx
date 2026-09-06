**file**: docs/requirements/requirement-shell-output-requirements.md  
**Status**: Active (Version 1.0.0)  
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered)

## 1. Purpose

This requirement is the **project Single Source of Truth** for **all CLI output** of the gitlab-nginx POSIX shell tool: human messages, machine JSON, channel split (stdout vs stderr), and mode behavior (normal / quiet / JSON / debug).

It defines the centralized output system and stdout/stderr channel contracts for this shell project.

**Scope:** Central `out_*` system, mode contracts, channel rules, JSON purity, quiet filtering, TTY colors, fatal error emission.  
**Out of scope (cited, not re-owned):** Command catalog (`requirement-shell-cli-interface.md`); self-management semantics; modular prefix table (except that output owns `out_*`); interactive prompt logic beyond prompt output hooks.

### 1.1 Human-facing

**In one sentence:** Everything this program says to you (or to a script) goes through one printer: human lines, JSON, quiet, and errors — not scattered `echo`.

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | You read `[INFO]` / `[ERROR]` or `--json` objects | `gitlab-nginx --json version` |
| The other role | Automation parses JSON on stdout; errors still appear | CI |
| Not this file | Command names; checksum algorithm | peer requirements |

| Includes | Excludes |
|----------|----------|
| `out_info` / `out_die` / `out_json` | Raw `echo` for product messages |
| Quiet hides chatter, not fatals | A second print helper |

| Surface | What you open | What for |
|---------|---------------|----------|
| `gitlab-nginx --json about` | command | machine object |
| `gitlab-nginx help` | command | human usage |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Script against the CLI | `--json` implies quiet; stdout is structured; fatals still fail closed. | `gitlab-nginx --json version` |

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Sacred core rule

**All user-facing and machine-facing product output MUST go through the centralized output system.**

| Forbidden outside the output module | Prefer |
|-------------------------------------|--------|
| Raw `echo` / bare `printf` for **user messages** | `out_info`, `out_success`, `out_warn`, `out_error`, `out_plain`, … |
| Direct `printf` of JSON from command logic | `out_json` / `out_json_error` |
| Ad-hoc `echo >&2` diagnostics | `out_warn` / `out_error` / `out_debug` |
| Second parallel “print helper” that bypasses mode guards | Extend `out_text` / wrappers only |

**Not every `printf` / `echo` is a violation.** The ban targets **product messaging** (what the CLI user or machine consumer sees as the command’s message/JSON). The following exceptions are **allowed** and intentional in this project (aligned with live `./gitlab-nginx` practice and §2.1.1 below).

### 2.1.1 Allowed `printf` / `echo` exceptions (this project)

| Exception class | Rule | Live examples in `./gitlab-nginx` |
|-----------------|------|-----------------------------------|
| **A. Inside output SSOT** | Only `out_text`, `out_json`, and `out_json_error` may `printf` to fd 1/2 for **product** human or JSON lines. Nested `printf … \| sed` used only to escape strings for those emitters is part of the same SSOT. | `out_text` level cases; `out_json` / `out_json_error` body builders |
| **B. Function return-via-stdout** | A helper may `printf '%s' "$value"` (or `echo "$value"`) **solely** so callers capture it with `$(…)`. That write is a **data return**, not product UI. Callers must capture it; bare top-level invocation must not be used as the user-facing message path. | `inst_self_uninstall_determine_bin`, `util_get_install_bin_path`, `inst_get_version`, `util_resolve_storage`, `util_preferred_cache_dir`, `util_fallback_cache_dir`, `util_persistent_storage_dir`, `util_resolve_persistent_storage`, `util_get_current_shell`, `prompt_ask` (answer/default return only; prompt text still via `out_*`) |
| **C. File I/O (redirected)** | `printf … >> "$file"` that appends config/content to a path is file mutation, not product stdout/stderr messaging. User-visible “what changed” lines still go through `out_*`. | `path_add_bashrc`, `path_add_zshrc`, `path_add_fish` |
| **D. Tool protocol / computation pipes** | `printf` feeding another program (checksum verify, filters) with product status still reported via `out_*`. | `inst_perform_install_download_with_checksum` → `printf … \| sha256sum -c` |
| **E. Command-sub fallbacks** | `cmd \|\| echo "unknown"` (or similar) assigned into a variable for logic only. | `USERNAME="$(id -un … \|\| echo "unknown")"`, remote version empty fallbacks, boolean strings built for `out_json` fields |

**Still forbidden:** product banners, install progress, errors, or JSON results via raw print outside classes A–E; using return-via-stdout as a substitute for `out_info` / `out_plain`; writing user text to the terminal while claiming “it is only a return value.”

### 2.2 Output function catalog (portable)

| Function | Purpose | Typical channel | Quiet | JSON |
|----------|---------|-----------------|-------|------|
| `out_text` | **SSOT** for human levels | Level-dependent | Filters | Suppress all human levels |
| `out_info` | Informational | stdout | Suppress | Suppress human; use JSON APIs for data |
| `out_success` | Success / OK | stdout | Suppress | Suppress human |
| `out_warn` | Warning | stderr | **Should still show** (see Implementation Notes if code differs) | Suppress human; prefer structured error/status as designed |
| `out_error` | Error | stderr | **Always show** (human) | Prefer `out_json_error` / `out_die` for structure |
| `out_die` | Fatal error + exit 1 | stderr (+ JSON error when JSON) | Always | Emits JSON error then exits |
| `out_plain` | Plain text, no prefix | stdout | Suppress under quiet | Suppress under JSON |
| `out_msg_n` | Prompt fragment without newline | stdout | Suppress under quiet/json | Never for machines |
| `out_empty_line` / `out_double_line` | Visual separators | stdout | Suppress under quiet | Suppress under JSON |
| `out_json` | Machine success/status object | stdout | N/A (JSON path) | Only when `JSON=1` |
| `out_json_error` | Machine error object | via JSON emitter (stderr when fatal path uses it as designed) | N/A | Only when `JSON=1` |

All convenience wrappers **MUST** delegate to the central human (`out_text`) or JSON (`out_json`) SSOT — no independent print logic in wrappers beyond argument shaping.

### 2.3 Channel contract (stdout vs stderr)

Align with SSOT-of-stdout and SSOT-of-stderr terms:

| Channel | Allowed content (via `out_*` only) |
|---------|-------------------------------------|
| **stdout (fd 1)** | Human info/success/plain **payload** in normal mode; **exactly one** JSON value in JSON mode for success/status results |
| **stderr (fd 2)** | Errors, warnings, and debug/diagnostics |

**Rules:**

1. **Errors never as the primary success payload on stdout** in a way that corrupts JSON pipes — fatal paths use `out_die` / `out_json_error`.  
2. **JSON purity:** In JSON mode, stdout is reserved for the structured result; no colors, banners, or progress mixed in.  
3. **Capture pattern for agents/CI:**  
   `gitlab-nginx --json <cmd> 2>err.log` → stdout = JSON; stderr = diagnostics as mode allows.  
4. **No secrets** on either channel (tokens, passwords, private keys).

### 2.4 Mode behavior (portable)

#### 2.4.1 Normal (human) mode

- Full human-readable messages with level prefixes (`[INFO]`, `[OK]`, `[WARN]`, `[ERROR]`).  
- Colors **only** when TTY is detected **and** not quiet **and** not JSON.  
- Primary success/info on stdout; warn/error on stderr.

#### 2.4.2 Quiet mode (`--quiet` / `-q` or `QUIET=1`)

- Suppress informational, success, and plain chatter.  
- **MUST** still surface errors (and **SHOULD** surface warnings).  
- Does not by itself enable JSON.

#### 2.4.3 JSON mode (`--json` or `JSON=1`)

- **MUST force quiet** for human chatter (`QUIET=1` when flag parsed).  
- Human `out_text` path **MUST** no-op for all human levels.  
- Success/status **MUST** use `out_json` (or equivalent structured emitter).  
- Failures **MUST** use `out_json_error` / `out_die` so machines get a structured error.  
- **MUST NOT** emit multiple competing human lines interleaved with JSON on stdout.  
- Prefer **one** primary JSON object per successful command invocation (additional JSON only if a specialized command explicitly documents a multi-emit protocol — default is single primary object).

#### 2.4.4 Debug mode (`--debug` or `DEBUG=1`)

- Extra diagnostics **MUST** go through the output system (or a dedicated `out_debug` when added) on **stderr**.  
- Debug **MUST NOT** pollute stdout.  
- Under JSON mode, debug **MUST** be suppressed or redirected so JSON stdout purity holds.

### 2.5 Implementation guidelines (portable)

1. Centralize color, quiet filtering, and JSON gating in the output module.  
2. Detect TTY once at startup (or via documented SSOT flags); do not scatter `test -t` for coloring.  
3. Escape JSON string fields safely (no raw unescaped quotes).  
4. Interactive prompts use `out_msg_n` / `prompt_*` and **MUST** not hang or print prompts in quiet/json/non-interactive paths.  
5. Command logic selects **what** to say; `out_*` decides **whether**, **where**, and **how**.

### 2.6 Implementation Notes (this project)

| Item | Value for gitlab-nginx |
|------|------------------------|
| **Product / binary** | `gitlab-nginx` (`APP_NAME`) |
| **Implementation file** | Repo root `./gitlab-nginx` |
| **Human SSOT** | `out_text` |
| **JSON SSOT** | `out_json` / `out_json_error` |
| **Mode flags** | `QUIET`, `JSON`, `DEBUG`, `TTY` (defaults `0` except TTY when stdin/stdout are TTYs) |
| **Flag wiring** | `app_main`: `--quiet`/`-q` → `QUIET=1`; `--json` → `JSON=1` and `QUIET=1`; `--debug` → `DEBUG=1` |
| **Color** | ANSI only when `TTY=1` and quiet/json off, inside `out_text` |
| **Domain** | No separate product logger; lifecycle commands use the same `out_*` |

#### Live `out_*` inventory

| Function | Role in `./gitlab-nginx` |
|----------|-------------------------|
| `out_text` | Human SSOT; JSON short-circuit; quiet filter; channel by level |
| `out_success` / `out_info` / `out_warn` / `out_error` | Level wrappers |
| `out_die` | `out_json_error` then `out_error` then `exit 1` |
| `out_plain` / `out_msg_n` | Plain / prompt fragment |
| `out_empty_line` / `out_double_line` | Separators |
| `out_json` | Structured success/status when `JSON=1` |
| `out_json_error` | Structured error object (`type` + `message` + `code`) |

#### Channel map (this project, current `out_text`)

| Level | fd | Prefix |
|-------|-----|--------|
| `out_error` | stderr | `[ERROR]` |
| `out_warn` | stderr | `[WARN]` |
| `out_info` | stdout | `[INFO]` |
| `out_success` | stdout | `[OK]` |
| `plain` / `plain_n` | stdout | (none) |

#### JSON object shape (this project)

`out_json` optional **raw nested JSON**: key prefixed with `@` (e.g. `@items`) inserts the value unquoted as JSON array/object. Default keys remain string-escaped.

`out_json` emits a single-line object:

- Required: `"type":"<type>"`  
- Optional: `"message":"..."` (escaped)  
- Optional key/value pairs: alternating arguments after type/message  

`out_json_error` uses `type=out_error`, message, and `code` (default `unknown`).

#### Normative acceptance behaviors (this project)

1. With `--json`, human install/about banners **must not** appear on stdout.  
2. With `--json`, successful `version` / `about` / `version-check` / install success paths emit structured JSON via `out_json`.  
3. Fatal unknown command uses `out_die` (structured error in JSON mode).  
4. Quiet mode suppresses info/success/plain; errors still visible on stderr.  
5. No new command may introduce raw `echo`/`printf` for **product user/machine messages** outside `out_*` (exceptions §2.1.1 only: SSOT internals, return-via-stdout, file I/O, tool pipes, command-sub fallbacks).

#### Compliance notes (implementation status)

| Item | Status |
|------|--------|
| Quiet keeps `out_warn` + `out_error` on stderr | **Implemented** in `out_text` (2026-07-12) |
| JSON errors on stderr via `out_json_error` | **Implemented** (stdout remains success/status JSON only) |
| `out_debug` on stderr when `DEBUG=1`, suppressed under JSON | **Implemented** |
| Command paths use human **or** JSON via mode flags | **Enforced** (`out_text` no-ops when `JSON=1`) |

### 2.7 Why This Requirement Exists (Direct CIAO Alignment)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Prevent output pollution that breaks pipes, CI, and automation.  
- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Explicit split of human vs JSON and stdout vs stderr.  
- **CIAO Principle 3 – Anti-fragile** (https://github.com/cloudgen/ciao): Works in TTY, `curl \| sh`, quiet, and JSON environments.  
- **CIAO Principle 5 – Single Source of Output** (https://github.com/cloudgen/ciao): One `out_text` / `out_json` authority.  
- **CIAO Principle 14 – Security & Traceability** (https://github.com/cloudgen/ciao): Separate user-facing payload from diagnostics; support ERROR/WARN/INFO/DEBUG discipline.  
- **CIAO Principle 4 (O) / Principle 20 – Over-protect / Protect Against AI & Human Modification** (https://github.com/cloudgen/ciao): JSON-forces-quiet and no-raw-print rules are sacred.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- **Caution:** Never assume raw prints are “just temporary.”  
- **Intentional:** Level name documents severity; channel documents consumer.  
- **Anti-fragile:** Mode flags at top; every message path respects them.  
- **Over-protect:** Do not “simplify” by inlining product `printf` in install/update helpers; keep legitimate return/file/pipe uses clearly scoped.  
- **SSOT:** Human → `out_text`; machine → `out_json*`; dispatch sets flags once in `app_main`.  
- **Pair with modular design:** Only `out_*` prefix owns emission (`requirement-shell-modular-function-design.md`).  
- **Pair with CLI interface:** Flag meanings stay aligned with `requirement-shell-cli-interface.md`.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Add raw `echo`, `printf`, or direct fd writes for **product** user/machine messages outside the central output functions (do not “ban” legitimate §2.1.1 exceptions).  
2. Misuse return-via-stdout, file redirects, or tool pipes as cover for user-facing banners without `out_*`.  
3. Cite `template-*.md` or `skill-*.md` in **product source** (`./gitlab-nginx`) as output authority — cite this requirement file only.  
4. Bypass `out_*` for “quick debug” on stdout.  
5. Remove or weaken **`--json` forces quiet** / human-suppression in `out_text`.  
6. Emit human banners on stdout while claiming JSON mode.  
7. Put errors on stdout as the success channel in a way that breaks `cmd --json > out.json`.  
8. Remove TTY detection / color gating without strong justification and requirement update.  
9. Dump secrets, tokens, or private keys into any output channel.  
10. Simplify away `out_json` escaping or the central quiet/json guards “for cleanliness.”  
11. Create a second logging framework that competes with `out_*`.

**Single Source of Output is non-negotiable for CIAO compliance on this shell CLI.**  
**Not every `printf` is forbidden — only product messaging that bypasses the SSOT (see §2.1.1).**

---

## 5. Definition of done (shell output requirements)

Output-related work for gitlab-nginx is **not done** if any of the following fail:

1. All new **product** user-facing messages use `out_*` only (exceptions limited to §2.1.1).  
2. Non-product `printf`/`echo` sites document their exception class in the function comment block when they are intentional helpers.  
3. `--json` implies quiet human suppression and structured JSON for supported commands.  
4. Errors remain usable under quiet (stderr).  
5. JSON success path does not mix human lines on stdout.  
6. Colors only when TTY and not quiet/json.  
7. Fatal paths use `out_die` / structured JSON error when JSON mode is on.  
8. Known channel/quiet gaps above are fixed or explicitly re-justified in this requirement.  
9. Changes cite `requirement-shell-output-requirements`.

---

## 6. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/requirement-shell-cli-interface.md` | Flag wiring and command surface |
| `docs/requirements/requirement-shell-modular-function-design.md` | `out_*` prefix ownership |
| `docs/requirements/requirement-shell-interactive-vs-noninteractive.md` | Mode interaction with quiet/json |
| `docs/requirements/index.md` | Registry SSOT |
| `./gitlab-nginx` | Implementation under test |

---

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-02** | `tests/test_cli.sh` | have |
| **TP-CLI-04** | `tests/test_cli.sh` | have |
| **TP-CLI-07** | `tests/test_cli.sh` | have |

**Map:** `reviews/test-plan.md`.

**Last Updated**: 2026-09-06  
**Owner**: gitlab-nginx project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO Principles 1, 2, 3, 5, 14, 4, 20 (v2.10.2) (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
