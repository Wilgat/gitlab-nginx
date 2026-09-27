**file**: docs/requirements/requirement-shell-cli-storage.md  
**Status**: Active (Version 1.2.0 – per-login per-process cache folder **and** persistence storage)  
**Area**: shell  
**Key**: `requirement-shell-cli-storage`  
**Philosophy**: CIAO **v2.10.2** / CIAO-Lite (Caution • Intentional • Anti-fragile • Over-engineered / Over-protect)

## 1. Purpose

This requirement is the **project Single Source of Truth** for **shell CLI storage** of the gitlab-nginx POSIX `/bin/sh` CLI. **Storage** means **two** classes:

| Class | Role | Survives reboot |
|-------|------|-----------------|
| **Cache folder** | Volatile scratch / temps / install staging | No (shm/tmp) or maybe (home fallback) |
| **Persistence storage** | Durable per-user app data for this CLI | Yes (under this login’s `$HOME`) |

It owns path **shapes**, central resolvers, `app_main` wire, and about diagnostics for both classes.

The preferred cache is **not** a ram-drive **project** tree (`/dev/shm/${APP_NAME}` or `/dev/shm/${APP_NAME}-${USERNAME}`). It lives under `/dev/shm/cache/` (Linux) or `/tmp/cache/` (Git Bash and Mac). The leaf is **per login and per process** so two logins never share one cache directory.

**Out of scope (cited, not re-owned):** Binary install paths (`USER_BIN` / `GLOBAL_BIN` — `${HOME}/.local/bin` is **not** persistence storage); domain host trees (`/etc/letsencrypt/*` — `requirement-domain-gitlab-nginx`); companion checksum; PATH shell-rc.

### 1.1 Human-facing

**In one sentence:** You run `gitlab-nginx about` as yourself and see a **cache folder** (throw-away scratch for this login and this process) and **persistence storage** (durable data under `${HOME}/.local/gitlab-nginx`).

| Box | Meaning | Example |
|-----|---------|---------|
| You / this login | Your cache leaf includes this login on volatile tiers, and this process id on every tier | `gitlab-nginx about` |
| The other role | Another login on the same host must not share your cache leaf | Volatile leaf `cache-${APP_NAME}-${login}-$$` |
| Not this file | Domain saved domains/email live under Let's Encrypt, not in this CLI's persistence storage | `requirement-domain-gitlab-nginx` |

| Includes | Excludes |
|----------|----------|
| Cache folder used / preferred / 1st fallback / 2nd fallback (when this host has one) and persistence storage on `about` | Treating `${HOME}/.local/bin` as persistence |
| Create-before-return for the chosen cache tier and for persistence | Domain `/etc/letsencrypt/*` files |
| `TMPDIR` inherited from the **cache** root | A system `/var/…` deposit as this CLI's persistence |
| A skipped cache tier is silent | A warning or error only because a higher tier was not used |

| Surface | What you open | What for |
|---------|---------------|----------|
| `./gitlab-nginx` | program file people install | live resolvers |
| `gitlab-nginx about` | command | cache folder + persistence storage lines |
| `gitlab-nginx --json about` | command | `cache_used` / `cache_preferred` / `cache_fallback` / `cache_fallback_2` / `persistence_storage` / `effective_storage` |

| You do… | What it means | What you type |
|---------|---------------|---------------|
| Inspect storage | about shows **Cache folder used**, **preferred**, **1st fallback**, **2nd fallback** when this host has one, and **Persistence storage**. A skipped tier prints nothing. Directories exist after resolve. | `gitlab-nginx about` |

## Under command line for normal user only

When this program runs on Termux, Git Bash, Windows Command Prompt, or the same class: **admin privilege** and **dedicated system user privilege** are unused. Do not wrap `sudo`, do not wrap Linux `apt`/`dnf`, do not create dedicated system users, and do not recommend `sudo curl | sh`. Git Bash and Windows cmd must not invoke Termux `pkg`.

**This requirement:** cache and persistence stay under this login. No `/var` deposit. Termux uses the **Linux** chain. On Termux the chosen cache folder is scratch only (it may be `noexec`).

---

## 2. Core Rules / Requirements (Mandatory)

### 2.1 Two storage classes

