return {
    'gisketch/triforce.nvim',
    cmd = "Triforce",
    dependencies = { 'nvzone/volt' },
    opts = {
        achievements = {},
        auto_save_interval = 300,
        backdrop = {
            enabled = true,
            winblend = 20
        },
        custom_languages = {},
        db_path = "/home/chilly/.local/share/nvim/triforce_stats.json",
        debug = false,
        enabled = true,
        gamification_enabled = true,
        heat_highlights = {
            TriforceHeat0 = "#f0f0f0",
            TriforceHeat1 = "#f0f0a0",
            TriforceHeat2 = "#f0a0a0",
            TriforceHeat3 = "#a0a0a0",
            TriforceHeat4 = "#707070"
        },
        icon_engine = "builtin",
        ignore_ft = {},
        keymap = {
            show_profile = ""
        },
        level_progression = {
            tier_1 = {
                max_level = 10,
                min_level = 1,
                xp_per_level = 500
            },
            tier_10 = {
                max_level = inf,
                min_level = 226,
                xp_per_level = 25000
            },
            tier_2 = {
                max_level = 20,
                min_level = 11,
                xp_per_level = 750
            },
            tier_3 = {
                max_level = 30,
                min_level = 21,
                xp_per_level = 1250
            },
            tier_4 = {
                max_level = 40,
                min_level = 31,
                xp_per_level = 2500
            },
            tier_5 = {
                max_level = 50,
                min_level = 41,
                xp_per_level = 3750
            },
            tier_6 = {
                max_level = 75,
                min_level = 51,
                xp_per_level = 5000
            },
            tier_7 = {
                max_level = 100,
                min_level = 76,
                xp_per_level = 10000
            },
            tier_8 = {
                max_level = 150,
                min_level = 101,
                xp_per_level = 12500
            },
            tier_9 = {
                max_level = 225,
                min_level = 151,
                xp_per_level = 15000
            }
        },
        levels = {},
        notifications = {
            achievements = true,
            enabled = true,
            level_up = true
        },
        override_levels = false,
        xp_rewards = {
            char = 1,
            line = 1,
            save = 10
        }
    },

}
