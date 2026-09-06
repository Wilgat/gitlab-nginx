**file**: docs/requirements/requirement-shell-cli-storage.md  
**Status**: Active (Version 1.1.0 – cache folder **and** persistence folder)  
**Philosophy**: CIAO / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth** for **shell CLI storage** of the gitlab-nginx POSIX `/bin/sh` CLI. **Storage** means **two** classes:

| Class | Role | Live path shape (this product) |
|-------|------|--------------------------------|
| **Cache folder** | Volatile scratch / temps / install staging | Preferred `/dev/shm/${APP_NAME}-${USERNAME}`; then `/tmp/${APP_NAME}-${USERNAME}`; fallback `STORAGE_DIR` (`${XDG_CACHE_HOME}/${APP_NAME}-${USERNAME}`) |
| **Persistence folder** | Durable per-user app data for this CLI | `${HOME}/.local/${APP_NAME}` |

It owns path **shapes**, central resolvers, `app_main` wire, and about diagnostics for **both** classes.

**Scope:** Cache resolve priority; persistence folder contract; isolation; `util_resolve_storage` / `util_resolve_persistent_storage`; `EFFECTIVE_STORAGE_DIR` / `PERSISTENT_STORAGE_DIR` / `TMPDIR` export; about human + JSON fields.  
**Out of scope (cited, not re-owned):** Binary install paths (`USER_BIN` / `GLOBAL_BIN` — `${HOME}/.local/bin` is **not** the persistence folder); domain host trees (`/etc/letsencrypt/*` — `requirement-domain-gitlab-nginx`); companion checksum; PATH shell-rc.

### 1.1 Human-facing

**In one sentence:** You run `gitlab-nginx about` as yourself and see **two** folders: a **cache folder** (throw-away scratch) and a **persistence folder** (durable data under `${HOME}/.local/gitlab-nginx`).

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Your cache and persistence folders are keyed to this app and this login | `gitlab-nginx about` |
| The other role | Another login on the same host must not share your cache dump | Isolated `${APP_NAME}-${USERNAME}` cache leaves |
| Not this file | Domain saved domains/email live under Let's Encrypt, not in this CLI's persistence folder | `requirement-domain-gitlab-nginx` |

| Includes | Excludes |
|----------|----------|
| Cache folder (preferred / fallback) and persistence folder on `about` | Treating `${HOME}/.local/bin` as persistence |
| Create-before-return for both roots | Domain `/etc/letsencrypt/*` files |
| `TMPDIR` inherited from the **cache** root | A system `/var/…` deposit as this CLI's persistence |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./gitlab-nginx` | program file people install | live resolvers |
| `gitlab-nginx about` | command | cache folder + persistence folder lines |
| `gitlab-nginx --json about` | command | `cache_preferred` / `cache_fallback` / `persistence_storage` / `effective_storage` |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Inspect folders | Human mode names **Cache folder (preferred)**, **Cache folder (fallback)**, and **Persistence folder**. JSON carries the same facts. Directories exist after resolve. | `gitlab-nginx about` |

## Under command line for normal user only

When this program runs on Termux, Git Bash, Windows Command Prompt, or the same class: **admin privilege** and **dedicated system user privilege** are unused. Do not wrap `sudo`, do not wrap Linux `apt`/`dnf`, do not create dedicated system users, and do not recommend `sudo curl | sh`. Git Bash and Windows cmd must not invoke Termux `pkg`.

**This requirement:** cache and persistence folders still resolve under this login (`/dev/shm`, `/tmp`, or `${HOME}/.local/gitlab-nginx`). No `/var` deposit.

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Storage is two classes

1. **MUST** treat **storage** as **cache folder** **and** **persistence folder** — never cache-only.  
2. **MUST NOT** store scratch/temps in the persistence folder when a cache root is available.  
3. **MUST NOT** use the persistence folder as `USER_BIN` (`${HOME}/.local/bin`).  
4. **MUST NOT** use a Type 1 `/var/…` deposit as this CLI's persistence folder.  
5. **MUST NOT** use `${HOME}/.local/share/${APP_NAME}` as this product's persistence shape.  
6. Domain durable files under `/etc/letsencrypt/` **MUST** stay on `requirement-domain-gitlab-nginx` — **MUST NOT** be relocated into `${HOME}/.local/${APP_NAME}`.

### 2.2 Cache resolver SSOT

1. **MUST** keep **one** authoritative **cache** resolver: **`util_resolve_storage`**.  
2. New code that needs a product scratch/cache **root** **MUST** call `util_resolve_storage` (or `mktemp` under a path it returned) — **MUST NOT** introduce parallel hard-coded `/tmp/gitlab-nginx` dumps.  
3. Cache resolver **MUST** print the chosen directory path on **stdout** for `$(util_resolve_storage)` capture (data return — not product UI).  
4. Helpers **`util_preferred_cache_dir`** and **`util_fallback_cache_dir`** **MUST** print the preferred and fallback cache **shapes** (data return).  
5. User-visible failure about storage **MUST** use Output SSOT (`out_die` / structured error as mode requires).

