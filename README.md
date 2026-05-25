# codewhale.nvim

CodeWhale integration for Neovim. Opens the [CodeWhale](https://github.com/Hmbown/DeepSeek-TUI) CLI in a [Snacks.nvim](https://github.com/folke/snacks.nvim) terminal window, with shortcutsTOM for injecting file path + line number references directly into the codewhale prompt.

This plugin draws inspiration from [opencode.nvim](https://github.com/nickjvandyke/opencode.nvim) and [deepseek.nvim](https://github.com/xiaopixiao/deepseek.nvim), and was built with [CodeWhale](https://github.com/Hmbown/DeepSeek-TUI) + DeepSeek-V4-Pro.

## Features

- **Terminal toggle** — open/hide the CodeWhale TUI in a right-side split
- **Smart focus** — jump to terminal if unfocused, hide if already focused
- **Session resume** — `:CodeWhaleResume` to pick up where you left off
- **File references** — the core feature: send file path + line number to the codewhale prompt with a single keystroke
  - Normal mode: `<leader>ca` sends `current/file:L42:C3` (cursor position)
  - Visual mode: `<leader>cA` sends `current/file:L10:C2-L25` (selection range)
  - Count prefix: `32<leader>cl` sends `current/file:L32` (line 32)
- **Pass-through shortcuts** — `<C-t>` (conversation log), `<C-p>` (fuzzy files), `<C-r>` (resume session) forwarded to codewhale TUI

## Requirements

- Neovim >= 0.10
- [Snacks.nvim](https://github.com/folke/snacks.nvim)
- [CodeWhale CLI](https://github.com/Hmbown/DeepSeek-TUI) (`codewhale` on `$PATH`)

## Installation

### lazy.nvim

```lua
{
  "zacharyxz/codewhale.nvim",
  dependencies = { "folke/snacks.nvim" },
  config = true,
  keys = {
    { "<leader>cw", "<cmd>CodeWhale<cr>",       desc = "Toggle CodeWhale" },
    { "<leader>cf", "<cmd>CodeWhaleFocus<cr>",   desc = "Focus CodeWhale" },
    { "<leader>cr", "<cmd>CodeWhaleRun<cr>",     desc = "CodeWhale run" },
    { "<leader>cR", "<cmd>CodeWhaleResume<cr>",  desc = "CodeWhale resume" },
    { "<leader>ca", desc = "Add file:line ref to CodeWhale" },
    { "<leader>cA", desc = "Add selection ref to CodeWhale", mode = "v" },
    { "<leader>cl", desc = "Add file:line ref (with count)" },
  },
}
```

### With custom options

```lua
{
  "zacharyxz/codewhale.nvim",
  dependencies = { "folke/snacks.nvim" },
  opts = {
    terminal = {
      split_side = "left",
      split_width = 0.25,
      snacks_win_opts = {
        wo = { winblend = 100 },
      },
    },
    keymaps = {
      toggle        = "<leader>cw",
      add_file      = "<leader>ca",
      add_selection = "<leader>cA",
      -- Disable a keymap
      run = false,
    },
  },
}
```

## Configuration

`opts` is passed to `require("codewhale").setup(opts)`.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `terminal.split_side` | `"left"` \| `"right"` | `"right"` | Which side the split opens on |
| `terminal.split_width` | `number` | `0.30` | Width ratio (0-1) |
| `terminal.auto_close` | `boolean` | `true` | Auto-close terminal buffer on exit |
| `terminal.snacks_win_opts` | `table` | `{}` | Merged into Snacks terminal `win` config |
| `terminal.cwd` | `string?` | `nil` | Working directory (default: current dir) |
| `terminal_cmd` | `string?` | `nil` | Override the binary (default: `codewhale`) |
| `env` | `table<string,string>?` | `nil` | Extra environment variables |
| `keymaps` | `table` | see below | Keymap overrides (set to `false` to disable) |

### Default keymaps

| Key | Command | Description |
|-----|---------|-------------|
| `<leader>cw` | `:CodeWhale` | Toggle codewhale terminal |
| `<leader>cf` | `:CodeWhaleFocus` | Smart focus/toggle |
| `<leader>cr` | `:CodeWhaleRun` | Open in run mode |
| `<leader>cR` | `:CodeWhaleResume` | Resume a saved session |
| `<leader>ca` | `:CodeWhaleAddRef` | **Add file:line reference** (cursor position in normal mode, selection range in visual mode) |
| `<leader>cl` | — | **Add file:line reference** with count as line number (e.g. `42<leader>cl` for line 42) |

## Commands

| Command | Description |
|---------|-------------|
| `:CodeWhale` | Toggle terminal (show/hide) |
| `:CodeWhaleFocus` | Smart focus -- jump to terminal, or hide if already focused |
| `:CodeWhaleOpen` | Open terminal without toggle logic |
| `:CodeWhaleClose` | Close the terminal |
| `:CodeWhaleRun [args]` | Open in `run` mode |
| `:CodeWhaleResume [name]` | Resume a saved session |
| `:CodeWhaleAddRef` | Add current file:line reference to the codewhale prompt |

## Terminal Key Bindings

Active inside the CodeWhale terminal window:

| Key | Action |
|-----|--------|
| `<C-t>` | Toggle conversation log overlay |
| `<C-p>` | Open fuzzy file picker |
| `<C-r>` | Open resume session picker |
| `<S-CR>` | New line (Shift+Enter) |

## File Reference Format

References are compact, relative-path strings sent directly to the codewhale terminal:

```
lua/codewhale/init.lua:L42          -- cursor at line 42
lua/codewhale/init.lua:L21:C5-L35   -- selection from line 21 col 5 to line 35
lua/codewhale/init.lua:L10:C1-L10   -- single-line selection at line 10
```

## License

MIT