Volatile leaf (shared parents `/dev/shm` and `/tmp`): `cache-${APP_NAME}-${login}-$$`.  
Home leaf (already per login): `cache-${APP_NAME}-$$`.  
`$$` is **this process id**. `${login}` is `id -un` as one path segment. **MUST NOT** hardcode either.

| Host | Preferred | 1st fallback | 2nd fallback |
|------|-----------|--------------|--------------|
| Linux (and Termux, and any host that is not Git Bash or Mac) | `/dev/shm/cache/cache-${APP_NAME}-${login}-$$` | `/tmp/cache/cache-${APP_NAME}-${login}-$$` | `${HOME}/.cache/cache-${APP_NAME}-$$` |
| Git Bash (`MSYSTEM`, or `uname -s` `MINGW*` / `MSYS*`) | `/tmp/cache/cache-${APP_NAME}-${login}-$$` | `${HOME}/AppData/Local/Temp/cache-${APP_NAME}-$$` | none |
| Mac (`uname -s` `Darwin`) | `/tmp/cache/cache-${APP_NAME}-${login}-$$` | `${HOME}/Library/Caches/cache-${APP_NAME}-$$` | `${HOME}/cache/cache-${APP_NAME}-$$` |

| Class | Helper |
|-------|--------|
| Cache folder (preferred) | `util_preferred_cache_dir` |
| Cache folder (1st fallback) | `util_fallback_cache_dir` |
| Cache folder (2nd fallback) | `util_fallback2_cache_dir` (empty on Git Bash) |
| Persistence storage | `util_persistent_storage_dir` → `${HOME}/.local/${APP_NAME}` |

Live chosen **cache** root: `util_resolve_storage` (stdout).  
Live **persistence** root: `util_resolve_persistent_storage` (stdout; create-before-return).

**Silent fallback.** Choosing a later tier **MUST NOT** print a warning or an error. **MUST NOT** say that a fallback happened. An error is allowed only when **every** tier for this host failed to be created.

**MUST NOT** mix these with:

| Forbidden as this product’s storage | Why |
|-------------------------------------|-----|
| `${HOME}/.local/bin` / `USER_BIN` | Install binary dir |
| A Type 1 `/var/…` deposit | Not this CLI's persistence |
| `/dev/shm/${APP_NAME}` or `/dev/shm/${APP_NAME}-${USERNAME}` | Looks like a ram-drive project folder |
| `${HOME}/.local/share/${APP_NAME}` | Not this product’s persistence shape |
| One shared `cache-${APP_NAME}` leaf, or `XDG_CACHE_HOME` / `STORAGE_DIR` as the chain | Logins must not share one directory |

Domain durable files under `/etc/letsencrypt/` **MUST** stay on `requirement-domain-gitlab-nginx`. **MUST NOT** be relocated into `${HOME}/.local/${APP_NAME}`.

### 2.2 Single cache resolver SSOT

1. **MUST** keep **one** authoritative cache resolver: **`util_resolve_storage`**.  
2. New code that needs a product scratch/cache **root** **MUST** call `util_resolve_storage` (or `mktemp` / `util_mktemp` under a path it returned). **MUST NOT** introduce parallel hard-coded `/tmp/gitlab-nginx` dumps.  
3. Resolver **MUST** print the chosen directory path on **stdout** for `$(util_resolve_storage)` capture.  
4. User-visible failure about cache **MUST** use Output SSOT.

Preferred, 1st fallback, and 2nd fallback **path shapes** **MUST** be `util_preferred_cache_dir`, `util_fallback_cache_dir`, and `util_fallback2_cache_dir`.

### 2.3 Live cache resolve priority

Walk this host’s chain in order. First directory that can be created **and** is writable wins. The chain is the table in §2.1. **MUST NOT** replace that chain with one shared `cache-${APP_NAME}` leaf or with `XDG_CACHE_HOME`.

**Parent:** for `/dev/shm/cache` and `/tmp/cache` the resolver **MUST** create that parent (prefer mode **1777** when creating) so each login can add its own `cache-${APP_NAME}-${login}-$$` leaf. The **leaf** **MUST** be mode **0700**.

**Create before return:** for the **chosen** leaf, the resolver **MUST** create it, confirm it is **writable**, then print the path. If create/write fails → try the next tier **with no message**. If none work → **MUST** fail closed. **MUST NOT** return a path without creating it.

**MUST NOT** use these as cache:

