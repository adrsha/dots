local opt = vim.opt
local g = vim.g

opt.hidden = true
opt.pumheight = 18
opt.cmdheight = 0
opt.splitbelow = true
opt.splitright = true
opt.fixendofline = true
opt.endofline = true

opt.list = true
opt.listchars = {
    space = "·",     -- middle dot for spaces
    tab = "→ ",      -- arrow for tab followed by a space
    trail = "•",     -- dot for trailing spaces
    extends = "⟩",   -- when line is too long
    precedes = "⟨",  -- when line continues to the left
    nbsp = "␣"       -- non-breaking space
}
opt.termguicolors = true
opt.conceallevel = 2
opt.showtabline = 0

opt.showmode = false
opt.backup = false
opt.writebackup = false
opt.number = true

opt.ruler = false
opt.updatetime = 250
opt.timeoutlen = 500
opt.clipboard = "unnamedplus"
opt.hlsearch = true
opt.ignorecase = true
opt.smartcase = true
opt.scrolloff = 0
opt.mouse = "a"
opt.cursorline = true

opt.tabstop = 4
opt.softtabstop = 4
opt.shiftwidth = 4
opt.autoread = true
-- opt.autoindent = false
opt.smartindent = false

opt.wrap = false
opt.expandtab = true
opt.laststatus = 0
opt.fillchars = { eob = "⠀" }

opt.undofile = true
opt.swapfile = false

opt.shortmess:append("sIcaWFSA")

opt.signcolumn = "yes"
opt.numberwidth = 3
opt.whichwrap:append("<,>,[,],h,l")

opt.sessionoptions = "blank,buffers,curdir,folds,help,tabpages,winsize,winpos,terminal,localoptions"
opt.formatoptions:remove({ "c", "r", "o" }) -- don't insert the current comment leader automatically for auto-wrapping comments using 'textwidth', hitting <Enter> in insert mode, or hitting 'o' or 'O' in normal mode.
-- disable some default providers
g.loaded_node_provider = 0
g.loaded_python3_provider = 0
g.loaded_perl_provider = 0
g.loaded_ruby_provider = 0
g.editorconfig = true

-- g.neovide_opacity = 0.4
-- g.transparency = 0.9

g.neovide_padding_top = 10
g.neovide_padding_bottom = 10
g.neovide_padding_right = 30
g.neovide_padding_left = 30
g.neovide_window_blurred = true

g.neovide_floating_blur_amount_x = 10.0
g.neovide_floating_blur_amount_y = 10.0
g.neovide_floating_corner_radius = 0.3
g.neovide_floating_shadow = false
g.neovide_light_angle_degrees = 45
g.neovide_light_radius = 5
g.neovide_floating_z_height = 50
g.neovide_cursor_vfx_mode = ""

g.instant_username = "adrsha"
opt.guifont = "Dank Mono:h16" -- text below applies for VimScript

-- add binaries installed by mason.nvim to path
local is_windows = vim.fn.has("win32") ~= 0
local sep = is_windows and "\\" or "/"
local delim = is_windows and ";" or ":"
vim.env.PATH = table.concat({ vim.fn.stdpath("data"), "mason", "bin" }, sep) .. delim .. vim.env.PATH
