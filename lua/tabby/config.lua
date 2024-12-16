--- Configuration options for tabby.
--- Apply configuration options with the exported `setup` function.
---@class TabbyConfig
TABBY_CONFIG = {
    remove_tab_group_if_only_tab = true,
    show_icon_in_tab_bar = true,
    show_close_all_button_in_tab_bar = true,
    debug = false,
    suppress_notifications = false,
}

local M      = {}

M.opts       = TABBY_CONFIG

--- Apply the given configuration options
--- @param opts TabbyConfig
M.setup      = function(opts)
    -- Check minimum version
    local version = vim.version()

    if version.major < 1 and version.minor < 8 then
        error("Tabby requires neovim version 0.8 or greater")
        return
    end

    -- Register callbacks
    require("tabby.tabline").register_refresh_tabline_callback()
    require("tabby.tabline").register_refresh_highlight_groups_callback()
    require("tabby.core").register_tab_callbacks()
    require("tabby.commands").register_commands()

    local log = require("tabby.log")

    log.debug("Setting up with opts: " .. vim.inspect(opts))

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
