-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- Clear all swap files
vim.api.nvim_create_user_command("ClearSwap", function()
  vim.fn.system("rm -f ~/.local/state/nvim/swap/*.swp")
  vim.notify("Swap files cleared", vim.log.levels.INFO)
end, { desc = "Clear all nvim swap files" })
