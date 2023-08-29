local telescope = require("telescope")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local sorters = require("telescope.sorters")
local action_state = require("telescope.actions.state")

local DEFAULT_CONFIG = require("npm-scripts.config").DEFAULT_CONFIG

local notify = require("npm-scripts.utils").notify
local is_custom_event = require("npm-scripts.utils").is_custom_event
local is_ready_event = require("npm-scripts.utils").is_ready_event
local is_error_event = require("npm-scripts.utils").is_error_event
local is_warn_event = require("npm-scripts.utils").is_warn_event
local has_localhost_keyword = require("npm-scripts.utils").has_localhost_keyword
local has_ignored_keyword = require("npm-scripts.utils").has_ignored_keyword

local M = {}

local config = {}

M.find_nearest_package_json = function(path)
	local function fileExists(filepath)
		local file = io.open(filepath, "r")
		if file then
			io.close(file)
			return true
		else
			return false
		end
	end

	local package_json_path = path .. "/package.json"
	if fileExists(package_json_path) then
		return package_json_path
	end

	local parent_path = path:match("^(.*[/\\])[^/\\]+$")
	if parent_path and parent_path ~= path then
		return M.find_nearest_package_json(parent_path)
	end

	local src_path = path .. "/src"
	if fileExists(src_path) then
		return M.find_nearest_package_json(src_path)
	end

	return nil
end

local function read_package_json_scripts(packageJsonPath)
	local file = io.open(packageJsonPath, "r")
	if file then
		local content = file:read("*a")
		io.close(file)

		local scripts = vim.json.decode(content)["scripts"]
		if scripts then
			return scripts
		end
	end

	return nil
end

M.execute_script = function(script)
	if script then
		local fullCommand = config.package_manager .. " run " .. script

		local job_id = vim.fn.jobstart(fullCommand, {

			on_exit = function(job_id, exit_code, event)
				if exit_code == 0 then
					notify("Script '" .. fullCommand .. "' finished successfully.", vim.log.levels.INFO)
				end
			end,

			on_stdout = function(job_id, data, event)
				local text = table.concat(data, "\n")

				if config.notify_all_events then
					notify(text, vim.log.levels.INFO)
				end

				if
						not has_ignored_keyword(text, config.ready_events.IGNORED)
						and config.ready_events.notify
						and is_ready_event(text)
						or has_localhost_keyword(text)
				then
					notify(text, vim.log.levels.INFO)
				end

				if
						not has_ignored_keyword(text, config.warn_events.IGNORED)
						and config.warn_events.notify
						and is_warn_event(text)
				then
					notify(text, vim.log.levels.WARN)
				end

				if
						not has_ignored_keyword(text, config.custom_events.IGNORED)
						and config.custom_events.notify
						and is_custom_event(text)
				then
					notify(text, vim.log.levels.INFO)
				end
			end,

			on_stderr = function(job_id, data, event)
				local text = table.concat(data, "\n")

				if config.notify_all_events then
					notify(text, vim.log.levels.ERROR)
				end

				if
						not has_ignored_keyword(text, config.error_events.IGNORED)
						and config.error_events.notify
						and is_error_event(text)
				then
					notify(text, vim.log.levels.ERROR)
				end

				if
						not has_ignored_keyword(text, config.custom_events.IGNORED)
						and config.custom_events.notify
						and is_custom_event(text)
				then
					notify(text, vim.log.levels.ERROR)
				end
			end,
		})
		notify("Executing script: " .. fullCommand, vim.log.levels.WARN)
	end
end

M.run = function()
	local nearest_package_json_path = M.find_nearest_package_json(vim.fn.getcwd())

	if nearest_package_json_path then
		local scripts = read_package_json_scripts(nearest_package_json_path)

		if scripts then
			local results = {}
			for script, _ in pairs(scripts) do
				table.insert(results, script)
			end

			pickers
					.new({
						prompt_title = "Scripts in package.json",
						finder = finders.new_table({
							results = results,
						}),
						sorter = sorters.get_generic_fuzzy_sorter(),
						attach_mappings = function(prompt_bufnr, map)
							actions.select_default:replace(function()
								actions.close(prompt_bufnr)
								local selection = action_state.get_selected_entry()
								M.execute_script(selection[1])
							end)
							return true
						end,
					})
					:find()
		else
			notify("No 'scripts' found in package.json.", vim.log.levels.WARN)
		end
	else
		notify("No package.json found in the current directory or its parent directories.", vim.log.levels.WARN)
	end
end

function M.setup(opts)
	config = vim.tbl_extend("force", config, DEFAULT_CONFIG, opts or {})
	vim.api.nvim_create_user_command("NS", M.run, { desc = "Run `ns` to show package.json scripts", force = true })
	vim.keymap.set("n", "<leader>ns", ":lua require('npm-scripts').run()<CR>", { silent = true, noremap = true })
end

return M
