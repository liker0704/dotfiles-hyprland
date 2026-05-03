return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        basedpyright = {
          root_markers = {
            "pyrightconfig.json",
            "pyproject.toml",
            "setup.py",
            "setup.cfg",
            "requirements.txt",
            "Pipfile",
            ".venv",
            "venv",
            ".git",
          },
          root_dir = function(bufnr, on_dir)
            local fname = vim.api.nvim_buf_get_name(bufnr)
            local found = vim.fs.root(fname, {
              "pyrightconfig.json",
              "pyproject.toml",
              "setup.py",
              "requirements.txt",
              "Pipfile",
              ".venv",
              "venv",
              ".git",
            })
            on_dir(found or vim.fn.getcwd())
          end,
          settings = {
            basedpyright = {
              disableOrganizeImports = true,
              analysis = {
                typeCheckingMode = "basic",
                diagnosticSeverityOverrides = {
                  reportUnusedImport = "none",
                  reportUnusedVariable = "none",
                  reportUnusedFunction = "none",
                  reportMissingTypeStubs = "none",
                  reportUnknownMemberType = "none",
                  reportUnknownVariableType = "none",
                  reportUnknownArgumentType = "none",
                  reportUnknownParameterType = "none",
                  reportUnknownLambdaType = "none",
                  reportAny = "none",
                  reportExplicitAny = "none",
                },
              },
            },
          },
          before_init = function(_, config)
            local function find_venv_python(start)
              local dir = vim.fs.find({ ".venv", "venv" }, {
                upward = true,
                path = start,
                type = "directory",
              })[1]
              if dir then
                local py = dir .. "/bin/python"
                if vim.uv.fs_stat(py) then
                  return py
                end
              end
            end
            local py = find_venv_python(vim.fs.dirname(vim.api.nvim_buf_get_name(0)))
              or (vim.env.VIRTUAL_ENV and vim.env.VIRTUAL_ENV ~= "" and vim.env.VIRTUAL_ENV .. "/bin/python")
              or vim.fn.exepath("python3")
            config.settings = vim.tbl_deep_extend("force", config.settings or {}, {
              python = { pythonPath = py },
            })
          end,
        },
      },
    },
  },
}
