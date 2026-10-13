local map = vim.keymap.set -- for conciseness

--------------------------------------------------------------------------------
-- WHICH-KEY GROUP LABELS
-- Registers friendly names for leader prefixes so <leader> popup shows
-- groups instead of raw command names. Requires which-key.nvim.
--------------------------------------------------------------------------------
local ok_wk, wk = pcall(require, "which-key")
if ok_wk then
    local groups = {
        b = "Buffer",
        c = "Code / LSP",
        f = "Find (Telescope / Oil)",
        j = "Split / Join",
        l = "Live Grep",
        n = "Notes (Obsidian)",
        r = "Rust",
        s = "Search / Status",
        t = "Toggle / Todo / Diagnostics",
        w = "WhichKey / Workspace",
    }

    if wk.add then
        -- which-key v3+
        local specs = {}
        for key, name in pairs(groups) do
            table.insert(specs, { "<leader>" .. key, group = name })
        end
        wk.add(specs)
    elseif wk.register then
        -- which-key v2 (legacy "register" API)
        local legacy = {}
        for key, name in pairs(groups) do
            legacy[key] = { name = name }
        end
        wk.register(legacy, { prefix = "<leader>" })
    else
        vim.notify("which-key: no add()/register() API found, group labels not set", vim.log.levels.WARN)
    end
end

--------------------------------------------------------------------------------
-- FILE / BUFFER MANAGEMENT
--------------------------------------------------------------------------------
map("c", "<C-w>", ":w !sudo tee % > /dev/null<CR>", { desc = "File: save with sudo (command mode)" })
map("n", "<C-y>", "<cmd>%y+<CR>", { desc = "File: yank whole file to clipboard" })

map("n", "<leader>bd", "<CMD>bdelete<CR>", { desc = "Buffer: close current" })
map("n", "<Tab>", "<CMD>bnext<CR>", { desc = "Buffer: next" })
map("n", "<S-Tab>", "<CMD>bprev<CR>", { desc = "Buffer: previous" })

--------------------------------------------------------------------------------
-- WINDOW MANAGEMENT (resize + navigate)
--------------------------------------------------------------------------------
map("n", "<C-Up>", ":resize -2<CR>", { desc = "Window: shrink height" })
map("n", "<C-Down>", ":resize +2<CR>", { desc = "Window: grow height" })
map("n", "<C-Left>", ":vertical resize -2<CR>", { desc = "Window: shrink width" })
map("n", "<C-Right>", ":vertical resize +2<CR>", { desc = "Window: grow width" })

map("n", "<A-Up>", "<C-\\><C-N><C-w>k", { desc = "Window: switch above" })
map("n", "<A-Down>", "<C-\\><C-N><C-w>j", { desc = "Window: switch below" })
map("n", "<A-Left>", "<C-\\><C-N><C-w>h", { desc = "Window: switch left" })
map("n", "<A-Right>", "<C-\\><C-N><C-w>l", { desc = "Window: switch right" })

--------------------------------------------------------------------------------
-- LINE / SELECTION MOVEMENT
--------------------------------------------------------------------------------
map("i", "<A-j>", "<Esc>:m .+1<CR>==gi", { desc = "Line: move down (insert)" })
map("i", "<A-k>", "<Esc>:m .-2<CR>==gi", { desc = "Line: move up (insert)" })
map("n", "<A-j>", ":m .+1<CR>==", { desc = "Line: move down (normal)" })
map("n", "<A-k>", ":m .-2<CR>==", { desc = "Line: move up (normal)" })
map("x", "<A-j>", ":m '>+1<CR>gv-gv", { desc = "Selection: move down (visual)" })
map("x", "<A-k>", ":m '<-2<CR>gv-gv", { desc = "Selection: move up (visual)" })

--------------------------------------------------------------------------------
-- INDENTATION (repeatable, keeps visual selection)
--------------------------------------------------------------------------------
map("n", "<", "<<", { desc = "Indent: shift line left" })
map("n", ">", ">>", { desc = "Indent: shift line right" })
map("v", "<", "<gv", { desc = "Indent: shift selection left (reselect)" })
map("v", ">", ">gv", { desc = "Indent: shift selection right (reselect)" })

