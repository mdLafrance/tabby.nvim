local config = require("tabby.config")

local M = {}

M.debug = function(fmt, ...)
    if config.TABBY_CONFIG.debug then
        print(string.format("TABBY DEBUG: %s", string.format(fmt, ...)))
    end
end

M.notify_info = function(fmt, ...)
    if not config.TABBY_CONFIG.supress_notifications then
        vim.notify(string.format(fmt, ...), vim.log.levels.INFO)
    end
end

M.notify_warning = function(fmt, ...)
    if not config.TABBY_CONFIG.supress_notifications then
        vim.notify(string.format(fmt, ...), vim.log.levels.WARN)
    end
end

return M
