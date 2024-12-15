local M = {}

M.list_contains = function(list, item)
    for _, x in ipairs(list) do
        if x == item then
            return true
        end
    end

    return false
end

M.capitalize = function(str)
    return string.upper(string.sub(str, 1, 1)) .. string.sub(str, 2)
end

return M
