-- This will run last in the setup process and is a good place to configure
-- things like custom filetypes. This is just pure lua so anything that doesn't
-- fit in the normal config locations above can go here

-- Force Unix line endings (LF) for all files
vim.opt.fileformat = "unix"
vim.opt.fileformats = "unix,dos" -- Prefer Unix, but can read DOS

-- Set up custom filetypes
vim.filetype.add {
  extension = {
    foo = "fooscript",
  },
  filename = {
    ["Foofile"] = "fooscript",
  },
  pattern = {
    ["~/%.config/foo/.*"] = "fooscript",
  },
}

-- Speech dispatcher TTS
require("speech_dispatcher").setup {
  rate = 0, -- adjust -100 to +100
  pitch = 0,
}

-- Remove leftover toggleterm mappings on <Leader>t* (Tabs group owns that prefix now)
vim.api.nvim_create_autocmd("User", {
  pattern = "VeryLazy",
  callback = function()
    for _, lhs in ipairs { "<Leader>tv", "<Leader>tu", "<Leader>tt" } do
      pcall(vim.keymap.del, "n", lhs)
    end
  end,
})
