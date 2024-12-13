local opts = require("tabby.config").opts

local M = {}

M.debug = function(fmt, ...)
    if opts.debug then
        print(string.format("TABBY DEBUG: %s", string.format(fmt, ...)))
    end
end

M.error = function(fmt, ...)
    error("TABBY: " .. string.format(fmt, ...))
end

M.notify_info = function(fmt, ...)
    if not opts.supress_notifications then
        vim.notify(string.format(fmt, ...), vim.log.levels.INFO)
    end
end

M.notify_warning = function(fmt, ...)
    if not opts.supress_notifications then
        vim.notify(string.format(fmt, ...), vim.log.levels.WARN)
    end
end

return M
