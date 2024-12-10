local core = require("tabby.core")
local buffers = require("tabby.buffers")
local tabline = require("tabby.tabline")

local register_callbacks = function()
    vim.api.nvim_create_autocmd("ColorScheme", {
        callback = tabline.set_highlight_group_from_theme
    })
end

register_callbacks()

local M = {}

M.new_tab = function()
    core.open_file_in_new_tab()
end

return M
