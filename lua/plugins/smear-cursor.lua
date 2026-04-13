-- Purple flame cursor — catppuccin mauve trail, near-white core
-- https://github.com/sphamba/smear-cursor.nvim
return {
  "sphamba/smear-cursor.nvim",
  event = "VeryLazy",
  opts = {
    -- Smear behaviour
    smear_between_buffers = true,
    smear_between_neighbor_lines = true,
    smear_insert_mode = true,

    -- Physics — loose and flowy
    stiffness = 0.5,
    trailing_stiffness = 0.1,
    trailing_exponent = 5,
    damping = 0.6,
    gradient_exponent = 0,
    gamma = 1,
    never_draw_over_target = true,
    hide_target_hack = true,

    -- Fire particles (perf-tuned)
    particles_enabled = true,
    particle_max_num = 50,
    particle_spread = 1,
    particles_per_second = 150,
    particles_per_length = 25,
    particle_max_lifetime = 500,
    particle_max_initial_velocity = 20,
    particle_velocity_from_cursor = 0.5,
    particle_damping = 0.1,
    particle_gravity = -100,
    min_distance_emit_particles = 0.01,
    -- max_kept_windows = 30,

    -- Catppuccin mauve trail
    cursor_color = "#cba6f7",
  },
  config = function(_, opts)
    require("smear_cursor").setup(opts)

    -- Near-white cursor core
    -- vim.api.nvim_set_hl(0, "Cursor", { fg = "#1e1e2e", bg = "#cdd6f4" })
  end,
}
