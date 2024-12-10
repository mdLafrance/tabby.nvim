TABBY_DEBUG = true

local M = {}

M.debug = function(fmt, ...)
    if TABBY_DEBUG then
        print(string.format("TABBY DEBUG: %s", string.format(fmt, ...)))
    end
end

return M
