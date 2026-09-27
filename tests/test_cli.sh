# =============================================================================
# tests/test_cli.sh — Type 0 CLI surface (no network install required)
# =============================================================================
# Covers: syntax, version, help, about, unknown command, quiet/json modes,
# help must not list CHECKSUM, self-uninstall --json fail-closed (INC-20260713-002
# contract shape when a binary is present under isolated USER_BIN).
# =============================================================================

# shellcheck source=helpers.sh
. "${TESTS_ROOT}/helpers.sh"

run_test_cli() {
    t_header "CLI surface"

    require_cmd sh
    require_cmd sha256sum
    require_cmd grep

    # --- syntax ---
    sh -n "${SCRIPT}"
    _syn=$?
    assert_eq "sh -n gitlab-nginx (syntax)" 0 "$_syn"

    # --- companion digest matches ship unit ---
    if [ -f "${REPO_ROOT}/gitlab-nginx.sha256" ]; then
        _expected=$(tr -d ' \n\r\t' < "${REPO_ROOT}/gitlab-nginx.sha256")
        _actual=$(sha256sum "${SCRIPT}" | awk '{print $1}')
        assert_eq "gitlab-nginx.sha256 matches ./gitlab-nginx" "$_expected" "$_actual"
    else
        t_fail "gitlab-nginx.sha256 missing at repo root"
    fi

    # --- version (human) ---
    _out=$(sh "${SCRIPT}" version 2>/dev/null)
    _ec=$?
    assert_eq "version exit 0" 0 "$_ec"
    assert_contains "version human mentions version" "$_out" "${PRODUCT_VERSION}"
    assert_contains "version human mentions app" "$_out" "gitlab-nginx"

    # --- version (json) ---
    _out=$(sh "${SCRIPT}" --json version 2>/dev/null)
    _ec=$?
    assert_eq "version --json exit 0" 0 "$_ec"
    assert_contains "version --json type" "$_out" '"type":"version"'
    assert_contains "version --json app" "$_out" '"app":"gitlab-nginx"'
    assert_contains "version --json version field" "$_out" "\"version\":\"${PRODUCT_VERSION}\""
    # app_version is the live dispatcher target (M1); no dual inline path
    assert_contains "version human via app_version" "$(sh "${SCRIPT}" version 2>/dev/null)" "${PRODUCT_VERSION}"

    # --- help (human): commands present, CHECKSUM absent ---
    _out=$(sh "${SCRIPT}" help 2>/dev/null)
    _ec=$?
    assert_eq "help exit 0" 0 "$_ec"
    assert_contains "help lists install" "$_out" "install"
    assert_contains "help lists version-check" "$_out" "version-check"
    assert_contains "help lists self-update" "$_out" "self-update"
    assert_contains "help lists self-uninstall" "$_out" "self-uninstall"
    assert_contains "help lists about" "$_out" "about"
    assert_contains "help lists --json" "$_out" "--json"
    assert_contains "help lists --force" "$_out" "--force"
    assert_contains "help lists REPO_USER" "$_out" "REPO_USER"
    assert_contains "help lists REPO_NAME" "$_out" "REPO_NAME"
    assert_contains "help lists SCRIPT_URL" "$_out" "SCRIPT_URL"
    assert_not_contains "help must not list CHECKSUM" "$_out" "CHECKSUM"

    # --- help (json): short object, not full prose ---
    _out=$(sh "${SCRIPT}" --json help 2>/dev/null)
    _ec=$?
    assert_eq "help --json exit 0" 0 "$_ec"
    assert_contains "help --json type success" "$_out" '"type":"success"'
    assert_contains "help --json command help" "$_out" '"command":"help"'

    # --- about (json): no CHECKSUM field; storage resolve fields ---
    _out=$(sh "${SCRIPT}" --json about 2>/dev/null)
    _ec=$?
    assert_eq "about --json exit 0" 0 "$_ec"
    assert_contains "about --json type" "$_out" '"type":"about"'
    assert_contains "about --json app" "$_out" '"app":"gitlab-nginx"'
    assert_not_contains "about --json must not include CHECKSUM" "$_out" "CHECKSUM"
    assert_contains "TP-CLI-04 about --json effective_storage" "$_out" '"effective_storage"'
    assert_contains "TP-CLI-04 about --json storage_dir" "$_out" '"storage_dir"'
    assert_contains "TP-CLI-04 about --json cache_used" "$_out" '"cache_used"'
    assert_contains "TP-CLI-04 about --json cache_preferred" "$_out" '"cache_preferred"'
    assert_contains "TP-CLI-04 about --json cache_fallback" "$_out" '"cache_fallback"'
    assert_contains "TP-CLI-04 about --json cache_fallback_2" "$_out" '"cache_fallback_2"'
    assert_contains "TP-CLI-04 about --json persistence_storage" "$_out" '"persistence_storage"'
    assert_contains "TP-CLI-04 about --json storage includes app name" "$_out" "${APP_NAME:-gitlab-nginx}"
    _out_h=$(sh "${SCRIPT}" about 2>/dev/null)
    assert_contains "TP-CLI-04 human Cache folder used" "$_out_h" "Cache folder used:"
    assert_contains "TP-CLI-04 human Cache folder (preferred)" "$_out_h" "Cache folder (preferred):"
    assert_contains "TP-CLI-04 human Cache folder (1st fallback)" "$_out_h" "Cache folder (1st fallback):"
    assert_contains "TP-CLI-04 human Cache folder (2nd fallback)" "$_out_h" "Cache folder (2nd fallback):"
    assert_contains "TP-CLI-04 human Persistence storage" "$_out_h" "Persistence storage:"
    assert_not_contains "TP-CLI-04 human must not use Storage (effective)" "$_out_h" "Storage (effective)"
    assert_not_contains "TP-CLI-04 human must not use Storage (fallback)" "$_out_h" "Storage (fallback)"

    # TP-CLI-05 cache isolation: per login + this process; host chains; silent skip
    ci_isolated_env 2>/dev/null || true
    if [ -n "${CI_HOME:-}" ]; then
        _login=$(id -un 2>/dev/null || echo "unknown")
        _out=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN:-${CI_HOME}/.local/bin}" \
            sh "${SCRIPT}" --json about 2>/dev/null)
        assert_contains "TP-CLI-05 isolated about has app in cache" "$_out" "${APP_NAME:-gitlab-nginx}"
        _pref=$(printf '%s' "$_out" | sed -n 's/.*"cache_preferred":"\([^"]*\)".*/\1/p' | head -n1)
        _pid="${_pref##*-}"
        case "${_pref}" in
            /dev/shm/cache/cache-"${APP_NAME:-gitlab-nginx}"-"${_login}"-[0-9]*)
                t_pass "TP-CLI-05 cache_preferred is shm login process leaf"
                ;;
            *) t_fail "TP-CLI-05 cache_preferred unexpected: '${_pref:-empty}'" ;;
        esac
        _fb=$(printf '%s' "$_out" | sed -n 's/.*"cache_fallback":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 cache_fallback 1st" "/tmp/cache/cache-${APP_NAME:-gitlab-nginx}-${_login}-${_pid}" "${_fb}"
        _fb2=$(printf '%s' "$_out" | sed -n 's/.*"cache_fallback_2":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 cache_fallback 2nd" "${CI_HOME}/.cache/cache-${APP_NAME:-gitlab-nginx}-${_pid}" "${_fb2}"
        _used=$(printf '%s' "$_out" | sed -n 's/.*"cache_used":"\([^"]*\)".*/\1/p' | head -n1)
        _eff=$(printf '%s' "$_out" | sed -n 's/.*"effective_storage":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 cache_used matches effective" "${_eff}" "${_used}"
        _sdir=$(printf '%s' "$_out" | sed -n 's/.*"storage_dir":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 storage_dir is 1st fallback" "${_fb}" "${_sdir}"
        if [ -n "$_eff" ] && [ -d "$_eff" ]; then
            t_pass "TP-CLI-05 effective cache directory exists"
        else
            t_fail "TP-CLI-05 effective cache missing: '${_eff:-empty}'"
        fi
        case "${_eff}" in
            /dev/shm/"${APP_NAME:-gitlab-nginx}"|/dev/shm/"${APP_NAME:-gitlab-nginx}"-*)
                t_fail "TP-CLI-05 effective cache must not be ram-drive project shape: '${_eff}'"
                ;;
            *) t_pass "TP-CLI-05 effective cache is not a ram-drive project shape" ;;
        esac
        case "$_out" in
            *'"effective_storage":"'*"${_login}"*|*'"effective_storage":"'*"unknown"*) \
                t_pass "TP-CLI-05 effective_storage includes user segment" ;;
            *) t_fail "TP-CLI-05 effective_storage missing user segment for '${_login}': $_out" ;;
        esac
        _err=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN:-${CI_HOME}/.local/bin}" \
            GITLAB_NGINX_CACHE_SKIP=preferred \
            sh "${SCRIPT}" about 2>&1 >/dev/null)
        assert_not_contains "TP-CLI-05 silent cache fallback" "${_err}" "fallback"
        assert_not_contains "TP-CLI-05 silent cache fallback error" "${_err}" "Cannot create cache"
        _skip=$(HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN:-${CI_HOME}/.local/bin}" \
            GITLAB_NGINX_CACHE_SKIP=preferred \
            sh "${SCRIPT}" --json about 2>/dev/null)
        _skip_eff=$(printf '%s' "$_skip" | sed -n 's/.*"effective_storage":"\([^"]*\)".*/\1/p' | head -n1)
        _skip_fb=$(printf '%s' "$_skip" | sed -n 's/.*"cache_fallback":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 skipped preferred uses 1st fallback" "${_skip_fb}" "${_skip_eff}"
        _gb=$(HOME="${CI_HOME}" GITLAB_NGINX_CACHE_HOST=gitbash \
            sh "${SCRIPT}" --json about 2>/dev/null)
        _gb_pref=$(printf '%s' "$_gb" | sed -n 's/.*"cache_preferred":"\([^"]*\)".*/\1/p' | head -n1)
        _gb_pid="${_gb_pref##*-}"
        assert_eq "TP-CLI-05 gitbash preferred" "/tmp/cache/cache-${APP_NAME:-gitlab-nginx}-${_login}-${_gb_pid}" "${_gb_pref}"
        _gb_fb=$(printf '%s' "$_gb" | sed -n 's/.*"cache_fallback":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 gitbash 1st fallback" "${CI_HOME}/AppData/Local/Temp/cache-${APP_NAME:-gitlab-nginx}-${_gb_pid}" "${_gb_fb}"
        _gb_fb2=$(printf '%s' "$_gb" | sed -n 's/.*"cache_fallback_2":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 gitbash no 2nd fallback" "" "${_gb_fb2}"
        _mac=$(HOME="${CI_HOME}" GITLAB_NGINX_CACHE_HOST=mac \
            sh "${SCRIPT}" --json about 2>/dev/null)
        _mac_pref=$(printf '%s' "$_mac" | sed -n 's/.*"cache_preferred":"\([^"]*\)".*/\1/p' | head -n1)
        _mac_pid="${_mac_pref##*-}"
        assert_eq "TP-CLI-05 mac preferred" "/tmp/cache/cache-${APP_NAME:-gitlab-nginx}-${_login}-${_mac_pid}" "${_mac_pref}"
        _mac_fb=$(printf '%s' "$_mac" | sed -n 's/.*"cache_fallback":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 mac 1st fallback" "${CI_HOME}/Library/Caches/cache-${APP_NAME:-gitlab-nginx}-${_mac_pid}" "${_mac_fb}"
        _mac_fb2=$(printf '%s' "$_mac" | sed -n 's/.*"cache_fallback_2":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 mac 2nd fallback" "${CI_HOME}/cache/cache-${APP_NAME:-gitlab-nginx}-${_mac_pid}" "${_mac_fb2}"
        _mode=$(stat -c %a "${_eff}" 2>/dev/null || echo "")
        assert_eq "TP-CLI-05 effective cache mode 0700" "700" "${_mode}"
        _hum_l=$(HOME="${CI_HOME}" sh "${SCRIPT}" about 2>/dev/null)
        assert_contains "TP-CLI-05 linux about used" "${_hum_l}" "Cache folder used:"
        assert_contains "TP-CLI-05 linux about preferred path" "${_hum_l}" "/dev/shm/cache/cache-${APP_NAME:-gitlab-nginx}-${_login}-"
        assert_contains "TP-CLI-05 linux about 2nd path" "${_hum_l}" "/.cache/cache-${APP_NAME:-gitlab-nginx}-"
        _hum_gb=$(HOME="${CI_HOME}" GITLAB_NGINX_CACHE_HOST=gitbash sh "${SCRIPT}" about 2>/dev/null)
        assert_contains "TP-CLI-05 gitbash about 1st" "${_hum_gb}" "AppData/Local/Temp/cache-${APP_NAME:-gitlab-nginx}-"
        assert_not_contains "TP-CLI-05 gitbash about omits 2nd" "${_hum_gb}" "Cache folder (2nd fallback)"
        _hum_mac=$(HOME="${CI_HOME}" GITLAB_NGINX_CACHE_HOST=mac sh "${SCRIPT}" about 2>/dev/null)
        assert_contains "TP-CLI-05 mac about 1st" "${_hum_mac}" "Library/Caches/cache-${APP_NAME:-gitlab-nginx}-"
        assert_contains "TP-CLI-05 mac about 2nd path" "${_hum_mac}" "Cache folder (2nd fallback): ${CI_HOME}/cache/cache-${APP_NAME:-gitlab-nginx}-"
        _persist=$(printf '%s' "$_out" | sed -n 's/.*"persistence_storage":"\([^"]*\)".*/\1/p' | head -n1)
        assert_eq "TP-CLI-05 persistence_storage path" "${CI_HOME}/.local/${APP_NAME:-gitlab-nginx}" "$_persist"
        if [ -n "$_persist" ] && [ -d "$_persist" ]; then
            t_pass "TP-CLI-05 persistence storage directory exists"
        else
            t_fail "TP-CLI-05 persistence storage missing: '${_persist:-empty}'"
        fi
        case "${_persist}" in
            */.local/bin|*/.local/bin/) t_fail "TP-CLI-05 persistence must not be USER_BIN: '${_persist}'" ;;
            *) t_pass "TP-CLI-05 persistence is not the install bin directory" ;;
        esac
        ci_cleanup_env 2>/dev/null || true
    else
        _out=$(sh "${SCRIPT}" --json about 2>/dev/null)
        _eff=$(printf '%s' "$_out" | sed -n 's/.*"effective_storage":"\([^"]*\)".*/\1/p' | head -n1)
        if [ -n "$_eff" ] && [ -d "$_eff" ]; then
            t_pass "TP-CLI-05 effective_storage directory exists after resolve"
        else
            t_fail "TP-CLI-05 effective_storage missing or not a directory: '${_eff:-empty}'"
        fi
    fi

    # --- unknown command ---
    _err=$(sh "${SCRIPT}" no-such-command 2>&1 >/dev/null)
    _ec=$?
    assert_eq "unknown command exit 1" 1 "$_ec"
    assert_contains "unknown command error text" "$_err" "Unknown command"

    _err=$(sh "${SCRIPT}" --json no-such-command 2>&1 >/dev/null)
    _ec=$?
    assert_eq "unknown command --json exit 1" 1 "$_ec"
    assert_contains "unknown command --json type error" "$_err" '"type":"out_error"'

    # --- quiet: version should not print info banners ---
    # Contract: --quiet suppresses non-error chatter; version uses out_info → suppressed.
    _out=$(sh "${SCRIPT}" --quiet version 2>/dev/null)
    _ec=$?
    assert_eq "version --quiet exit 0" 0 "$_ec"
    # out_info is suppressed under quiet → empty or near-empty stdout is correct
    if [ -z "$_out" ]; then
        t_pass "version --quiet suppresses human info"
    else
        _trim=$(printf '%s' "$_out" | tr -d ' \t\n\r')
        if [ -z "$_trim" ]; then
            t_pass "version --quiet suppresses human info"
        else
            t_fail "version --quiet expected empty stdout, got '$(_trunc "$_out")'"
        fi
    fi

    # --- HOME unset under set -u (INC-20260713-001) ---
    # Must not abort with "HOME: parameter not set"; defaults HOME then USER_BIN.
    _out=$(env -u HOME sh "${SCRIPT}" version 2>/dev/null)
    _ec=$?
    assert_eq "env -u HOME version exit 0" 0 "$_ec"
    assert_contains "env -u HOME version still reports version" "$_out" "${PRODUCT_VERSION}"

    # --- zero-arg auto-install propagates failure (not exit 0 on download fail) ---
    ci_isolated_env
    _errf="${CI_HOME}/zero-arg-err.txt"
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" \
        SCRIPT_URL="http://127.0.0.1:1/gitlab-nginx-unreachable" \
        sh "${SCRIPT}" </dev/null 2>"${_errf}"
    )
    _ec=$?
    _err=$(cat "${_errf}" 2>/dev/null || true)
    if [ "$_ec" -ne 0 ]; then
        t_pass "zero-arg failed install exits non-zero"
    else
        t_fail "zero-arg failed install expected non-zero exit, got 0 (stdout='$(_trunc "$_out")' err='$(_trunc "$_err")')"
    fi
    assert_file_missing "zero-arg failed install left no binary" "${CI_USER_BIN}/gitlab-nginx"
    ci_cleanup_env

    # --- self-uninstall --json without force when binary present (isolated) ---
    # Fail-closed confirm_required (INC-20260713-002 contract).
    ci_isolated_env
    mkdir -p "${CI_USER_BIN}"
    # Place a stub install so uninstall path runs without network
    cp "${SCRIPT}" "${CI_USER_BIN}/gitlab-nginx"
    chmod +x "${CI_USER_BIN}/gitlab-nginx"
    _errf="${CI_HOME}/un-err.txt"
    _out=$(
        HOME="${CI_HOME}" USER_BIN="${CI_USER_BIN}" GLOBAL_BIN="${CI_GLOBAL_BIN}" \
        sh "${SCRIPT}" --json self-uninstall 2>"${_errf}"
    )
    _ec=$?
    _err=$(cat "${_errf}" 2>/dev/null || true)
    assert_eq "self-uninstall --json without --force exit 1" 1 "$_ec"
    assert_contains "self-uninstall --json confirm_required code" "$_err" '"code":"confirm_required"'
    assert_contains "self-uninstall --json out_error type" "$_err" '"type":"out_error"'
    assert_not_contains "self-uninstall --json must not fake success cancel" "$_out$_err" "cancelled by user"
    assert_file_exists "binary remains without --force" "${CI_USER_BIN}/gitlab-nginx"
    ci_cleanup_env
}
