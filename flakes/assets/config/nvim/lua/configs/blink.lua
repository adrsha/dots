dofile(vim.g.base46_cache .. "blink")

local M = {}
local ui = require("nvconfig").ui.cmp
local atom_styled = ui.style == "atom" or ui.style == "atom_colored"

local menu_cols
if atom_styled or ui.icons_left then
    menu_cols = { { "kind_icon" }, { "label" }, { "kind" } }
else
    menu_cols = { { "label" }, { "kind_icon" }, { "kind" } }
end

local opts = {
    snippets = { preset = "luasnip" },
    cmdline = {
        enabled = false
    },
    appearance = { nerd_font_variant = "normal" },
    fuzzy = { implementation = "prefer_rust" },
    sources = { default = { "lsp", "snippets", "buffer", "path" } },

    keymap = {
        preset = "default",
        ["<C-l>"] = { "accept", "fallback" },
        ["<C-j>"] = { "select_next", "snippet_forward", "fallback" },
        ["<C-k>"] = { "select_prev", "snippet_backward", "fallback" },
    },

    completion = {
        ghost_text = { enabled = true },
        documentation = {
            auto_show = true,
            auto_show_delay_ms = 200,
            window = { border = "single" },
        },
        list = {
            selection = {
                preselect = true,
                auto_insert = true
            },
        },
        menu = {
            scrollbar = false,
            border = atom_styled and "none" or "single",
            draw = {
                padding = { atom_styled and 0 or 1, 1 },
                columns = menu_cols,
                components = {
                    kind_icon = {
                        text = function(ctx)
                            local icons = require "utils.lspkind"
                            local icon = (icons[ctx.kind] or "󰈚")

                            if atom_styled then
                                icon = " " .. icon .. " "
                            end

                            return icon
                        end,
                    },

                    kind = {
                        highlight = function(ctx)
                            return atom_styled and "comment" or ctx.kind
                        end,
                    },
                },
            },
        },
    },
}

return opts
