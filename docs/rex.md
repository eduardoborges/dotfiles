# Rex

[Rex](https://www.superlogical.com/rex/) is the terminal multiplexer that
replaces herdr. The config lives in `rex/.config/rex/init.lua` and is stowed to
`~/.config/rex`. It carries over the herdr shortcuts, so the tables below match
[herdr.md](herdr.md) wherever Rex has the same action.

The prefix is `Control + Space`, written as a key sequence such as
`ctrl+space>c`. Press it twice to send `Control + Space` to the terminal. Theme
and font are app settings and don't go in `init.lua`.

After editing the config:

```bash
rex config check
rex config reload
```

`Prefix + Shift + R` reloads from inside the app. A shortcut set in the app
with **Change Shortcut…** wins over this file.

## Tabs

| Shortcut | Action |
| --- | --- |
| `Command + T` or `Prefix + C` | New tab |
| `Control + Option + 1…9` or `Prefix + 1…9` | Switch to tab 1…9 |
| `Command + Shift + ]`, `Control + Option + ]`, `Prefix + N`, `Prefix + Shift + Right` | Next tab |
| `Command + Shift + [`, `Control + Option + [`, `Prefix + P`, `Prefix + Shift + Left` | Previous tab |
| `Prefix + Shift + X` | Close tab |
| `Prefix + Shift + T` | Rename tab |

## Panes

| Shortcut | Action |
| --- | --- |
| `Command + D` or `Prefix + V` | Split side by side |
| `Command + Shift + D` or `Prefix + -` | Split stacked |
| `Command + W` or `Prefix + X` | Close pane |
| `Command + ]` or `Prefix + Tab` | Cycle to the next pane |
| `Command + [` or `Prefix + Shift + Tab` | Cycle to the previous pane |
| `Control + Option + H/J/K/L`, `Prefix + H/J/K/L`, `Prefix + Arrows` | Focus the pane in that direction |
| `Prefix + Shift + H/J/K/L` | Move the pane in that direction |
| `Prefix + R` | Resize mode: H/J/K/L or arrows, Shift for bigger steps, `=` to balance, Escape or Return to leave |
| `Prefix + Z` | Toggle zoom |
| `Command + F` or `Prefix + [` | Find |
| `Command + K` | Clear the pane and its scrollback |
| `Prefix + E` | Open the scrollback in `$EDITOR` |

## Sessions

A Rex session is what herdr called a workspace.

| Shortcut | Action |
| --- | --- |
| `Command + 1…9` | Go to session 1…9, in the order `rex ls` prints |
| `Prefix + Shift + N` | New session |
| `Prefix + Shift + W` | Rename session |
| `Prefix + W` or `Prefix + G` | Session picker |

## Interface

| Shortcut | Action |
| --- | --- |
| `Prefix + B` | Toggle the sidebar |
| `Prefix + S` | Settings |
| `Prefix + ?` | Command palette |
| `Prefix + Shift + R` | Reload config |

## Left behind

Rex has no action for these herdr shortcuts: rename pane (`Prefix + Shift + P`),
create a worktree (`Prefix + Shift + G`), detach (`Prefix + Q`) and focus the
pane behind a notification (`Prefix + O`). Find takes the place of copy mode.
Close workspace (`Prefix + Shift + D`) is left out on purpose, because closing a
Rex session ends every program in it.

The number row keeps the split from
[herdr.md](herdr.md#who-owns-the-number-row), with Rex in herdr's place.
