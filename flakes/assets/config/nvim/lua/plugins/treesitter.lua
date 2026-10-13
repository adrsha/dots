return {
    {
        "HiPhish/rainbow-delimiters.nvim",
        dependencies = { "nvim-treesitter/nvim-treesitter"},
    },
    {
        "nvim-treesitter/nvim-treesitter",
        event = { "BufReadPost", "BufNewFile" },
        cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
        build = ":TSUpdate | TSInstallAll",
        opts = function()
            return require "configs.treesitter"
        end,
    }
}
