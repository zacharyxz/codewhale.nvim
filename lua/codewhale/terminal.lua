---Terminal provider for the codewhale TUI via Snacks.nvim.

local M = {}

local snacks_available, Snacks = pcall(require, "snacks")
local terminal = nil

---@class codewhale.TerminalConfig
---@field split_side string  "left" | "right" (default: "right")
---@field split_width number   Width ratio 0-1 (default: 0.30)
---@field auto_close boolean   Auto-close on exit (default: true)
---@field terminal_cmd string? Override the binary (default: "codewhale")
---@field env table<string,string>? Extra environment variables
---@field cwd string?         Working directory (default: current dir)
---@field snacks_win_opts table? Merged into Snacks terminal `win` config

local defaults = {
  split_side = "right",
  split_width = 0.30,
  auto_close = true,
  terminal_cmd = nil,
  env = {},
  cwd = nil,
  snacks_win_opts = {},
}

M.defaults = defaults

---@return boolean
local function available()
  return snacks_available and Snacks and Snacks.terminal ~= nil
end

---@param config codewhale.TerminalConfig
---@param env_table table
---@param focus boolean?
---@return snacks.terminal.Opts
local function build_opts(config, env_table, focus)
  if focus == nil then
    focus = true
  end
  local opts = {
    start_insert = focus,
    auto_insert = focus,
    auto_close = false,
    win = vim.tbl_deep_extend("force", {
      position = config.split_side,
      width = config.split_width,
      height = 0,
      relative = "editor",
      keys = {
        codewhale_new_line = {
          "<S-CR>",
          function()
            vim.api.nvim_feedkeys("\\", "t", true)
            vim.defer_fn(function()
              vim.api.nvim_feedkeys("\r", "t", true)
            end, 10)
          end,
          mode = "t",
          desc = "New line (codewhale)",
        },
        codewhale_ctrl_t = {
          "<C-t>",
          function()
            local chan = vim.bo[vim.api.nvim_get_current_buf()].channel
            if chan and chan > 0 then
              vim.api.nvim_chan_send(chan, "\x14")
            end
          end,
          mode = "t",
          desc = "Toggle conversation log",
        },
        codewhale_ctrl_p = {
          "<C-p>",
          function()
            local chan = vim.bo[vim.api.nvim_get_current_buf()].channel
            if chan and chan > 0 then
              vim.api.nvim_chan_send(chan, "\x10")
            end
          end,
          mode = "t",
          desc = "Fuzzy file picker",
        },
        codewhale_ctrl_r = {
          "<C-r>",
          function()
            local chan = vim.bo[vim.api.nvim_get_current_buf()].channel
            if chan and chan > 0 then
              vim.api.nvim_chan_send(chan, "\x12")
            end
          end,
          mode = "t",
          desc = "Resume session picker",
        },
        codewhale_escape = {
          "<Esc>",
          function()
            vim.cmd("stopinsert")
          end,
          mode = "t",
          desc = "Exit terminal insert mode",
        },
      },
    }, config.snacks_win_opts or {}),
  }
  if env_table and not vim.tbl_isempty(env_table) then
    opts.env = env_table
  end
  if config.cwd then
    opts.cwd = config.cwd
  end
  return opts
end

---@param term_instance table
---@param config codewhale.TerminalConfig
local function setup_events(term_instance, config)
  if config.auto_close then
    term_instance:on("TermClose", function()
      if vim.v.event.status ~= 0 then
        vim.notify(
          "codewhale exited with code " .. vim.v.event.status,
          vim.log.levels.WARN
        )
      end
      terminal = nil
      vim.schedule(function()
        term_instance:close({ buf = true })
        vim.cmd.checktime()
      end)
    end, { buf = true })
  end

  term_instance:on("BufWipeout", function()
    terminal = nil
  end, { buf = true })
end

---Merge user config into defaults.
---@param user_config codewhale.TerminalConfig?
---@param p_terminal_cmd string?
---@param p_env table?
function M.setup(user_config, p_terminal_cmd, p_env)
  user_config = user_config or {}

  if p_terminal_cmd == nil or type(p_terminal_cmd) == "string" then
    defaults.terminal_cmd = p_terminal_cmd
  end
  if p_env == nil or type(p_env) == "table" then
    defaults.env = p_env or {}
  end

  for k, v in pairs(user_config) do
    if k == "split_side" and (v == "left" or v == "right") then
      defaults.split_side = v
    elseif k == "split_width" and type(v) == "number" and v > 0 and v < 1 then
      defaults.split_width = v
    elseif k == "auto_close" and type(v) == "boolean" then
      defaults.auto_close = v
    elseif k == "snacks_win_opts" and type(v) == "table" then
      defaults.snacks_win_opts = v
    elseif k == "cwd" and (v == nil or type(v) == "string") then
      defaults.cwd = v
    end
  end
end

