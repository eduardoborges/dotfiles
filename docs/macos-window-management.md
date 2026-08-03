# macOS window management

This setup uses [yabai](https://github.com/asmvik/yabai) for BSP tiling and
[skhd](https://github.com/asmvik/skhd) for global hotkeys. The advanced profile
uses yabai's scripting addition with System Integrity Protection partially
disabled. Window opacity remains at 100%, and JankyBorders highlights the
focused window.

`Option` (`Alt` in the config) plays the same role as `Super` in the Hyprland
configuration.

## Applications

| Shortcut | Action |
| --- | --- |
| `Option + Return` | Open a new Ghostty instance |
| `Option + Command + Return` | Open Ghostty with tmux when available |
| `Option + Shift + Return` | Open or focus Google Chrome |
| `Option + Shift + B` | Open or focus Google Chrome |
| `Option + Shift + Command + B` | Open an incognito Chrome window |
| `Option + Shift + F` | Open Finder at Home |
| `Option + Shift + M` | Open or focus Spotify |
| `Option + Shift + N` | Open or focus VS Code Insiders |
| `Option + Shift + D` | Open or focus Docker |
| `Option + /` | Open or focus 1Password |
| `Option + Shift + /` | Open or focus 1Password |
| `Option + Shift + S` | Open or focus Slack |
| `Option + Shift + G` | Open ChatGPT |
| `Option + Shift + C` | Open Notion Calendar |
| `Option + Shift + W` | Open WhatsApp |

## Focus, movement, and resizing

| Shortcut | Action |
| --- | --- |
| `Option + H/J/K/L` or arrows | Focus west/south/north/east |
| `Option + Shift + H/J/K/L` or arrows | Move the window in the BSP tree |
| `Option + Command + H/J/K/L` | Swap with the adjacent window |
| `Option + Command + Shift + H/J/K/L` | Stack with the adjacent window |
| `Option + Control + H/J/K/L` | Resize the focused window |
| `Option + Control + Shift + H/J/K/L` | Set the next insertion direction |
| `Option + Command + Left/Right` | Focus the display to the west/east |
| `Option + Command + Shift + Left/Right` | Move the window to another display |

Horizontal focus and movement automatically cross to an adjacent display when
there is no window in that direction.

## Spaces

| Shortcut | Action |
| --- | --- |
| `Option + 1…9` | Focus logical Space 1…9, creating missing Spaces first |
| `Option + Shift + 1…9` | Move the window to that Space and follow it, creating missing Spaces first |
| `Option + Control + Left/Right` | Focus the previous/next Space |

The shortcut helper dynamically resolves normal Spaces and ignores
native-fullscreen Spaces, so opening a fullscreen app does not shift the
numeric shortcuts. `ws-N` labels are also recreated after login for inspection
and direct yabai commands, but the keyboard shortcuts do not depend on them.
The number row uses physical keycodes, so Option-generated symbols from
international keyboard layouts do not interfere.
The login bootstrap keeps at least 7 normal Spaces available by default.

## Layout

| Shortcut | Action |
| --- | --- |
| `Option + Shift + Space` | Toggle the focused window between floating and tiled |
| `Option + F` | Toggle zoom fullscreen |
| `Option + E` | Balance all windows |
| `Option + R` | Rotate the BSP tree 90 degrees |
| `Option + T` | Toggle the focused split orientation |
| `Option + Command + X/Y` | Mirror the layout on the X/Y axis |
| `Option + Command + B` | Set the current Space to BSP |
| `Option + Command + F` | Set the current Space to floating |
| `Option + P` | Toggle sticky window |
| `Option + Shift + P` | Toggle picture-in-picture |
| `Option + Command + Up/Down` | Raise/lower the window layer |
| `Option + Q` | Close the focused window |

## Scratchpad

Focus a window and press `Option + Shift + Grave` once to assign it as the
`terminal` scratchpad. Afterwards, `Option + Grave` toggles it from any Space.

## Space management

| Shortcut | Action |
| --- | --- |
| `Option + Command + N` | Create and focus a new Space |
| `Option + Command + Backspace` | Destroy the current Space |
| `Option + Control + Command + Left/Right` | Reorder the current Space |
| `Option + Control + Command + Shift + Left/Right` | Move the current Space to another display |

## Mouse

Hold `Option` while dragging:

- Left button: move a window.
- Right button: resize a window.
- Drop one tiled window on another: swap them.

## Installation and diagnostics

Run:

```bash
./install.sh
```

On macOS the installer:

1. Installs `yabai` and `skhd` from `asmvik/formulae` when missing.
2. Links `.yabairc`, `.skhdrc`, and the Space helpers through GNU Stow.
3. Starts or restarts both launchd services.
4. Registers a login bootstrap that repairs launch-order races after reboot.
5. Configures and loads the scripting addition when SIP allows it.
6. Prints a diagnostic summary.

Both binaries need permission in **System Settings → Privacy & Security →
Accessibility**. Window animations additionally require yabai under **Screen &
System Audio Recording**.

On Apple Silicon, after setting `-arm64e_preview_abi` in NVRAM, reboot once
before the scripting addition can load. Verify the active kernel arguments
with:

```bash
sysctl kern.bootargs
```

Useful manual checks:

```bash
yabai -m query --spaces
yabai -m query --windows --space
yabai --restart-service
skhd --restart-service
```

## macOS 27 "Golden Gate"

Every Space command silently no-ops on Golden Gate with a stock yabai build.
`yabai -m space --focus 5` and `space --create` both exit 0 and change nothing,
which takes down `Option + 1…9` and `Option + Control + Left/Right` at once. The
cause is the scripting addition: Apple moved the seven patched functions inside
the Dock binary, so the Tahoe offsets no longer resolve. Upstream v7.1.25 (May
2026) predates the beta and carries no fix.

The offsets and byte patterns live in [asmvik/yabai#2802][gg-issue]. Confirm
they still apply to the installed Dock before building anything, using the
[offset checker][gg-gist] linked from that issue:

```bash
python3 verify_offsets.py /System/Library/CoreServices/Dock.app/Contents/MacOS/Dock
```

`OK` and `MOVED` rows are a one-line edit each; a `CHANGED` row needs Ghidra.
Apple reshuffles these every few betas, so re-run the checker after every
system update. Verified 7/7 `OK` on build `26A5388g`.

Building from the patched fork replaces the Homebrew binary:

```bash
git clone https://github.com/AhsanFazal/yabai && cd yabai
make install-local
brew pin yabai
```

`install-local` needs a self-signed `yabai-cert` Code Signing identity in the
keychain (Keychain Access → Certificate Assistant → Create a Certificate). It
codesigns with that stable identity so the Accessibility grant survives
rebuilds, and rewrites `/etc/sudoers.d/yabai` with the new binary's hash. The
`brew pin` matters: an unpinned `brew upgrade` restores the broken build.

Confirm the addition actually loaded, rather than trusting the exit code:

```bash
plutil -p /Library/ScriptingAdditions/yabai.osax/Contents/Info.plist \
  | grep CFBundleShortVersionString
yabai -m space --focus 5 && yabai -m query --spaces --space
```

[gg-issue]: https://github.com/asmvik/yabai/issues/2802
[gg-gist]: https://gist.github.com/AhsanFazal/d18a54b9dc0f259b49e21b8ed70078d2

### Native Space hotkeys are disabled

skhd owns `Option + digit` and `Option + Arrow` outright. The matching native
shortcuts are switched off in `com.apple.symbolichotkeys`, because macOS
symbolic hotkeys are handled by the WindowServer and win over skhd's event tap:

| ID | Action |
| --- | --- |
| 79-82 | Move left/right a Space |
| 118-127 | Switch to Desktop 1-10 |

Do not try to rebind these in **System Settings → Keyboard → Keyboard Shortcuts
→ Mission Control**. The recorder silently refuses `Option + digit`, since that
combination produces a printable character under the U.S. International layout;
the field just stays empty. `Control + Option + digit` records fine, which is
how to tell the refusal apart from a stuck key.

To restore the native shortcuts, flip `enabled` back and log out:

```bash
defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys -dict-add 118 \
  '{enabled=1;value={type=standard;parameters=(49,18,524288);};}'
```

Two traps when scripting this. Read state back with `defaults read`, not
`defaults export`, which serves a stale on-disk snapshot. And edit through
`defaults`, not PlistBuddy: `cfprefsd` holds its own copy and flushes it over
direct file writes. Either way, the WindowServer only picks up hotkey changes
at the next login.
