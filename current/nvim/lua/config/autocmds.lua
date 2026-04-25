-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Hide tmux status bar while nvim is open (paired with pane-exited hook in tmux.conf).
-- This file loads on VeryLazy (after VimEnter), so we hide immediately rather than
-- via a VimEnter autocmd that would never fire. VimLeavePre + os.execute is used
-- on exit because VimLeave with vim.fn.system is unreliable (neovim/neovim#21856).
local function tmux_hide()
  if vim.env.TMUX then
    os.execute("tmux set -g status off")
  end
end
local function tmux_show()
  if vim.env.TMUX then
    os.execute("tmux set -g status on")
  end
end
tmux_hide()
local tmux_status = vim.api.nvim_create_augroup("tmux_status", { clear = true })
vim.api.nvim_create_autocmd("VimResume", { group = tmux_status, callback = tmux_hide })
vim.api.nvim_create_autocmd({ "VimLeavePre", "VimSuspend" }, { group = tmux_status, callback = tmux_show })
