local M = {}

M.list_contains = function(list, item)
    for _, x in ipairs(list) do
        if x == item then
            return true
        end
    end

    return false
end

return M
