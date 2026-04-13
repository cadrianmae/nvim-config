-- lua/speech_dispatcher.lua
-- TTS via speech-dispatcher (spd-say). Piper is the default backend.

local M = {}

local config = {
  rate = 0, -- spd-say -r, range -100 to +100
  pitch = 0, -- spd-say -p, range -100 to +100
}

-- Build and run spd-say command asynchronously
local function speak(text)
  if not text or vim.trim(text) == "" then return end
  local cmd = { "spd-say", "-r", tostring(config.rate), "-p", tostring(config.pitch), text }
  vim.fn.jobstart(cmd, { detach = true })
end

-- Cancel all queued speech
local function cancel() vim.fn.jobstart({ "spd-say", "--cancel" }, { detach = true }) end

-- Get the text of the current line
local function get_line() return vim.api.nvim_get_current_line() end

-- Get visual selection text (called after exiting visual mode so marks are set)
local function get_visual_selection()
  local s = vim.api.nvim_buf_get_mark(0, "<")
  local e = vim.api.nvim_buf_get_mark(0, ">")
  local lines = vim.api.nvim_buf_get_lines(0, s[1] - 1, e[1], false)
  if #lines == 0 then return "" end
  if #lines == 1 then
    lines[1] = lines[1]:sub(s[2] + 1, e[2] + 1)
  else
    lines[1] = lines[1]:sub(s[2] + 1)
    lines[#lines] = lines[#lines]:sub(1, e[2] + 1)
  end
  return table.concat(lines, " ")
end

function M.setup(opts)
  config = vim.tbl_deep_extend("force", config, opts or {})

  vim.api.nvim_create_user_command("SpeakLine", function() speak(get_line()) end, { desc = "Speak current line" })

  vim.api.nvim_create_user_command("SpeakStop", function() cancel() end, { desc = "Stop/cancel speech" })

  -- Normal mode: speak current line
  vim.keymap.set("n", "<leader>sl", function() speak(get_line()) end, { desc = "Speak line" })

  -- Normal mode: stop speech
  vim.keymap.set("n", "<leader>sq", function() cancel() end, { desc = "Stop speech" })

  -- Visual mode: speak selection
  -- Press Escape first to exit visual and set '< '> marks
  vim.keymap.set("x", "<leader>ss", function()
    vim.cmd "normal! \27"
    speak(get_visual_selection())
  end, { desc = "Speak selection" })
end

return M
