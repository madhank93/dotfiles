-- Rex server config. Apply edits with: rex config check && rex config reload
-- Action names come from the app: rex -C <client> actions
-- Rex's default cmd keys already cover split/focus/zoom/tabs/copy mode;
-- only add what the defaults lack.

-- Resize mode: arrows or hjkl move the divider, shift for bigger steps, esc leaves.
-- Exclusive so stray keys don't type into the terminal while resizing.
rex.bind("shift+cmd+r", "client.mode.enter", { name = "resize" })
rex.mode("resize", { exclusive = true })

local dirs = { left = "h", down = "j", up = "k", right = "l" }
for dir, vim in pairs(dirs) do
  for _, key in ipairs({ dir, vim }) do
    rex.bind("resize/" .. key, "pane.resize", { direction = dir })
    rex.bind("resize/shift+" .. key, "pane.resize", { direction = dir, amount = 15 })
  end
end

-- Homelab Talos cluster, viewed from this Mac: k9s beside the Talos node
-- dashboard. The node comes from talosconfig (`talosctl config node`), keeping
-- LAN addresses out of this repo.
rex.action{
  name     = "talos",
  title    = "Open Talos Cluster",
  category = "Homelab",
  keywords = "k8s kubernetes k9s cluster",
  run      = function()
    local shell = "com.superlogical.terminal.shell"
    local _, err = rex.session.new_window{
      window_label = "talos",
      layout = rex.layout.horizontal(0.6,
        rex.layout.block{ flavor = shell, options = { command = { "k9s", "--context", "admin@talos-cluster" } } },
        rex.layout.block{ flavor = shell, options = { command = { "talosctl", "dashboard" } } }),
    }
    if err ~= nil then error(err, 0) end
  end,
}
rex.bind("shift+cmd+k", "talos")

-- nvim beside a shell, both in the focused pane's directory (needs the OSC 7
-- hook in zsh/functions.zsh; falls back to $HOME).
rex.action{
  name     = "dev",
  title    = "Open Dev Layout",
  keywords = "nvim editor split",
  run      = function(ctx)
    local ok, res = pcall(rex.block.call, "com.superlogical.terminal", "pwd", { block_id = ctx.block_id })
    local cwd = ok and res.pwd and res.pwd:gsub("^file://[^/]*", ""):gsub("%%20", " ")
    cwd = (cwd and cwd ~= "") and cwd or os.getenv("HOME")
    local shell = "com.superlogical.terminal.shell"
    local _, err = rex.session.new_window{
      window_label = cwd:match("[^/]+$") or "dev",
      layout = rex.layout.horizontal(0.6,
        rex.layout.block{ flavor = shell, options = { cwd = cwd, command = { "nvim", "." } } },
        rex.layout.block{ flavor = shell, options = { cwd = cwd } }),
    }
    if err ~= nil then error(err, 0) end
  end,
}
rex.bind("shift+cmd+e", "dev")
