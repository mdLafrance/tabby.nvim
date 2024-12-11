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

    show_tabs = core.debug_print_tabs,
}

M.register_commands = function()
    vim.api.nvim_create_user_command("Tabby", function(args)
            local cmd = commands[args.fargs[1]]

            if cmd == nil then
                error("No such command: " .. args.fargs[1])
            end

            -- NOTE: This is due to how lua handles empty tables and "truthyness".
            -- It is often convenient to check if an optional arg is 'nil' by simply
            -- doing a truthyness check. However, if the fargs slice is empty, then
            -- the args passed is {} which will incorrectly pass the truthyness check.
            local fn_args = vim.list_slice(args.fargs, 2)

            -- Manually convert empty args table to nil
            if next(fn_args) == nil then
                fn_args = nil
            end

            cmd(fn_args)
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
