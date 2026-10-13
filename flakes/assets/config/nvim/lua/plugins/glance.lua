return {
    'dnlhc/glance.nvim',
    cmd = 'Glance',
    opts = {
        theme = {
            enable = true, -- Generate colors based on current colorscheme
            mode = 'auto', -- 'brighten'|'darken'|'auto', 'auto' will set mode based on the brightness of your colorscheme
        },
        list = {
            position = 'left', -- Position of the list window 'left'|'right'
            width = 0.33,       -- Width as percentage (0.1 to 0.5)
        },
        border = {
            enable = false, -- Show window borders. Only horizontal borders allowed
            top_char = '―',
            bottom_char = '―',
        },
    }
}
