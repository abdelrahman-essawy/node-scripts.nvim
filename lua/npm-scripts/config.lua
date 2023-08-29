local pluginName = "npm-scripts"

local DEFAULT_CONFIG = {
  ready_events = {
    notify = true,
    LOOK_FOR = { "ready", "READY", "Ready" },
    IGNORED = { "" },
  },
  warn_events = {
    notify = false, -- usefull for linting warnings
    LOOK_FOR = { "warn", "warning", "WARN", "WARNING", "Warn", "Warning" },
    IGNORED = { "" },
  },
  error_events = {
    notify = true,
    LOOK_FOR = { "error", "ERROR", "Error" },
    IGNORED = { "" }, -- ex: ignore "Watchpack" errors
  },
  custom_events = {
    notify = false,
    LOOK_FOR = { "whatever", "words", "you", "looking", "for" },
    IGNORED = { "" },
  },
  notify_all_events = false,
  notify_timeout = 2000,
  package_manager = "npm",
  auto_open_localhost = true,
}

return {
  DEFAULT_CONFIG = DEFAULT_CONFIG,
  pluginName = pluginName,
}
