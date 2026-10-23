# ------------------------------------------------------------------------------
# MCP servers, user scope.
#
# Claude Code keeps them in ~/.claude.json, next to session history and OAuth
# tokens, so that file cannot be stowed. Only the mcpServers block is tracked
# here, and it goes back in through `claude mcp add-json` rather than a hand
# edit of the live file.
#
# Home paths are stored as ~/... so the file survives a different username.
# ------------------------------------------------------------------------------
MCP_SERVERS_FILE="$DOTFILES_DIR/mcp-servers.json"
CLAUDE_CONFIG="$HOME/.claude.json"

# The work profile (CLAUDE_CONFIG_DIR=~/.claude-work) has its own MCP list.
# Only the servers below get copied into it, so work and personal stay apart.
WORK_CLAUDE_DIR="$HOME/.claude-work"
WORK_MCP_SERVERS=(chrome-devtools)

# add-json refuses to replace, so drop the old entry first
add_mcp_server() {
  claude mcp remove "$1" -s user &>/dev/null || true
  claude mcp add-json "$1" "$2" -s user &>/dev/null
}

sync_mcp_servers() {
  section "Syncing MCP servers"

  [[ -f "$MCP_SERVERS_FILE" ]] || { warn "no mcp-servers.json, skipping"; return 0; }
  command -v jq &>/dev/null || { warn "jq is missing, skipping"; return 0; }
  command -v claude &>/dev/null || { warn "claude is missing, skipping"; return 0; }

  local name config
  while IFS=$'\t' read -r name config; do
    if add_mcp_server "$name" "$config"; then
      info "$name"
    else
      warn "could not add $name"
    fi
    if [[ -d "$WORK_CLAUDE_DIR" && " ${WORK_MCP_SERVERS[*]} " == *" $name "* ]]; then
      if CLAUDE_CONFIG_DIR="$WORK_CLAUDE_DIR" add_mcp_server "$name" "$config"; then
        info "$name (work)"
      else
        warn "could not add $name to the work profile"
      fi
    fi
  done < <(sed "s|\"~/|\"$HOME/|g" "$MCP_SERVERS_FILE" |
    jq -r 'to_entries[] | [.key, (.value | tojson)] | @tsv')
}

save_mcp_servers() {
  section "Saving MCP servers"

  command -v jq &>/dev/null || die "jq is required to save the MCP servers."
  [[ -f "$CLAUDE_CONFIG" ]] || die "$CLAUDE_CONFIG does not exist."

  jq '.mcpServers // {}' "$CLAUDE_CONFIG" | sed "s|\"$HOME/|\"~/|g" >"$MCP_SERVERS_FILE"
  ok "saved $(jq -r 'keys | length' "$MCP_SERVERS_FILE") servers to $MCP_SERVERS_FILE"
}
