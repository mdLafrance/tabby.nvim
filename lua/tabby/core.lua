local buffers = require("tabby.buffers")
local tabline = require("tabby.tabline")
local TabGroup = require("tabby.tab_group")

-- Mapping from window id to tab group.
-- Does there exist a tab group on the current window? Display it
-- When the window closes: if there's a tab group associated,
--
-- Feature ideas:
-- - hint for vim marks on the tab name. this would be SUPER useful to be able to
-- jump around on open and hidden tabs


--- The global record of all currently managed tab groups.
---
--- Interaction with this object should be done obscured behind the interface.
---@type table<number, TabGroup>
local g_tabs = {}

-- Core functionality

--- Returns true if the given window id has an associated tab group.
--- @param window number The window id
local window_has_tab_group = function(window)
    return g_tabs[window] ~= nil
end

--- Creates a tab group on the given window, inserting the currently open buffer
--- as tab 0.
---@param window number The numerical id of the window to tabify
local create_tab_group = function(window)
    -- Add table entry
    g_tabs[window] = { window = window, buffers = {}, index = 0 }

    -- Attach callbacks
    -- vim.api.nvim_create_autocmd("WinClosed", {
    --     callback = function()
    --         print("Removing tab record for", window)
    --         g_tabs[window] = nil
    --     end
    -- })
end

local set_current_tab = function(window, idx)
    if not window_has_tab_group(window) then
        error("Adding buffer to window with no tab group")
    end

    local tabs = g_tabs[window]

    if idx == -1 then
        tabs.index = #tabs.buffers
    else
        tabs.index = idx
    end

    tabline.redraw_tabline(tabs)

    local bufnr = tabs.buffers[tabs.index]

    vim.api.nvim_win_set_buf(window, bufnr)
    vim.api.nvim_exec_autocmds('BufRead', {
        buffer = bufnr
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

    table.insert(g_tabs[window].buffers, bufnr)

    tabline.redraw_tabline(g_tabs[window])

    if show ~= false then
        set_current_tab(window, -1)
    end
end


--- Opens a telescope window to pick a file to open in a new tab.
---
--- Once the user has selected a file, the given callback function is invoked with the full file path.
--- @param callback fun(path: string): nil The callback function to execute when a user has selected a file.
local telescope_pick_file = function(callback)
    local telescope = require('telescope.builtin')
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')

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
        end
    })
end


local open_file_in_new_tab = function()
    local window = vim.api.nvim_get_current_win()

    telescope_pick_file(function(file)
        if not window_has_tab_group(window) then
            print("No group exists for window: ", window)
            create_tab_group(window)
        else
            print("Tabs exist for", window)
        end

        local buf = buffers.get_buffer_for_file(file)

        add_buffer_to_tab_group(buf, window, true)
    end)
end

-- Exports
local M = {}

M.open_file_in_new_tab = open_file_in_new_tab
M.set_current_tab = set_current_tab
M.get_tabs_for_window = function(window)
    return g_tabs[window]
end

return M
