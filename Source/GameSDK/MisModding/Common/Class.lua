-- Copyright (C) 2022 Theros < MisModding | SvalTek >
-- 
-- This file is part of ServerPlugin.
-- 
-- ServerPlugin is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- ServerPlugin is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with ServerPlugin.  If not, see <http://www.gnu.org/licenses/>.

local function newClass(name, base)
    ---@class MisModding.Class
    ---@field new fun(...:any):any
    local class = {}
    if type(name) == "table" then
        base = name
        name = "Anonymous"
    end

    if type(base) == "table" then for k, v in pairs(base) do class[k] = v end end
    return setmetatable(class, {
        __call = function(self, ...)
            local instance = setmetatable({}, {
                __index = self,
                __tostring = function(cls)
                    return string.format("Class: %s", name)
                end
            })
            if instance.new then instance:new(...) end
            return instance
        end
    })
end


---@overload fun(base: table): MisModding.Class|any
---@overload fun(name: string, base: table): MisModding.Class|any
local Class = setmetatable({}, {
    __call = function(self, name, base)
        return newClass(name, base)
    end
})


RegisterModule("MisModding.Common.Class", Class)
return Class