local tabby = require("tabby")

vim.keymap.set("n", "<leader>nt", tabby.new_tab, {})
vim.keymap.set("n", "<leader>net", tabby.cycle_tab, {})

return tabby
