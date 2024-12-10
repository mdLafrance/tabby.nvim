local log = require("tabby.log")

local try_get_existing_buffer = function(file)
    local buffers = vim.api.nvim_list_bufs()
    for _, buf in ipairs(buffers) do
        if vim.api.nvim_buf_is_loaded(buf) then
            local buf_name = vim.api.nvim_buf_get_name(buf)
            if buf_name == file then
                return buf
            end
        end
    end

    return nil
end

local get_buffer_for_file = function(file_path)
    log.debug("Obtaining buffer for file %s", file_path)

    -- A buffer of the same file_path is open, use that
    local buf = try_get_existing_buffer(file_path)

    if buf ~= nil then
        log.debug("Existing buffer found: %d", buf)
        return buf
    end

    -- Create a new buffer and load file_path contents
    buf = vim.api.nvim_create_buf(true, true)
    vim.api.nvim_buf_set_name(buf, file_path)
    log.debug("Creating new buffer: %d", buf)

    local file = io.open(file_path, "r")

    if file then
        local content = file:read("*a")
        file:close()
        vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
    else
        error(string.format("Unable to read file contents of: %s", file_path))
    end

    return buf
end

-- Exports
local M = {}

M.get_buffer_for_file = get_buffer_for_file

return M
