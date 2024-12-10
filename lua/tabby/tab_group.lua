--- A tab group is a structure containing all necessary information to work
--- with a collected group of buffers, visible on one window.
---
--- A tab group "posesses" a window, and keeps track of all buffers currently
--- "open" in that group. Only one buffer (one "tab") is visible at a time.
--- The other buffers exist in a hidden state
---
--- The group is considered closed when all tabs within that group have themselves been closed.
---@class TabGroup
---@field window number The window id this tab group is posessing.
---@field buffers number[] References to the currently managed buffers.
---@field index number The currently active index
local TabGroup = {}

return TabGroup
