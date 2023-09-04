local telescope = require("telescope")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local sorters = require("telescope.sorters")
local action_state = require("telescope.actions.state")

local DEFAULT_CONFIG = require("npm-scripts.config").DEFAULT_CONFIG

local notify = require("npm-scripts.utils").notify
local has_keywords = require("npm-scripts.utils").has_keywords

local M = {}

local config = {}

M.find_package_json_path = function(path)
	if not path or path == "" then
		return nil
	end
	local packageJsonPath = vim.fn.findfile("package.json", path .. ";")
	if packageJsonPath ~= "" then
		return packageJsonPath
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

-- Execute a script using the configured package manager
M.execute_script = function(script)
	if script then
		local fullCommand = config.package_manager .. " run " .. script

		-- Start a job to run the script
		local job_id = vim.fn.jobstart(fullCommand, {
			on_exit = function(job_id, exit_code, event)
				-- Notify when the job exits with a successful exit code
				if exit_code == 0 then
					notify("Script '" .. fullCommand .. "' finished successfully.", vim.log.levels.INFO)
				end
			end,

			on_stdout = function(job_id, data, event)
				local text = table.concat(data, "\n")

				if config.notify.stdout.notify_all and not has_keywords(text, config.notify.stdout.exclude) then
					-- Notify when all stdout is enabled and no exclusions apply
					notify(text, vim.log.levels.INFO)
				elseif has_keywords(text, config.notify.stdout.keywords) then
					-- Notify when specific stdout keywords are found
					notify(text, vim.log.levels.INFO)
				end
			end,

			on_stderr = function(job_id, data, event)
				local text = table.concat(data, "\n")

				if config.notify.stderr.notify_all and not has_keywords(text, config.notify.stderr.exclude) then
					-- Notify when all stderr is enabled and no exclusions apply
					notify(text, vim.log.levels.ERROR)
				elseif has_keywords(text, config.notify.stderr.keywords) then
					-- Notify when specific stderr keywords are found
					notify(text, vim.log.levels.ERROR)
				end
			end,
		})

		-- Notify that the script is being executed
		if config.notify.job_finished then
			notify("Executing script: " .. fullCommand, vim.log.levels.INFO)
		end
	end
end

M.run = function()
	local nearest_package_json_path = M.find_package_json_path(vim.fn.getcwd())

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
