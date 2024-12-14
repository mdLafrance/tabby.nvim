-- Core functionality

local buffers = require("tabby.buffers")
local tabline = require("tabby.tabline")
local log = require("tabby.log")

--- The global record of all currently managed tab groups.
---
--- Interaction with this object should be done behind an interface.
---@type table<number, TabGroup>
local g_tabs = {}


---Returns true if the given window id has an associated tab group.
---
---@param window number The window id
local function window_has_tab_group(window)
    return g_tabs[window] ~= nil
end


--- Register a tab group for the given window.
---
---@param window number The numerical id of the window to tabify
local function create_tab_group(window)
    g_tabs[window] = { window = window, buffers = {}, index = 0 }
end


--- Set the current tab of the given window to the tab at the given index.
---
--- This function will error if the given window has no associated tab group.
---
--- @param window number|nil The id of the tab window containing the target tab group. If this value is nil, the current window will be used.
--- @param idx number The index of the tab to switch to.
local function set_current_tab(window, idx)
    -- Infer window
    if not window then
        window = vim.api.set_current_win()
    end

    if not window_has_tab_group(window) then
        error("Attempting to set tab on window with no tab group")
        return
    end

    local tabs = g_tabs[window]

    if idx == -1 then
        tabs.index = #tabs.buffers
    else
        tabs.index = idx
    end

    log.debug("Window %d switching to tab %d", window, tabs.index)

    local bufnr = tabs.buffers[tabs.index]

    -- Setting the buffer triggers an autocommand that will apply changed tab behaviors.
    -- See `register_tab_callbacks` for details.
    vim.api.nvim_win_set_buf(window, bufnr)
    vim.api.nvim_exec_autocmds("BufRead", { -- trigger lsp attach commands
        buffer = bufnr,
    })

    tabline.redraw_tabline(tabs)
end


--- Adds the given buffer to the tab group associated with the given window.
---
--- This function will error if the given window has no associated tab group.
--- @param bufnr number The buffer number of the buffer to add
--- @param window number The id of the tab window to add this new tab to.
local function add_buffer_to_tab_group(bufnr, window)
    if not window_has_tab_group(window) then
        error(string.format("Adding buffer to window with no tab group: [%s]", window))
    end

    log.debug("Adding buffer %d to window %d", bufnr, window)

    table.insert(g_tabs[window].buffers, bufnr)

    set_current_tab(window, -1)
end


--- Opens a telescope window to pick a file to open in a new tab.
--- Once the user has selected a file, the given callback function is invoked with the full file path.
---
--- @param callback fun(path: string): nil The callback function to execute when a user has selected a file.
local function telescope_pick_file(callback)
    local telescope = require("telescope.builtin")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    log.debug("Opening telescope")

    telescope.find_files({
        prompt_title = "Open in new tab",
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()

                if selection then
                    actions.close(prompt_bufnr)

                    callback(selection.path)
                end

                return true
            end)
            return true
        end,
    })
end


--- Converts the given window into a tab group, with the current buffer is added as the first tab.
---
--- This function will error if the given window has no associated tab group.
---@param window number|nil The id of the tab window to convert. If this value is nil, the current window will be used.
local function convert_to_tab_group(window)
    -- if window == nil or (type(window) == "table" and next(window) == nil) then
    --     window = vim.api.nvim_get_current_win()
    -- end

    if not window then
        window = vim.api.nvim_get_current_win()
    end

    if window_has_tab_group(window) then
        error(string.format("Window %d is already a tab group", window))
        return
    end

    local buf = vim.api.nvim_win_get_buf(window)

    create_tab_group(window)
    add_buffer_to_tab_group(buf, window)
end