--------------------------------------------------------------------------------
-- SEARCH / SEARCH-AND-REPLACE
--------------------------------------------------------------------------------
map("n", "<C-n>", "*", { desc = "Search: find all instances of word under cursor" })
map("v", "<C-n>", "*<Esc><s-n>", { desc = "Search: find all instances of selection" })
map("n", "<S-l>", ":noh<CR>", { desc = "Search: clear highlight" })

map("n", "<C-s>", ":%s/", { desc = "Search: substitute across file" })
map("i", "<C-s>", "<Esc>:%s/", { desc = "Search: substitute across file (from insert)" })

--------------------------------------------------------------------------------
-- TELESCOPE / OIL (finders & pickers)
--------------------------------------------------------------------------------
map("n", "<leader><leader>", "<CMD>Telescope<CR>", { desc = "Find: Telescope main menu" })
map("n", "<leader>ff", function() require("oil").open_float() end, { desc = "Find: files (Oil float)" })
map("n", "<leader>fr", "<CMD>Telescope oldfiles<CR>", { desc = "Find: recent files" })
map("n", "<leader>fa", "<cmd>Telescope find_files follow=true no_ignore=true hidden=true<CR>",
    { desc = "Find: all files (incl. hidden/ignored)" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<CR>", { desc = "Find: help tags" })
map("n", "<leader>lg", "<CMD>Telescope live_grep<CR>", { desc = "Find: live grep" })
map("n", "<leader>cm", "<cmd>Telescope git_commits<CR>", { desc = "Git: commits (Telescope)" })
map("n", "<leader>st", "<cmd>Telescope git_status<CR>", { desc = "Git: status (Telescope)" })

map("n", "<leader>td", function()
    local builtin = require("telescope.builtin")
    local themes = require("telescope.themes")
    builtin.diagnostics(themes.get_ivy())
end, { desc = "Toggle/Todo: diagnostics list (Telescope)" })
map("n", "<leader>tt", "<CMD>TodoTelescope<CR>", { desc = "Toggle/Todo: TODO comments list" })

--------------------------------------------------------------------------------
-- LSP: NAVIGATION (Glance)
--------------------------------------------------------------------------------
map("n", "gd", "<CMD>Glance definitions<CR>", { desc = "LSP: go to definitions (Glance)" })
map("n", "gr", "<CMD>Glance references<CR>", { desc = "LSP: show references (Glance)" })
map("n", "gD", "<CMD>Glance type_definitions<CR>", { desc = "LSP: go to type definitions (Glance)" })
map("n", "gi", "<CMD>Glance implementations<CR>", { desc = "LSP: go to implementations (Glance)" })

--------------------------------------------------------------------------------
-- LSP: CODE ACTIONS / FORMATTING / RENAME
--------------------------------------------------------------------------------
map("n", "<leader>ca", function()
    require("tiny-code-action").code_action()
end, { noremap = true, silent = true, desc = "Code: run code action" })

map("n", "<leader>cF", function()
    require("conform").format({ lsp_fallback = false })
end, { desc = "Code: format file" })

map("n", "<leader>cr", function()
    require("nvchad.lsp.renamer")
end, { desc = "Code: rename symbol" })

map("n", "<S-k>", function()
    require("pretty_hover").hover()
end, { desc = "Code: pretty hover docs" })

map("n", "<leader>tih", function()
    vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
end, { desc = "Toggle: inlay hints" })

--------------------------------------------------------------------------------
-- LSP: WORKSPACE / WHICHKEY HELP
--------------------------------------------------------------------------------
map("n", "<leader>wl", function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
end, { desc = "Workspace: list folders" })

map("n", "<leader>wK", "<cmd>WhichKey <CR>", { desc = "WhichKey: show all keymaps" })
map("n", "<leader>wk", function()
    vim.cmd("WhichKey " .. vim.fn.input("WhichKey: "))
end, { desc = "WhichKey: query lookup" })

--------------------------------------------------------------------------------
-- RUST (rust-tools / rustaceanvim)
--------------------------------------------------------------------------------
map("n", "<leader>re", function()
    vim.cmd.RustLsp({ "explainError", "current" })
end, { desc = "Rust: explain current error" })

map("n", "<leader>rj", function()
    vim.cmd.RustLsp("joinLines")
end, { desc = "Rust: join lines" })

map("n", "<leader>rrd", function()
    vim.cmd.RustLsp("relatedDiagnostics")
end, { desc = "Rust: related diagnostics" })

--------------------------------------------------------------------------------
-- GIT (gitsigns)
--------------------------------------------------------------------------------
map("n", "g<space>", function()
    require("gitsigns").preview_hunk_inline()
end, { desc = "Git: preview hunk inline" })

map("n", "g<S-space>", function()
    require("gitsigns").reset_hunk()
end, { desc = "Git: reset hunk" })

--------------------------------------------------------------------------------
-- TERMINAL
--------------------------------------------------------------------------------
map({ "n", "t" }, "<A-i>", function()
    require("nvchad.term").toggle({ pos = "float", id = "floatTerm" })
end, { desc = "Terminal: toggle floating" })

--------------------------------------------------------------------------------
-- SPLIT / JOIN
--------------------------------------------------------------------------------
map("n", "<leader>j", function()
    require("mini.splitjoin").toggle()
end, { desc = "Split/Join: toggle argument/line join" })

--------------------------------------------------------------------------------
-- TREESITTER MOTION (treewalker) — move & swap by syntax node
--------------------------------------------------------------------------------
map("n", "<C-k>", function() require("treewalker").move_up() end, { desc = "Treewalker: move up" })
map("n", "<C-j>", function() require("treewalker").move_down() end, { desc = "Treewalker: move down" })
map("n", "<C-l>", function() require("treewalker").move_in() end, { desc = "Treewalker: move in (right)" })
map("n", "<C-h>", function() require("treewalker").move_out() end, { desc = "Treewalker: move out (left)" })

map("n", "<C-A-k>", function() require("treewalker").swap_up() end, { desc = "Treewalker: swap node up" })
map("n", "<C-A-j>", function() require("treewalker").swap_down() end, { desc = "Treewalker: swap node down" })
map("n", "<C-A-l>", function() require("treewalker").swap_in() end, { desc = "Treewalker: swap node right" })
map("n", "<C-A-h>", function() require("treewalker").swap_out() end, { desc = "Treewalker: swap node left" })

--------------------------------------------------------------------------------
-- DISABLED / COMMENTED OUT (kept for reference)
--------------------------------------------------------------------------------
-- map("v", "<s-i>", "<Esc>", { desc = "Escape from visual mode" })
-- map("n", "o", "o<Esc>^Da", { desc = "Next line without commenting" })
-- map("n", "O", "O<Esc>^Da", { desc = "Next line without commenting" })
-- map("n", "gD", vim.lsp.buf.declaration, { desc = "Go to declaration" })
-- map("n", "gd", vim.lsp.buf.definition, { desc = "Go to definition" })
-- map("n", "gi", vim.lsp.buf.implementation, { desc = "Go to implementation" })
-- map("n", "gtd", vim.lsp.buf.type_definition, { desc = "Go to type definition" })
-- map("n", "<leader>sh", vim.lsp.buf.signature_help, { desc = "Show signature help" })
-- map("n", "<leader>wa", vim.lsp.buf.add_workspace_folder, { desc = "Add workspace folder" })
-- map("n", "<leader>wr", vim.lsp.buf.remove_workspace_folder, { desc = "Remove workspace folder" })
-- map("n", "gr", vim.lsp.buf.references, { desc = "Show references" })
-- map('n', 'gco', '<Plug>(git-conflict-ours)')
-- map('n', 'gct', '<Plug>(git-conflict-theirs)')
-- map('n', 'gcb', '<Plug>(git-conflict-both)')
-- map('n', 'gc0', '<Plug>(git-conflict-none)')
-- map('n', 'gcn', '<Plug>(git-conflict-prev-conflict)')
-- map('n', 'gcp', '<Plug>(git-conflict-next-conflict)')
-- map("n", "<leader>ff", "<CMD>Telescope find_files<CR>", { desc = "Find files" })
-- vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
