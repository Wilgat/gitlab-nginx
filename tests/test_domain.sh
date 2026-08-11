# =============================================================================
# tests/test_domain.sh — gitlab-nginx domain surface (RQ-DOMAIN-GITLAB-NGINX)
# =============================================================================
# Host-mutating run/nginx-conf need root; this suite proves dispatch, help,
# about domain rows, empty-argv ≠ domain run, and read-only domains behavior.
# =============================================================================

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"

run_test_domain() {
    t_header "Domain surface (TP-GLN-*)"

    require_cmd sh

    # --- TP-GLN-01: help lists domain verbs + Type 0 + --no-cloudflare ---
    _out=$(sh "${SCRIPT}" help 2>/dev/null)
    _ec=$?
    assert_eq "TP-GLN-01 help exit 0" 0 "$_ec"
    assert_contains "TP-GLN-01 help lists run" "$_out" "run"
    assert_contains "TP-GLN-01 help lists domains" "$_out" "domains"
    assert_contains "TP-GLN-01 help lists email" "$_out" "email"
    assert_contains "TP-GLN-01 help lists nginx-conf" "$_out" "nginx-conf"
    assert_contains "TP-GLN-01 help lists ssh-hostname" "$_out" "ssh-hostname"
    assert_contains "TP-GLN-01 help lists --no-cloudflare" "$_out" "--no-cloudflare"
    assert_contains "TP-GLN-01 help still lists install" "$_out" "install"
    assert_contains "TP-GLN-01 help still lists self-update" "$_out" "self-update"

    # --- TP-GLN-02: help --json mentions domain note surface ---
    _out=$(sh "${SCRIPT}" --json help 2>/dev/null)
    _ec=$?
    assert_eq "TP-GLN-02 help --json exit 0" 0 "$_ec"
    assert_contains "TP-GLN-02 help --json success" "$_out" '"type":"success"'
    assert_contains "TP-GLN-02 help --json notes domains" "$_out" "domains"

    # --- TP-GLN-03: about JSON domain fields ---
    _out=$(sh "${SCRIPT}" --json about 2>/dev/null)
    _ec=$?
    assert_eq "TP-GLN-03 about --json exit 0" 0 "$_ec"
    assert_contains "TP-GLN-03 about type" "$_out" '"type":"about"'
    assert_contains "TP-GLN-03 about domains_file" "$_out" '"domains_file"'
    assert_contains "TP-GLN-03 about email_file" "$_out" '"email_file"'
    assert_contains "TP-GLN-03 about domain_count" "$_out" '"domain_count"'
    assert_contains "TP-GLN-03 about domain product" "$_out" '"domain":"gitlab-nginx"'

    # --- TP-GLN-04: empty argv is Type O install-ensure, NOT domain run ---
    # When already not forcing network: use isolated env + bad SCRIPT_URL → non-zero,
    # and must not invoke interactive domain setup banners (Certbot / GitLab CE).
    ci_isolated_env
    _errf="${CI_HOME}/empty-arg-err.txt"
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" \
        SCRIPT_URL="http://127.0.0.1:1/gitlab-nginx-unreachable" \
        sh "${SCRIPT}" </dev/null 2>"${_errf}"
    )
    _ec=$?
    _err=$(cat "${_errf}" 2>/dev/null || true)
    _all="${_out}${_err}"
    if [ "$_ec" -ne 0 ]; then
        t_pass "TP-GLN-04 empty argv failed install exits non-zero (Type O)"
    else
        t_fail "TP-GLN-04 empty argv expected non-zero without channel, got 0"
    fi
    assert_not_contains "TP-GLN-04 empty argv must not start GitLab install text" "$_all" "Installing GitLab"
    assert_not_contains "TP-GLN-04 empty argv must not run certbot standalone" "$_all" "certbot certonly"
    assert_file_missing "TP-GLN-04 empty argv left no binary" "${CI_USER_BIN}/gitlab-nginx"
    ci_cleanup_env

    # --- TP-GLN-05: domains command is routed (not unknown) ---
    # May succeed (readable domains file) or warn; must not be "Unknown command".
    _errf=$(mktemp)
    _out=$(sh "${SCRIPT}" domains 2>"${_errf}")
    _ec=$?
    _err=$(cat "${_errf}" 2>/dev/null || true)
    rm -f "${_errf}"
    assert_not_contains "TP-GLN-05 domains not unknown command" "${_out}${_err}" "Unknown command"
    # exit 0 typical when file readable; allow non-zero only for permission paths without crash
    if [ "$_ec" -eq 0 ] || [ "$_ec" -eq 1 ]; then
        t_pass "TP-GLN-05 domains exits 0 or 1 (routed)"
    else
        t_fail "TP-GLN-05 domains unexpected exit ${_ec}"
    fi

    # --- TP-GLN-06: domains --json produces JSON object when possible ---
    _errf=$(mktemp)
    _out=$(sh "${SCRIPT}" --json domains 2>"${_errf}")
    _ec=$?
    _err=$(cat "${_errf}" 2>/dev/null || true)
    rm -f "${_errf}"
    _all="${_out}${_err}"
    assert_not_contains "TP-GLN-06 domains --json not unknown" "$_all" "Unknown command"
    case "$_all" in
        *'"type":'*) t_pass "TP-GLN-06 domains --json emits type field" ;;
        *)
            # permission denied human path still acceptable if not unknown
            case "$_all" in
                *[Pp]ermission*|*denied*) t_pass "TP-GLN-06 domains --json permission-gated (honest)" ;;
                *) t_fail "TP-GLN-06 domains --json no type/permission: $(_trunc "$_all")" ;;
            esac
            ;;
    esac

    # --- TP-GLN-07: nginx-conf without root fails closed (not unknown) ---
    _errf=$(mktemp)
    _out=$(sh "${SCRIPT}" nginx-conf 2>"${_errf}")
    _ec=$?
    _err=$(cat "${_errf}" 2>/dev/null || true)
    rm -f "${_errf}"
    _all="${_out}${_err}"
    assert_eq "TP-GLN-07 nginx-conf non-root exit 1" 1 "$_ec"
    assert_not_contains "TP-GLN-07 nginx-conf not unknown" "$_all" "Unknown command"
    assert_contains "TP-GLN-07 nginx-conf root required" "$_all" "root"

    # --- TP-GLN-08: run without root fails closed ---
    _errf=$(mktemp)
    # run may start non-interactive path; ensure not root path dies on check_root eventually
    # Force non-TTY: </dev/null
    _out=$(sh "${SCRIPT}" run </dev/null 2>"${_errf}")
    _ec=$?
    _err=$(cat "${_errf}" 2>/dev/null || true)
    rm -f "${_errf}"
    _all="${_out}${_err}"
    assert_not_contains "TP-GLN-08 run not unknown command" "$_all" "Unknown command"
    # Non-root non-interactive typically dies on root check during setup steps
    if [ "$_ec" -ne 0 ]; then
        t_pass "TP-GLN-08 run non-root exits non-zero"
    else
        # If somehow succeeds without root, still fail closed expectation
        t_fail "TP-GLN-08 run non-root expected non-zero exit"
    fi
}