--- Change the tab of the given tab group by the given offset.
---
--- This function will error if the given window has no associated tab group.
--
--- @param window number|nil The id of the tab window containing the target tab group. If this value is nil, the current window will be used.
--- @param offset number The offset to change the tab by (positive, or negative).
local function change_tab_offset(window, offset)
    if not window then
        window = vim.api.nvim_get_current_win()
    end

    local tabs = g_tabs[window]

    if tabs == nil then
        error("Cannot cycle tabs on window with no tab group")
        return
    end

    local next_tab = ((tabs.index - 1 + offset) % #tabs.buffers) + 1

    set_current_tab(window, next_tab)
end


--- Close the tab on the given tab group at the given index.
---
--- If there are no more tabs after this removal operation, then the tab group is also removed.
---
--- @param window number|nil The window id of a window with an associated tab group. Will use the current window if nil.
--- @param tab number|nil The index to close. Will use the current tab if nil.
local function close_tab(window, tab)
    -- Infer window if not provided
    if window == nil then
        window = vim.api.nvim_get_current_win()
    end

    local tabs = g_tabs[window]

    if tabs == nil then
        error("Cannot close tab on window with no tab group")
        return
    end

    -- Infer tab if not provided
    if tab == nil then
        tab = tabs.index
    end

    if tab < 1 or tab > #tabs.buffers then
        error("Cannot close tab with index %d (index doesnt exist)", tab)
        return
    end

    log.debug("Closing tab %d", tab)
    table.remove(tabs.buffers, tab)

    -- No more tabs - close the whole window
    if #tabs.buffers == 0 then
        log.debug("No more tabs for tab group, closing window")
        g_tabs[window] = nil

        -- This is a quirk with what i THINK is a bug in nvim
        -- The tabline is not properly reset when you immediately open a new window to the same buffer.
        -- winbar is supposed to be window local, but i think there's something else going on.
        -- Manually clearning the tabline for the window BEFORE you close it seems to dodge the issue.
        tabline.clear_tabline_for_window(window)

        vim.api.nvim_win_close(window, true)
        return

        -- This was the last tab, decrement index
    elseif tabs.index > #tabs.buffers then
        tabs.index = #tabs.buffers
    end

    set_current_tab(window, tabs.index)
end


--- Close all tabs on the given window tag group.
---
--- This function will error if there aren't any tab groups on the given window
---
--- @param window number|nil The window id to clear tabs for. If nil, the current window will be used.
local function close_all_tabs(window)
    if window == nil then
        window = vim.api.nvim_get_current_win()
    end

    local tabs = g_tabs[window]

    if tabs == nil then
        log.error("Cant close all tabs on window with no tab group: %d", window)
        return
    end

    for _ = 1, #tabs.buffers do
        close_tab(window, nil)
    end
end


--- Detach the given tab from the given tab group and split it out in a direction.
---
--- Will throw an error if the given window id is not a tab group.
---
--- Will throw an error if the tab index is out of bounds.
---
--- @param window number|nil Window id containing a tab group. If this value is nil, the current window will be used.
--- @param idx number|nil Tab index to split. If this value is nil, the current tab will be used.
--- @param direction 'above'|'below'|'left'|'right' The direction to perform the split.
local function detach_tab(window, idx, direction)
    if window == nil then
        window = vim.api.nvim_get_current_win()
    end

    if not window_has_tab_group(window) then
        error("Cannot detach tab from window with no tab group")
        return
    end

    local tabs = g_tabs[window]

    if idx == nil then
        idx = tabs.index
    elseif idx < 1 or idx > #tabs.buffers then
        error("Invalid tab to split:", idx)
        return
    end

    local buf = tabs.buffers[idx]

    vim.api.nvim_open_win(buf, true, {
        split = direction,
    })

    close_tab(window, idx)
end

-- Exports --
local M = {}

M.set_current_tab = set_current_tab
M.convert_to_tab_group = convert_to_tab_group
M.change_tab_offset = change_tab_offset
M.close_tab = close_tab
M.detach_tab = detach_tab
M.close_all_tabs = close_all_tabs

--- Opens a telescope picker to browse for a file to open as a new tab.
---
--- If a tab group doesn't exist for the current window, one will be created
--- and the current buffer will be added to it as the first tab.
M.browse_and_open_as_tab = function()
    local window = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()

    telescope_pick_file(function(file)
        local new_buf = buffers.get_buffer_for_file(file)

        if not window_has_tab_group(window) then
            -- If this is called while the current window is not writable, open
            -- a new window to use as the tab group
            if vim.api.nvim_get_option_value("buftype", { buf = buf }) ~= "" then
                window = vim.api.nvim_open_win(new_buf, true, { win = -1, split = 'right' })
            end

            convert_to_tab_group(window)
        else
            add_buffer_to_tab_group(new_buf, window)
        end
    end)
end


--- Gets the tab group associated with the given window.
---
--- @param window number The window id to get the tab group for.
--- @return TabGroup tabs
M.get_tabs_for_window = function(window)
    return g_tabs[window]
end


-- Register relevant autocommands
--
-- Call only once during setup
M.register_tab_callbacks = function()
    -- Callback to handle clicking on tabs
    vim.keymap.set({ 'n', 'i' }, '<LeftRelease>', function()
        local mp = vim.fn.getmousepos()

        local x = mp.winrow
        local y = mp.wincol

        local tabs = g_tabs[mp.winid]

        if x == 1 and tabs ~= nil then
            local res = tabline.get_clicked_tab(tabs, y)

            if res == nil then
                return
            end

            local tab, do_close = res.idx, res.close

            if do_close then
                close_tab(mp.winid, tab)
            else
                set_current_tab(mp.winid, tab)
            end
        end
    end)

    -- Callback to resolve tab group settings and tabline when the buffer
    -- shown in a tab group changes
    vim.api.nvim_create_autocmd("BufEnter", {
        callback = function()
            local bufnr = vim.api.nvim_get_current_buf()
            local window = vim.api.nvim_get_current_win()

            local tabs = g_tabs[window]

            -- If a buffer is being opened on a window marked as a tab group
            if tabs ~= nil then
                local tab_exists = false

                -- Check if there is already a tab for this buffer
                for idx, buf in ipairs(tabs.buffers) do
                    if buf == bufnr then
                        tab_exists = true
                        tabs.index = idx
                    end
                end

                -- If not, then add new tab for this buffer
                if not tab_exists then
                    table.insert(tabs.buffers, bufnr)
                    tabs.index = #tabs.buffers
                end

                tabline.redraw_tabline(tabs)
            else
                tabline.clear_tabline_for_window(window)
            end
        end
    })

    -- Callback to cleanup any tab window definitions when a window is closd
    vim.api.nvim_create_autocmd("WinCLosed", {
        callback = function(event)
            local window = tonumber(event.file)

            if not window then
                log.error("Couldn't get window from closed event:", vim.inspect(event))
                return
            end

            local tabs = g_tabs[window]

            if tabs ~= nil then
                log.debug("Window %d closed with tabs. Clearing tab group", window)

                g_tabs[window] = nil
                tabline.clear_tabline_for_window(window)
            end
        end
    })

    -- Redraw tabline when window resized
    vim.api.nvim_create_autocmd("WinResized", {
        callback = function()
            -- NOTE: There's strange behavior about which window gets a WinResized
            -- event when resizing split windows. Only one seems to get the event.
            --
            -- Instead, just redraw all tablines when a resize occurs. This shouldnt actually
            -- be too wasteful in common use cases since:
            -- 1. The operation is cheap
            -- 2. There's a high chance at least one of the tab groups is being resized.
            for _, tabs in pairs(g_tabs) do
                tabline.redraw_tabline(tabs)
            end
        end
    })
end

-- Debug utils

--- Utility function that prints information about currently active tab groups
M.debug_print_tabs = function()
    local num_groups = 0

    for _, _ in pairs(g_tabs) do
        num_groups = num_groups + 1
    end

    if num_groups == 0 then
        print("No tab groups open")
        return
    end

    local s = num_groups .. " tab groups open:\n"

    for win_id, tabs in pairs(g_tabs) do
        s = s .. string.format("Window [%d], %d tabs, current idx %d\n", win_id, #tabs.buffers, tabs.index)

        local bufs_string = "Buffer ids: "

        for _, buf_id in ipairs(tabs.buffers) do
            bufs_string = bufs_string .. buf_id .. " "
        end

        s = s .. bufs_string .. "\n\n"
    end

    print(s)
end

return M
