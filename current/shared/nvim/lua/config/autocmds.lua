-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Hide tmux status bar while nvim is open.
-- This file loads on VeryLazy (after VimEnter), so we hide immediately rather than
-- via a VimEnter autocmd that would never fire.
-- IMPORTANT: target via $TMUX_PANE, not bare `set-option`. Without -t, tmux applies
-- the change to the "current" session (last attached client), which may NOT be the
-- session containing this nvim. $TMUX_PANE uniquely identifies the pane → session.
local function tmux_set(state)
  local pane = vim.env.TMUX_PANE
  if vim.env.TMUX and pane then
    os.execute("tmux set-option -q -t " .. vim.fn.shellescape(pane) .. " status " .. state)
  end
end
local function tmux_hide() tmux_set("off") end
local function tmux_show() tmux_set("on") end
tmux_hide()
local tmux_status = vim.api.nvim_create_augroup("tmux_status", { clear = true })
vim.api.nvim_create_autocmd("VimResume", { group = tmux_status, callback = tmux_hide })
vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, { group = tmux_status, callback = tmux_show })
