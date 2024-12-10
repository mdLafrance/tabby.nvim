-- Functionality for creating the visual tab line indicator

local TabGroup = require("tabby.tab_group")
local log = require("tabby.log")

local set_highlight_group_from_theme = function()
    local n = vim.api.nvim_get_hl_by_name("Normal", true)
    local p1 = vim.api.nvim_get_hl_by_name("TabLine", true)
    local p2 = vim.api.nvim_get_hl_by_name("StatusLine", true)
    local p3 = vim.api.nvim_get_hl_by_name("LineNr", true)

    local text = n.fg or n.foreground or nil
    local text_muted = p3.fg or p3.foreground or nil
    local foreground = n.bg or n.background or nil
    local foreground_muted = p2.bg or p2.background or nil
    local background = p1.bg or p1.background or nil

    vim.api.nvim_set_hl(0, "TabbyFG", {
        fg = text,
        bg = foreground,
    })

    vim.api.nvim_set_hl(0, "TabbyFGInactive", {
        fg = text_muted,
        bg = foreground_muted,
    })

    vim.api.nvim_set_hl(0, "TabbyBG", {
        -- bg = p2.bg,
        -- fg = p2.fg
        fg = foreground,
        bg = background,
    })

    vim.api.nvim_set_hl(0, "TabbyBGInactive", {
        -- bg = p2.bg,
        -- fg = p2.fg
        fg = foreground_muted,
        bg = background,
    })
end

---@param bufnr number The id of the buffer this tab represents
---@param is_active boolean Whether or not this tab is active
local format_buffer_tab = function(bufnr, idx, is_active)
    local filename = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(bufnr), ":t")

    local bg = ""
    local fg = ""

    if is_active then
        bg = "%#TabbyBG#"
        fg = "%#TabbyFG#"
    else
        bg = "%#TabbyBGInactive#"
        fg = "%#TabbyFGInactive#"
    end

    local leader_character = ""

    if idx > 1 then
        leader_character = ""
    end

    local icon = ""

    return bg .. leader_character .. fg .. " " .. icon .. filename .. " " .. bg .. ""
end

--- Redraw the tab line for the given tab group.
---
--- This function will error if the associated tabline hasn't been created.
--- @param tab_group TabGroup The tab group to redraw for
local redraw_tabline = function(tab_group)
    log.debug("Drawing tabline for %d (%d tabs)", tab_group.window, #tab_group.buffers)

    local filenames = {}

    for idx, buf_id in ipairs(tab_group.buffers) do
        table.insert(filenames, format_buffer_tab(buf_id, idx, idx == tab_group.index))
    end

    local content = table.concat(filenames, " ")

    log.debug("Setting winbar for window %d", tab_group.window)

    vim.api.nvim_win_set_option(tab_group.window, "winbar", content .. "%#TabbyBG#")
end

local clear_tabline_for_window = function(window)
    log.debug("Clearing tabline for window %d", window)

    vim.api.nvim_win_set_option(window, "winbar", nil)
end

---@param tab_group TabGroup The tab group that was clicked on
---@param cell_x number The X coordinate of the selected cell.
---@param cell_y number The Y coordinate of the selected cell.
---@return number|nil bufnr The buffer number of the selected tab, or nil if no valid tab was selected.
local get_clicked_tab = function(tab_group, cell_x, cell_y) end

-- Exports
local M = {}

M.redraw_tabline = redraw_tabline
M.clear_tabline_for_window = clear_tabline_for_window

M.register_refresh_highlight_groups_callback = function()
    vim.api.nvim_create_autocmd("ColorScheme", {
        callback = set_highlight_group_from_theme,
    })
end

M.register_refresh_tabline_callback = function()
    local core = require("tabby.core")

    vim.api.nvim_create_autocmd("BufWinEnter", {
        callback = function()
            local bufnr = vim.api.nvim_win_get_buf(0)
            local window = vim.api.nvim_get_current_win()

            local tabs = core.get_tabs_for_window(window)

            if tabs ~= nil then
                redraw_tabline(tabs)
            end
        end,
    })

    -- When new windows are created, make sure the tabline is cleared if
    -- its not a tab group
    --
    -- This is a quirk of listening to split events specifically, since the regular
    -- Win Enter event doesnt fire for splits.
    vim.api.nvim_create_autocmd("WinNew", {
        callback = function()
            for _, win_id in ipairs(vim.api.nvim_list_wins()) do
                local tabs = core.get_tabs_for_window(win_id)

                if tabs == nil then
                    clear_tabline_for_window(win_id)
                end
            end
        end
    })
end

return M
