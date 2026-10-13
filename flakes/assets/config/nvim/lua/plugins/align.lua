return {
    "Vonr/align.nvim",
    init = function()
        -- Aligns to 1 character
        vim.keymap.set(
            'x',
            'aa',
            function()
                require 'align'.align_to_char({
                    -- preview = true,
                    length = 1,
                })
            end,
            NS
        )

        -- Aligns to a string with previews
        vim.keymap.set(
            'x',
            '<A-=>',
            function()
                require 'align'.align_to_string({
                    preview = true,
                    regex = false,
                })
            end,
            NS
        )

        -- Aligns to a Vim regex with previews
        vim.keymap.set(
            'x',
            'ar',
            function()
                require 'align'.align_to_string({
                    preview = true,
                    regex = true,
                })
            end,
            NS
        )
    end
}
