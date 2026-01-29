-- Monochrome colorscheme matching terminal (#18181b)
return {
  -- Use tokyonight as base but override colors
  {
    "folke/tokyonight.nvim",
    lazy = false,
    priority = 1000,
    opts = {
      style = "night",
      transparent = false,
      terminal_colors = true,
      styles = {
        comments = { italic = false },
        keywords = { italic = false },
        sidebars = "dark",
        floats = "dark",
      },
      on_colors = function(colors)
        -- Match terminal background
        colors.bg = "#18181b"
        colors.bg_dark = "#18181b"
        colors.bg_float = "#18181b"
        colors.bg_popup = "#18181b"
        colors.bg_sidebar = "#18181b"
        colors.bg_statusline = "#27272a"
        colors.bg_highlight = "#27272a"
        colors.fg = "#e5e7eb"
        colors.fg_dark = "#a1a1aa"
        colors.fg_gutter = "#3f3f46"
        colors.border = "#3f3f46"
        colors.comment = "#71717a"
      end,
      on_highlights = function(hl, c)
        -- Make sure Normal bg matches exactly
        hl.Normal = { bg = "#18181b", fg = "#e5e7eb" }
        hl.NormalNC = { bg = "#18181b", fg = "#e5e7eb" }
        hl.NormalFloat = { bg = "#18181b" }
        hl.NormalSB = { bg = "#18181b" }
        hl.SignColumn = { bg = "#18181b" }
        hl.LineNr = { fg = "#52525b", bg = "#18181b" }
        hl.CursorLineNr = { fg = "#a1a1aa", bg = "#18181b" }
        hl.CursorLine = { bg = "#27272a" }
        hl.Visual = { bg = "#3f3f46" }
        hl.Pmenu = { bg = "#18181b", fg = "#e5e7eb" }
        hl.PmenuSel = { bg = "#3f3f46", fg = "#ffffff" }
        -- Neo-tree
        hl.NeoTreeNormal = { bg = "#18181b" }
        hl.NeoTreeNormalNC = { bg = "#18181b" }
        hl.NeoTreeEndOfBuffer = { bg = "#18181b" }
        -- Telescope
        hl.TelescopeNormal = { bg = "#18181b" }
        hl.TelescopeBorder = { bg = "#18181b", fg = "#3f3f46" }
        -- StatusLine
        hl.StatusLine = { bg = "#27272a", fg = "#e5e7eb" }
        hl.StatusLineNC = { bg = "#18181b", fg = "#71717a" }
        -- End of buffer
        hl.EndOfBuffer = { fg = "#18181b" }
      end,
    },
  },

  -- Configure LazyVim to use tokyonight
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "tokyonight",
    },
  },
}
