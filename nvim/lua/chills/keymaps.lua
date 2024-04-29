local opts = { noremap = true, silent = true }
local keymap = vim.keymap -- for conciseness
vim.g.mapleader = " "


-- NVIM MODIFICATIONS
-- Move current line / block with Alt-j/k ala vscode.
keymap.set("i", "<A-j>", "<Esc>:m .+1<CR>==gi")
keymap.set("i", "<A-k>", "<Esc>:m .-2<CR>==gi")
keymap.set("c", "<C-w>", ":w !sudo tee % > /dev/null<CR>")

-- Move current line / block with Alt-j/k ala vscode.

-- keymap.set("n", "<C-h>", "<C-w>h")
-- keymap.set("n", "<C-j>", "<C-w>j")
-- keymap.set("n", "<C-k>", "<C-w>k")
-- keymap.set("n", "<C-l>", "<C-w>l")

-- Resize with arrows
keymap.set("n", "<C-Up>", ":resize -2<CR>")
keymap.set("n", "<C-Down>", ":resize +2<CR>")
keymap.set("n", "<C-Left>", ":vertical resize -2<CR>")
keymap.set("n", "<C-Right>", ":vertical resize +2<CR>")

-- Move current line / block with Alt-j/k a la vscode.
keymap.set("n", "<A-j>", ":m .+1<CR>==")
keymap.set("n", "<A-k>", ":m .-2<CR>==")
keymap.set("n", "<A-Up>", "<C-\\><C-N><C-w>k")
keymap.set("x", "<A-j>", ":m '>+1<CR>gv-gv")
keymap.set("x", "<A-k>", ":m '<-2<CR>gv-gv")

-- Find all instances of the word
keymap.set("n", "<C-n>", "*")
-- Find next bracket
keymap.set("n", "<leader>n", "%")

-- Tabs dont unselect the selection
keymap.set("v", "<A-h>", "<gv")
keymap.set("v", "<A-l>", ">gv")
keymap.set("n", "<A-l>", ">>")
keymap.set("n", "<A-h>", "<<")

-- keymap.set("n", "<", "<<")
-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

--Buffers
keymap.set("n", "<leader>bd", "<CMD>bdelete<CR>")

-- Comments
-- In /setups/comments.nvim

-- HighlightColor
-- Use :HighlightColorToggle/HighlightColorOn/HighlightColorOff on the cmd itself

--Replace
keymap.set("n", "<C-s>", ":%s/")
keymap.set("i", "<C-s>", "<Esc>:%s/")


-- Buffer
keymap.set("n", "<Tab>", "<CMD>bnext<CR>")
keymap.set("n", "<S-Tab>", "<CMD>bprev<CR>")

-- BetterEscape
-- In /setups/betterescape.lua

-- Surround.nvim
-- Using the defaults
--
--FTERM
opts.desc = "Fterm"
keymap.set('n', '<A-i>', '<CMD>lua require("FTerm").toggle()<CR>')
keymap.set('t', '<A-i>', '<C-\\><C-n><CMD>lua require("FTerm").toggle()<CR>')

-- LuaSnip
opts.desc = "LuaSnip"
keymap.set("i", "<c-j>", "<cmd>lua require'luasnip'.jump(1)<CR>", opts)
keymap.set("s", "<c-j>", "<cmd>lua require'luasnip'.jump(1)<CR>", opts)
keymap.set("i", "<c-k>", "<cmd>lua require'luasnip'.jump(-1)<CR>", opts)
keymap.set("s", "<c-k>", "<cmd>lua require'luasnip'.jump(-1)<CR>", opts)
-- keymap.set("i", "<c-f>", "i<Esc>==<S-a><BS>", opts)
-- keymap.set("i", "<c-f>", "<Esc>ddkA<CR>", opts)
--
--Telescope
keymap.set("n", "<leader>fr", "<CMD>Telescope oldfiles<CR>")
keymap.set("n", "<leader>lg", "<CMD>Telescope live_grep<CR>")
keymap.set("n", "<leader>ss", "<CMD>Telescope spell_suggest<CR>")
keymap.set("n", "<leader>bb", "<CMD>Telescope builtin<CR>")
keymap.set("n", "<leader>ff", "<CMD>Telescope fd<CR>")
-- Insitu Telescope shortcuts are in Telescope.lua
