local P = "ctrl+space>"
local TERMINAL = "com.superlogical.terminal"

local function bind(keys, action, args)
  for _, key in ipairs(keys) do
    rex.bind(key, action, args)
  end
end

rex.action{
  name     = "session_goto",
  title    = "Go to Session",
  category = "Sessions",
  args     = { index = "integer" },
  run      = function(ctx, args)
    local res, err = rex.call("session.list")
    if res == nil then error(err, 0) end
    local session = (res.sessions or {})[args.index]
    if session ~= nil then
      rex.client.queue("session.select", { session_id = session.session_id })
    end
  end,
}

rex.action{
  name     = "clear_pane",
  title    = "Clear Pane and Scrollback",
  category = "Panes",
  run      = function(ctx)
    local _, err = rex.block.call(TERMINAL, "clear", { block_id = ctx.block_id })
    if err ~= nil then error(err, 0) end
  end,
}

rex.action{
  name     = "edit_scrollback",
  title    = "Open Scrollback in Editor",
  category = "Panes",
  run      = function(ctx)
    local res, err = rex.block.call(TERMINAL, "format", {
      block_id = ctx.block_id,
      format   = "text",
      trim     = true,
    })
    if res == nil then error(err, 0) end

    local path = (os.getenv("TMPDIR") or "/tmp/") .. "rex-scrollback-" .. os.time() .. ".txt"
    local f = assert(io.open(path, "w"))
    f:write(res.content)
    f:close()

    local _, start_err = rex.exec.start(
      { "/bin/zsh", "-ic", '${=EDITOR:-vi} "$1"', "zsh", path },
      { detach = true })
    if start_err ~= nil then error(start_err, 0) end
  end,
}

bind({ P .. "ctrl+space" }, "pane.send_key", { key = "ctrl+space" })

bind({ "cmd+t", P .. "c" }, "client.tab.new")
bind({ P .. "shift+x" }, "client.tab.close")
bind({ P .. "shift+t" }, "client.tab.rename")
bind({ "cmd+shift+]", "ctrl+alt+]", P .. "n", P .. "shift+right" }, "client.tab.next")
bind({ "cmd+shift+[", "ctrl+alt+[", P .. "p", P .. "shift+left" }, "client.tab.previous")

for i = 1, 9 do
  bind({ "ctrl+alt+" .. i, P .. i }, "client.tab.goto", { index = i })
  bind({ "cmd+" .. i }, "session_goto", { index = i })
end

bind({ "cmd+d", P .. "v" }, "pane.split.right")
bind({ "cmd+shift+d", P .. "-" }, "pane.split.down")
bind({ "cmd+w", P .. "x" }, "pane.close")
bind({ "cmd+]", P .. "tab" }, "pane.focus_next")
bind({ "cmd+[", P .. "shift+tab" }, "pane.focus_previous")
bind({ P .. "z" }, "pane.zoom")
bind({ "cmd+f", P .. "[" }, "client.find.open")
bind({ "cmd+k" }, "clear_pane")
bind({ P .. "e" }, "edit_scrollback")

rex.mode("resize", { exclusive = true })
bind({ P .. "r" }, "client.mode.enter", { name = "resize" })
bind({ "resize/=" }, "pane.balance")
bind({ "resize/enter" }, "client.mode.exit")

local directions = { h = "left", j = "down", k = "up", l = "right" }
for key, dir in pairs(directions) do
  bind({ "ctrl+alt+" .. key, P .. key, P .. dir }, "pane.focus." .. dir)
  bind({ P .. "shift+" .. key }, "pane.move." .. dir)
  bind({ "resize/" .. key, "resize/" .. dir }, "pane.resize", { direction = dir })
  bind({ "resize/shift+" .. key, "resize/shift+" .. dir }, "pane.resize", { direction = dir, amount = 15 })
end

bind({ P .. "shift+n" }, "session.new")
bind({ P .. "shift+w" }, "session.rename")
bind({ P .. "w", P .. "g" }, "session.switch")

bind({ P .. "b" }, "client.sidebar.toggle")
bind({ P .. "s" }, "client.settings")
bind({ P .. "shift+/" }, "client.palette.toggle")
bind({ P .. "shift+r" }, "client.config.reload")
