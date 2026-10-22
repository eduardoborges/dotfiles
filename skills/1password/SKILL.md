---
name: 1password
description: Read, inject or store secrets with the 1Password CLI (`op`) without exposing them. Use when a task needs an API key, token, password or other credential, when the user mentions 1Password, `op`, a vault or an `op://` reference, or when a secret would otherwise be pasted, printed or written to a file. Triggers include "1password", "op read", "op run", "secret", "api key", "token".
metadata:
  short-description: Use secrets from 1Password without printing them
  compatibility: claude-code
---

# 1Password CLI

`op` goes through the 1Password desktop app. The first call pops a Touch ID prompt. Once the user approves it, the authorization holds across separate Bash calls until it sits idle for about 10 minutes.

## Never let a value reach the output

Whatever a command prints ends up in the transcript and goes to the model API. So:

- Never print a secret: no `op read` to stdout, no `op item get --reveal`, no `cat`, `echo` or `env` of a secret, no `set -x` around one.
- Use the value inside the command that needs it: `--token "$(op read 'op://Vault/Item/field')"`, or pipe it: `op read 'op://Vault/Item/token' | gh auth login --with-token`.
- To check that a secret exists, look at metadata or its length: `op read 'op://Vault/Item/field' | wc -c`.
- When you inspect a file that may hold secrets (`.env`, `.envrc`, a config), print only the names: `sed 's/=.*/=…/'`. A regex that tries to mask just the value misses quoted JSON and leaks it.

## Find a reference

A reference looks like `op://<vault>/<item>/[<section>/]<field>`. Add `?attribute=otp` for a TOTP code.

```bash
op vault list --format json | jq -r '.[].name'
op item list --vault <vault> --format json | jq -r '.[].title' | grep -i <name>
# labels and references only; the JSON also carries the values, so never print .value
op item get "<item>" --vault <vault> --format json | jq -r '.fields[] | "\(.label)\t\(.reference)"'
```

## Use a secret

- One command: `op run --env-file=.env.op -- <cmd>`, where `.env.op` holds `KEY=op://...` lines. `op run` masks the values in the command's output.
- A config file: `op inject -i config.tpl -o config`. The output holds plaintext, so keep it out of git and `chmod 600` it.
- A shell variable: `export KEY="$(op read 'op://...')"`, only inside the same Bash call that uses it.

## Write to the vault

Creating or editing an item changes the user's vault. Confirm first with AskUserQuestion, naming the vault, the item title and the field labels, never the value. Set field types explicitly (`label[text]=`, `label[concealed]=`, `label[url]=`) and conceal only real secrets.

Arguments to `op item create` land in the transcript. Use `--generate-password` for a new password. For a value another command produces, build a JSON template from that output with `jq` into a `chmod 600` temp file, pass it with `--template`, then delete the file.

## When auth fails

- `op whoami` says "account is not signed in" even while app integration works. Test with `op vault list --format json | jq length` instead.
- `authorization timeout`: nobody answered the Touch ID prompt. Ask the user to watch for it and retry once.
- No prompt at all: the app is locked, or Settings > Developer > "Integrate with 1Password CLI" is off.
