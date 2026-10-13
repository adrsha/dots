return {
    "nvim-lua/plenary.nvim",
    {
        "nvchad/base46",
        build = function()
            require("base46").load_all_highlights()
        end,
    },

    {
        "nvchad/ui",
        lazy = false,
        config = function()
            require "nvchad"
        end,
    },


    {
        "mason-org/mason.nvim",
        cmd = { "Mason", "MasonInstall", "MasonUpdate" },
        opts = function()
            return require "configs.mason"
        end,
    },

    {
        "neovim/nvim-lspconfig",
        event = "User FilePost",
        config = function()
            require("configs.lspconfig").defaults()
        end,
    },
}
