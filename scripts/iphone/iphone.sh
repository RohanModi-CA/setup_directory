#!/usr/bin/env bash
# iphone-mount.sh — robust iPhone mounting for Linux (AFC or PTP), with DCIM auto-detect + reset
# Tested on Ubuntu w/ zsh and bash. Requires: ifuse, libimobiledevice-utils, gvfs-backends, gvfs-fuse, (optional) gphoto2, gio.
#
# Quick install (Debian/Ubuntu):
#   sudo apt update && sudo apt install -y ifuse libimobiledevice6 libimobiledevice-utils gvfs-backends gvfs-fuse gphoto2
#
# Usage:
#   ./iphone-mount.sh pair
#   ./iphone-mount.sh list
#   ./iphone-mount.sh status
#   ./iphone-mount.sh mount afc
#   ./iphone-mount.sh mount dcim            # tries PTP first; falls back to AFC+bind
#   ./iphone-mount.sh mount dcim --method=ptp|afc
#   ./iphone-mount.sh mount app com.apple.DocumentsApp
#   ./iphone-mount.sh mount all              # afc + dcim
#   ./iphone-mount.sh unmount
#   ./iphone-mount.sh reset                  # force unmounts, restarts gvfs, cleans dirs

set -Eeuo pipefail

LOG_PREFIX="[iphone-mount]"
info(){ printf "%s %s\n" "$LOG_PREFIX" "$*"; }
warn(){ printf "%s WARN: %s\n" "$LOG_PREFIX" "$*" >&2; }
err(){  printf "%s ERROR: %s\n" "$LOG_PREFIX" "$*" >&2; }
have(){ command -v "$1" >/dev/null 2>&1; }
mountpoint_q(){ mountpoint -q "$1"; }

# ---- Paths
USER_ID="$(id -u)"
MOUNT_BASE="${HOME}/mnt/iphone"
AFC_MOUNT="${MOUNT_BASE}/afc"
DCIM_MOUNT="${MOUNT_BASE}/dcim"
APPS_MOUNT_BASE="${MOUNT_BASE}/apps"
TMP_AFC="/tmp/iphone-afc-${USER_ID}"           # never mount temp under $MOUNT_BASE
GVFS_DIR="/run/user/${USER_ID}/gvfs"

# ---- Ensure dirs
ensure_dirs(){ mkdir -p "$MOUNT_BASE" "$AFC_MOUNT" "$DCIM_MOUNT" "$APPS_MOUNT_BASE"; }

# ---- Dependencies
need_tools=( idevice_id idevicepair ifuse )
for t in "${need_tools[@]}"; do
  if ! have "$t"; then err "Missing '$t' (install libimobiledevice/ifuse packages)."; exit 1; fi
done
# Optional but recommended for PTP:
if ! have gio || ! have gphoto2; then
  warn "Optional PTP helpers missing (gio and/or gphoto2). PTP mounting may be limited."
fi

# ---- Pairing
get_udid(){ idevice_id -l | head -n1 || true; }
pair_device(){
  local udid="$1"
  if [[ -z "$udid" ]]; then err "No iPhone detected (unlock phone, check cable, tap Trust)."; exit 2; fi
  if ! idevicepair validate >/dev/null 2>&1; then
    info "Pairing with $udid (tap 'Trust' on iPhone if prompted)..."
    idevicepair pair || { err "Pairing failed."; exit 3; }
  fi
  info "Paired with $udid."
}

# ---- Unmount helpers
fusermount_un(){
  local p="$1"
  fusermount3 -uz "$p" 2>/dev/null || fusermount -uz "$p" 2>/dev/null || sudo umount -l "$p" 2>/dev/null || true
}
gio_unmount_uri(){
  local uri="$1"
  if have gio; then gio mount -u "$uri" 2>/dev/null || true; fi
}

unmount_all(){
  info "Unmounting iPhone mounts..."
  # Unmount bind/DCIM first
  sudo umount -l "$DCIM_MOUNT" 2>/dev/null || true
  # Unmount AFC mount + temp AFC
  fusermount_un "$AFC_MOUNT"
  fusermount_un "$TMP_AFC"
  rmdir "$TMP_AFC" 2>/dev/null || true
  # Unmount any GVFS gphoto mounts
  if mount | grep -q gphoto; then
    while read -r mp; do sudo umount -l "$mp" 2>/dev/null || true; done < <(mount | awk '/gphoto/ {print $3}')
  fi
  # Clean empty dirs
  rmdir "$AFC_MOUNT" "$DCIM_MOUNT" 2>/dev/null || true
  info "Unmount complete."
}

