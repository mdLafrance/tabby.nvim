local log = require("tabby.log")
local core = require("tabby.core")

local M = {}

local commands = {
    new_tab = core.browse_and_open_as_tab,

    convert_to_tab_group = core.convert_to_tab_group,

    set_tab = function(idx)
        if type(idx) ~= "number" then
            error("Cannot switch to tab given by non-number value: " .. idx)
            return
        end

        core.set_current_tab(nil, idx)
    end,

    cycle_tab = function()
        core.change_tab_offset(nil, 1)
    end,

    next_tab = function()
        core.change_tab_offset(nil, 1)
    end,

    previous_tab = function()
        core.change_tab_offset(nil, 1)
    end,

    detatch = function(direction)
        local directions = { left = true, right = true, above = true, below = true }

        if not directions[direction] then
            log.notify_warning("Invalid direction to split: %s", vim.inspect(direction))
            return
        end

        core.detach_tab(nil, nil, direction)
    end,

    show_tabs = core.debug_print_tabs,
}

M.register_commands = function()
    vim.api.nvim_create_user_command("Tabby", function(args)
            local cmd = commands[args.fargs[1]]

            if cmd == nil then
                error("No such command: " .. args.fargs[1])
            end

            local fn_args = vim.list_slice(args.fargs, 2)

            cmd(unpack(fn_args))
        end,
        {
            range = true,
            nargs = "+",
            complete = function(arg)
                local command_names = {}

                for name, _ in pairs(commands) do
                    table.insert(command_names, name)
                end

                return vim.tbl_filter(function(s)
                    return string.match(s, '^' .. arg)
                end, command_names)
            end
        })
end

return M
