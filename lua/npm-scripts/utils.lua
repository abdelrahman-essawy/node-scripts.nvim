local config = require("npm-scripts.config").DEFAULT_CONFIG
local pluginName = require("npm-scripts.config").pluginName

local function strip_ansi_escape_codes(text)
	return text:gsub("\27%[[%d;]+m", "")
end

local function has_keywords(text, keywords)
	for _, word in ipairs(keywords) do
		if text:find(word) then
			return true
		end
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

local function is_empty(message, level)
	if message == nil or message == "" then
		return true
	end
	return false
end

local function notify(message, level)
	if not config.notify.enabled then
		return
	end
	local clean_message = strip_ansi_escape_codes(message)
	if is_empty(clean_message, level) then
		return
	end

	vim.notify(clean_message, level, {
		title = pluginName,
		timeout = config.notify_timeout,

		on_open = function(win)
			vim.schedule(function()
				local buf = vim.api.nvim_win_get_buf(win)
				vim.api.nvim_buf_set_option(buf, "filetype", "typescript")

				if config.auto_open_localhost and has_keywords(clean_message, { "localhost" }) then
					local url = extract_url_from_message(clean_message)
					if url then
						open_browser(url)
					end
				end
			end)
		end,
	})
end

return {
	notify = notify,
	has_keywords = has_keywords,
}
