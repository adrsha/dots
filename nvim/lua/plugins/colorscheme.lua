return {
  "catppuccin/nvim",
  name = "catppuccin",
  priority = 1000,
  event = 'VimEnter',
  config = function()
    require("catppuccin").setup({
      flavour = "mocha", -- latte, frappe, macchiato, mocha
      background = {
        -- :h background
        light = "latte",
        dark = "mocha",
      },
      transparent_background = true,
      show_end_of_buffer = false, -- show the '~' characters after the end of buffers
      term_colors = true,
      dim_inactive = {
        enabled = false,
        shade = "dark",
        percentage = 0.15,
      },
      no_italic = true, -- Force no italic
      no_bold = false,  -- Force no bold
      styles = {
        comments = {},
        conditionals = { "bold" },
        loops = { "bold" },
        functions = { "bold" },
        keywords = {},
        strings = {},
        variables = {},
        numbers = {},
        booleans = {},
        properties = {},
        types = {},
        operators = {},
      },
      color_overrides = {
        mocha = {
          rosewater = "#e8dee9",
          flamingo = "#81a1c1",
          mauve = "#b48ead",
          pink = "#F5C2E7",
          red = "#bf616a",
          maroon = "#E8A2AF",
          peach = "#d08770",
          yellow = "#ebcb8b",
          green = "#a3be8c",
          blue = "#88c0d0",
          sky = "#5e81ac",
          teal = "#B5E8E0",
          lavender = "#81a1c1",

          text = "#eceff4",
          subtext1 = "#e5e9f0",
          subtext0 = "#e5e9f0",
          overlay2 = "#d8dee9",
          overlay1 = "#d8dee9",
          overlay0 = "#4c566a",
          surface2 = "#434c5e",
          surface1 = "#3b4252",
          surface0 = "#2e3440",

          base = "#242933",
          mantle = "#242933",
          crust = "#2e3440",
        },
      },
      custom_highlights = {},
      integrations = {
        cmp = true,
        gitsigns = true,
        nvimtree = true,
        telescope = true,
        notify = false,
        mini = false,
        -- For more plugins integrations please scroll down (https://github.com/catppuccin/nvim#integrations)
      },
    })
    vim.cmd.colorscheme "catppuccin"


    vim.cmd([[
  hi NormalFloat guibg=NONE
  hi Title guibg=NONE guifg=#cc9b9d
  hi FloatBorder guibg=NONE
  hi BufferTabpageFill guibg=NONE
  hi TabLineFill guibg=NONE
  hi TabLine guibg=NONE


  highlight! DiagnosticLineNrError guibg=#B7435E guifg=#cc9b9d gui=bold
  highlight! DiagnosticLineNrWarn guibg=#D88B72 guifg=#E8CCA7 gui=bold
  highlight! DiagnosticLineNrInfo guibg=#6E7EBF guifg=#B8C9EA gui=bold
  highlight! DiagnosticLineNrHint guibg=#414560 guifg=#63718B gui=bold
  hi DiagnosticError  guifg=#cc9b9d gui=bold
  hi DiagnosticWarn  guifg=#E8CCA7 gui=bold
  hi DiagnosticInfo  guifg=#B8C9EA gui=bold
  hi DiagnosticHint  guifg=#63718B gui=bold

  sign define DiagnosticSignError text= texthl=DiagnosticSignError linehl= numhl=DiagnosticLineNrError
  sign define DiagnosticSignWarn text= texthl=DiagnosticSignWarn linehl= numhl=DiagnosticLineNrWarn
  sign define DiagnosticSignInfo text= texthl=DiagnosticSignInfo linehl= numhl=DiagnosticLineNrInfo
  sign define DiagnosticSignHint text= texthl=DiagnosticSignHint linehl= numhl=DiagnosticLineNrHint

  highlight! link TelescopeBorder CursorColumn
  highlight! link TelescopeNormal CursorColumn
  highlight! link TelescopeTitle Title

  highlight! CmpItemAbbrDeprecated guibg=NONE gui=strikethrough guifg=#808080

  highlight! CmpItemAbbrMatch guibg=NONE guifg=#CCCBD9
  highlight! link CmpItemAbbrMatchFuzzy CmpItemAbbrMatch

  highlight! CmpItemKindVariable guibg=NONE guifg=#95C2D1
  highlight! link CmpItemKindInterface CmpItemKindVariable
  highlight! link CmpItemKindText CmpItemKindVariable

  highlight! CmpItemKindFunction guibg=NONE guifg=#f6bbe7
  highlight! link CmpItemKindMethod CmpItemKindFunction

  highlight! CmpItemKindKeyword guibg=NONE guifg=#caf6bb
  highlight! link CmpItemKindProperty CmpItemKindKeyword
  highlight! link CmpItemKindUnit CmpItemKindKeyword

  highlight! CmpItemMenu guibg=NONE guifg=#63718B

  augroup packer_user_config
    autocmd!
    autocmd BufWritePost packer.lua source <afile> | PackerSync
  augroup end

highlight NotifyERRORBorder guifg=#F28FAD
highlight NotifyWARNBorder guifg=#FAE3B0
highlight NotifyINFOBorder guifg=#ABE9B3
highlight NotifyDEBUGBorder guifg=#575268
highlight NotifyTRACEBorder guifg=#988BA2

highlight NotifyERRORIcon guifg=#F5C2E7
highlight NotifyWARNIcon guifg=#F8BD96
highlight NotifyINFOIcon guifg=#ABE9B3
highlight NotifyDEBUGIcon guifg=#6E6C7E
highlight NotifyTRACEIcon guifg=#DDB6F2
highlight NotifyERRORTitle  guifg=#F5C2E7
highlight NotifyWARNTitle guifg=#F8BD96
highlight NotifyINFOTitle guifg=#ABE9B3
highlight NotifyDEBUGTitle  guifg=#6E6C7E
highlight NotifyTRACETitle  guifg=#DDB6F2
highlight link NotifyERRORBody Normal
highlight link NotifyWARNBody Normal
highlight link NotifyINFOBody Normal
highlight link NotifyDEBUGBody Normal
highlight link NotifyTRACEBody Normal


highlight TSRainbowOrange  guifg=#F8BD96 ctermfg=White
highlight TSRainbowRed  guifg=#F28FAD ctermfg=White
highlight TSRainbowYellow  guifg=#FAE3B0 ctermfg=White
highlight TSRainbowBlue  guifg=#96CDFB ctermfg=White
highlight TSRainbowGreen  guifg=#988BA2 ctermfg=White
highlight TSRainbowViolet  guifg=#DDB6F2 ctermfg=White
highlight TSRainbowCyan  guifg=#89DCEB ctermfg=White
]])
  end
}
