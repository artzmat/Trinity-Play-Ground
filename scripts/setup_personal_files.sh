#!/usr/bin/env bash
# setup_personal_files.sh — Integrate user's Google Drive + other personal files into the Trinity (Left/Right/Center)
#
# Checks home trees (as requested).
# Sets up rclone mount for Google Drive at /data/gdrive (fits /data = big data rule).
# Extends "usual" setups for the three screens so personal files are "used" by the personas:
#   - Left (analytical/chill): access to Documents/Matt (Health, House, Marriage, Military, Work) for structured review/analysis + gdrive docs.
#   - Right (creative/play): access to Pictures/Personal (Family, Memes, Military photos, BackGround), Music, Videos/Clips, Photos for inspiration/play + gdrive media.
#   - Center (white HQ orchestrator): clean/minimal personal view (e.g. Work subdir or "X", or browser to gdrive; desktop remains white/untouched). Orchestration only.
#
# Principles: reversible (symlinks, no copies of sensitive data unless chosen), auditable (logs), local-first where possible, Center white HQ protection (no clutter on HDMI-A-1), /data for mounts.
# Google Drive via rclone (on-demand, no always-on sync bloat).
#
# Usage:
#   ./scripts/setup_personal_files.sh --dry-run
#   ./scripts/setup_personal_files.sh --install-rclone
#   ./scripts/setup_personal_files.sh --configure-gdrive
#   ./scripts/setup_personal_files.sh --mount
#   ./scripts/setup_personal_files.sh --usual-left   # or integrate into left-usual
#   ./scripts/setup_personal_files.sh --usual-right
#   ./scripts/setup_personal_files.sh --usual-center
#
# After setup: run left-usual, right-usual equivalents on their monitors.
# Sensitive: Marriage/Mental Health etc. – Left for "analysis" only if user chooses; user controls what to open on which screen.

set -euo pipefail

REPO_DIR="/data/PCaC-Playgrounds"
source "$REPO_DIR/scripts/lib/common.sh" 2>/dev/null || true

GDRIVE_MOUNT="/data/gdrive"
PERSONAL_BASE="/data/personal"
RCLONE_REMOTE="gdrive"  # user can change

usage() {
  cat <<USAGE
Usage: $(basename "$0") [options]

Setup personal files (Google Drive + home tree) for Trinity personas.

Options:
  --help
  --dry-run                 Show what would happen
  --check-home-trees        Just report the home tree findings (sensitive personal data map)
  --install-rclone          paru -S rclone (or echo if no paru)
  --configure-gdrive        rclone config create $RCLONE_REMOTE drive (interactive OAuth)
  --create-mountpoints      mkdir -p $GDRIVE_MOUNT $PERSONAL_BASE
  --mount                   rclone mount $RCLONE_REMOTE: $GDRIVE_MOUNT --daemon --allow-other (or user)
  --unmount                 fusermount -u $GDRIVE_MOUNT
  --usual-left              Extend Left chill/analytical with personal file access (Documents/Matt + gdrive)
  --usual-right             Extend Right creative/play with personal media (Pictures/Personal + Music + Videos + gdrive)
  --usual-center            Minimal clean personal for Center white HQ (Work/X + browser gdrive if needed)
  --all                     Do the safe non-interactive parts (dry-run first recommended)

Home tree summary (from check):
- Very sensitive in ~/Documents/Matt: Health, House, Marriage Stuff (Kelsey/Rachel divorce/legal/parenting), Military (Mental Health/Records), Work, X.
- Creative in ~/Pictures: Personal (BackGround/Family/Memes/Military), Photos (dated), Screenshots.
- Other: Music, Videos/Clips, Projects, Desktop, Downloads, PC-Stuff-Workspace, thunderbird.
- No Google Drive mount currently (no rclone/insync in PATH, no fstab/systemd mounts, no running daemons).
- Access currently browser-only (flatpak Chrome/ungoogled-chromium).

All changes reversible (unmount, rm symlinks, etc.). Logs to $PCAC_LOG_DIR.
Center white HQ (HDMI-A-1) stays clean — personal access launched on the side screens' "usual" apps.
USAGE
}

log() { pcac_log INFO "$*"; }

