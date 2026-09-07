# herdr

[herdr](https://herdr.dev) is the terminal multiplexer that runs inside Ghostty.
The config lives in `herdr/.config/herdr/config.toml` and is stowed to
`~/.config/herdr`. It uses the Dracula theme with a custom palette, hides the
new tab name prompt, and sorts the agent panel by space.

The prefix is `Control + Space`. Most actions have a prefix form and a direct
form, so the table lists every way to trigger them. Direct Command shortcuts
work because Ghostty unbinds them (see [ghostty.md](ghostty.md)). `Prefix + ?`
opens the built in help.

After editing the config:

```bash
herdr config check
herdr server reload-config
```

`Prefix + Shift + R` does the reload from inside herdr.

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
| `Prefix + Shift + H/J/K/L` | Swap with the pane in that direction |
| `Prefix + R` | Resize mode |
| `Prefix + Z` | Toggle zoom |
| `Prefix + Shift + P` | Rename pane |
| `Prefix + [` | Copy mode |
| `Prefix + E` | Open the scrollback in `$EDITOR` |

`Prefix + Shift + H` is also bound by the hunkdiff plugin below. Both entries
pass `herdr config check`; which one wins is untested.

## Workspaces and sessions

| Shortcut | Action |
| --- | --- |
| `Command + 1…9` | Switch to workspace 1…9 |
| `Prefix + Shift + N` | New workspace |
| `Prefix + Shift + D` | Close workspace |
| `Prefix + Shift + W` | Rename workspace |
| `Prefix + W` | Workspace picker |
| `Prefix + G` | Session navigator |
| `Prefix + Shift + G` | Create a Git worktree from the workspace |
| `Prefix + Q` | Detach |

## Interface

| Shortcut | Action |
| --- | --- |
| `Prefix + B` | Toggle the sidebar |
| `Prefix + S` | Settings |
| `Prefix + O` | Focus the pane behind the current notification |
| `Prefix + ?` | Keybinding help |
| `Prefix + Shift + R` | Reload config |

## hunkdiff plugin

Managed by the plugin's `setup-keys`; edit through the plugin, not by hand.

| Shortcut | Action |
| --- | --- |
| `Prefix + Shift + H` | Review changes |
| `Prefix + Shift + S` | Send the review to the agent |
| `Prefix + Shift + C` | Review the last commit |
| `Prefix + Shift + A` | Review staged changes |

## Who owns the number row

Three tools compete for modifier + digit. This is the split, chosen so nothing
overlaps:

| Shortcut | Owner | Action |
| --- | --- | --- |
| `Option + 1…9` | skhd | Focus Space 1…9 |
| `Option + Shift + 1…9` | skhd | Move the window to Space 1…9 |
| `Command + 1…9` | herdr | Workspace 1…9 |
| `Control + Option + 1…9` | herdr | Tab 1…9 |
| `Command + Shift + 3/4/5` | macOS | Screenshots, so `Command + Shift + digit` stays free |

skhd grabs its combinations globally, so a terminal never sees `Option + digit`.
That is also why `Option + Control + J/K` are left unbound in skhd: herdr uses
them for pane focus.
