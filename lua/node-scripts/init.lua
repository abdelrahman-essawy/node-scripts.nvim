local telescope = require("telescope")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local sorters = require("telescope.sorters")
local action_state = require("telescope.actions.state")

local pluginName = "node-scripts"

-- local function start_with_word(text, word)
-- 	local startIndex = string.find(text, word)
-- 	if startIndex == 1 then
-- 		return true
-- 	end
-- 	return false
-- end

local notify_warn_events = false
local notify_error_events = true
local notify_ready_events = true
local notify_all_events = false

local function notify(message, level)
	vim.notify(message, level, {
		title = pluginName,
	})
end

local function is_ready_event(text)
	local POSSIBLE_WORDS = { "ready", "READY", "Ready" }
	for _, word in ipairs(POSSIBLE_WORDS) do
		if text:find(word) then
			return true
		end
	end
	return false
end

local function is_error_event(text)
	local POSSIBLE_WORDS = { "error", "ERROR", "Error" }
	for _, word in ipairs(POSSIBLE_WORDS) do
		if text:find(word) then
			return true
		end
	end
	return false
end

local function is_warn_event(text)
	local POSSIBLE_WORDS = { "warn", "warning", "WARN", "WARNING", "Warn", "Warning" }
	for _, word in ipairs(POSSIBLE_WORDS) do
		if text:find(word) then
			return true
		end
	end
	return false
end

local function findNearestPackageJson(path)
	local function fileExists(filepath)
		local file = io.open(filepath, "r")
		if file then
			io.close(file)
			return true
		else
			return false
		end
	end

	local packageJsonPath = path .. "/package.json"
	if fileExists(packageJsonPath) then
		return packageJsonPath
	end

	local parentPath = path:match("^(.*[/\\])[^/\\]+$")
	if parentPath and parentPath ~= path then
		return findNearestPackageJson(parentPath)
	end

	local srcPath = path .. "/src"
	if fileExists(srcPath) then
		return findNearestPackageJson(srcPath)
	end

	return nil
end

local function choosenPackageManager()
	return "npm"
end

local function readPackageJsonScripts(packageJsonPath)
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

local function runScript(script)
	if script then
		local fullCommand = choosenPackageManager() .. " run " .. script
		local job_id = vim.fn.jobstart(fullCommand, {

			on_exit = function(job_id, exit_code, event)
				if exit_code == 0 then
					notify("Script '" .. fullCommand .. "' finished successfully.", vim.log.levels.INFO)
				else
					notify(
						"Script '" .. fullCommand .. "' finished with exit code " .. exit_code .. ".",
						vim.log.levels.ERROR
					)
				end
			end,

			on_stdout = function(job_id, data, event)
				local text = table.concat(data, "\n")
				if notify_all_events then
					notify(text, vim.log.levels.INFO)
				end
				if notify_ready_events and is_ready_event(text) then
					notify(text, vim.log.levels.INFO)
				end
				if notify_warn_events and is_warn_event(text) then
					notify(text, vim.log.levels.WARN)
				end
			end,

			on_stderr = function(job_id, data, event)
				local text = table.concat(data, "\n")

				if notify_all_events then
					notify(text, vim.log.levels.ERROR)
				end
				if notify_error_events and is_error_event(text) then
					notify(text, vim.log.levels.ERROR)
				end
			end,
		})
		notify("Executing script: " .. fullCommand, vim.log.levels.WARN)
	end
end

local nearestPackageJsonPath = findNearestPackageJson(vim.fn.getcwd())

if nearestPackageJsonPath then
	local scripts = readPackageJsonScripts(nearestPackageJsonPath)

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
							runScript(selection[1])
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
