local tabby = require("tabby")

-- TESTING --
local function reload()
    print("Reloading!")
    package.loaded["tabby"] = nil
    require("tabby")
    require("tabby.core")
end

vim.keymap.set("n", "<leader>rl", reload, {})
vim.keymap.set("n", "<leader>nt", tabby.new_tab, {})

return tabby
