local pluginName = "npm-scripts"

local DEFAULT_CONFIG = {
	auto_open_localhost = true, -- Automatically open localhost in the browser when starting the server
	package_manager = "npm", -- Package manager to use

	notify = {
		enabled = true, -- Enable notifications
		timeout = 2000, -- Notification timeout
		job_finished = true, -- Notify when the job finishes

		stdout = {
			notify_all = false, -- Notify all standard outputs
			keywords = { "ready", "READY", "Ready", "localhost", "Warning" }, -- Keywords to trigger notifications
			exclude = {}, -- Keywords to exclude from notifications when notify_all is true
		},

		stderr = {
			notify_all = true, -- Notify all standard errors
			keywords = {}, -- Keywords to trigger notifications
			exclude = { "Watchpack" }, -- Keywords to exclude from notifications when notify_all is true
		},
	},
}

return {
	DEFAULT_CONFIG = DEFAULT_CONFIG,
	pluginName = pluginName,
}
