# ------------------------------------------------------------------------------
# Rex app settings.
#
# Rex keeps font, theme, panes and sidebar in the defaults domain
# com.superlogical.rex, next to window frames, sync records and the last
# focused session. cfprefsd owns that plist, so it can't be stowed. Only the
# Workspace.* keys are tracked, in rex-settings.json, minus the two that hold
# session state. Applying merges them into the live domain and leaves the other
# keys alone.
#
# The custom themes are a data value holding JSON. The file stores them
# decoded, as {"$json": ...}, so a theme change shows up as a readable diff.
# ------------------------------------------------------------------------------
REX_DOMAIN="com.superlogical.rex"
REX_SETTINGS_FILE="$DOTFILES_DIR/rex-settings.json"

# usage: rex_settings_py save <live.plist> <settings.json>
#        rex_settings_py merge <live.plist> <settings.json> <merged.plist>
rex_settings_py() {
  python3 -I - "$@" <<'PY'
import json, plistlib, sys

STATE = {"Workspace.lastFocusedSession", "Workspace.programActivitySeen"}

def tracked(key):
    return key.startswith("Workspace.") and key not in STATE

def to_json(value):
    return {"$json": json.loads(value)} if isinstance(value, bytes) else value

def from_json(value):
    if isinstance(value, dict) and set(value) == {"$json"}:
        return json.dumps(value["$json"], ensure_ascii=False, separators=(",", ":")).encode()
    return value

cmd, live_path, settings_path = sys.argv[1:4]
with open(live_path, "rb") as f:
    live = plistlib.load(f)

if cmd == "save":
    settings = {k: to_json(v) for k, v in sorted(live.items()) if tracked(k)}
    with open(settings_path, "w") as f:
        json.dump(settings, f, indent=2, ensure_ascii=False)
        f.write("\n")
elif cmd == "merge":
    with open(settings_path) as f:
        settings = json.load(f)
    for key, value in settings.items():
        current = live.get(key)
        if isinstance(current, bytes) and to_json(current) == value:
            continue  # same content, so keep Rex's own encoding
        live[key] = from_json(value)
    with open(sys.argv[4], "wb") as f:
        plistlib.dump(live, f, fmt=plistlib.FMT_BINARY)

print(len(settings))
PY
}

apply_rex_settings() {
  section "Applying Rex settings"

  [[ -f "$REX_SETTINGS_FILE" ]] || { warn "no rex-settings.json, skipping"; return 0; }
  command -v python3 &>/dev/null || { warn "python3 is missing, skipping"; return 0; }

  local tmp count
  tmp="$(mktemp -d)"
  defaults export "$REX_DOMAIN" "$tmp/live.plist"
  count="$(rex_settings_py merge "$tmp/live.plist" "$REX_SETTINGS_FILE" "$tmp/merged.plist")"
  defaults import "$REX_DOMAIN" "$tmp/merged.plist"
  rm -rf "$tmp"

  ok "applied $count settings"
  if pgrep -xq Rex; then
    warn "Rex is open, restart it to load them"
  fi
}

save_rex_settings() {
  section "Saving Rex settings"

  command -v python3 &>/dev/null || die "python3 is required to save the Rex settings."

  local tmp count
  tmp="$(mktemp -d)"
  defaults export "$REX_DOMAIN" "$tmp/live.plist"
  count="$(rex_settings_py save "$tmp/live.plist" "$REX_SETTINGS_FILE")"
  rm -rf "$tmp"

  ok "saved $count settings to $REX_SETTINGS_FILE"
}
