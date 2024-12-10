--- Configuration options for tabby.
---
--- Apply configuration options with the exported `setup` function.
---
---@class TABBY_CONFIG
---@field debug boolean Whether or not to enable debug logging.
---@field supress_notifications boolean Whether or not to suppress notifications.
TABBY_CONFIG   = {
    debug = false,
    supress_notifications = false,
}

local M        = {}

M.TABBY_CONFIG = TABBY_CONFIG

M.setup        = function(opts)
    -- Register callbacks
    require("tabby.tabline").register_refresh_tabline_callback()
    require("tabby.tabline").register_refresh_highlight_groups_callback()
    require("tabby.core").register_tab_callbacks()
    require("tabby.commands").register_commands()

    if opts == nil then
        return
    end

    for k, v in pairs(opts) do
        if TABBY_CONFIG[k] == nil then
            error(string.format("TABBY: Unknown config option: %s", k))
        elseif type(v) ~= type(TABBY_CONFIG[k]) then
            error(string.format("TABBY: Invalid config option %s. Must be of type %s", k, type(TABBY_CONFIG[k])))
        else
            TABBY_CONFIG[k] = v
        end
    end

    print("Config set to:", vim.inspect(TABBY_CONFIG))
end

return M
