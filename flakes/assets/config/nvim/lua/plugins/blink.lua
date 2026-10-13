return {
    "saghen/blink.cmp",
    version = "1.*",
    event = { "InsertEnter" },

    dependencies = {
        "rafamadriz/friendly-snippets",
        {
            -- snippet plugin
            "L3MON4D3/LuaSnip",
            dependencies = "rafamadriz/friendly-snippets",
            opts = {
                history = true,
                updateevents = "TextChanged,TextChangedI"
            },
            config = function(_, opts)
                require("luasnip").config.set_config(opts)
                require "configs.luasnip"
            end,
        },

        {
            "windwp/nvim-autopairs",
            opts = {
                fast_wrap = {},
                disable_filetype = { "TelescopePrompt", "vim" },
            },
        },
    },

    opts_extend = { "sources.default" },

    opts = function()
        return require "configs.blink"
    end,
}
