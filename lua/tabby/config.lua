--- Configuration options for tabby.
---
--- Apply configuration options with the exported `setup` function.
---
---@class TABBY_CONFIG
---@field always_convert_to_tab_group boolean If enabled, any new writable buffer that is opened will automatically be converted into a tab group.
---@field debug boolean Whether or not to enable debug trace logging.
---@field supress_notifications boolean Whether or not to suppress popup notifications. These will be warning messages fired when attempting to perform invalid operations.
TABBY_CONFIG = {
    always_convert_to_tab_group = false,
    show_marks_in_tab_bar = true,
    show_icon_in_tab_bar = true,
    show_close_all_button_in_tab_bar = true,
    debug = false,
    supress_notifications = false,
}

local M      = {}

M.opts       = TABBY_CONFIG

M.setup      = function(opts)
    -- Register callbacks
    require("tabby.tabline").register_refresh_tabline_callback()
    require("tabby.tabline").register_refresh_highlight_groups_callback()
    require("tabby.core").register_tab_callbacks()
    require("tabby.commands").register_commands()
    local log = require("tabby.log")

    if opts == nil then
        return
    end

    for k, v in pairs(opts) do
        if TABBY_CONFIG[k] == nil then
            log.error("Unknown config option: %s", k)
        elseif type(v) ~= type(TABBY_CONFIG[k]) then
            log.error("Invalid config option %s. Must be of type %s", k, type(TABBY_CONFIG[k]))
        else
            TABBY_CONFIG[k] = v
        end
    end
end

return M
