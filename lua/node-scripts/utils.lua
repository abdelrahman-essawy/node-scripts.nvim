local config = require("node-scripts.config").DEFAULT_CONFIG
local pluginName = require("node-scripts.config").pluginName

local function strip_ansi_escape_codes(text)
  return text:gsub("\27%[[%d;]+m", "")
end

local function has_localhost_keyword(text)
  if text:find("localhost") then
    return true
  end
  return false
end

local function open_browser(url)
  local os_name = vim.loop.os_uname().sysname

  if os_name == "Linux" then
    -- On Linux, use xdg-open to open the browser
    os.execute("xdg-open " .. url)
  elseif os_name == "Darwin" then
    -- On macOS, use the 'open' command to open the browser
    os.execute("open " .. url)
  elseif os_name == "Windows" then
    os.execute("start " .. url)
  else
    print("Unsupported operating system: " .. os_name)
  end
end

local function extract_url_from_message(message)
  local pattern = "http[s]?://%S+"
  local url = message:match(pattern)
  return url
end

local function notify(message, level)
  local clean_message = strip_ansi_escape_codes(message)

  vim.notify(clean_message, level, {
    title = pluginName,
    timeout = config.notify_timeout,

    on_open = function(win)
      vim.schedule(function()
        local buf = vim.api.nvim_win_get_buf(win)
        vim.api.nvim_buf_set_option(buf, "filetype", "typescript")

        if config.auto_open_localhost and has_localhost_keyword(clean_message) then
          local url = extract_url_from_message(clean_message)
          if url then
            open_browser(url)
          end
        end
      end)
    end,
  })
end

local function is_custom_event(text)
  local POSSIBLE_WORDS = config.custom_events.LOOK_FOR
  for _, word in ipairs(POSSIBLE_WORDS) do
    if text:find(word) then
      return true
    end
  end
  return false
end

local function is_ready_event(text)
  local POSSIBLE_WORDS = config.ready_events.LOOK_FOR
  for _, word in ipairs(POSSIBLE_WORDS) do
    if text:find(word) then
      return true
    end
  end
  return false
end

local function is_error_event(text)
  local POSSIBLE_WORDS = config.error_events.LOOK_FOR
  for _, word in ipairs(POSSIBLE_WORDS) do
    if text:find(word) then
      return true
    end
  end
  return false
end

local function is_warn_event(text)
  local POSSIBLE_WORDS = config.warn_events.LOOK_FOR
  for _, word in ipairs(POSSIBLE_WORDS) do
    if text:find(word) then
      return true
    end
  end
  return false
end

local function has_ignored_keyword(text, ignored_keywords)
  for _, word in ipairs(ignored_keywords) do
    if text:find(word) then
      return true
    end
  end
  return false
end

return {
  notify = notify,
  is_custom_event = is_custom_event,
  is_ready_event = is_ready_event,
  is_error_event = is_error_event,
  is_warn_event = is_warn_event,
  has_localhost_keyword = has_localhost_keyword,
  has_ignored_keyword = has_ignored_keyword,
}
