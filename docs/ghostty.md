# Ghostty

The config lives in `ghostty/.config/ghostty/config` and is stowed to
`~/.config/ghostty`. Font is DankMono Nerd Font at 13pt, theme is `draculinho`
(a Dracula variant kept in `themes/`). The titlebar is hidden, window state is
never restored, and scrollback is capped at 1 MB because herdr keeps its own.

`macos-option-as-alt = true` makes Option behave as Alt inside the terminal.
Without it the Control + Option bindings in herdr and the Option + Arrow word
jumps below never reach the shell.

Ghostty reloads its config on `Command + Shift + ,`. Check the file first:

```bash
/Applications/Ghostty.app/Contents/MacOS/ghostty +validate-config
/Applications/Ghostty.app/Contents/MacOS/ghostty +list-keybinds
```

The second command prints the effective bindings, defaults plus overrides.

## Shortcuts handed to herdr

Ghostty unbinds these so the keypress reaches herdr, which runs inside every
Ghostty window. See [herdr.md](herdr.md) for the full herdr reference.

| Shortcut | Ghostty default (off) | herdr now |
| --- | --- | --- |
| `Command + T` | New tab | New tab |
| `Command + W` | Close surface | Close pane |
| `Command + D` | Split right | Split side by side |
| `Command + Shift + D` | Split down | Split stacked |
| `Command + [` / `]` | Previous/next split | Previous/next pane |
| `Command + Shift + [` / `]` | Previous/next tab | Previous/next tab |
| `Command + 1…9` | Go to tab 1…9 | Workspace 1…9 |

Ghostty binds both `super+1` and `super+digit_1`, so each digit needs two
`unbind` lines. In a plain shell without herdr these keys do nothing.

## Windows, tabs, and splits

| Shortcut | Action |
| --- | --- |
| `Command + N` | New window |
| `Command + Shift + W` | Close window |
| `Command + Option + W` | Close tab |
| `Command + Option + Shift + W` | Close all windows |
| `Command + Q` | Quit |
| `Control + Tab` / `Control + Shift + Tab` | Next/previous Ghostty tab |
| `Command + Return` or `Command + Control + F` | Toggle fullscreen |
| `Command + Shift + Return` | Zoom the focused split |
| `Command + Option + Arrows` | Focus the split in that direction |
| `Command + Control + Arrows` | Resize the split by 10 |
| `Command + Control + Option + Shift + Arrows` | Resize the split by 100 |
| `Command + Control + =` | Equalize splits |
| `Command + Shift + P` | Command palette |
| `Command + ,` / `Command + Shift + ,` | Open / reload config |
| `Command + Option + I` | Toggle the inspector |

Ghostty splits are still available through the arrow bindings, but day to day
herdr owns panes and tabs.

## Clipboard and selection

| Shortcut | Action |
| --- | --- |
| `Command + C` / `Command + V` | Copy / paste |
| `Control + Insert` / `Shift + Insert` | Copy / paste (PC style) |
| `Command + Shift + V` | Paste from selection |
| `Command + A` | Select all |
| `Shift + Arrows`, `Shift + Home/End`, `Shift + Page Up/Down` | Adjust the selection |
| `Command + Z` / `Command + Shift + Z` | Undo / redo |
| `Command + K` | Clear screen |
| `Command + Shift + J` | Write the screen to a file and paste its path |
| `Command + Control + Shift + J` | Write the screen to a file and copy its path |
| `Command + Option + Shift + J` | Write the screen to a file and open it |

## Search and scrolling

| Shortcut | Action |
| --- | --- |
| `Command + F` | Start search |
| `Command + G` / `Command + Shift + G` | Next / previous match |
| `Command + E` | Search the current selection |
| `Command + Shift + F` or `Escape` | End search |
| `Command + Up/Down` | Jump to the previous/next prompt |
| `Command + Home/End` | Scroll to top / bottom |
| `Command + Page Up/Down` | Scroll one page |
| `Command + J` | Scroll to the selection |

## Font

| Shortcut | Action |
| --- | --- |
| `Command + =` / `Command + -` | Increase / decrease font size |
| `Command + 0` | Reset font size |

## Line editing

These send readline sequences to the shell.

| Shortcut | Sends |
| --- | --- |
| `Command + Left` / `Command + Right` | `Control + A` / `Control + E` (line start / end) |
| `Command + Backspace` | `Control + U` (delete to line start) |
| `Option + Left` / `Option + Right` | `Escape b` / `Escape f` (word back / forward) |
