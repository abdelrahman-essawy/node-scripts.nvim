# npm-scripts.nvim

A Neovim Lua plugin for displaying and executing scripts defined in the `package.json` file of your projects, keeping you in the loop about scripts results and events.

## Features

- List and execute scripts from the `package.json`.
- Display notifications for scripts execution results using the `notify` plugin.
- Notifications for ready, warning, and error events with syntax highighlighting using `Treesitter`.
- Automatically open localhost URLs in the browser.
- Scripts searching and selection using the Telescope fuzzy finder.
- Customizable notification behavior.

## Installation

To install the plugin, use your preferred Neovim plugin manager.

   For `lazy.nvim`:

```lua
  {
    "abdelrahman-essawy/npm-scripts.nvim",
    config = function() require("npm-scripts").setup {} end,
    event = "VeryLazy",
  }
```

For `vim-plug`:
```lua
Plug 'abdelrahman-essawy/npm-scripts.nvim', { 'do': 'lua require("npm-scripts").setup()' }
```


## Configuration (Optional)
`npm-scripts.nvim` is ready-to-go with the default setup. However, If you want more control, you're covered.
Simply pass your preferred settings to the setup function:
```lua
require("npm-scripts").setup({
  auto_open_localhost = true, -- Auto-open localhost URLs in the browser
  timeout = 3000,
  -- Other configuration options...
})
```

### Default Configuration
```lua
require("npm-scripts").setup({
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
})
```

## Usage

- Open the project directory containing a package.json file.

- In normal mode, press `<Leader>ns` or type in command `:NS` to open the list of scripts in the package.json file.

- Use arrow keys to navigate to the desired script and press Enter to execute it.


## Contributing
Contributions, issues, and feature requests are welcome! If you encounter any problems or have suggestions, please open an issue on the GitHub repository.

## License
This project is licensed under the terms of the MIT license.
