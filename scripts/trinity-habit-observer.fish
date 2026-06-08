#!/usr/bin/env fish
# trinity-habit-observer.fish — Fish entry point for the Trinity Habit Observer + Self-Training Loop
# Delegates to the bash implementation with proper low-priority launch.
#
# New management (optimized for persistent low-prio running per Right-Brain cross feedback):
#   trinity-habit-observer start     # background with nice/ionice + PID file (safe restartable)
#   trinity-habit-observer stop
#   trinity-habit-observer status
#   trinity-habit-observer restart
#   trinity-habit-observer           # (or --help) — foreground low-prio (for watch pane or manual)

set script /data/PCaC-Playgrounds/scripts/trinity-habit-observer.sh
set PID_FILE /data/var/log/pcac/trinity-habit-observer.pid
set LOG_FILE /data/var/log/pcac/habit-proposals.log

if not test -x $script
    echo "trinity-habit-observer.sh not found or not executable at $script" >&2
    exit 1
end

if contains -- --help $argv; or contains -- -h $argv
    exec $script --help
end

function _launch_foreground
    echo "Launching Trinity Habit Observer with low priority (nice -n 15 ionice -c3)..."
    exec nice -n 15 ionice -c3 -n7 $script $argv
end

function _start
    if test -f $PID_FILE
        set oldpid (cat $PID_FILE 2>/dev/null)
        if ps -p $oldpid >/dev/null 2>&1
            echo "Observer already running (pid $oldpid). Use 'trinity-habit-observer restart' or 'stop' first."
            return 0
        end
    end
    echo "Starting Trinity Habit Observer persistently (low priority, Center white HQ safe)..."
    nohup nice -n 15 ionice -c 3 -n7 $script >> $LOG_FILE 2>&1 &
    set bgpid $last_pid
    echo $bgpid > $PID_FILE
    sleep 1
    # Force correct priority (workaround for some launch environments where initial nice doesn't stick to 15)
    renice -n 15 $bgpid >/dev/null 2>&1 || true
    ionice -c 3 -n 7 -p $bgpid >/dev/null 2>&1 || true
    echo "Started (pid $bgpid, forced nice 15 / idle io). Logs: tail -f $LOG_FILE"
    echo "Status: trinity-habit-observer status"
end

function _stop
    if not test -f $PID_FILE
        echo "No pid file. Trying pkill..."
        pkill -f 'trinity-habit-observer.sh' 2>/dev/null || true
        return
    end
    set pid (cat $PID_FILE 2>/dev/null)
    if test -n "$pid"; and ps -p $pid >/dev/null 2>&1
        echo "Stopping observer (pid $pid)..."
        kill $pid 2>/dev/null || true
        sleep 1
        if ps -p $pid >/dev/null 2>&1
            kill -9 $pid 2>/dev/null || true
        end
    end
    rm -f $PID_FILE
    pkill -f 'trinity-habit-observer.sh' 2>/dev/null || true
    echo "Observer stopped."
end

function _status
    echo "Trinity Habit Observer status:"
    if test -f $PID_FILE
        set pid (cat $PID_FILE 2>/dev/null)
        if test -n "$pid"; and ps -p $pid >/dev/null 2>&1
            # Ensure correct low priority (force if not 15)
            set current_nice (ps -o nice= -p $pid | string trim)
            if test "$current_nice" != "15"
                renice -n 15 $pid >/dev/null 2>&1 || true
                ionice -c 3 -n 7 -p $pid >/dev/null 2>&1 || true
            end
            echo "  Running (pid $pid, low-prio)"
            ps -o pid,nice,comm -p $pid
            return
        end
    end
    if pgrep -f 'trinity-habit-observer.sh' >/dev/null 2>&1
        echo "  Running (detected, no/invalid pid file)"
        pgrep -af 'trinity-habit-observer.sh'
    else
        echo "  Not running"
    end
end

function _restart
    _stop
    sleep 1
    _start
end

switch $argv[1]
    case start
        _start
    case stop
        _stop
    case status
        _status
    case restart
        _restart
    case '*'
        _launch_foreground
end
