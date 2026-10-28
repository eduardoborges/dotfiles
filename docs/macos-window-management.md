# macOS window management

This setup uses [yabai](https://github.com/asmvik/yabai) for BSP tiling and
[skhd](https://github.com/asmvik/skhd) for global hotkeys. The advanced profile
uses yabai's scripting addition with System Integrity Protection partially
disabled. Window opacity remains at 100%, and JankyBorders highlights the
focused window.

## Applications

| Shortcut | Action |
| --- | --- |
| `Option + Return` | Open or focus Rex |
| `Option + Shift + B` | Open or focus Google Chrome Dev |
| `Option + Shift + Command + B` | Open an incognito Chrome Dev window |
| `Option + Shift + F` | Open Finder at Home |
| `Option + Shift + M` | Open or focus Spotify |
| `Option + Shift + N` | Open or focus VS Code |
| `Option + Shift + D` | Open or focus Docker |
| `Option + /` | Open or focus 1Password |
| `Option + Shift + /` | Open or focus 1Password |
| `Option + Shift + S` | Open or focus Slack |
| `Option + Shift + A` | Open or focus Claude |
| `Option + Shift + C` | Open Notion Calendar |
| `Option + Shift + W` | Open WhatsApp |

## Focus, movement, and resizing

| Shortcut | Action |
| --- | --- |
| `Option + H/J/K/L` or arrows | Focus west/south/north/east |
| `Option + Shift + H/J/K/L` or arrows | Move the window in the BSP tree |
| `Option + Command + H/J/K/L` | Swap with the adjacent window |
| `Option + Command + Shift + H/J/K/L` | Stack with the adjacent window |
| `Option + -` / `Option + =` | Shrink / grow the window horizontally |
| `Option + Shift + -` / `Option + Shift + =` | Shrink / grow the window vertically |
| `Option + Control + Shift + H/J/K/L` | Set the next insertion direction |
| `Option + Command + Left/Right` | Focus the display to the west/east |
| `Option + Command + Shift + Left/Right` | Move the window to another display |

Horizontal focus and movement automatically cross to an adjacent display when
there is no window in that direction.

`Option + Control + J/K` are deliberately unbound here. Rex uses them to
focus panes inside the terminal, and skhd would swallow them first (see
[rex.md](rex.md)).

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

1. Installs `yabai` from `eduardoborges/tap` and `skhd` from `asmvik/formulae`
   when missing.
2. Links `.yabairc`, `.skhdrc`, the Space helpers and `yabai-resign` through
   GNU Stow.
3. Runs `yabai-resign` when `~/.local/libexec/yabai` is missing, older than the
   Homebrew build, or not the binary launchd starts. Otherwise it restarts yabai
   from that copy.
4. Starts or restarts skhd.
5. Registers a login bootstrap that repairs launch-order races after reboot.
6. Loads the scripting addition when SIP allows it.
7. Prints a diagnostic summary.

yabai runs from `~/.local/libexec/yabai`, not from the Homebrew path, so that is
the binary to allow in **System Settings → Privacy & Security →
Accessibility**, along with skhd. Window animations also need yabai under
**Screen & System Audio Recording**.

`yabai-resign` signs that copy with a self-signed Code Signing identity named
`yabai-cert`, which keeps those grants across upgrades. Create it once per
machine in Keychain Access → Certificate Assistant → Create a Certificate, with
Certificate Type set to Code Signing. Without it the script signs ad hoc and
warns, and Accessibility has to be granted again after every upgrade.

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
cause is the scripting addition: it finds the functions it patches inside the
Dock binary by byte pattern from a fixed offset, and Apple moves them in point
releases. Upstream v7.1.25 (May 2026) predates Golden Gate and carries no fix.

yabai here is built from the fork [eduardoborges/yabai][fork], which has the
27.0 and 27.2 offsets, through the `eduardoborges/tap/yabai` formula in the
Brewfile. The formula pins a commit of the fork, and the formula is pinned in
Homebrew so a stray `brew upgrade` leaves it alone. To ship a fork change, push
it, point `revision:` in the tap's `Formula/yabai.rb` at the new commit, bump
`revision`, then run:

```bash
brew unpin eduardoborges/tap/yabai
brew upgrade eduardoborges/tap/yabai
brew pin eduardoborges/tap/yabai
yabai-resign
```

`yabai-resign` comes from the `yabai` package and is linked into
`~/.local/bin`. It copies the Cellar binary to `~/.local/libexec/yabai`, signs
it with `yabai-cert`, writes the new hash to `/etc/sudoers.d/yabai` and restarts
the service from that copy. launchd and `.yabairc` run that copy, not the
Homebrew one.

### When an update breaks Spaces again

Ask the payload what it resolved before touching any code. It answers a
handshake on its socket with its version and a bitmask of the Dock functions it
found:

```bash
python3 -c 'import socket,struct,getpass; s=socket.socket(socket.AF_UNIX); s.connect(f"/tmp/yabai-sa_{getpass.getuser()}.socket"); s.send(b"\x01\x00\x01"); v,a=s.recv(64).split(b"\0",1); print(v.decode(), hex(struct.unpack("<I",a[:4])[0]))'
```

On 27.2 a working payload reports `0x4d`: dock.spaces, add_space, remove_space
and the animation time. `0x0` means no pattern matched. The Dock also logs each
lookup:

```bash
/usr/bin/log show --last 10m --predicate 'process == "Dock" AND eventMessage CONTAINS "yabai-sa"'
```

New offsets tend to show up in the upstream issues first ([#2802][gg-issue] for
27.0, [#2832][gg-272] for 27.2). The Dock is a fat binary with `arm64e` and
`arm64e.x1` slices, so check a pattern against both before building;
`lipo -detailed_info` prints where each slice starts. On the M5 Pro the Dock
runs the `arm64e` slice.

Every payload change needs a new `OSAX_VERSION` in `src/osax/common.h`.
`--load-sa` only replaces the installed payload when that version differs, so a
rebuild with the same version keeps the old payload running. That is how a
2.1.31 payload from another fork kept running under this fork's build until
27.2.

The 27.2 Dock no longer has `DPDesktopPictureManager`, so moving a Space to
another display does not work there.

[fork]: https://github.com/eduardoborges/yabai
[gg-issue]: https://github.com/asmvik/yabai/issues/2802
[gg-272]: https://github.com/asmvik/yabai/issues/2832

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
