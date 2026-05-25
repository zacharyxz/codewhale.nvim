---codewhale.nvim - CodeWhale integration for Neovim.
---
---@module 'codewhale'

local M = {}

---@class codewhale.Config
---@field terminal codewhale.TerminalConfig?
---@field terminal_cmd string?           Override the codewhale binary path.
---@field env table<string,string>?      Extra env vars for the terminal.
---@field keymaps table<string,string|false>? Keymap overrides (set to false to disable).

---@type codewhale.Config
local defaults = {
  terminal = nil,
  terminal_cmd = nil,
  env = nil,
  keymaps = {
    toggle        = "<leader>cw",
    focus         = "<leader>cf",
    run           = "<leader>cr",
    resume        = "<leader>cR",
    add_file      = "<leader>ca",  -- Add current file:line reference
    add_selection = "<leader>cA",  -- Add visual selection as reference
    add_file_line = "<leader>cl",  -- Add file with count line number
  },
}

---Setup codewhale.nvim.
---@param opts codewhale.Config?
function M.setup(opts)
  opts = vim.tbl_deep_extend("force", defaults, opts or {})

  -- Configure terminal
  local term_ok, terminal = pcall(require, "codewhale.terminal")
  if term_ok and type(terminal.setup) == "function" then
    terminal.setup(opts.terminal, opts.terminal_cmd, opts.env)
  end

  M._create_commands()
  M._create_keymaps(opts.keymaps or {})
end

---Register user commands.
function M._create_commands()
  local term_ok, terminal = pcall(require, "codewhale.terminal")
  if not term_ok then
    return
  end

  vim.api.nvim_create_user_command("CodeWhale", function(opts)
    local args = opts.args and opts.args ~= "" and opts.args or nil
    terminal.toggle({}, args)
  end, {
    nargs = "*",
    desc = "Toggle the CodeWhale terminal window",
  })

  vim.api.nvim_create_user_command("CodeWhaleFocus", function(opts)
    local args = opts.args and opts.args ~= "" and opts.args or nil
    terminal.focus_toggle({}, args)
  end, {
    nargs = "*",
    desc = "Smart focus/toggle CodeWhale terminal",
  })

  vim.api.nvim_create_user_command("CodeWhaleOpen", function(opts)
    local args = opts.args and opts.args ~= "" and opts.args or nil
    terminal.open({}, args)
  end, {
    nargs = "*",
    desc = "Open CodeWhale terminal",
  })

  vim.api.nvim_create_user_command("CodeWhaleClose", function()
    terminal.close()
  end, {
    desc = "Close CodeWhale terminal",
  })

  vim.api.nvim_create_user_command("CodeWhaleRun", function(opts)
    local args = opts.args and opts.args ~= "" and "run " .. opts.args or "run"
    terminal.open({}, args)
  end, {
    nargs = "*",
    desc = "Open CodeWhale in run mode",
  })

  vim.api.nvim_create_user_command("CodeWhaleResume", function(opts)
    local args = opts.args and opts.args ~= "" and "resume " .. opts.args or "resume"
    terminal.open({}, args)
  end, {
    nargs = "*",
    desc = "Resume a saved CodeWhale session",
  })

  ---Add the current file:line reference to the codewhale prompt.
  vim.api.nvim_create_user_command("CodeWhaleAddRef", function()
    local context = require("codewhale.context")
    local ref = context.get_ref()
    if ref then
      require("codewhale.terminal").send_text(ref)
    else
      vim.notify("codewhale.nvim: No file to reference.", vim.log.levels.WARN)
    end
  end, {
    desc = "Add current file:line reference to CodeWhale",
    range = true,
  })
end

---Register default keymaps.
---@param keymaps table<string, string|false>
function M._create_keymaps(keymaps)
  local maps = {}

  -- Toggle
  if keymaps.toggle ~= false then
    maps[keymaps.toggle] = {
      action = "<cmd>CodeWhale<cr>",
      desc = "Toggle CodeWhale",
    }
  end

  -- Focus
  if keymaps.focus ~= false then
    maps[keymaps.focus] = {
      action = "<cmd>CodeWhaleFocus<cr>",
      desc = "Focus CodeWhale",
    }
  end

  -- Run
  if keymaps.run ~= false then
    maps[keymaps.run] = {
      action = "<cmd>CodeWhaleRun<cr>",
      desc = "CodeWhale run",
    }
  end

  -- Resume
  if keymaps.resume ~= false then
    maps[keymaps.resume] = {
      action = "<cmd>CodeWhaleResume<cr>",
      desc = "CodeWhale resume",
    }
  end

  -- Add file reference (normal mode: cursor line)
  if keymaps.add_file ~= false then
    maps[keymaps.add_file] = {
      action = function()
        require("codewhale.terminal").send_text(
          require("codewhale.context").get_ref()
        )
      end,
      desc = "Add file:line ref to CodeWhale",
    }
  end

  -- Add selection reference (visual mode)
  if keymaps.add_selection ~= false then
    maps[keymaps.add_selection] = {
      action = "<cmd>CodeWhaleAddRef<cr>",
      desc = "Add selection ref to CodeWhale",
      mode = "v",
    }
  end

  -- Add file with count as line number
  if keymaps.add_file_line ~= false then
    maps[keymaps.add_file_line] = {
      action = function()
        local count = vim.v.count
        local ref
        if count > 0 then
          ref = require("codewhale.context").get_ref_at(count)
        else
          ref = require("codewhale.context").get_ref()
        end
        if ref then
          require("codewhale.terminal").send_text(ref)
        end
      end,
      desc = "Add file:line ref (with count)",
    }
  end

  -- Register all keymaps
  for lhs, map in pairs(maps) do
    local opts = { noremap = true, silent = true, desc = map.desc }
    if map.mode then
      vim.keymap.set(map.mode, lhs, map.action, opts)
    else
      vim.keymap.set("n", lhs, map.action, opts)
    end
  end
end

return M
