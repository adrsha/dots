-- chadrc.lua
-- Structure must match nvconfig.lua:
-- https://github.com/NvChad/ui/blob/v3.0/lua/nvconfig.lua

local M          = {};

-- Read a THEME_XXX env var.
-- Hard error if missing so misconfiguration is obvious.
local function color(key)
    local v = vim.env["THEME_" .. key];
    if v == nil or v == "" then
        vim.notify(
            "chadrc: missing env var THEME_" .. key .. " (run set_theme before starting nvim)",
            vim.log.levels.ERROR
        );
        return "#000000";
    end;
    return v;
end;

local function build_theme()
    return {
        base_16 = {
            base00 = color("BASE00"),
            base01 = color("BASE01"),
            base02 = color("BASE02"),
            base03 = color("BASE03"),
            base04 = color("BASE04"),
            base05 = color("BASE05"),
            base06 = color("BASE06"),
            base07 = color("BASE07"),
            base08 = color("BASE08"),
            base09 = color("BASE09"),
            base0A = color("BASE0A"),
            base0B = color("BASE0B"),
            base0C = color("BASE0C"),
            base0D = color("BASE0D"),
            base0E = color("BASE0E"),
            base0F = color("BASE0F"),
        },
        base_30 = {
            white          = color("WHITE"),
            darker_black   = color("DARKER_BLACK"),
            black          = color("BLACK"),
            black2         = color("BLACK2"),
            one_bg         = color("ONE_BG"),
            one_bg2        = color("ONE_BG2"),
            one_bg3        = color("ONE_BG3"),
            grey           = color("GREY"),
            grey_fg        = color("GREY_FG"),
            grey_fg2       = color("GREY_FG2"),
            light_grey     = color("LIGHT_GREY"),
            red            = color("RED"),
            baby_pink      = color("BABY_PINK"),
            pink           = color("PINK"),
            line           = color("LINE"),
            green          = color("GREEN"),
            vibrant_green  = color("VIBRANT_GREEN"),
            blue           = color("BLUE"),
            nord_blue      = color("NORD_BLUE"),
            yellow         = color("YELLOW"),
            sun            = color("SUN"),
            purple         = color("PURPLE"),
            dark_purple    = color("DARK_PURPLE"),
            teal           = color("TEAL"),
            orange         = color("ORANGE"),
            cyan           = color("CYAN"),
            statusline_bg  = color("STATUSLINE_BG"),
            lightbg        = color("LIGHTBG"),
            pmenu_bg       = color("PMENU_BG"),
            folder_bg      = color("FOLDER_BG"),
        },
    };
end;

-- Reload the theme from current env vars without restarting nvim.
-- Called by set_theme.fish via: nvim --server $socket --remote-expr 'v:lua.reload_nvchad_theme()'
--
-- set_theme.fish writes /tmp/nvim_theme_patch.lua before calling us.
-- That file assigns all THEME_* values directly into vim.env, patching
-- the stale process environment so color() reads the correct values.
_G.reload_nvchad_theme = function()
    local patch = "/tmp/nvim_theme_patch.lua"
    if vim.fn.filereadable(patch) == 1 then
        dofile(patch)
    else
        vim.notify("chadrc: /tmp/nvim_theme_patch.lua not found — run set_theme first", vim.log.levels.ERROR)
        return "error"
    end

    vim.g.theme_variant = vim.env.THEME_VARIANT or "dark"
    vim.o.background    = vim.g.theme_variant

    -- Clear all cached modules so everything re-reads from scratch.
    package.loaded["nvconfig"]   = nil
    package.loaded["base46"]     = nil
    package.loaded["highlights"] = nil

    local nvconfig            = require("nvconfig")
    local environment_palette = build_theme()

    nvconfig.base46.theme = "onedark"
    nvconfig.ui.theme     = "onedark"

    nvconfig.base46.changed_themes = {
        ["onedark"] = {
            base_16 = environment_palette.base_16,
            base_30 = environment_palette.base_30,
        }
    }

    local base46 = require("base46")

    -- Compile first so load_all_highlights reads the correct bytecode,
    -- not whatever was on disk from the previous theme.
    base46.compile()
    base46.load_all_highlights()

    vim.schedule(function()
        package.loaded["highlights"] = nil
        require("highlights").set_custom_highlights()
    end)

    vim.notify("nvchad: theme reloaded", vim.log.levels.INFO)
    return "ok"
end

M = {
    base46 = {
        theme          = "onedark",
        hl_add         = {},
        integrations   = {},
        changed_themes = { ["onedark"] = build_theme() },
        transparency   = false,
    },

    ui = {
        cmp = {
            icons_left    = true,
            lspkind_text  = true,
            style         = "flat_dark",
            format_colors = {
                tailwind = true,
                icon     = "󱓻",
            },
        },
        telescope = { style = "borderless" },
        tabufline = {
            enabled  = false,
            lazyload = true,
            order    = { "treeOffset", "buffers", "tabs", "btns" },
            modules  = nil,
        },
    },

    term = {
        winopts = { number = false, relativenumber = false },
        sizes   = { sp = 0.3, vsp = 0.2, ["bo sp"] = 0.3, ["bo vsp"] = 0.2 },
        float   = {
            relative = "editor",
            row      = 0.3,
            col      = 0.1,
            width    = 0.8,
            height   = 0.9,
            border   = "single",
        },
    },

    lsp      = { signature = true },
    mason    = { pkgs = {} },

    colorify = {
        enabled   = true,
        mode      = "virtual",
        virt_text = "󱓻 ",
        highlight = { hex = true, lspvars = true },
    },
};

-- Compile on first load so the cache matches the current env palette.
vim.schedule(function()
    local base46 = require("base46")
    base46.compile()
    base46.load_all_highlights()
    require("highlights").set_custom_highlights()
end)

return M;

