-- obsidian.nvim — vault editing from Neovim, plus advanced-uri triggers
-- See https://github.com/obsidian-nvim/obsidian.nvim (active fork)

return {
  "obsidian-nvim/obsidian.nvim",
  lazy = true,
  ft = "markdown",
  cmd = { "Obsidian" },
  dependencies = { "nvim-lua/plenary.nvim" },
  keys = {
    { "<leader>oo", "<cmd>Obsidian open<cr>",         desc = "Open in Obsidian GUI" },
    { "<leader>od", "<cmd>Obsidian today<cr>",        desc = "Daily: today" },
    { "<leader>oy", "<cmd>Obsidian yesterday<cr>",    desc = "Daily: yesterday" },
    { "<leader>os", "<cmd>Obsidian search<cr>",       desc = "Search vault" },
    { "<leader>oq", "<cmd>Obsidian quick_switch<cr>", desc = "Quick switch note" },
    { "<leader>on", "<cmd>Obsidian new<cr>",          desc = "New note" },
    { "<leader>ob", "<cmd>Obsidian backlinks<cr>",    desc = "Backlinks" },
    { "<leader>ot", "<cmd>Obsidian tags<cr>",         desc = "Tags picker" },
    { "<leader>op", "<cmd>Obsidian paste_img<cr>",    desc = "Paste image" },
  },
  opts = {
    legacy_commands = false,
    workspaces = {
      { name = "MainVault", path = vim.fn.expand("~/Notes/MainVault") },
    },
    daily_notes = {
      folder = "01_Daily",
      date_format = "%Y-%m-%d",
      template = "Daily.md",
    },
    templates = {
      folder = "Templates",
      date_format = "%Y-%m-%d",
      time_format = "%H:%M",
    },
    new_notes_location = "00_Inbox",
    completion = {
      nvim_cmp = false,
      blink = true,
      min_chars = 2,
    },
    picker = { name = "snacks.pick" },
    open = {
      func = function(uri)
        vim.ui.open(uri)
      end,
    },
    open_notes_in = "current",
    ui = { enable = false }, -- LazyVim ships render-markdown.nvim; avoid double styling
  },
}
