return {
    "max397574/better-escape.nvim",
    event = "InsertEnter",
    config = function()
        -- lua, default settings
        require("better_escape").setup({
            timeout = vim.o.timeoutlen,
            default_mappings = false,
            mappings = {
                i = {
                    j = {
                        k = "<Esc>",
                    },
                },
                c = {
                    j = {
                        k = "<Esc>",
                    },
                },
                t = {
                    j = {
                        k = "<C-\\><C-n>",
                    },
                },
                -- v = {
                -- 	j = {
                -- 		k = "<Esc>",
                -- 	},
                -- },
                s = {
                    j = {
                        k = "<Esc>",
                    },
                },
            },
        })
    end,
}