# ---- Reset GVFS (user services)
restart_gvfs(){
  if have systemctl; then
    systemctl --user restart gvfs-daemon gvfs-gphoto2-volume-monitor.service 2>/dev/null || true
  fi
}

# ---- Status
status(){
  info "Mounts:"
  mount | grep -E 'ifuse|gphoto' || echo "  (none)"
  echo
  info "Paths:"
  echo "  AFC:  $AFC_MOUNT  $(mountpoint -q "$AFC_MOUNT" && echo '[mounted]' || true)"
  echo "  DCIM: $DCIM_MOUNT $(mountpoint -q "$DCIM_MOUNT" && echo '[mounted]' || true)"
  echo "  GVFS: $GVFS_DIR"
}

# ---- Mount: AFC
mount_afc(){
  ensure_dirs
  # Avoid racing with PTP
  if mount | grep -q gphoto; then
    warn "PTP (gphoto2) is mounted; unmounting to avoid races."
    while read -r mp; do sudo umount -l "$mp" 2>/dev/null || true; done < <(mount | awk '/gphoto/ {print $3}')
  fi
  if mountpoint_q "$AFC_MOUNT"; then info "AFC already mounted at $AFC_MOUNT"; return; fi
  info "Mounting AFC at $AFC_MOUNT ..."
  ifuse "$AFC_MOUNT"
  info "AFC mounted."
}

# ---- Mount: DCIM via PTP (GVFS/gphoto2)
ptp_mount_dcim(){
  ensure_dirs
  # Ensure AFC is not mounted to avoid conflicts
  fusermount_un "$AFC_MOUNT"

  if ! have gio; then err "gio not installed; cannot perform PTP mount."; return 1; fi

  restart_gvfs

  # Use gio to mount the iPhone camera endpoint
  local URI
  URI="$(gio mount -li | awk -F'=| ' '/activation_root=gphoto2:.*Apple_.*iPhone/ {print $2; exit}')"
  if [[ -z "${URI:-}" ]]; then
    warn "No gphoto2 activation_root found. Ensure phone is unlocked; try taking a fresh photo."
  else
    info "Mounting PTP via GVFS: $URI"
    gio mount "$URI" || warn "gio mount returned non-zero (check iPhone 'Allow photos/videos' prompt)."
  fi

  # Discover the mounted directory under GVFS
  local IPH_DIR
  IPH_DIR="$(find "$GVFS_DIR" -maxdepth 1 -type d -name 'gphoto2:host=Apple_*_iPhone_*' -print -quit 2>/dev/null || true)"
  if [[ -z "${IPH_DIR:-}" ]]; then
    err "PTP mount not found under $GVFS_DIR. iPhone must be unlocked; tap 'Allow' for photos/videos."
    return 2
  fi
  info "GVFS PTP path: $IPH_DIR"

  # Verify DCIM exists
  if [[ ! -d "$IPH_DIR/DCIM" ]]; then
    err "No DCIM at $IPH_DIR/DCIM (phone locked? no local photos? try opening Photos app and taking 1 new photo)."
    return 3
  fi

  info "PTP/DCIM ready at: $IPH_DIR/DCIM"
  # We do NOT bind the GVFS path; tools should read from the GVFS path directly.
  echo "$IPH_DIR/DCIM"
  return 0
}

# ---- Mount: DCIM via AFC + bind (fallback & for rsync workflows)
afc_bind_dcim(){
  ensure_dirs
  mount_afc
  # Probe common DCIM locations
  local candidates=(
    "$AFC_MOUNT/DCIM"
    "$AFC_MOUNT/var/mobile/Media/DCIM"
    "$AFC_MOUNT/private/var/mobile/Media/DCIM"
  )
  local SRC=""
  for p in "${candidates[@]}"; do
    if [[ -d "$p" ]]; then SRC="$p"; break; fi
  done
  if [[ -z "$SRC" ]]; then
    # Deep search (up to depth 4)
    SRC="$(find "$AFC_MOUNT" -maxdepth 4 -type d -name DCIM -print -quit 2>/dev/null || true)"
  fi
  if [[ -z "$SRC" ]]; then
    err "DCIM not found under AFC. Open Photos, ensure at least one local photo exists, then retry."
    return 4
  fi
  info "Binding DCIM from: $SRC"
  mkdir -p "$DCIM_MOUNT"
  if mountpoint_q "$DCIM_MOUNT"; then
    info "DCIM already bound at $DCIM_MOUNT"
  else
    sudo mount --bind "$SRC" "$DCIM_MOUNT"
    info "DCIM available at $DCIM_MOUNT"
  fi
}