### 2.3 Live cache resolve priority (normative for this product)

First match that is available and writable:

| Order | Condition | Path shape |
|-------|-----------|------------|
| 1 | `/dev/shm` exists and is writable | `/dev/shm/${APP_NAME}-${USERNAME}` |
| 2 | `/tmp` is writable | `/tmp/${APP_NAME}-${USERNAME}` |
| 3 | Fallback | `STORAGE_DIR` (`${XDG_CACHE_HOME}/${APP_NAME}-${USERNAME}`, env-overridable) |

**Create before return:** for the **chosen** cache tier, the resolver **MUST** `mkdir -p` the root, then print the path. If create fails → **MUST** fail closed via `out_die`. **MUST NOT** return a path without creating it.

### 2.4 Persistence folder (normative)

1. Persistence folder **MUST** be **`${HOME}/.local/${APP_NAME}`** (this product: `${HOME}/.local/gitlab-nginx`).  
2. Helper **`util_persistent_storage_dir`** **MUST** print that path. **`util_resolve_persistent_storage`** **MUST** `mkdir -p` it, confirm it is writable, then print it (fail closed).  
3. Resolve **MUST** refuse if the computed path is `${HOME}/.local/bin` (install bin, not persistence).  
4. Persistence resolve is a **data return** on stdout (`$(util_resolve_persistent_storage)`).

### 2.5 Isolation

1. Cache paths **MUST** include **`${APP_NAME}`** and **`${USERNAME}`** (with safe defaults when unset).  
2. Persistence path **MUST** include **`${APP_NAME}`** under the invoking user's `${HOME}`.  
3. **MUST NOT** rewrite either resolver to a single shared world-writable directory for all users.  
4. Live product **MUST** export `TMPDIR=${EFFECTIVE_STORAGE_DIR}` so `mktemp -t` install staging inherits the isolated **cache** root (not the persistence folder).

### 2.6 Wire and diagnostics

| Surface | Requirement |
|---------|-------------|
| `app_main` | Resolve once early: `EFFECTIVE_STORAGE_DIR=$(util_resolve_storage)`; `PERSISTENT_STORAGE_DIR=$(util_resolve_persistent_storage)`; export both plus config fallback `STORAGE_DIR`; **`TMPDIR=${EFFECTIVE_STORAGE_DIR}`** so temps inherit **cache** isolation |
| `app_about` JSON | Include `cache_preferred`, `cache_fallback`, `persistence_storage`, live chosen cache `effective_storage`, and config `storage_dir` (no CHECKSUM) |
| `app_about` human | **Cache folder (preferred):** `/dev/shm/${APP_NAME}-${USERNAME}` · **Cache folder (fallback):** XDG `${APP_NAME}-${USERNAME}` · **Persistence folder:** `${HOME}/.local/${APP_NAME}`. **MUST NOT** label cache lines Storage (effective)/(fallback) only |

### 2.7 Implementation Notes (this project)

| Item | Live value |
|------|------------|
| **Product / binary** | `gitlab-nginx` |
| **Cache resolver** | `util_resolve_storage` in `./gitlab-nginx` |
| **Preferred cache helper** | `util_preferred_cache_dir` → `/dev/shm/${APP_NAME}-${USERNAME}` |
| **Fallback cache helper** | `util_fallback_cache_dir` → `${XDG_CACHE_HOME}/${APP_NAME}-${USERNAME}` |
| **Config fallback `STORAGE_DIR`** | `: "${STORAGE_DIR:=${XDG_CACHE_HOME}/${APP_NAME}-${USERNAME}}"` |
| **Persistence path** | `${HOME}/.local/gitlab-nginx` |
| **Persistence helpers** | `util_persistent_storage_dir` (print); `util_resolve_persistent_storage` (create-before-return) |
| **Call sites** | `app_main` (cache + persistence resolve, `TMPDIR` from cache); `app_about` (human + JSON) |
| **Not used for** | Domain Let's Encrypt files; CLI binary placement (`USER_BIN` / `GLOBAL_BIN`) |
| **Tests** | `tests/test_cli.sh` — about cache + persistence fields, isolation, dirs exist, `STORAGE_DIR` override on fallback field |

