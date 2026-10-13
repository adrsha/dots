local notes_dir = vim.fn.expand("~/Notes")

local function notes_telescope_opts()
    return {
        cwd = notes_dir,
        hidden = true,
        follow = true,
    }
end

local function note_title(path)
    local name = vim.fn.fnamemodify(path, ":t:r")
    return name:gsub("%s+", "_")
end

local function build_graph()
    local files = vim.fn.globpath(notes_dir, "**/*.md", false, true)
    local edges = {}

    for _, file in ipairs(files) do
        local source = note_title(file)
        local lines = vim.fn.readfile(file)

        for _, line in ipairs(lines) do
            for target in line:gmatch("%[%[([^%]]+)%]%]") do
                target = target:gsub("|.*$", "")
                target = target:gsub("#.*$", "")
                target = target:gsub("%s+", "_")

                if target ~= "" then
                    table.insert(edges, string.format("    %s --> %s", source, target))
                end
            end
        end
    end

    local graph = { "# Notes Graph", "", "```mermaid", "graph TD" }
    vim.list_extend(graph, edges)

    if #edges == 0 then
        table.insert(graph, "    index --> Add_wiki_links")
    end

    vim.list_extend(graph, { "```", "" })

    vim.cmd("tabnew")
    vim.api.nvim_buf_set_name(0, "Notes Graph")
    vim.bo.buftype = "nofile"
    vim.bo.bufhidden = "wipe"
    vim.bo.swapfile = false
    vim.bo.filetype = "markdown"
    vim.api.nvim_buf_set_lines(0, 0, -1, false, graph)
end

local function open_notes_index()
    vim.cmd.edit(vim.fn.fnameescape(notes_dir .. "/index.md"))
end

return {
    {
        "obsidian-nvim/obsidian.nvim",
        version = "*",
        ft = "markdown",
        dependencies = {
            "nvim-lua/plenary.nvim",
            "nvim-telescope/telescope.nvim",
        },
        opts = {
            workspaces = {
                {
                    name = "notes",
                    path = notes_dir,
                },
            },
            notes_subdir = "scratch",
            new_notes_location = "notes_subdir",
            daily_notes = {
                folder = "scratch/daily",
                date_format = "%Y-%m-%d",
                alias_format = "%B %-d, %Y",
                template = nil,
            },
            templates = {
                folder = "09_resources/templates",
                date_format = "%Y-%m-%d",
                time_format = "%H:%M",
            },
            completion = {
                min_chars = 2,
            },
            picker = {
                name = "telescope.nvim",
            },
            legacy_commands = false,
            open = {
                func = vim.ui.open,
            },
            ui = {
                enable = true,
            },
        },
        keys = {
            -- NOTE: "no" and "ni" both call open_notes_index() — likely an
            -- unintentional duplicate. Left both mapped below so nothing
            -- breaks, but consider freeing one of these up (e.g. "ni" for
            -- something else, since "no" reads naturally as "notes open").
            { "<leader>no", open_notes_index, desc = "Notes: open index" },
            { "<leader>ni", open_notes_index, desc = "Notes: open index (dup of <leader>no)" },

            { "<leader>nn", "<cmd>Obsidian new<cr>", desc = "Notes: create new note" },
            { "<leader>nt", "<cmd>Obsidian today<cr>", desc = "Notes: open today's daily note" },
            { "<leader>nr", "<cmd>Obsidian rename<cr>", desc = "Notes: rename current note (updates links)" },
            { "<leader>np", "<cmd>Obsidian paste_img<cr>", desc = "Notes: paste image into note" },

            { "<leader>ns", "<cmd>Obsidian search<cr>", desc = "Notes: search note contents" },
            { "<leader>nq", "<cmd>Obsidian quick_switch<cr>", desc = "Notes: quick switch note" },
            { "<leader>nb", "<cmd>Obsidian backlinks<cr>", desc = "Notes: show backlinks to current note" },
            { "<leader>nl", "<cmd>Obsidian links<cr>", desc = "Notes: show outgoing links in current note" },
            { "<leader>nf", "<cmd>Obsidian follow_link<cr>", desc = "Notes: follow [[link]] under cursor" },

            { "<leader>ng", build_graph, desc = "Notes: render wiki-link graph (mermaid, new tab)" },

            {
                "<leader>nF",
                function()
                    require("telescope.builtin").find_files(notes_telescope_opts())
                end,
                desc = "Notes: find files (Telescope, scoped to notes dir)",
            },
            {
                "<leader>nG",
                function()
                    require("telescope.builtin").live_grep(notes_telescope_opts())
                end,
                desc = "Notes: live grep (Telescope, scoped to notes dir)",
            },
            {
                "<leader>nT",
                function()
                    require("telescope.builtin").grep_string({
                        cwd = notes_dir,
                        search = "#%w+",
                        use_regex = true,
                    })
                end,
                desc = "Notes: list #tags across notes",
            },
            {
                "<leader>nx",
                function()
                    require("telescope.builtin").grep_string({
                        cwd = notes_dir,
                        search = "- %[[ xX]%]",
                        use_regex = true,
                    })
                end,
                desc = "Notes: list completed tasks (- [x])",
            },
            {
                "<leader>nX",
                function()
                    require("telescope.builtin").grep_string({
                        cwd = notes_dir,
                        search = "- %[ %]",
                        use_regex = true,
                    })
                end,
                desc = "Notes: list open tasks (- [ ])",
            },
        },
    },
}
