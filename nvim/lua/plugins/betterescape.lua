return {
  "max397574/better-escape.nvim",
  event = 'InsertEnter',
  config = function()
    require("better_escape").setup {
      mapping = { "jk" },       -- a table with mappings to use
      timeout = 300,            -- the time in which the keys must be hit in ms. Use option timeoutlen by default
      clear_empty_lines = true, -- clear line after escaping if there is only whitespace
      keys = "<Esc>",           -- keys used for escaping, if it is a function will use the result everytime
      -- To keep the cursor in the appropriate place instead of behind the previous cursor
      -- keys = function()
      --   return vim.api.nvim_win_get_cursor(0)[2] > 1 and '<esc>l' or '<esc>'
      -- end,
    }
  end
}
