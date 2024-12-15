local core = require("tabby.core")

local M = {}

vim.keymap.set("n", "<leader>nt", ":TabbyNewTab<CR>", {})
vim.keymap.set("n", "<leader>mt", ":TabbyConvertToTabGroup<CR>", {})
vim.keymap.set("n", "<leader>cl", ":TabbyCloseTab<CR>", {})
vim.keymap.set("n", "<leader>tdr", ":TabbyDetach right<CR>", {})
vim.keymap.set("n", "<leader>tdd", ":TabbyDetach below<CR>", {})
vim.keymap.set("n", "<leader>[", ":TabbyPreviousTab<CR>", {})
vim.keymap.set("n", "<leader>]", ":TabbyNextTab<CR>", {})

local function print_buf_info()
    local buf = vim.api.nvim_get_current_buf()
    local buf_name = vim.api.nvim_buf_get_name(buf)
    local buf_type = vim.api.nvim_get_option_value("buftype", { buf = buf })
    local filename = vim.api.nvim_get_option_value("filetype", { buf = buf })

    print(string.format("buf/name/type/filetype %d - %s - %s - %s", buf, buf_name, buf_type, filename))
end

vim.keymap.set("n", "<leader>cl", core.close_tab, {})
vim.keymap.set("n", "<leader>bt", print_buf_info, {})

return M
