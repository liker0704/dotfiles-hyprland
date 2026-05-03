-- Disable markdownlint-cli2 on vault/markdown files (npm pkg not installed,
-- and personal notes don't need it). Set linters_by_ft.markdown to empty list.
return {
  "mfussenegger/nvim-lint",
  opts = {
    linters_by_ft = {
      markdown = {},
    },
  },
}
