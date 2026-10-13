return {
    "nvim-telescope/telescope.nvim", version = "*",
    event = "VeryLazy",
    dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
    },
    config = function()
        require("telescope").setup({
            -- your telescope opts here
        })

        pcall(function()
            require("telescope").load_extension("fzf")
        end)

        -- Re-apply after telescope has set its own highlight links.
        local ok, hl = pcall(require, "highlights")
        if ok and type(hl.set_custom_highlights) == "function" then
            hl.set_custom_highlights()
        end
    end,
}
