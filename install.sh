#!/usr/bin/env bash
set -euo pipefail

AUTO_YES=0
DEBUG=0

usage() {
  cat <<'EOF'
Usage: install.sh [--debug] [-y|--yes]

  --debug   Show full command output.
  -y,--yes  Accept all prompts automatically.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --debug) DEBUG=1 ;;
    -y|--yes) AUTO_YES=1 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $arg" >&2; usage; exit 1 ;;
  esac
done

# Set APT_YES_FLAG based on AUTO_YES
if [[ "$AUTO_YES" -eq 1 ]]; then
  APT_YES_FLAG="-y"
else
  APT_YES_FLAG=""
fi

if command -v tput >/dev/null 2>&1; then
  COLOR_OK=$(tput setaf 2)
  COLOR_WARN=$(tput setaf 3)
  COLOR_ERR=$(tput setaf 1)
  COLOR_INFO=$(tput setaf 6)
  COLOR_DIM=$(tput setaf 7)
  COLOR_RESET=$(tput sgr0)
else
  COLOR_OK=""
  COLOR_WARN=""
  COLOR_ERR=""
  COLOR_INFO=""
  COLOR_DIM=""
  COLOR_RESET=""
fi

fail() {
  echo "${COLOR_ERR}[error]${COLOR_RESET} $*" >&2
  exit 1
}

info() {
  echo "${COLOR_INFO}[info]${COLOR_RESET} $*"
}

warn() {
  echo "${COLOR_WARN}[warn]${COLOR_RESET} $*" >&2
}

ok() {
  echo "${COLOR_OK}[ok]${COLOR_RESET} $*"
}

prompt_confirm() {
  local message="$1"
  if [[ "$AUTO_YES" -eq 1 ]]; then
    echo "${COLOR_DIM}[auto-yes]${COLOR_RESET} $message"
    return 0
  fi
  read -r -p "$message [y/N]: " reply
  [[ "$reply" == "y" || "$reply" == "Y" ]]
}

LOG_DIR="${LOG_DIR:-$HOME/.cache/huawei-fnkeys-fix/logs}"
CONFIG_DIR="$HOME/.config/input-remapper-2"
PRESET_DEVICE="Huawei WMI hotkeys"
PRESET_NAME="volume-ignore"
PRESET_DIR="$CONFIG_DIR/presets/$PRESET_DEVICE"
PRESET_FILE="$PRESET_DIR/$PRESET_NAME.json"
CONFIG_FILE="$CONFIG_DIR/config.json"

run_cmd() {
  local label="$1"
  shift
  mkdir -p "$LOG_DIR"
  if [[ "$DEBUG" -eq 1 ]]; then
    info "$label"
    "$@"
  else
    local log_file
    log_file="$LOG_DIR/$(date +%Y%m%d-%H%M%S)-${label// /_}.log"
    info "$label (log: $log_file)"
    if ! "$@" >"$log_file" 2>&1; then
      warn "$label failed; see $log_file"
      tail -n 40 "$log_file" >&2 || true
      return 1
    fi
  fi
}

if ! command -v apt >/dev/null 2>&1; then
  fail "apt not found; this installer targets Debian-based systems"
fi

info "Installing input-remapper"
run_cmd "apt update" sudo apt update
run_cmd "install input-remapper" sudo apt install $APT_YES_FLAG input-remapper

info "Creating input-remapper preset"
run_cmd "create preset dir" mkdir -p "$PRESET_DIR"
cat >"$PRESET_FILE" <<'EOF'
[
  {
    "input_combination": [
      {
        "type": 1,
        "code": 114
      }
    ],
    "output_symbol": "disable",
    "target_uinput": "keyboard"
  },
  {
    "input_combination": [
      {
        "type": 1,
        "code": 115
      }
    ],
    "output_symbol": "disable",
    "target_uinput": "keyboard"
  }
]
EOF
ok "Preset created: $PRESET_FILE"

info "Configuring autoload"
python3 - <<'PY'
import json
import os

config_file = os.path.expanduser("~/.config/input-remapper-2/config.json")
os.makedirs(os.path.dirname(config_file), exist_ok=True)

data = {}
if os.path.exists(config_file):
  try:
    with open(config_file, "r", encoding="utf-8") as fh:
      data = json.load(fh)
  except json.JSONDecodeError:
    data = {}

data.setdefault("autoload", {})
data["autoload"]["Huawei WMI hotkeys"] = "volume-ignore"

if "version" not in data:
  try:
    from inputremapper.logging.logger import VERSION

    data["version"] = VERSION
  except Exception:
    data["version"] = "2.1.1"

with open(config_file, "w", encoding="utf-8") as fh:
  json.dump(data, fh, indent=4)
  fh.write("\n")
PY
ok "Autoload set in: $CONFIG_FILE"

if prompt_confirm "Enable input-remapper daemon and autoload preset?"; then
  if command -v systemctl >/dev/null 2>&1; then
    run_cmd "enable input-remapper-daemon" sudo systemctl enable --now input-remapper-daemon.service
    if systemctl list-unit-files --type=service | grep -q '^input-remapper-gtk-autostart'; then
      run_cmd "disable input-remapper-gtk-autostart" sudo systemctl disable input-remapper-gtk-autostart
    fi
  else
    warn "systemctl not found; enable input-remapper-daemon manually"
  fi

  if command -v input-remapper-control >/dev/null 2>&1; then
    run_cmd "autoload preset" input-remapper-control --command autoload
  else
    warn "input-remapper-control not found; open input-remapper-gtk and enable autoload"
  fi
else
  warn "Skipped daemon/autoload setup"
fi

ok "done"
info "Checks:"
info "  systemctl status input-remapper-daemon.service"
info "  input-remapper-control --list-presets"
info "  xinput test \"$PRESET_DEVICE\""
