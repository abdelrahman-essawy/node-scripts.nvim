local telescope = require("telescope")
local actions = require("telescope.actions")
local finders = require("telescope.finders")
local pickers = require("telescope.pickers")
local sorters = require("telescope.sorters")
local action_state = require("telescope.actions.state")

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

local function runScript(scriptCommand)
  if scriptCommand then
    local fullCommand = choosenPackageManager() .. " run " .. scriptCommand
    vim.notify("Executing script: " .. fullCommand, vim.log.levels.WARN)
    local job_id = vim.fn.jobstart(fullCommand, {
      cwd = vim.fn.getcwd(),
      on_exit = function(job_id, exit_code)
        local success = exit_code == 0
        local message = success and "Script executed successfully!" or "Script execution failed!"
        vim.notify(message, success and vim.log.levels.INFO or vim.log.levels.ERROR)
        if success then
          vim.notify("Script ran successfully!", vim.log.levels.INFO)
        end
      end,
    })
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
    print("No 'scripts' found in package.json.")
  end
else
  print("No package.json found in the current directory or its parent directories.")
end