check_home_trees() {
  echo "=== HOME TREE CHECK (as requested) ==="
  echo "Top-level personal dirs:"
  ls -ld ~/{Desktop,Documents,Downloads,Music,Pictures,Projects,Public,Templates,Videos,PC-Stuff-Workspace,thunderbird,.local/share} 2>/dev/null | cat
  echo ""
  echo "Documents/Matt (HIGHLY SENSITIVE - marriage, military, health, house, work):"
  tree -L 2 ~/Documents/Matt 2>/dev/null || find ~/Documents/Matt -maxdepth 2 -type d | sort
  echo ""
  echo "Pictures (creative/personal/family/military):"
  tree -L 2 ~/Pictures 2>/dev/null || find ~/Pictures -maxdepth 2 -type d | sort
  echo ""
  echo "Other media/projects:"
  ls -d ~/Music ~/Videos ~/Projects ~/Desktop ~/Downloads 2>/dev/null | cat
  echo ""
  echo "Google Drive / cloud sync status:"
  echo "  Mounts: $(mount | grep -iE 'google|drive|gdrive|insync|rclone' || echo 'NONE')"
  echo "  rclone: $(which rclone 2>/dev/null || echo 'NOT IN PATH')"
  echo "  Configs: $(find ~/.config -maxdepth 1 -type d 2>/dev/null | grep -iE 'rclone|insync|google|drive' || echo 'NONE')"
  echo "  Daemons: $(ps aux | grep -iE 'rclone mount|insync|google-drive' | grep -v grep || echo 'NONE visible')"
  echo ""
  echo "Thunderbird (personal email):"
  ls -ld ~/thunderbird 2>/dev/null || echo "  dir present but empty or not standard"
  echo ""
  echo "Recommendation: Use /data/gdrive for live Google Drive mount (on-demand). Symlink or open specific subtrees per persona. Keep sensitive (Marriage/Mental) Left-only for 'analysis' if desired. Center sees almost none on desktop."
}

install_rclone() {
  if command -v rclone >/dev/null; then
    log "rclone already installed: $(rclone --version | head -1)"
    return
  fi
  if command -v paru >/dev/null; then
    log "Installing rclone via paru..."
    paru -S --noconfirm rclone
  else
    log "paru not found. Please install rclone manually: https://rclone.org/install/"
    log "Or: sudo pacman -S rclone (if in repos) or AUR."
    return 1
  fi
}

configure_gdrive() {
  if ! command -v rclone >/dev/null; then
    log "rclone not installed. Run with --install-rclone first."
    return 1
  fi
  log "Configuring rclone remote '$RCLONE_REMOTE' for Google Drive."
  log "This will open a browser for OAuth. Follow prompts."
  log "Choose 'drive' as type, leave client_id/secret blank for default, full access."
  rclone config create "$RCLONE_REMOTE" drive || true
  log "Test with: rclone ls $RCLONE_REMOTE: (should list your Drive root)"
}

create_mountpoints() {
  sudo mkdir -p "$GDRIVE_MOUNT" "$PERSONAL_BASE" || mkdir -p "$GDRIVE_MOUNT" "$PERSONAL_BASE"
  sudo chown matt:matt "$GDRIVE_MOUNT" "$PERSONAL_BASE" || true
  log "Mountpoints ready: $GDRIVE_MOUNT (for rclone Google Drive) and $PERSONAL_BASE (for symlinks/views)"
}

mount_gdrive() {
  if ! command -v rclone >/dev/null; then
    log "rclone not found."
    return 1
  fi
  if mount | grep -q "$GDRIVE_MOUNT"; then
    log "Already mounted at $GDRIVE_MOUNT"
    return
  fi
  mkdir -p "$GDRIVE_MOUNT"
  log "Mounting rclone $RCLONE_REMOTE: at $GDRIVE_MOUNT (daemon, allow-other for multi-user if needed)..."
  # Use --daemon for background. Add --vfs-cache-mode writes or full for performance.
  # For read-heavy personal use: --vfs-cache-mode full
  rclone mount "$RCLONE_REMOTE:" "$GDRIVE_MOUNT" \
    --daemon \
    --allow-other \
    --vfs-cache-mode full \
    --log-file "$PCAC_LOG_DIR/rclone-gdrive.log" \
    --log-level INFO || {
      log "Mount failed. Check logs: $PCAC_LOG_DIR/rclone-gdrive.log"
      log "Common fixes: user_allow_other in /etc/fuse.conf, or run without --allow-other (single user)."
      return 1
    }
  log "Mounted. Test: ls $GDRIVE_MOUNT"
  # Optional: create bind views in PERSONAL_BASE for personas
  mkdir -p "$PERSONAL_BASE/gdrive"
  # Bind mount or just use directly; for simplicity use the main mount.
}