### 2.8 Why This Requirement Exists (CIAO)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Multi-user / sudo / containers — never mix users' scratch; never treat install-bin as data.  
- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Storage = cache folder **and** persistence folder; about says both.  
- **CIAO Principle 3 – Anti-fragile** (https://github.com/cloudgen/ciao): Missing `/dev/shm` still works via `/tmp` or cache fallback; persistence is independent of volatile mounts.  
- **CIAO Principle 4 (O) / Principle 20** (https://github.com/cloudgen/ciao): Forbid “simplify” to shared dumps; create fail-closed; keep persistence on `about`.  
- **CIAO Principle 11 – Safe Temporary File Handling** (https://github.com/cloudgen/ciao): `TMPDIR` from the **cache** root.  
- **CIAO Principle 17 / 19 – Defensive storage** (https://github.com/cloudgen/ciao): Durable data has an explicit persistence folder, not an implied cache leaf.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- Volatile first, user cache last for **scratch**.  
- Persistence folder is `${HOME}/.local/${APP_NAME}`, not under `bin` or `/var`.  
- Isolation before convenience.  
- Soft-`mkdir` of the effective cache or persistence root is forbidden; create is fail-closed in the resolvers.  
- About names **Cache folder** and **Persistence folder** — not a single “Storage” line.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Remove `${APP_NAME}` / `${USERNAME}` isolation from `util_resolve_storage`.  
2. Replace the cache fallback chain with a single shared world-writable path.  
3. Scatter new hard-coded `/tmp/${APP_NAME}` roots outside the cache resolver.  
4. Leave the resolvers as dead code with no call sites while claiming storage is product law.  
5. Echo a cache or persistence path **without** creating it (or without fail-closed create).  
6. Bypass Output SSOT for storage failure messages.  
7. Put CHECKSUM in about storage diagnostics.  
8. Drop the persistence folder from this requirement or from `about`. Persistence **MUST** be `${HOME}/.local/${APP_NAME}` — **MUST NOT** `${HOME}/.local/bin` or a Type 1 `/var/…` deposit.  
9. Label about cache lines **Storage (effective)** / **Storage (fallback)** instead of **Cache folder (preferred)** / **Cache folder (fallback)**.  
10. Relocate domain `/etc/letsencrypt/*` files into the Type 0 persistence folder, or store scratch in persistence when a cache root exists.

**Violating this rule is a critical storage isolation regression.**

---

## 5. Definition of done (shell CLI storage)

Storage work for gitlab-nginx is **not done** if any of the following fail:

1. Cache resolver (`util_resolve_storage`) returns the chosen path on stdout after `mkdir -p` of that root.  
2. Cache resolve priority matches this requirement (writable `/dev/shm` → `/tmp` → `STORAGE_DIR` fallback).  
3. Persistence resolver (`util_resolve_persistent_storage`) creates and returns `${HOME}/.local/${APP_NAME}`.  
4. Cache paths include `${APP_NAME}` and `${USERNAME}` isolation; no shared world-writable single dump for all users.  
5. `app_main` sets `EFFECTIVE_STORAGE_DIR` and `PERSISTENT_STORAGE_DIR`; exports `TMPDIR` from the **cache** resolver once early.  
6. `app_about` human shows **Cache folder (preferred)/(fallback)** and **Persistence folder**; JSON includes `cache_preferred`, `cache_fallback`, `persistence_storage`, `effective_storage`; **omit** `CHECKSUM`.  
7. User-visible storage failures use Output SSOT (`out_die` / structured error).  
8. Tests cover about cache + persistence fields / isolation / override as designed (`tests/test_cli.sh`).  
9. Implementation changes cite this requirement key `requirement-shell-cli-storage`.

---

## 6. Related artifacts

| Artifact | Role |
|----------|------|
| `docs/requirements/index.md` | Registry SSOT |
| `docs/requirements/requirement-shell-modular-function-design.md` | `util_*` ownership |
| `docs/requirements/requirement-shell-output-requirements.md` | about JSON via `out_json` |
| `docs/requirements/requirement-shell-self-management.md` | about lifecycle |
| `docs/requirements/requirement-domain-gitlab-nginx.md` | Domain host persistence (`/etc/letsencrypt/*`) — not this folder |
| `./gitlab-nginx` | Implementation under test |
| `tests/test_cli.sh` | Cache + persistence diagnostics tests |
| `reviews/test-plan.md` | TP-CLI-04 / TP-CLI-05 |

## Design-time verification

| TP family / ID | Suite | Status |
|----------------|-------|--------|
| **TP-CLI-04** | `tests/test_cli.sh` | have |
| **TP-CLI-05** | `tests/test_cli.sh` | have |

**Map:** `reviews/test-plan.md`.

**Last Updated**: 2026-09-06  
**Owner**: gitlab-nginx project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO Principles 1, 2, 3, 4, 5, 11, 17, 19, 20 (v2.10.2) (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
