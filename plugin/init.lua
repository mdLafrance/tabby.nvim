local config = require("tabby.config")
local core = require("tabby.core")

local M = {}

M.setup = config.setup

config.setup({ debug = true })

vim.keymap.set("n", "<leader>ot", ":Tabby new_tab<CR>", {})
vim.keymap.set("n", "<leader>nt", ":Tabby next_tab<CR>", {})
vim.keymap.set("n", "<leader>pt", ":Tabby previous_tab<CR>", {})

vim.keymap.set("n", "<leader>cl", core.close_tab, {})

return M
