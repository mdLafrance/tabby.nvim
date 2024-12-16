<h1 align=center>
  <img src="https://github.com/user-attachments/assets/e5005f94-1c42-4bc3-97a9-6d57ef77b710" width="30" height="30" style="vertical-align: bottom" />
 tabby.nvim
  <img src="https://img.shields.io/badge/beta-4287f5" />

</h1>

<p align="center" size=10>
  Neovim tabs like a regular IDE 
</p>


<p align="center">
    <code>:help tabby</code>
</p>

<br />

## About 
Tabby brings ide-like tabs to neovim. Typically, in a visual editor, you 
have panes open each with their own tabs, as well as side content like file
explorers or debuggers. Vim has a different concept of tabs, in which one tab
contains the entire screen worth of windows (including any side content which
are themselves just windows into special buffers).

Tabby lets you open virtual tab groups on top of your windows themselves, so
you can keep your side content open while flipping between buffers. You can even
have two windows with different tab groups open side by side (or as many as you want).

Tab groups created by tabby also support some features you might be used to 
from other visual editors, like mouse support. 

See the [help doc](./doc/tabby.nvim.txt) for usage details.

## Examples
<details open>
  <summary>
    Screenshot
  </summary>

![image](https://github.com/user-attachments/assets/3e173d90-90e6-4dbc-aaa3-57493248d2d7)

  
</details>

## Installation
### Lazy
```lua
return {
  "mdlafrance/tabby.nvim",
  opts = {}
}
```

### Configuration
Tabby's setup function accepts the following table:

```lua
require("tabby").setup({
    -- If a tab group has only one tab, automatically convert back into a regular buffer window
    remove_tab_group_if_only_tab = true,

    -- Show filetype icons for tabs
    show_icon_in_tab_bar = true,

    -- Enable debug logging
    debug = false,

    -- Suppress notifications from tabby. These are fired when encountering unexpected behavior
    suppress_notifications = false,
})
```

## Requirements
Tabby uses the `winbar`, and will conflict with other plugins that do so as well.

neovim >= 0.8 is required.

## Help
Tabby has a detailed [help doc](./doc/tabby.nvim.txt). Access it from within neovim with `:help tabby` for explanations on the plugin, and commands.
