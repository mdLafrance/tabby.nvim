-- Functionality for window tab merging
local core = require("tabby.core")
local log = require("tabby.log")
local compat = require("tabby.compat")

--- Get the window that exists at coordinate [x, y], or nil if none does.
--- @param x number x coordinate
--- @param y number y coordinate
--- @return number|nil window
local function get_window_at_pos(x, y)
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        local pos = vim.api.nvim_win_get_position(win)
        local r0 = pos[1]
        local c0 = pos[2]
        local r1 = r0 + vim.api.nvim_win_get_height(win)
        local c1 = c0 + vim.api.nvim_win_get_width(win)

        if r0 <= x and x <= r1 then
            if c0 <= y and y <= c1 then
                return win
            end
        end
    end

    return nil
end

--- Merge the given window or tab group into the nearest window in the given
--- direction
---
--- If there is no valid window in the chosen direction, an error will be thrown.
---
--- @param window number|nil The id if the window or tab group to merge. Current window if nil
--- @param direction "up" | "down" | "left" | "right" The direction to merge in.
local function merge_tabs(window, direction)
    if window == nil then
        window = vim.api.nvim_get_current_win()
    end

    local pos = vim.api.nvim_win_get_position(window)
    local row = pos[1]
    local column = pos[2]

    local drow = 0
    local dcol = 0

    if direction == "up" then
        drow = row - 1
        dcol = column
    elseif direction == "left" then
        drow = row
        dcol = column - 1
    elseif direction == "right" then
        drow = row
        dcol = column + vim.api.nvim_win_get_width(window) + 1
    elseif direction == "down" then
        drow = row + vim.api.nvim_win_get_height(window) + 1
        dcol = column
    end

    local new_window = get_window_at_pos(drow, dcol)

    if not new_window then
        log.error("No window exists at position %d, %d", drow, dcol)
    end

    local buf_in_window = vim.api.nvim_win_get_buf(new_window)

    if compat.get_buf_type(buf_in_window) ~= "" then
        log.error("Cannot merge with unwritable buffer %d", buf_in_window)
    end

    if not core.window_has_tab_group(new_window) then
        core.convert_to_tab_group(new_window)
    end

    -- If the current window is a tab group, move all tabs over
    if core.window_has_tab_group(window) then
        for _, buf in ipairs(core.get_tabs_for_window(window).buffers) do
            core.add_buffer_to_tab_group(buf, new_window)
        end
    else
        core.add_buffer_to_tab_group(buf_in_window, new_window)
    end

    -- Close current window
    vim.api.nvim_win_close(window, true)
end

-- Exports

local M = {}

M.merge_tabs = merge_tabs

return M
