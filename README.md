# rayso-snap.nvim

NVIM plugin to open the selected text in [https://ray.so](https://ray.so)

## Installation

### Lazy.nvim

Add this to your pluging list:
```lua
{
    "masshirodev/rayso-snap.nvim",
    init = function()
    require 'raysosnap'.setup()
    end
}
```

## Usage

Select some text in visual mode and run this command:
```vimL
:Ray
```

### Browser
The plugin will try it's best to use your default browser. If it fails, or you want to customize it, set this variable to whichever you want to use in your config file. Example for google-chrome:

```lua
vim.g.ray_browser = 'google-chrome'
```

The plugin supports WSL instances, in that case, it'll try to launch your default browser.

### Options
You can set the query string that will be passed to [https://ray.so](https://ray.so) by overriding ray_options in your config file.
Example:

```lua
vim.g.ray_options = {
    'theme' : 'midnight',
    'background' : 'true',
    'darkMode' : 'true',
    'padding' : '64',
    'language' : 'auto'
}
```
