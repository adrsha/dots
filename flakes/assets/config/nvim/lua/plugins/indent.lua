
return {
    url = 'https://github.com/nvimdev/indentmini.nvim',
    cmd = { 'IndentToggle', 'IndentEnable', 'IndentDisable' },
    -- keys = {
    --     { '<leader>tim', '<Cmd>IndentToggle<CR>', desc = 'Toggle indent guides' },
    -- },
    event = { 'BufReadPost' },
    config = function()
        require("indentmini").setup({
            only_current = false,
            enabled = true,
            char = '┃', -- ┃
            -- key = '<leader>tim', -- optional, can be set here if you don't lazy-load
            minlevel = 2,
            exclude = { 'markdown', 'help', 'text', 'rst' },
            exclude_nodetype = { 'string', 'comment' }
        })
    end
}
