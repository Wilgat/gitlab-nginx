**file**: docs/requirements/requirement-shell-cli-storage.md  
**Status**: Active (Version 1.0.0 – gitlab-nginx storage wire)  
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth** for **shell CLI storage resolution** of the gitlab-nginx POSIX `/bin/sh` Type 0 bootstrap CLI: volatile scratch and app-scoped cache path selection, per-user isolation, central resolver ownership, `app_main` wire, and about diagnostics.

**Scope:** Resolve priority chain; isolation; `util_resolve_storage` contract; `EFFECTIVE_STORAGE_DIR` / `TMPDIR` export; about human + JSON fields.  
**Out of scope (cited, not re-owned):** Binary install paths (`USER_BIN` / `GLOBAL_BIN`); domain project trees (none on this bootstrap product); companion checksum; PATH shell-rc.

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Single resolver SSOT

1. **MUST** keep **one** authoritative storage-resolve helper: **`util_resolve_storage`**.  
2. New code that needs a product scratch/cache **root** **MUST** call `util_resolve_storage` (or `mktemp` under a path it returned) — **MUST NOT** introduce parallel hard-coded `/tmp/gitlab-nginx` dumps.  
3. Resolver **MUST** print the chosen directory path on **stdout** for `$(util_resolve_storage)` capture (data return — not product UI).  
4. User-visible failure about storage **MUST** use Output SSOT (`out_die` / structured error as mode requires).

### 2.2 Live resolve priority (normative for this product)

First match that is available and writable:

| Order | Condition | Path shape |
|-------|-----------|------------|
| 1 | `/dev/shm` exists and is writable | `/dev/shm/${APP_NAME}-${USERNAME}` |
| 2 | `/tmp` is writable | `/tmp/${APP_NAME}-${USERNAME}` |
| 3 | Fallback | `STORAGE_DIR` (`${XDG_CACHE_HOME}/${APP_NAME}-${USERNAME}`, env-overridable) |

**Create before return:** for the **chosen** tier, the resolver **MUST** `mkdir -p` the root (all tiers), then print the path. If create fails → **MUST** fail closed via `out_die`. **MUST NOT** return a path without creating it.

### 2.3 Isolation

1. Paths **MUST** include **`${APP_NAME}`** and **`${USERNAME}`** (with safe defaults when unset).  
2. **MUST NOT** rewrite the resolver to a single shared world-writable directory for all users.  
3. Live product **MUST** export `TMPDIR=${EFFECTIVE_STORAGE_DIR}` so `mktemp -t` install staging inherits the isolated root.

### 2.4 Wire and diagnostics

| Surface | Requirement |
|---------|-------------|
| `app_main` | Resolve once early: `EFFECTIVE_STORAGE_DIR=$(util_resolve_storage)`; export `EFFECTIVE_STORAGE_DIR`, `STORAGE_DIR`, `TMPDIR` |
| `app_about` JSON | Include `effective_storage` and `storage_dir` (no CHECKSUM) |
| `app_about` human | Show effective storage (and config fallback field) |

### 2.5 Implementation Notes (this project)

| Item | Live value |
|------|------------|
| **Product / binary** | `gitlab-nginx` |
| **Resolver** | `util_resolve_storage` in `./gitlab-nginx` |
| **Config fallback** | `: "${STORAGE_DIR:=${XDG_CACHE_HOME}/${APP_NAME}-${USERNAME}}"` |
| **Call sites** | `app_main` (resolve + TMPDIR); `app_about` (human + JSON) |
| **Not used for** | Domain project trees (bootstrap has none) |
| **Tests** | `tests/test_cli.sh` — about storage fields, isolation, dir exists, STORAGE_DIR override on fallback field |

### 2.6 Why This Requirement Exists (CIAO)

- **Caution:** Multi-user / sudo / containers — never mix users’ scratch.  
- **Intentional:** One resolver; explicit tiers; wired from main.  
- **Anti-fragile:** Missing `/dev/shm` still works via `/tmp` or cache.  
- **Over-protect:** Forbid “simplify” to shared dumps; create fail-closed.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- Volatile first, user cache last for **scratch**.  
- Isolation before convenience.  
- Soft-`mkdir` of the effective root is forbidden; create is fail-closed in the resolver.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Remove `${APP_NAME}` / `${USERNAME}` isolation from `util_resolve_storage`.  
2. Replace the fallback chain with a single shared world-writable path.  
3. Scatter new hard-coded `/tmp/${APP_NAME}` roots outside the resolver.  
4. Leave the resolver as dead code with no call sites while claiming storage is product law.  
5. Echo a tier path **without** creating it (or without fail-closed create).  
6. Bypass Output SSOT for storage failure messages.  
7. Put CHECKSUM in about storage diagnostics.  

**Violating this rule is a critical storage isolation regression.**

---

## 5. Definition of done (shell CLI storage)

Storage resolve work for gitlab-nginx is **not done** if any of the following fail:

1. Exactly one authoritative resolver (`util_resolve_storage`) returns the chosen path on stdout after `mkdir -p` of that root.  
2. Resolve priority matches this requirement (writable `/dev/shm` → `/tmp` → `STORAGE_DIR` fallback).  
3. Paths include `${APP_NAME}` and `${USERNAME}` isolation; no shared world-writable single dump for all users.  
4. `app_main` sets `EFFECTIVE_STORAGE_DIR` / exports `TMPDIR` from the resolver once early.  
5. `app_about` human + JSON expose effective storage fields and **omit** `CHECKSUM`.  
6. User-visible storage failures use Output SSOT (`out_die` / structured error).  
7. Tests cover about storage fields / isolation / override as designed (`tests/test_cli.sh`).  
8. Implementation changes cite this requirement key `requirement-shell-cli-storage`.

---

## 6. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-modular-function-design.md` | `util_*` ownership |
| `docs/requirements/requirement-shell-output-requirements.md` | about JSON via `out_json` |
| `docs/requirements/requirement-shell-self-management.md` | about lifecycle |
| `./gitlab-nginx` | Implementation under test |
| `tests/test_cli.sh` | Storage diagnostics tests |

---

**Last Updated**: 2026-07-19  
**Owner**: gitlab-nginx project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO Principles 1, 2, 3, 4, 5, 11, 19, 20 (v2.10.2) (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
