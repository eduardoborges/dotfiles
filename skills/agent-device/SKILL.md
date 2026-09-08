---
name: agent-device
description: Automates Apple-platform apps (iOS, tvOS, macOS), Android devices, and Amazon Vega OS TV apps in Vega Virtual Devices. Use when navigating apps, taking snapshots/screenshots where supported, driving TV remotes, tapping, typing, scrolling, extracting UI info, collecting evidence, or planning agent-device CLI commands.
---

# agent-device

For a normal app-driving task, start immediately. Do not probe first with `--help`, `--version`, `devices`, `appstate`, `snapshot`, or `screenshot`:

```bash
agent-device open <app> --foreground
```

That starts the session and returns the initial interactive snapshot with `@refs`. If the app id is unknown, run `devices`, then `apps`, then `open <discovered-id>` — never invent an id. If a session for the app already exists, continue from its current state instead of reopening it.

Loop: act with `press|click|fill|longpress <target> ... --settle`, `hover <target> --settle` (web only, reveals hover-gated UI), `scroll <direction|top|bottom> [amount] --settle`, or `back --settle`; continue from the printed diff, verify the named expectation (`wait text "..."`, `wait <selector>`, `is`, `get`, or `find`), then run `agent-device close`. `--settle` only applies to press/click/fill/longpress/hover/scroll/back — never to `open`, `snapshot`, or `close`, and `type` never takes it. `fill <target> <text> --settle` replaces the field's contents; `type <text>` appends after focus. For a late network or debounce result, use `wait text "Expected"` rather than polling with snapshot.

Copy refs byte-for-byte: `@e12`, `@e12~s4` — keep the `@` and any `~sN` pin (refs go stale after mutations). A literal `@handle` in the UI is `label="@handle"`, not a bare ref. Prefer current refs, then `id`/`label`/`role` selectors (keys: id role text label value appname windowtitle visible hidden editable selected focused enabled hittable); coordinates are a last resort. If snapshot reports sparse/AX-unavailable, its refs and selectors are invalid: run `agent-device screenshot`, inspect the image, use coordinates, then retry `snapshot -i` after navigating. Otherwise run `snapshot -i` only when the diff lacks the next target or didn't settle.

Output full `agent-device` commands only, no pipes, grep, jq, or pseudo-commands. Error output includes corrective hints; follow them instead of re-planning. Only when the task is specialized (for example gestures, scripting, TV, macOS, remote, web, or debugging) or a command shape is unclear, run `agent-device help <topic>` (workflow, manual-qa, dogfood, validate, debugging, scripting, gestures, react-native, react-devtools, cdp, tv, web, macos, remote, physical-device, ios-system-ui, maestro). `agent-device --help` lists topics, but is not a startup step.
