local core = require("tabby.core")

local M = {}

vim.keymap.set("n", "<leader>nt", ":Tabby new_tab<CR>", {})
vim.keymap.set("n", "<leader>mt", ":Tabby convert_to_tab_group<CR>", {})
vim.keymap.set("n", "<leader>cl", ":Tabby close_tab<CR>", {})
vim.keymap.set("n", "<leader>tdr", ":Tabby detach right<CR>", {})
vim.keymap.set("n", "<leader>tdd", ":Tabby detach below<CR>", {})
vim.keymap.set("n", "<leader>[", ":Tabby previous_tab<CR>", {})
vim.keymap.set("n", "<leader>]", ":Tabby next_tab<CR>", {})

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
