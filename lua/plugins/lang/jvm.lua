-- JVM: Java, Kotlin and Gradle, for Minecraft mod work. One bundle rather than
-- two files because they arrive together and share the build tooling -- a
-- build.gradle.kts belongs to both.
-- On-demand: jdtls is one of the largest Mason packages, so it stays
-- uninstalled until a .java or .kt file is opened.
--
-- The java pack's `javadbg`/`javatest` adapters are absent from
-- mason-nvim-dap's filetype table, so they are attributed by hand.
require("lang_policy").on_demand("java", { "java-debug-adapter", "java-test" })

---@type LazySpec
return {
  { import = "astrocommunity.pack.java" },
  { import = "astrocommunity.pack.kotlin" },
}
