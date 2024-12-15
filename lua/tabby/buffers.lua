-- Functionality for opening and working with buffers

local log = require("tabby.log")

--- Get an existing buffer for the given filepath, if one exists.
--- @param file string File path a buffer might exist for
--- @return number|nil bufnr
local function try_get_existing_buffer(file)
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


-- Exports
local M = {}

--- Get a buffer for the given text file.
--- If a buffer for the given file exists, it is returned. Otherwise a new buffer is created.
--- @param file_path string File path to open
--- @return number bufnr
M.get_buffer_for_file = function(file_path)
    log.debug("Obtaining buffer for file %s", file_path)

    vim.cmd.edit(file_path)

    return vim.api.nvim_get_current_buf()

    -- -- A buffer of the same file_path is open, use that
    -- local buf = try_get_existing_buffer(file_path)

    -- if buf ~= nil then
    --     log.debug("Existing buffer found: %d", buf)
    --     return buf
    -- end

    -- -- Create a new buffer and load file_path contents
    -- buf = vim.api.nvim_create_buf(true, false)
    -- vim.api.nvim_buf_set_name(buf, file_path)
    -- log.debug("Creating new buffer: %d", buf)

    -- local file = io.open(file_path, "r")

    -- if file then
    --     local content = file:read("*a")
    --     file:close()
    --     vim.api.nvim_buf_set_lines(buf, 0, -1, false, vim.split(content, "\n"))
    -- else
    --     error(string.format("Unable to read file contents of: %s", file_path))
    -- end

    -- return buf
end

return M
