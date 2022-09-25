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
--
-- ────────────────────────────────────────────────────────────── TABLE UTILS ─────
--
if not table.pack then
    table.pack = function(...) return {n = select('#', ...), ...} end
end

---* Return the Size of a Table.
-- Works with non Indexed Tables
--- @param table table  `any table to get the size of`
--- @return number      `size of the table`
function table.size(table)
    local n = 0
    for k, v in pairs(table) do n = n + 1 end
    return n
end

--- Return an array of keys of a table.
---@param tbl table `The input table.`
---@return table `The array of keys.`
function table.keys(tbl)
    local ks = {}
    for k, _ in pairs(tbl) do table.insert(ks, k) end
    return ks
end

---* Copies all the fields from the source into t and return .
-- If a key exists in multiple tables the right-most table value is used.
--- @param t table      table to update
function table.update(t, ...)
    for i = 1, select('#', ...) do
        local x = select(i, ...)
        if x then for k, v in pairs(x) do t[k] = v end end
    end
    return t
end

function table.GetFirstKey(t)
    local k, v = next(t)
    return k
end

function table.GetFirstValue(t)
    local k, v = next(t)
    return v
end

function table.GetLastKey(t)
    local k, v = next(t, table.size(t) - 1)
    return k
end

function table.GetLastValue(t)
    local k, v = next(t, table.size(t) - 1)
    return v
end

function table.FindNext(tab, val)
    local bfound = false
    for k, v in pairs(tab) do
        if (bfound) then return v end
        if (val == v) then bfound = true end
    end

    return table.GetFirstValue(tab)
end

function table.ArrContains(arr, find)
    for i = 1, #arr do
        if arr[i] == find then
            return true
        end
    end
    return false
end

function table.FindPrev(tab, val)
    local last = table.GetLastValue(tab)
    for k, v in pairs(tab) do
        if (val == v) then return last end
        last = v
    end

    return last

end

function table.GetWinningKey(tab)

    local highest = -math.huge
    local winner = nil

    for k, v in pairs(tab) do
        if (v > highest) then
            winner = k
            highest = v
        end
    end

    return winner

end

function table.KeyFromValue(tbl, val)
    for key, value in pairs(tbl) do if (value == val) then return key end end
end

function table.RemoveByValue(tbl, val)

    local key = table.KeyFromValue(tbl, val)
    if (not key) then return false end

    table.remove(tbl, key)
    return key

end

function table.KeysFromValue(tbl, val)
    local res = {}
    for key, value in pairs(tbl) do
        if (value == val) then res[#res + 1] = key end
    end
    return res
end

function table.Reverse(tbl)
    local len = #tbl
    local ret = {}

    for i = len, 1, -1 do ret[len - i + 1] = tbl[i] end

    return ret

end

function table.ForEach(tab, funcname)
    for k, v in pairs(tab) do funcname(v, k) end
end

function table.ForArr(tab, funcname)
    for k, v in ipairs(tab) do funcname(v, k) end
end

function table.IsEmpty(tab) return next(tab) == nil end

--- make the provided table inherit from the provided base table by setting 
--- its __index metamethod to the base table
function table.Inherit(t, base)
    local mt = {__index = base}
    setmetatable(t, mt)
end

--- Get the value from the table based on a string path to the property
--- like `'MyProperty.MySubProperty.key'`
---@param tbl table         the table to get the value from
---@param path string       the path to the property
---@return any|nil          value or nil if not found
---@return nil|string       err message if not found
function table.GetPath(tbl, path)
    if not path then return nil, 'no path provided' end
    local pathParts = string.split(path, '%.')
    for i, part in ipairs(pathParts) do
        if tbl[part] then
            tbl = tbl[part]
        else
            return nil, 'property not found'
        end
    end
    return tbl
end

--- Set the value from the table based on a string path to the property
--- like `'MyProperty.MySubProperty.key'`
---@param tbl table         table to set the value on
---@param path string       path to the property
---@param value string|number|boolean|table
---@return boolean          true if set, false if not
---@return nil|string       err message if not found
function table.SetPath(tbl, path, value)
    if not path then return false, 'no path provided' end
    local pathParts = string.split(path, '%.')
    for i, part in ipairs(pathParts) do
        if i == #pathParts then
            tbl[part] = value
        elseif tbl[part] then
            tbl = tbl[part]
        else
            return false, 'property not found'
        end
    end
    return true
end

--- Proxies a table marking its contents as readonly
---@param tbl table        the table to make readonly
---@return table           readonlyTable table
function table.ReadOnly(tbl)
    return setmetatable({}, {
        __index = tbl,
        __newindex = function(t, k, v)
            local msg = ("[table.ReadOnly] Attempt to modify readonly table: ${k} = ${v}"):expand({k = k, v = v})
            Log(msg)
        end,
        __metatable = false
    })
end