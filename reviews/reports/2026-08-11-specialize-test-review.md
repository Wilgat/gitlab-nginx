# Report: specialize revision + tests (gitlab-nginx 2.3.1)

**Date:** 2026-08-11  
**Scope:** Review specialize from selfmanaged; create test plan + suite; run and fix

## Findings

| ID | Severity | Finding | Fix |
|----|----------|---------|-----|
| F1 | **Critical** | `run` non-interactive as non-root mutated host paths (sudoers attempts, nginx backups) and exited 0 | `check_root` first in `run_non_interactive_setup` |
| F2 | High | Suite false failures: host `/usr/local/bin/gitlab-nginx` made `inst_is_installed` true under isolated HOME | `ci_isolated_env` exports isolated `GLOBAL_BIN` |
| F3 | Medium | Completion text still said `sudo gitlab-nginx` without `run` | Message → `sudo gitlab-nginx run` |
| F4 | Low | No product `tests/` / `reviews/test-plan.md` after specialize | Ported Type 0 suite + TP-GLN domain suite + plan |

## Baseline

```
PASS=133 FAIL=0 SKIP=0
RESULT: OK
```

Entry: `./tests/run.sh`  
Plan: `reviews/test-plan.md`

## Verdict

**Pass** — Type 0 + domain surface automated; critical non-root run path fixed; companion digest current for 2.3.1.
