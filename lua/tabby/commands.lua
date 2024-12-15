-- Functionality to define and expose user commands

local log = require("tabby.log")
local core = require("tabby.core")
local util = require("tabby.util")

local M = {}

local commands = {
    help = function()
        vim.cmd("help tabby.nvim")
    end,

    new_tab = core.browse_and_open_as_tab,

    convert_to_tab_group = core.convert_to_tab_group,

    cycle_tab = function()
        core.change_tab_offset(nil, 1)
    end,

    next_tab = function()
        core.change_tab_offset(nil, 1)
    end,

    previous_tab = function()
        core.change_tab_offset(nil, -1)
    end,

    set_tab = function(idx_)
        local ok, idx = pcall(tonumber, idx_)

        if not ok then
            log.notify_warning("Cannot switch to tab given by non-number value: %s (%s)", idx_, type(idx_))
            return
        end

        core.set_current_tab(nil, idx)
    end,

    close_tab = function()
        core.close_tab(nil, nil)
    end,

    close_all = function()
        core.close_all_tabs(nil)
    end,

    detach = function(direction)
        local directions = { left = true, right = true, above = true, below = true }

        if not directions[direction] then
            log.notify_warning("Invalid direction to split: %s\nValid directions are left, right, above, below",
                vim.inspect(direction))
            return
        end

        core.detach_tab(nil, nil, direction)
    end,

    show_tabs = core.debug_print_tabs,
}

--- Register user commands.
--- Call only once in setup.
M.register_commands = function()
    local function wrap_cmd(fn)
        return function(args)
            fn(unpack(args.fargs))
        end
    end

    for name, cmd in pairs(commands) do
        local cmd_name = "Tabby" .. string.gsub(util.capitalize(name), "_(%w)", function(letter)
            return string.upper(letter)
        end)

        log.debug("Registering command: %s", name)

        vim.api.nvim_create_user_command(cmd_name, wrap_cmd(cmd), { nargs = "*" })
    end

    -- vim.api.nvim_create_user_command("Tabby", function(args)
    --         local cmd = commands[args.fargs[1]]

    --         if cmd == nil then
    --             error("No such command: " .. args.fargs[1])
    --         end

    --         local fn_args = vim.list_slice(args.fargs, 2)

    --         cmd(unpack(fn_args))
    --     end,
    --     {
    --         range = true,
    --         nargs = "+",
    --         complete = function(arg)
    --             local command_names = {}

    --             for name, _ in pairs(commands) do
    --                 table.insert(command_names, name)
    --             end

    --             return vim.tbl_filter(function(s)
    --                 return string.match(s, '^' .. arg)
    --             end, command_names)
    --         end
    --     })
end

return M