# ---- Mount: app sandbox by bundle id
mount_app(){
  local bundle="$1"
  if [[ -z "${bundle:-}" ]]; then err "Usage: mount app <bundleId>"; exit 5; fi
  ensure_dirs
  local mount_dir="${APPS_MOUNT_BASE}/${bundle}"
  mkdir -p "$mount_dir"
  if mountpoint_q "$mount_dir"; then info "App already mounted at $mount_dir"; return; fi
  info "Mounting app '$bundle' at $mount_dir ..."
  ifuse "$mount_dir" --appid "$bundle" || { err "ApplicationLookupFailed: bundle id invalid or app not exposable via iTunes File Sharing."; exit 6; }
  info "App mounted."
}

# ---- List services / info
list_services(){
  info "ifuse services:"
  ifuse --list || true
  if have gphoto2; then
    echo
    info "gphoto2 auto-detect:"
    gphoto2 --auto-detect || true
  fi
}

# ---- Commands
cmd="${1:-}"; shift || true
sub="${1:-}"; [[ -n "${sub:-}" ]] && shift || true

case "${cmd:-}" in
  pair)
    pair_device "$(get_udid)"
    ;;
  list)
    list_services
    ;;
  status)
    status
    ;;
  reset)
    unmount_all
    restart_gvfs
    ensure_dirs
    info "Reset complete."
    ;;
  unmount)
    unmount_all
    ;;
  mount)
    case "${sub:-}" in
      afc)
        pair_device "$(get_udid)"; mount_afc
        ;;
      app)
        pair_device "$(get_udid)"; mount_app "${1:-}"
        ;;
      dcim)
        pair_device "$(get_udid)"
        # Parse optional --method=
        METHOD="auto"
        while [[ "${1:-}" == --method=* ]]; do METHOD="${1#--method=}"; shift || true; done
        case "$METHOD" in
          ptp)
            ptp_mount_dcim || { err "PTP/DCIM mount failed."; exit 7; }
            ;;
          afc)
            afc_bind_dcim || { err "AFC/DCIM bind failed."; exit 8; }
            ;;
          auto)
            if ptp_mount_dcim >/dev/null 2>&1; then
              PTPCMD="$(ptp_mount_dcim || true)"; [[ -n "${PTPCMD:-}" ]] && info "Use this path for imports: ${PTPCMD}"
            else
              warn "Falling back to AFC bind for DCIM..."
              afc_bind_dcim || { err "AFC fallback failed."; exit 9; }
            fi
            ;;
          *)
            err "Unknown --method=$METHOD (use ptp|afc|auto)"; exit 10;;
        esac
        ;;
      all)
        pair_device "$(get_udid)"
        mount_afc
        # Try PTP first for better gThumb UX; bind fallback if needed
        if ! ptp_mount_dcim >/dev/null 2>&1; then
          warn "PTP/DCIM unavailable; binding DCIM via AFC."
          afc_bind_dcim || { err "Could not expose DCIM."; exit 11; }
        else
          info "PTP/DCIM mounted via GVFS (see status for path)."
        fi
        ;;
      *)
        cat <<EOF
Usage: $0 mount [afc|dcim|app <bundle>|all] [--method=ptp|afc|auto]
EOF
        exit 1
        ;;
    esac
    ;;
  ""|-h|--help|help)
    cat <<EOF
iPhone Mount Helper

Commands:
  pair                     Pair/validate trust with the connected iPhone.
  list                     List ifuse services and (optionally) gphoto2 devices.
  status                   Show current mount status.
  mount afc                Mount AFC (user data) at: $AFC_MOUNT
  mount dcim [--method=ptp|afc|auto]
                           Expose DCIM. PTP gives a GVFS path; AFC binds DCIM to: $DCIM_MOUNT
  mount app <bundle>       Mount a specific app's container at: $APPS_MOUNT_BASE/<bundle>
  mount all                Mount AFC and attempt DCIM (PTP preferred, AFC bind fallback).
  unmount                  Unmount AFC, DCIM (bind), GVFS/PTP and clean temp mounts.
  reset                    Unmount everything, restart GVFS user services, recreate dirs.

Tips:
- PTP requires tapping "Allow photos/videos" on iPhone (separate from "Trust this computer").
- Don't mix AFC and PTP simultaneously; this script avoids races, but tools can still hold handles.
- If DCIM is "missing", open Photos on the phone and take one new picture to initialize it.

EOF
    ;;
  *)
    err "Unknown command '$cmd'"; exit 1
    ;;
esac
