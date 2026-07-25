-- Docker: dockerls and hadolint for Dockerfile and Containerfile.
-- On-demand: nothing installs until a Dockerfile is opened.
--
-- hadolint is a none-ls source, but no pack declares it here, so it is
-- attributed to the filetype directly.
require("lang_policy").on_demand("dockerfile", { "hadolint" })

---@type LazySpec
return {
  {
    "AstroNvim/astrolsp",
    ---@type AstroLSPOpts
    opts = {
      servers = { "dockerls" },
    },
  },
}
