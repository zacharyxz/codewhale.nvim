---File path and line number reference formatting for codewhale.
---Produces compact references like: `relative/path:L21-L35`

local M = {}

---Returns the filename for a buffer if it has one, else nil.
---@param buf number
---@return string|nil
local function buf_filename(buf)
  if vim.api.nvim_get_option_value("buftype", { buf = buf }) == "" then
    local name = vim.api.nvim_buf_get_name(buf)
    if name ~= "" then
      return name
    end
  end
  return nil
end

---Find the most-recently-used window that has a named buffer.
---@return number
local function last_used_win()
  local best_win = 0
  local best_time = 0
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if buf_filename(buf) then
      local lastused = vim.fn.getbufinfo(buf)[1].lastused or 0
      if lastused > best_time then
        best_time = lastused
        best_win = win
      end
    end
  end
  return best_win
end

---Format a buffer or filepath into a compact reference string.
---
---Examples:
---  `lua/codewhale/init.lua:L42`            -- cursor line only
---  `lua/codewhale/init.lua:L21:C5-L35`     -- range with start col
---
---@param loc string|integer  Buffer number or absolute/relative filepath.
---@param args? { start_line?: integer, start_col?: integer, end_line?: integer, end_col?: integer }
---@return string|nil
function M.format(loc, args)
  if type(loc) ~= "string" and type(loc) ~= "number" then
    return nil
  end
  if type(loc) == "string" and #loc == 0 then
    return nil
  end

  local filepath
  if type(loc) == "number" then
    filepath = buf_filename(loc)
  else
    filepath = loc
  end
  if not filepath then
    return nil
  end

  -- Use path relative to cwd for compact display
  local rel = vim.fn.fnamemodify(filepath, ":.")

  if not args or not args.start_line then
    return rel
  end

  local result = rel .. ":L" .. args.start_line
  if args.start_col then
    result = result .. ":C" .. args.start_col
  end

  if args.end_line and args.end_line ~= args.start_line then
    local sl, el = args.start_line, args.end_line
    if sl > el then
      sl, el = el, sl
    end
    result = result .. "-L" .. el
    if args.end_col then
      result = result .. ":C" .. args.end_col
    end
  end

  return result
end

---Get the visual selection range, silently leaving visual mode.
---@param buf number
---@return { from: integer[], to: integer[], kind: "char"|"line"|"block" }|nil
function M.get_selection(buf)
  local mode = vim.fn.mode()
  local kind
  if mode == "v" then
    kind = "char"
  elseif mode == "V" then
    kind = "line"
  elseif mode == "\22" then
    kind = "block"
  else
    return nil
  end

  -- Exit visual mode to get consistent '< '> marks
  vim.api.nvim_feedkeys(
    vim.api.nvim_replace_termcodes("<esc>", true, false, true),
    "x", true
  )

  local from = vim.api.nvim_buf_get_mark(buf, "<")
  local to = vim.api.nvim_buf_get_mark(buf, ">")
  if from[1] > to[1] or (from[1] == to[1] and from[2] > to[2]) then
    from, to = to, from
  end

  return { from = { from[1], from[2] }, to = { to[1], to[2] }, kind = kind }
end

---Build a reference for the current position:
---  visual selection range  (if active),
---  or cursor line only.
---
---@return string|nil
function M.get_ref()
  local win = last_used_win()
  if win == 0 then
    return nil
  end
  local buf = vim.api.nvim_win_get_buf(win)

  local sel = M.get_selection(buf)
  if sel then
    return M.format(buf, {
      start_line = sel.from[1],
      start_col = sel.kind ~= "line" and sel.from[2] or nil,
      end_line = sel.to[1],
      end_col = sel.kind ~= "line" and sel.to[2] or nil,
    })
  end

  local cursor = vim.api.nvim_win_get_cursor(win)
  return M.format(buf, {
    start_line = cursor[1],
    start_col = cursor[2] + 1,
  })
end

---Build a reference at a specific line (1-based).
---@param line number
---@return string|nil
function M.get_ref_at(line)
  local win = last_used_win()
  if win == 0 then
    return nil
  end
  local buf = vim.api.nvim_win_get_buf(win)
  return M.format(buf, { start_line = line })
end

return M