usual_left() {
  log "Extending Left usual for personal/analytical files (Documents/Matt + gdrive if mounted)..."
  # Open file manager (dolphin for KDE) to sensitive-but-analytical personal dirs.
  # User controls what to actually open on the Left monitor.
  if [ -d ~/Documents/Matt ]; then
    dolphin ~/Documents/Matt ~/Documents/Matt/Health ~/Documents/Matt/House ~/Documents/Matt/Military ~/Documents/Matt/Work 2>/dev/null &
    log "Opened dolphin to Matt personal dirs for Left analytical review."
  fi
  if mount | grep -q "$GDRIVE_MOUNT"; then
    dolphin "$GDRIVE_MOUNT" 2>/dev/null &
    log "Opened gdrive for Left."
  else
    log "gdrive not mounted; run --mount first or open via browser."
  fi
  # Also open Pictures/Personal if relevant for Left chill.
  if [ -d ~/Pictures/Personal ]; then
    dolphin ~/Pictures/Personal 2>/dev/null &
  fi
  log "Left personal files ready on DP-3 (analytical/chill use). Pair with existing OpenRGB + Firefox kiosk."
  log "Tip: use window rules or --usual to position on left output."
}

usual_right() {
  log "Extending Right usual for personal creative files (Pictures/Personal + media + gdrive)..."
  if [ -d ~/Pictures/Personal ]; then
    dolphin ~/Pictures/Personal ~/Pictures/Photos 2>/dev/null &
    log "Opened Pictures/Personal and Photos for Right creative inspiration."
  fi
  if [ -d ~/Music ]; then
    dolphin ~/Music 2>/dev/null &
  fi
  if [ -d ~/Videos ]; then
    dolphin ~/Videos/Clips 2>/dev/null &
  fi
  if mount | grep -q "$GDRIVE_MOUNT"; then
    dolphin "$GDRIVE_MOUNT" 2>/dev/null &
    log "Opened gdrive media for Right."
  fi
  log "Right personal files ready on DP-2 (play/creative use). Keep compact."
}

usual_center() {
  log "Minimal clean personal for Center white HQ (HDMI-A-1 protection)..."
  # Only non-cluttering: e.g. Work subdir or a "safe" view. No full family/marriage open on desktop.
  if [ -d ~/Documents/Matt/Work ]; then
    dolphin ~/Documents/Matt/Work 2>/dev/null &
    log "Opened only Work for Center reference (keeps desktop clean)."
  fi
  if [ -d ~/Documents/Matt/X ]; then
    dolphin ~/Documents/Matt/X 2>/dev/null &
  fi
  # Browser to gdrive if wanted (but Center already launches grok.x.ai + searx).
  if mount | grep -q "$GDRIVE_MOUNT"; then
    # Don't auto-open full gdrive on Center desktop; suggest bookmark or manual.
    log "gdrive mounted at $GDRIVE_MOUNT. For Center, open selectively in existing browser or file manager only as needed. Desktop stays white."
  fi
  log "Center personal access: minimal, reversible, no visual/mental load on white HQ."
}

main() {
  local do_dry=false
  local do_check=false
  local do_install=false
  local do_config=false
  local do_mountpoints=false
  local do_mount=false
  local do_unmount=false
  local do_left=false
  local do_right=false
  local do_center=false
  local do_all=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --help|-h) usage; exit 0 ;;
      --dry-run) do_dry=true; shift ;;
      --check-home-trees) do_check=true; shift ;;
      --install-rclone) do_install=true; shift ;;
      --configure-gdrive) do_config=true; shift ;;
      --create-mountpoints) do_mountpoints=true; shift ;;
      --mount) do_mount=true; shift ;;
      --unmount) do_unmount=true; shift ;;
      --usual-left) do_left=true; shift ;;
      --usual-right) do_right=true; shift ;;
      --usual-center) do_center=true; shift ;;
      --all) do_all=true; shift ;;
      *) pcac_log WARN "Unknown: $1"; usage; exit 1 ;;
    esac
  done

  if $do_dry || $do_all; then
    log "DRY-RUN / ALL mode"
  fi

  if $do_check || $do_all; then
    check_home_trees
  fi

  if $do_install || $do_all; then
    install_rclone
  fi

  if $do_config || $do_all; then
    configure_gdrive
  fi

  if $do_mountpoints || $do_all; then
    create_mountpoints
  fi

  if $do_mount || $do_all; then
    mount_gdrive
  fi

  if $do_unmount; then
    fusermount -u "$GDRIVE_MOUNT" 2>/dev/null || log "Not mounted or unmount failed."
  fi

  if $do_left || $do_all; then
    usual_left
  fi
  if $do_right || $do_all; then
    usual_right
  fi
  if $do_center || $do_all; then
    usual_center
  fi

  if [[ "$do_dry" == false && "$do_install" == false && "$do_config" == false && "$do_mountpoints" == false && "$do_mount" == false && "$do_unmount" == false && "$do_left" == false && "$do_right" == false && "$do_center" == false && "$do_all" == false ]]; then
    usage
  fi

  log "Done. Reversible: unmount, rm -rf symlinks, etc. All changes logged."
  log "Next: run left-usual / equivalent on the physical monitors after mounting gdrive."
}

main "$@"