| Forbidden cache path | Why |
|----------------------|-----|
| `/dev/shm/${APP_NAME}` | Looks like a ram-drive project folder |
| `/dev/shm/${APP_NAME}-${USERNAME}` | Same confusion. Login belongs in the leaf **under** `cache/`, as `cache-${APP_NAME}-${login}-$$` |
| `/dev/shm` or `/tmp` as a dump | No app-named cache leaf |
| Persistence storage | Durable data is not scratch |

### 2.4 Cache isolation

1. Cache leaves **MUST** include **`cache-${APP_NAME}`** (app identity).  
2. Volatile leaves (`/dev/shm/cache` and `/tmp/cache`) **MUST** be `cache-${APP_NAME}-${login}-$$`. Home leaves **MUST** be `cache-${APP_NAME}-$$` (no login segment). Isolation is the login segment plus this process id.  
3. **MUST NOT** use a single shared world-writable directory for all logins or all apps.  
4. Live product **MUST** export `TMPDIR=${EFFECTIVE_STORAGE_DIR}` so `mktemp` inherits the isolated **cache** root.  
5. New scratch files **MUST** be created via **`util_mktemp`** (or `mktemp` under a path `util_resolve_storage` returned).  
6. The **cache directory** name includes `$$` (this process). Scratch **files** inside it **MUST NOT** use a predictable `$$` file name (forbidden: `/tmp/${APP_NAME}.$$`, `${EFFECTIVE_STORAGE_DIR}/${APP_NAME}.$$`).

### 2.5 Persistence storage

1. Persistence **MUST** be **`${HOME}/.local/${APP_NAME}`** (this product: `${HOME}/.local/gitlab-nginx`). No login suffix and no `$$`.  
2. Helper **`util_persistent_storage_dir`** **MUST** print that path. **`util_resolve_persistent_storage`** **MUST** `mkdir -p` it, confirm it is writable, then print it (fail closed).  
3. Resolve **MUST** refuse if the computed path is `${HOME}/.local/bin` (install bin, not persistence).  
4. Persistence resolve is a **data return** on stdout (`$(util_resolve_persistent_storage)`).  
5. **MUST NOT** store scratch/temps in persistence when a cache root is available.

### 2.6 Wire and diagnostics

| Surface | Requirement |
|---------|-------------|
| `app_main` | Resolve once early: `EFFECTIVE_STORAGE_DIR=$(util_resolve_storage)`; `STORAGE_DIR=$(util_fallback_cache_dir)` (1st fallback shape, not an env override of the chain); `PERSISTENT_STORAGE_DIR=$(util_resolve_persistent_storage)`; export `EFFECTIVE_STORAGE_DIR`, `STORAGE_DIR`, `PERSISTENT_STORAGE_DIR`, and **`TMPDIR=${EFFECTIVE_STORAGE_DIR}`** |
| `app_about` human | **MUST** print **`Cache folder used:`** then the live directory; **`Cache folder (preferred):`** then this host’s preferred path; **`Cache folder (1st fallback):`** then the 1st fallback; **`Cache folder (2nd fallback):`** only when this host has a 2nd fallback; **`Persistence storage:`** then `${HOME}/.local/${APP_NAME}`. **MUST NOT** label cache lines **Storage (effective)** or **Storage (fallback)**. **MUST NOT** warn or error when the used directory is a fallback |
| `app_about` JSON | **MUST** include `cache_used`, `cache_preferred`, `cache_fallback` (1st), `cache_fallback_2` (2nd, empty string when the host has none), `persistence_storage`, and the live chosen cache root as `effective_storage` (same value as `cache_used`; `storage_dir` = 1st fallback). **MUST NOT** include `CHECKSUM` |

Linux `about` lines (`$$` is this process, not a fixed number). `Cache folder used` is the tier that was created. When the preferred tier is the one used, the used line and the preferred line are the same path. When a fallback is used, the used line is that fallback path and the preferred line still shows the preferred path. Neither case prints a warning.

```
[INFO] Cache folder used: /dev/shm/cache/cache-${APP_NAME}-${login}-$$
[INFO] Cache folder (preferred): /dev/shm/cache/cache-${APP_NAME}-${login}-$$
[INFO] Cache folder (1st fallback): /tmp/cache/cache-${APP_NAME}-${login}-$$
[INFO] Cache folder (2nd fallback): ${HOME}/.cache/cache-${APP_NAME}-$$
[INFO] Persistence storage: ${HOME}/.local/${APP_NAME}
```

