return {
    "utilyre/barbecue.nvim",
    name = "barbecue",
    version = "*",
    dependencies = {
        "SmiteshP/nvim-navic",
        "nvim-tree/nvim-web-devicons", -- optional dependency
    },
    event = "VeryLazy",
    config = function()
        local function hl(name, fallback)
            local ok, highlight = pcall(vim.api.nvim_get_hl, 0, { name = name })
            if ok and highlight and highlight.fg then
                return { fg = highlight.fg }
            end
            return fallback or {}
        end

        local default = hl("CursorLineNr")

        require("barbecue").setup({
            show_dirname = true,
            show_basename = true,
            show_modified = true,

            theme = {
                normal                 = default,

                ellipsis               = default,
                separator              = default,
                modified               = default,

                dirname                = default,
                basename               = { fg = default.fg, bold = true},
                context                = default,

                -- File & container
                context_file           = hl("@text.uri", default),
                context_module         = hl("@module", default),
                context_namespace      = hl("@namespace", default),
                context_package        = hl("@module", default),

                -- Types
                context_class          = hl("@type"),
                context_struct         = hl("@type"),
                context_interface      = hl("@type"),
                context_enum           = hl("@type"),
                context_type_parameter = hl("@type.parameter"),

                -- Callables
                context_function       = hl("@function"),
                context_method         = hl("@method"),
                context_constructor    = hl("@constructor"),
                context_event          = hl("@function"),

                -- Variables & values
                context_variable       = hl("@variable"),
                context_constant       = hl("@constant"),
                context_property       = hl("@property"),
                context_field          = hl("@field"),
                context_enum_member    = hl("@constant"),
                context_parameter      = hl("@parameter"),

                -- Literals
                context_string         = hl("@string"),
                context_number         = hl("@number"),
                context_boolean        = hl("@boolean"),
                context_array          = hl("@punctuation.bracket"),
                context_object         = hl("@punctuation.bracket"),
                context_key            = hl("@property"),
                context_null           = hl("@constant.builtin"),

                -- Operators
                context_operator       = hl("@operator"),
            },
        })
    end
}
