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

M.cycle_tab = function()
    local window = vim.api.nvim_get_current_win()

    local tabs = core.get_tabs_for_window(window)

    if tabs == nil then
        error("Cannot cycle tabs on window with no tab group")
        return
    end

    local next_tab = tabs.index + 1

    if next_tab > #tabs.buffers then
        next_tab = 1
    end

    core.set_current_tab(window, next_tab)
end

return M