Git Bash omits the 2nd fallback line. Mac prints preferred under `/tmp/cache/`, 1st fallback under `${HOME}/Library/Caches/`, and 2nd fallback under `${HOME}/cache/`.

### 2.7 Implementation Notes (this project)

| Item | Live value |
|------|------------|
| **Product / binary** | `gitlab-nginx` |
| **Cache resolver** | `util_resolve_storage` in `./gitlab-nginx` |
| **Linux preferred** | `/dev/shm/cache/cache-${APP_NAME}-${login}-$$` |
| **Linux 1st / 2nd** | `/tmp/cache/cache-${APP_NAME}-${login}-$$` then `${HOME}/.cache/cache-${APP_NAME}-$$` |
| **Git Bash** | `/tmp/cache/cache-${APP_NAME}-${login}-$$` then `${HOME}/AppData/Local/Temp/cache-${APP_NAME}-$$` |
| **Mac** | `/tmp/cache/cache-${APP_NAME}-${login}-$$` then `${HOME}/Library/Caches/cache-${APP_NAME}-$$` then `${HOME}/cache/cache-${APP_NAME}-$$` |
| **Persistence** | `${HOME}/.local/gitlab-nginx` |
| **Persistence helpers** | `util_persistent_storage_dir` (print); `util_resolve_persistent_storage` (create-before-return) |
| **Scratch files** | `util_mktemp` (install staging and companion digest temps). Leaf names use `mktemp` `XXXXXX`, not `$$` |
| **Call sites** | `app_main` (cache + persistence resolve, `TMPDIR` from cache); `app_about` (human + JSON) |
| **Not used for** | Domain Let's Encrypt files; CLI binary placement (`USER_BIN` / `GLOBAL_BIN`) |
| **Tests** | `tests/test_cli.sh` — **TP-CLI-04** about labels and JSON fields; **TP-CLI-05** host chains, silent skip, mode 0700, persistence |

### 2.8 Why This Requirement Exists (CIAO)

