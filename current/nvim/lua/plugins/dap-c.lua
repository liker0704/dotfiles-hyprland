return {
  {
    "mfussenegger/nvim-dap",
    config = function()
      local dap = require("dap")

      dap.adapters.codelldb = {
        type = "server",
        port = "${port}",
        executable = {
          command = vim.fn.stdpath("data") .. "/mason/bin/codelldb",
          args = { "--port", "${port}" },
        },
      }

      dap.configurations.c = {
        {
          name = "Launch",
          type = "codelldb",
          request = "launch",
          program = function()
            return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
          end,
          cwd = "${workspaceFolder}",
          stopOnEntry = false,
          stdio = { nil, nil, nil },
          runInTerminal = true,
          args = function()
            local input = vim.fn.input("Arguments (or empty): ")
            if input == "" then
              return {}
            end
            return vim.split(input, " ")
          end,
        },
      }

      dap.configurations.cpp = dap.configurations.c
    end,
  },
}
