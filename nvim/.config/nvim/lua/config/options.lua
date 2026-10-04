-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Re-enable unnamedplus so yanking automatically sends to system clipboard
vim.opt.clipboard = "unnamedplus"

-- Hybrid clipboard provider (see :help clipboard-osc52 / :help clipboard-tool):
--   * SSH session   -> OSC 52 through the terminal. Copy always works; paste sends
--                      an OSC 52 read query and, if the terminal doesn't answer
--                      quickly (most disable clipboard reads for security, and tmux
--                      answers with its own stale clipboard instead of the real one),
--                      falls back silently to Neovim's internal registers.
--   * local macOS   -> pbcopy/pbpaste
--   * local Wayland -> wl-copy/wl-paste: reads the LIVE system clipboard directly,
--                      bypassing tmux entirely (this is what makes paste dynamic).
--   * local X11     -> xclip
--   * otherwise     -> OSC 52 (same as SSH branch)

local function has_exe(cmd)
  return vim.fn.executable(cmd) == 1
end

-- Budget for the OSC 52 paste query. Ghostty answers within milliseconds when it
-- answers at all; raise this only if very slow SSH links cause false fallbacks.
local OSC52_PASTE_TIMEOUT_MS = 500

-- Like require("vim.ui.clipboard.osc52").paste(), but with a short timeout and no
-- warnings. Returning 0 on failure makes Neovim fall back to its own register
-- contents (get_yank_register() -> y_previous in src/nvim/register.c).
local function osc52_paste(reg)
  local clipboard = reg == "+" and "c" or "p"
  return function()
    local contents ---@type string?
    local id = vim.api.nvim_create_autocmd("TermResponse", {
      callback = function(ev)
        local encoded = ev.data.sequence:match("\027%]52;%w?;([A-Za-z0-9+/=]*)")
        if encoded then
          contents = vim.base64.decode(encoded)
          return true -- delete this autocmd
        end
      end,
    })

    -- pcall: no-op when no TUI is attached (e.g. headless Neovim)
    pcall(vim.api.nvim_ui_send, string.format("\027]52;%s;?\027\\", clipboard))

    vim.wait(OSC52_PASTE_TIMEOUT_MS, function()
      return contents ~= nil
    end)

    if contents == nil then
      pcall(vim.api.nvim_del_autocmd, id) -- in case the callback never fired
      return 0 -- -> Neovim pastes from its internal register instead
    end
    return vim.split(contents, "\n")
  end
end

local function osc52_provider()
  local osc52 = require("vim.ui.clipboard.osc52")
  return {
    name = "OSC 52 (fast fallback paste)",
    copy = {
      ["+"] = osc52.copy("+"),
      ["*"] = osc52.copy("*"),
    },
    paste = {
      ["+"] = osc52_paste("+"),
      ["*"] = osc52_paste("*"),
    },
  }
end

if vim.env.SSH_TTY or vim.env.SSH_CONNECTION then
  -- Remote session: no local clipboard tool can reach the system clipboard
  vim.g.clipboard = osc52_provider()
elseif vim.fn.has("mac") == 1 and has_exe("pbcopy") and has_exe("pbpaste") then
  vim.g.clipboard = {
    name = "macOS-Clipboard",
    copy = {
      ["+"] = "pbcopy",
      ["*"] = "pbcopy",
    },
    paste = {
      ["+"] = "pbpaste",
      ["*"] = "pbpaste",
    },
  }
elseif vim.env.WAYLAND_DISPLAY and has_exe("wl-copy") and has_exe("wl-paste") then
  vim.g.clipboard = {
    name = "wl-clipboard",
    copy = {
      ["+"] = { "wl-copy", "--type", "text/plain" },
      ["*"] = { "wl-copy", "--primary", "--type", "text/plain" },
    },
    paste = {
      ["+"] = { "wl-paste", "--no-newline" },
      ["*"] = { "wl-paste", "--primary", "--no-newline" },
    },
  }
elseif vim.env.DISPLAY and has_exe("xclip") then
  vim.g.clipboard = {
    name = "xclip",
    copy = {
      ["+"] = { "xclip", "-quiet", "-i", "-selection", "clipboard" },
      ["*"] = { "xclip", "-quiet", "-i", "-selection", "primary" },
    },
    paste = {
      ["+"] = { "xclip", "-o", "-selection", "clipboard" },
      ["*"] = { "xclip", "-o", "-selection", "primary" },
    },
  }
else
  -- Last resort (e.g. console without Wayland/X tools)
  vim.g.clipboard = osc52_provider()
end