---Build command string and environment.
---@param cmd_args string?
---@return string, table
local function get_cmd_and_env(cmd_args)
  local base = defaults.terminal_cmd or "codewhale"
  local cmd
  if cmd_args and cmd_args ~= "" then
    cmd = base .. " " .. cmd_args
  else
    cmd = base
  end
  return cmd, vim.deepcopy(defaults.env)
end

---Open terminal window.
---@param opts_override table?
---@param cmd_args string?
function M.open(opts_override, cmd_args)
  if not available() then
    vim.notify(
      "codewhale.nvim: Snacks.nvim not available.",
      vim.log.levels.ERROR
    )
    return
  end

  local config = vim.deepcopy(defaults)
  if type(opts_override) == "table" then
    for k, v in pairs(opts_override) do
      if config[k] ~= nil then
        config[k] = v
      end
    end
  end

  local cmd_string, env_table = get_cmd_and_env(cmd_args)

  if terminal and terminal:buf_valid() then
    if not terminal.win or not vim.api.nvim_win_is_valid(terminal.win) then
      terminal:toggle()
      terminal:focus()
      if terminal.buf
        and vim.api.nvim_buf_get_option(terminal.buf, "buftype") == "terminal"
      then
        if terminal.win and vim.api.nvim_win_is_valid(terminal.win) then
          vim.api.nvim_win_call(terminal.win, function()
            vim.cmd("startinsert")
          end)
        end
      end
    else
      terminal:focus()
      if terminal.buf
        and vim.api.nvim_buf_get_option(terminal.buf, "buftype") == "terminal"
      then
        if terminal.win and vim.api.nvim_win_is_valid(terminal.win) then
          vim.api.nvim_win_call(terminal.win, function()
            vim.cmd("startinsert")
          end)
        end
      end
    end
    return
  end

  local opts = build_opts(config, env_table, true)
  local term = Snacks.terminal.open(cmd_string, opts)
  if term and term:buf_valid() then
    setup_events(term, config)
    terminal = term
  else
    terminal = nil
    vim.notify(
      "codewhale.nvim: Failed to open terminal.",
      vim.log.levels.ERROR
    )
  end
end

---Close terminal.
function M.close()
  if terminal and terminal:buf_valid() then
    terminal:close()
  end
end

---Simple toggle: show/hide terminal.
---@param opts_override table?
---@param cmd_args string?
function M.toggle(opts_override, cmd_args)
  if not available() then
    vim.notify(
      "codewhale.nvim: Snacks.nvim not available.",
      vim.log.levels.ERROR
    )
    return
  end

  if terminal and terminal:buf_valid() and terminal:win_valid() then
    terminal:toggle()
  elseif terminal and terminal:buf_valid() and not terminal:win_valid() then
    terminal:toggle()
  else
    M.open(opts_override, cmd_args)
  end
end

---Smart focus toggle: jump to terminal or hide if already focused.
---@param opts_override table?
---@param cmd_args string?
function M.focus_toggle(opts_override, cmd_args)
  if not available() then
    vim.notify(
      "codewhale.nvim: Snacks.nvim not available.",
      vim.log.levels.ERROR
    )
    return
  end

  if terminal and terminal:buf_valid() and not terminal:win_valid() then
    terminal:toggle()
  elseif terminal and terminal:buf_valid() and terminal:win_valid() then
    local term_win = terminal.win
    local cur_win = vim.api.nvim_get_current_win()
    if term_win == cur_win then
      terminal:toggle()
    else
      vim.api.nvim_set_current_win(term_win)
      if terminal.buf and vim.api.nvim_buf_is_valid(terminal.buf) then
        if vim.api.nvim_buf_get_option(terminal.buf, "buftype") == "terminal" then
          vim.api.nvim_win_call(term_win, function()
            vim.cmd("startinsert")
          end)
        end
      end
    end
  else
    M.open(opts_override, cmd_args)
  end
end

---Send text to the codewhale terminal input.
---
---This is the core function for injecting file references.
---It types the given text into the terminal as if the user pasted it.
---
---@param text string  Text to send to the terminal.
function M.send_text(text)
  if not terminal or not terminal:buf_valid() then
    vim.notify(
      "codewhale.nvim: No active terminal. Open one with :CodeWhale first.",
      vim.log.levels.WARN
    )
    return
  end
  if not terminal.win or not vim.api.nvim_win_is_valid(terminal.win) then
    -- Terminal is hidden; make it visible first
    terminal:toggle()
  end
  terminal:focus()
  if terminal.buf
    and vim.api.nvim_buf_get_option(terminal.buf, "buftype") == "terminal"
  then
    local chan = vim.bo[terminal.buf].channel
    if chan and chan > 0 then
      -- Ensure insert mode
      vim.api.nvim_win_call(terminal.win, function()
        vim.cmd("startinsert")
      end)
      -- Send text + newline to the PTY
      vim.api.nvim_chan_send(chan, text .. "\r")
    end
  end
end

---@return number?
function M.get_active_bufnr()
  if terminal and terminal:buf_valid() and terminal.buf then
    if vim.api.nvim_buf_is_valid(terminal.buf) then
      return terminal.buf
    end
  end
  return nil
end

return M
