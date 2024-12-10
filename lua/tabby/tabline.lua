-- Functionality for creating the visual tab line indicator

local TabGroup = require("tabby.tab_group")

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
local format_buffer_tab = function(bufnr, is_active)
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

    local icon = ""

    -- if vim.lsp.buf_is_attached() then
    --     icon = vim.lsp.buf.document_symbol()
    -- end

    return bg .. "" .. fg .. " " .. icon .. filename .. " " .. bg .. ""
end

---@param tab_group TabGroup The tab group that was clicked on
---@param cell_x number The X coordinate of the selected cell.
---@param cell_y number The Y coordinate of the selected cell.
---@return number|nil bufnr The buffer number of the selected tab, or nil if no valid tab was selected.
local get_clicked_tab = function(tab_group, cell_x, cell_y)

end

-- Exports
local M = {}

--- Redraw the tab line for the given tab group.
---
--- This function will error if the associated tabline hasn't been created.
--- @param tab_group TabGroup The tab group to redraw for
M.redraw_tabline = function(tab_group)
    local filenames = {}

    for idx, buf_id in ipairs(tab_group.buffers) do
        table.insert(filenames, format_buffer_tab(buf_id, idx == tab_group.index))
    end

    local content = table.concat(filenames, " ")

    vim.api.nvim_win_set_option(0, 'winbar', content .. "%#TabbyBG#")
end

M.set_highlight_group_from_theme = set_highlight_group_from_theme

return M
