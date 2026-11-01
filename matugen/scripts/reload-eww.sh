#!/usr/bin/env bash
# Called from matugen's post_hook. Returns immediately; the real work runs detached.
#
# `eww reload` is unreliable after a colour change (it can hang, or the daemon can die), so instead
# of reloading we restart the daemon: that always re-reads eww.scss/colors.scss, and it also
# brings eww back if it had already crashed. The control panel is re-opened if it was open.
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/eww-reload.log"

log() { printf '%s  %s\n' "$(date +%T)" "$*" >>"$LOG"; }

(
    log "reload-eww: started"
    pkill -9 eww
    exec 9>"${XDG_RUNTIME_DIR:-/tmp}/eww-reload.lock"
    flock -n 9 || { log "another reload running, skipping"; exit 0; }
    sleep 1.5                                  # let matugen / hyprctl reload settle

    was_open=0
    if pgrep -x eww >/dev/null; then
        timeout 2 eww active-windows 2>/dev/null | grep -q control_panel && was_open=1
    fi

    log "was_open=$was_open, restarting daemon"
    timeout 3 eww kill >/dev/null 2>&1
    pkill -9 -x eww 2>/dev/null
    for _ in 1 2 3 4 5 6; do pgrep -x eww >/dev/null || break; sleep 0.2; done

    setsid -f eww daemon >>"$LOG" 2>&1

    # wait (max ~4s) until the daemon answers
    for _ in $(seq 1 20); do
        timeout 1 eww ping >/dev/null 2>&1 && break
        sleep 0.2
    done

    if timeout 1 eww ping >/dev/null 2>&1; then log "daemon is up"; else log "DAEMON NOT RESPONDING"; fi
    [[ "$was_open" -eq 1 ]] && timeout 3 eww open control_panel >>"$LOG" 2>&1
) >/dev/null 2>&1 &
disown
exit 0
