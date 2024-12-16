<h1 align=center>
  <img src="https://github.com/user-attachments/assets/e5005f94-1c42-4bc3-97a9-6d57ef77b710" width="30" height="30" style="vertical-align: bottom" />
 tabby.nvim
</h1>

<p align="center" size=10>
  Neovim tabs like a regular IDE 
</p>

<p align="center">
    <sup>(Still in beta)</sup> <!-- x-release-please-version -->
</p>

<p align="center">
    <code>:help tabby</code>
</p>

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
functionality.

## Examples
> TODO

## Installation
#### Lazy
```lua
return {
  "mdlafrance/tabby.nvim",
  opts = {}
}
```

## Requirements
Tabby uses the `winbar`, and will conflict with other plugins that do so as well.

neovim >= 0.8 is required.

## Help
Tabby has a detailed help doc, access it from within neovim with `:help tabby` for explanations on the plugin, and commands.
