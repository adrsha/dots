local M = {};
local lightenColor         = require("utils/colors").lightenColor;
local darkenColor          = require("utils/colors").darkenColor;
local mergeColors          = require("utils/colors").mergeColors;

local function get_colors(base46)
    local base_16 = base46.get_theme_tb("base_16")
    local base_30 = base46.get_theme_tb("base_30")

    return base_16, base_30
end

local transparency_enabled = vim.g.transparency or false;

local function hex(h)
    return tonumber("0x" .. h:sub(2));
end;


M.set_custom_highlights = function ()
    local base46  = require("base46");
    local base_16, base_30 = get_colors(base46);

    local colors = {
        green   = hex(base_30.green),
        yellow  = hex(base_30.yellow),
        red     = hex(base_30.red),
        blue    = hex(base_30.blue),
        orange  = hex(base_30.orange),
        cyan    = hex(base_30.cyan),
        overlay = hex(base_30.grey_fg),
        base    = hex(base_16.base00),
        darker  = hex(base_30.darker_black),
    };

    local variant     = vim.g.theme_variant or vim.env.THEME_VARIANT or "dark";
    local light_theme = variant == "light";

    -- In dark themes:  subtle UI elements need lightening  (push away from black)
    -- In light themes: subtle UI elements need darkening   (push away from white)
    local function subtle_shift(color, amount)
        if light_theme then
            return darkenColor(color, amount);   -- no multiplier needed
        else
            return lightenColor(color, amount);
        end;
    end;

    -- Override Normal background if transparency is enabled
    if transparency_enabled then
        vim.api.nvim_set_hl(0, "Normal",        { bg = "NONE" });
        vim.api.nvim_set_hl(0, "NormalNC",      { bg = "NONE" });
        vim.api.nvim_set_hl(0, "SignColumn",    { bg = "NONE" });
        vim.api.nvim_set_hl(0, "LineNr",        { bg = "NONE" });
        vim.api.nvim_set_hl(0, "CursorLineNr",  { bg = "NONE" });
        vim.api.nvim_set_hl(0, "EndOfBuffer",   { bg = "NONE" });
    end;

    local float_bg_val = subtle_shift(colors.base, 0.3);

    local ColorSets = {
        -- Floating windows should ALWAYS be solid
        NormalFloat                 = { bg = float_bg_val },
        FloatBorder                 = { bg = float_bg_val, fg = colors.cyan },
        TelescopeBorder             = { bg = float_bg_val, fg = colors.cyan },
        TelescopeNormal             = { bg = float_bg_val },

        --Comments
        -- Comment                     = { fg = subtle_shift(colors.base, 1.0) },
        -- ["@comment"]                = { fg = subtle_shift(colors.base, 1.0) },
        
        -- LSP Diagnostics
        LspDiagnosticHint           = { fg = colors.green },
        LspDiagnosticWarn           = { fg = colors.orange },
        LspDiagnosticError          = { fg = colors.red },
        LspDiagnosticInfo           = { fg = colors.blue },
        DiagnosticHint              = { fg = colors.green },
        DiagnosticWarn              = { fg = colors.orange },
        DiagnosticError             = { fg = colors.red },
        DiagnosticInfo              = { fg = colors.blue },

        -- Diagnostic open (solid backgrounds)
        DiagnosticOpenSep           = { fg = colors.darker, bg = "NONE" },
        DiagnosticOpenArrow         = { bg = colors.darker, fg = colors.overlay },
        DiagnosticOpenHint          = { fg = colors.green,  bg = colors.darker, bold = true },
        DiagnosticOpenWarn          = { fg = colors.yellow, bg = colors.darker, bold = true },
        DiagnosticOpenError         = { fg = colors.red,    bg = colors.darker, bold = true },
        DiagnosticOpenInfo          = { fg = colors.blue,   bg = colors.darker, bold = true },

        -- Diagnostic lines
        DiagnosticLineHint          = { fg = colors.green,  bg = "NONE" },
        DiagnosticLineWarn          = { fg = colors.orange, bg = "NONE" },
        DiagnosticLineError         = { fg = colors.red,    bg = "NONE" },
        DiagnosticLineInfo          = { fg = colors.blue,   bg = "NONE" },

        -- Virtual text (solid backgrounds)
        DiagnosticVirtualTextHint   = {
            bg     = mergeColors(colors.green,  colors.base, 0.1),
            fg     = colors.green,
            bold   = true,
            italic = true,
        },
        DiagnosticVirtualTextWarn   = {
            bg     = mergeColors(colors.orange, colors.base, 0.1),
            fg     = colors.orange,
            bold   = true,
            italic = true,
        },
        DiagnosticVirtualTextError  = {
            bg     = mergeColors(colors.red,    colors.base, 0.1),
            fg     = colors.red,
            bold   = true,
            italic = true,
        },
        DiagnosticVirtualTextInfo   = {
            bg     = mergeColors(colors.blue,   colors.base, 0.1),
            fg     = colors.blue,
            bold   = true,
            italic = true,
        },

        CursorLine                  = { bg = colors.base },
        CursorLineNr                = { fg = colors.overlay },

        -- Whitespace dots/tabs: nudged away from bg so they're visible but muted
        -- WhiteSpace                  = { fg = subtle_shift(colors.base, 0.5) },
        -- LineNr                      = { fg = subtle_shift(colors.base, 0.5) },

        -- Indent guides: same logic, current indent slightly more visible
        -- IndentLine                  = { fg = subtle_shift(colors.base, 0.4) },
        -- IndentLineCurrent           = { fg = subtle_shift(colors.base, 0.7) },

        -- Symbol usage (solid backgrounds)
        SymbolUsageRounding         = { fg = colors.darker },
        SymbolUsageContent          = { bg = colors.darker, fg = subtle_shift(colors.overlay, 0.7), bold = true },
        SymbolUsageRef              = { bg = colors.darker, fg = colors.blue },
        SymbolUsageDef              = { bg = colors.darker, fg = colors.red },
        SymbolUsageImpl             = { bg = colors.darker, fg = colors.yellow },

        -- Underlines (solid backgrounds)
        DiagnosticUnderlineWarn     = { bg = mergeColors(colors.orange, colors.base, 0.2), fg = colors.orange },
        DiagnosticUnderlineHint     = { bg = mergeColors(colors.green,  colors.base, 0.2), fg = colors.green },
        DiagnosticUnderlineInfo     = { bg = mergeColors(colors.blue,   colors.base, 0.2), fg = colors.blue },
        DiagnosticUnderlineError    = { bg = mergeColors(colors.red,    colors.base, 0.2), fg = colors.red },

        TinyDiagnosticVirtualTextWarn   = { bg = mergeColors(colors.orange, colors.base, 0.2), fg = colors.orange },
        TinyDiagnosticVirtualTextHint   = { bg = mergeColors(colors.green,  colors.base, 0.2), fg = colors.green },
        TinyDiagnosticVirtualTextInfo   = { bg = mergeColors(colors.blue,   colors.base, 0.2), fg = colors.blue },
        TinyDiagnosticVirtualTextError  = { bg = mergeColors(colors.red,    colors.base, 0.2), fg = colors.red },

        TinyInlineDiagnosticVirtualTextWarn  = { bg = mergeColors(colors.orange, colors.base, 0.2), fg = colors.orange },
        TinyInlineDiagnosticVirtualTextHint  = { bg = mergeColors(colors.green,  colors.base, 0.2), fg = colors.green },
        TinyInlineDiagnosticVirtualTextInfo  = { bg = mergeColors(colors.blue,   colors.base, 0.2), fg = colors.blue },
        TinyInlineDiagnosticVirtualTextError = { bg = mergeColors(colors.red,    colors.base, 0.2), fg = colors.red },

        LspInlayHint = { fg = subtle_shift(colors.base, 0.2) },

        -- TreeSitter context (solid backgrounds)
        TreeSitterContext           = { fg = colors.overlay, bg = colors.darker },
        TreeSitterContextBottom     = { fg = colors.overlay, bg = colors.darker },
        TreeSitterContextLineNumber = { fg = colors.base,    bg = colors.darker },
        TreeSitterContextSeparator  = { fg = colors.darker,  bg = colors.darker },

        -- Rainbow delimiters
        RainbowDelimiterRed         = { fg = colors.red },
        RainbowDelimiterGreen       = { fg = colors.green },
        RainbowDelimiterBlue        = { fg = colors.blue },
        RainbowDelimiterYellow      = { fg = colors.yellow },
        RainbowDelimiterOrange      = { fg = colors.orange },
        RainbowDelimiterCyan        = { fg = colors.cyan },
        RainbowDelimiterViolet      = { fg = colors.blue },

        -- Git conflict (solid backgrounds)
        GitConflictCurrent          = { bg = mergeColors(colors.yellow, colors.base, 0.1) },
        GitConflictCurrentLabel     = { bg = colors.yellow, fg = colors.base },
        GitConflictIncoming         = { bg = mergeColors(colors.blue,   colors.base, 0.1) },
        GitConflictIncomingLabel    = { bg = colors.blue,   fg = colors.base },

        -- Render markdown (solid background)
        RenderMarkdownCode          = { bg = colors.darker },

        ScrollbarHandle             = { bg = subtle_shift(colors.base, 0.5) },
        ScrollbarGitHandle          = { bg = subtle_shift(colors.base, 0.5), fg = colors.cyan },
        ScrollbarHintHandle         = { bg = subtle_shift(colors.base, 0.5), fg = colors.green },
        ScrollbarInfoHandle         = { bg = subtle_shift(colors.base, 0.5), fg = colors.blue },
        ScrollbarMiscHandle         = { bg = subtle_shift(colors.base, 0.5), fg = colors.overlay },
        ScrollbarWarnHandle         = { bg = subtle_shift(colors.base, 0.5), fg = colors.orange },
        ScrollbarErrorHandle        = { bg = subtle_shift(colors.base, 0.5), fg = colors.red },
        ScrollbarCursorHandle       = { bg = subtle_shift(colors.base, 0.5), fg = colors.darker },
        ScrollbarGit                = { fg = colors.cyan },
        ScrollbarHint               = { fg = colors.green },
        ScrollbarInfo               = { fg = colors.blue },
        ScrollbarMisc               = { fg = colors.overlay },
        ScrollbarWarn               = { fg = colors.orange },
        ScrollbarError              = { fg = colors.red },
        ScrollbarCursor             = { fg = colors.darker },
    };
    
    for hl, col in pairs(ColorSets) do
        vim.api.nvim_set_hl(0, hl, col);
    end;
end

return M;
