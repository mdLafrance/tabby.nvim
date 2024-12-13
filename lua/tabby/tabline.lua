-- Functionality for creating the visual tab line indicator

local devicons = require('nvim-web-devicons')

local TabGroup = require("tabby.tab_group")
local log = require("tabby.log")
local opts = require("tabby.config").opts

---@class Palette
---@field text string Color for normal text
---@field text_muted string Color for muted text
---@field background string Color for the tabline background
---@field tab_active string Color for active tabs
---@field tab_inactive string Color for inactive tabs
local Palette = {}

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
    local ext = vim.fn.fnamemodify(filename, ":e")

    local bg = ""
    local fg = ""

    if is_active then
        bg = "%#TabbyBG#"
        fg = "%#TabbyFG#"
    else
        bg = "%#TabbyBGInactive#"
        fg = "%#TabbyFGInactive#"
    end

    local leader_character = ""

    local icon = ""
    local icon_highlight = ""

    if opts.show_icon_in_tab_bar then
        icon, hlg = devicons.get_icon(filename, ext)

        if icon ~= "" then
            icon = icon .. "  "
        end

        if is_active then
            icon_highlight = "%#" .. hlg .. "#"
        end
    end

    return bg .. " " .. leader_character .. fg .. " " .. icon_highlight .. icon .. fg .. filename .. " x " .. bg .. ""
end

---@return number len
local function get_length_of_tabline_text(text)
    local stripped = text:gsub("%%#%w+#", "")
    return select(2, string.gsub(stripped, "[%z\1-\127\194-\244][\128-\191]*", ""))
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

    local content = table.concat(filenames, "")

    if opts.show_close_all_button_in_tab_bar then
        local content_len = get_length_of_tabline_text(content)
        local window_width = vim.api.nvim_win_get_width(tab_group.window)

        local space_remaining = window_width - content_len

        if space_remaining > 1 then
            content = content .. string.rep(" ", space_remaining - 2) .. "󰱝"
        end
    end

    log.debug("Setting winbar for window %d", tab_group.window)

    vim.api.nvim_win_set_option(tab_group.window, "winbar", content .. "%#TabbyBG#")
end

local clear_tabline_for_window = function(window)
    log.debug("Clearing tabline for window %d", window)

    vim.api.nvim_win_set_option(window, "winbar", nil)
end

---@param tab_group TabGroup The tab group that was clicked on
---@param cell_y number The window-y coordinate of the selected cell.
---@return {idx: number, close: boolean}|nil res The index of the clicked tab, and whether the user clicked on the close button. If the user did not click a valid tab, nil is returned instead.
local get_clicked_tab = function(tab_group, cell_y)
    local p0 = 0
    local p1 = 0

    for idx, bufnr in ipairs(tab_group.buffers) do
        local tab_length = get_length_of_tabline_text(format_buffer_tab(bufnr, idx, idx == tab_group.index))

        p0 = p1
        p1 = p0 + tab_length

        if p0 < cell_y and cell_y <= p1 then
            return {
                idx = idx,
                close = cell_y == (p1 - 2) -- if we clicked on the x cell
            }
        end
    end
end

-- Exports
local M = {}

M.redraw_tabline = redraw_tabline
M.clear_tabline_for_window = clear_tabline_for_window
M.get_clicked_tab = get_clicked_tab

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