- **CIAO Principle 1 – Caution** (https://github.com/cloudgen/ciao): Multi-user isolation without looking like a project tree on tmpfs; durable data is not the install bin.  
- **CIAO Principle 2 – Intentional** (https://github.com/cloudgen/ciao): Storage = cache folder **and** persistence storage; about says both.  
- **CIAO Principle 3 – Anti-fragile** (https://github.com/cloudgen/ciao): Missing `/dev/shm` still works, and the miss is silent.  
- **CIAO Principle 11 – Safe Temporary File Handling** (https://github.com/cloudgen/ciao): `TMPDIR` from the **cache** root; scratch **files** stay `mktemp` names. The cache **directory** carries `$$`.  
- **CIAO Principle 17 / 19 – Defensive storage** (https://github.com/cloudgen/ciao): Durable data has an explicit persistence path, not an implied cache leaf.

---

## 3. Design Principles (CIAO / CIAO-Lite)

- Volatile cache first, user cache last for scratch.  
- Persistence is `${HOME}/.local/${APP_NAME}`, not under `bin` or `/var`.  
- Isolation before convenience.  
- Create is fail-closed only when every cache tier failed; one missed tier is silent.  
- About names **Cache folder used / preferred / 1st fallback / 2nd fallback** and **Persistence storage**.

---

## 4. Protection Rule (Sacred)

**Future AI assistants, Grok, or maintainers MUST NOT**:

1. Restore `/dev/shm/${APP_NAME}` or `/dev/shm/${APP_NAME}-${USERNAME}` as the preferred cache.  
2. Label about cache lines **Storage (effective)** / **Storage (fallback)**. The labels are **Cache folder used**, **Cache folder (preferred)**, **Cache folder (1st fallback)**, **Cache folder (2nd fallback)** when that host has one.  
3. Drop persistence storage from this requirement or from `about`. Persistence **MUST** be `${HOME}/.local/${APP_NAME}` — **MUST NOT** `${HOME}/.local/bin` or a Type 1 `/var/…` deposit.  
4. Replace the cache fallback chain with a shared world-writable dump, or with one `cache-${APP_NAME}` leaf shared by every login.  
5. Scatter hard-coded `/tmp/gitlab-nginx` roots outside the cache resolver.  
6. Leave the resolvers as dead code with no call sites while claiming storage is product law.  
7. Echo a tier path **without** creating it.  
8. Put CHECKSUM in about storage diagnostics.  
9. Use predictable `$$` scratch **file** names instead of `util_mktemp` / `mktemp` `XXXXXX`. The cache **directory** itself includes `$$`.  
10. Warn or error only because a higher cache tier was skipped.  
11. Drop `${login}` or `$$` from a volatile cache leaf, or put the login back on `/dev/shm/${APP_NAME}-${login}` outside `cache/`.  
12. Relocate domain `/etc/letsencrypt/*` files into persistence storage, or store scratch in persistence when a cache root exists.  
13. Strip the **Under command line for normal user only** section, or enable admin privilege / a dedicated system user on Termux / Git Bash / Windows cmd.

**Violating this rule is a critical cache isolation / honesty regression.**

---

## 5. Definition of done (shell CLI storage)

Storage work for gitlab-nginx is **not done** if any of the following fail:

1. Exactly one cache resolver (`util_resolve_storage`) creates and returns the chosen leaf.  
2. Linux preferred leaf is `/dev/shm/cache/cache-${APP_NAME}-${login}-$$` when that directory is usable. Git Bash and Mac preferred leaf is `/tmp/cache/cache-${APP_NAME}-${login}-$$`.  
3. Persistence resolver creates and returns `${HOME}/.local/${APP_NAME}`.  
4. Volatile leaves include `${login}` and `$$`. Home leaves omit the login. No shared world-writable single dump.  
5. `app_main` sets `EFFECTIVE_STORAGE_DIR`, `STORAGE_DIR` (1st fallback), and `PERSISTENT_STORAGE_DIR`; exports `TMPDIR` from the cache resolver once early.  
6. `app_about` human shows Cache folder used, preferred, 1st fallback, 2nd fallback when present, and Persistence storage. JSON includes `cache_used`, `cache_preferred`, `cache_fallback`, `cache_fallback_2`, `persistence_storage`, `effective_storage`. **Omit** `CHECKSUM`.  
7. Skipping a cache tier prints no warning and no error. Git Bash has no 2nd fallback. Mac 2nd fallback is `${HOME}/cache/cache-${APP_NAME}-$$`.  
8. User-visible storage failures use Output SSOT (`out_die` / structured error), and only when every tier failed.  
9. Tests cover the about fields and the host chains (`tests/test_cli.sh`, **TP-CLI-04** / **TP-CLI-05**).  
10. Implementation changes cite this requirement key `requirement-shell-cli-storage`.

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
| **TP-CLI-04** | `tests/test_cli.sh` | **have** — about JSON `cache_used` / `cache_preferred` / `cache_fallback` / `cache_fallback_2` / `persistence_storage`; human Cache folder used, preferred, 1st fallback, 2nd fallback, Persistence storage |
| **TP-CLI-05** | `tests/test_cli.sh` | **have** — Linux preferred `/dev/shm/cache/cache-${APP_NAME}-${login}-$$`; 1st `/tmp/cache/...`; 2nd `${HOME}/.cache/cache-${APP_NAME}-$$`; Git Bash and Mac chains; silent skip of preferred; leaf mode 0700; persistence `${HOME}/.local/${APP_NAME}`; live dir exists; not `/dev/shm/${APP_NAME}-${login}` |

**Map:** `reviews/test-plan.md`.

## 7. Status history

| Date | Status | Note |
|------|--------|------|
| 2026-07-16 | Active | Create-before-return cache resolver; `TMPDIR` from cache |
| 2026-08-30 | Active 1.1.0 | Storage = cache folder **and** persistence `${HOME}/.local/${APP_NAME}`; about Cache folder labels |
| 2026-09-27 | Active 1.2.0 | Per-login per-process cache leaves. Linux shm → tmp → `${HOME}/.cache`. Git Bash tmp → AppData Local Temp. Mac tmp → Library/Caches → `${HOME}/cache`. Silent tier miss. `about` prints used / preferred / 1st / 2nd. Label **Persistence storage** |

---

**Last Updated**: 2026-09-27  
**Owner**: gitlab-nginx project maintainers  
**Alignment**: Registry `docs/requirements/index.md`; CIAO Principles 1, 2, 3, 11, 17, 19 (v2.10.2) (https://github.com/cloudgen/ciao); CIAO-Lite (https://github.com/cloudgen/ciao-lite).
