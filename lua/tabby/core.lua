-- Core functionality

local buffers = require("tabby.buffers")
local tabline = require("tabby.tabline")
local TabGroup = require("tabby.tab_group")
local log = require("tabby.log")

--- The global record of all currently managed tab groups.
---
--- Interaction with this object should be done behind an interface.
---@type table<number, TabGroup>
local g_tabs = {}

-- Core functionality

---Returns true if the given window id has an associated tab group.
---
---@param window number The window id
local window_has_tab_group = function(window)
    return g_tabs[window] ~= nil
end

--- Creates a tab group on the given window.
--- NOTE: This tab group is empty. Call add_buffer_to_tab_group to add buffers to it.
---
---@param window number The numerical id of the window to tabify
local create_tab_group = function(window)
    g_tabs[window] = { window = window, buffers = {}, index = 0 }
end

--- Set the current tab of the given window to the tab at the given index.
---
--- This function will error if the given window has no associated tab group.
---
--- @param window number|nil The id of the tab window containing the target tab group. If this value is nil, the current window will be used.
--- @param idx number The index of the tab to switch to.
local set_current_tab = function(window, idx)
    if not window then
        window = vim.api.set_current_win()
    end

    if not window_has_tab_group(window) then
        error("Adding buffer to window with no tab group")
    end

    local tabs = g_tabs[window]

    if idx == -1 then
        tabs.index = #tabs.buffers
    else
        tabs.index = idx
    end

    log.debug("Window %d switching to tab %d", window, tabs.index)

    tabline.redraw_tabline(tabs)

    local bufnr = tabs.buffers[tabs.index]

    vim.api.nvim_win_set_buf(window, bufnr)
    vim.api.nvim_exec_autocmds("BufRead", { -- trigger lsp attach commands
        buffer = bufnr,
    })
end

--- Adds the given buffer to the tab group associated with the given window.
---
--- This function will error if the given window has no associated tab group.
--- @param bufnr number The buffer number of the buffer to add
--- @param window number The id of the tab window to add this new tab to.
--- @param show boolean (Optional) Whether or not to show the new tab immediately. Defaults to true.
local add_buffer_to_tab_group = function(bufnr, window, show)
    if not window_has_tab_group(window) then
        error(string.format("Adding buffer to window with no tab group: [%s]", window))
    end

    log.debug("Adding buffer %d to window %d", bufnr, window)

    table.insert(g_tabs[window].buffers, bufnr)

    tabline.redraw_tabline(g_tabs[window])

    if show ~= false then
        set_current_tab(window, -1)
    end
end

--- Opens a telescope window to pick a file to open in a new tab.
--- Once the user has selected a file, the given callback function is invoked with the full file path.
---
--- @param callback fun(path: string): nil The callback function to execute when a user has selected a file.
local telescope_pick_file = function(callback)
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
local convert_to_tab_group = function(window)
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
    add_buffer_to_tab_group(buf, window, true)
end

--- Change the tab of the given tab group by the given offset.
---
--- This function will error if the given window has no associated tab group.
--
--- @param window number|nil The id of the tab window containing the target tab group. If this value is nil, the current window will be used.
--- @param offset number The offset to change the tab by (positive, or negative).
local change_tab_offset = function(window, offset)
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

-- Exports --
local M = {}

M.set_current_tab = set_current_tab
M.convert_to_tab_group = convert_to_tab_group
M.change_tab_offset = change_tab_offset

--- Opens a telescope picker to browse for a file to open as a new tab.
---
--- If a tab group doesn't exist for the current window, one will be created
--- and the current buffer will be added to it as the first tab.
M.browse_and_open_as_tab = function()
    local window = vim.api.nvim_get_current_win()
    local buf = vim.api.nvim_get_current_buf()

    telescope_pick_file(function(file)
        if not window_has_tab_group(window) then
            convert_to_tab_group(window)
        end

        local new_buf = buffers.get_buffer_for_file(file)
        add_buffer_to_tab_group(new_buf, window, true)
    end)
end

--- Removes the tab group associated with the given window.
--- This function will error if the given window has no associated tab group.
--- This function will error if there is more than one tab attached to this tab group.
---
--- @param window number|nil The id of the tab window containing the target tab group. If this value is nil, the current window will be used.
M.remove_tab_group = function(window)
    local tabs = g_tabs[window]

    if tabs == nil then
        error("Cannot remove tab group on window with no tab group")
    end

    if #tabs.buffers > 1 then
        error("Cannot remove tab group with more than one tab")
    end
end

M.close_tab = function(window, tab)
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

    -- Last tab - close the whole window
    if #tabs.buffers == 0 then
        log.debug("No more tabs for tab group, closing window")
        g_tabs[window] = nil

        -- This is a quirk with what i THINK is a bug in nvim
        -- The tabline is not properly reset when you immediately open a new window to the same buffer.
        -- winbar is supposed to be window local, but i think there's something else going on.
        -- Manually clearning the tabline for THIS window before you close it seems to dodge the issue.
        tabline.clear_tabline_for_window(window)

        vim.api.nvim_win_close(window, true)
        return
    end

    if tab > 1 then
        tabs.index = tab - 1
    end

    set_current_tab(window, tabs.index)
end

--- Gets the tab group associated with the given window.
---
--- @param window number The window id to get the tab group for.
M.get_tabs_for_window = function(window)
    return g_tabs[window]
end

M.register_tab_callbacks = function()
    -- vim.api.nvim_create_autocmd("BufDelete", {
    --     callback = function()
    --         log.notify_info("Returning false..")
    --         return false
    --     end
    -- })

    -- vim.api.nvim_create_autocmd("WinClosed", {
    --     callback = function(event)
    --         vim.cmd("abort")
    --         local window = event.file

    --         local tabs = g_tabs[window]

    --         if tabs ~= nil then
    --             log.debug("Tab window closing: %d", tabs.window)
    --         end
    --     end
    -- })
end

-- Debug utils

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
