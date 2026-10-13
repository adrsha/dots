return {
  "nvim-flutter/flutter-tools.nvim",
  lazy = false,
  ft = { "dart" },
  dependencies = {
    "nvim-lua/plenary.nvim",
    "stevearc/dressing.nvim",
  },
  config = function()
    require("flutter-tools").setup {
      flutter_path = "/usr/bin/flutter",
      widget_guides = {
        enabled = false,
      },
      closing_tags = {
        highlight = "ErrorMsg", -- highlight for the closing tag
        prefix = ">", -- character to use for close tag e.g. > Widget
        priority = 10, -- priority of virtual text in current line
        -- consider to configure this when there is a possibility of multiple virtual text items in one line
        -- see `priority` option in |:help nvim_buf_set_extmark| for more info
        enabled = true, -- set to false to disable
      },
      ui = {
        border = "single",
        notification_style = "native",
      },
      decorations = {
        statusline = {
          app_version = false,
          device = false,
          project_config = false,
        },
      },
      lsp = {
        settings = {
          showTodos = true,
          completeFunctionCalls = true,
          renameFilesWithClasses = "prompt",
          enableSnippets = true,
          updateImportsOnRename = true,
        },
      },
    }
  end,
}
