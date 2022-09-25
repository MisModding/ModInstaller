---@diagnostic disable: cast-local-type, need-check-nil
-- Copyright (C) 2022 Theros < MisModding | SvalTek >
-- MisDB2 is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- MisDB2 is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with MisDB2.  If not, see <http://www.gnu.org/licenses/>.
-- ---------------------------------------------------------------------------------------------- --
--                                            ~ MisDB2 ~                                           --
-- ---------------------------------------------------------------------------------------------- --
--[[
    MisDB2 Provides Mods With a Method for "Data Persistance"
    Via JSON File Backed "Pages" and "Collections".
    Based on a Module to Providing a "Pure Lua" implementation
    'Similar' to flatDB/NoDB
    
    MisDB2 Takes a Lua Table Converts it to JSON, and we call that a "Page"
    These "Pages" are Grouped into Named "Collections" and Stored as Seperate Files,
    One for Each Different Collection in a Folder with this "MisDB2 Objects" Name
    And Placed in the Specified Base Directory (Relative to Your Server Root)
    eg:
    
    For a MisDB2 Called "MyModsData" with a Collection Named "Settings"
    and Stored in the BaseDir "MisDB2data" :
        [ServerRoot]>{BaseDir}/{MisDB2 Name}/{Collection Name}
            ServerRoot>/MisDB2data/MyModsData/Settings
    
    
    Methods:
    
    *    MisDB2:Create(BaseDir, Name) ~> TableObject(Your Main MisDB2 Object)
            Creates a New MisDB2 Object to Store Collections Backed by files in
            [ServerRoot]>{BaseDir}/{Name}
    
    With the Returned {Object} then:
    *    {Object}:Collection(Name) ~> CollectionObject(Table/Object defining this Collection)
            Create/Fetch a New Collection in this MisDB2 (Non Existant Collections Are autoCreated)
    
    the Returned {Collection} then provides the following Methods:
    *    {Collection}:GetPage(pageId)
            Fetch The Contents of a "Page" from this "Collection" By Specified PageID
            ! This Will return nil, with a message as the Second return var if the Page Does Not Exist
    *    {Collection}:SetPage(pageId,data)
            Set The Contents of a "Page" from this "Collection" By Specified PageID
            ? Returns the "written to disk" Copy of the Page Content you Set
            ? Use this to save your page data and use the return to verify against your data
    *    {Collection}:PurgePage(pageId)
            Remove a "Page" from this "Collection" By Specified PageID
            ? returns true/nil and a message with the result
    
--]] --
local pathseparator = package.config:sub(1, 1);

local function getPath(...)
    local elements = {...}
    return table.concat(elements, pathseparator)
end
local function isFile(path)
    local f = io.open(path, 'r')
    if f then
        f:close()
        return true
    end
    return false
end
local function isDir(path)
    path = string.gsub(path .. '/', '//', '/')
    local ok, err, code = os.rename(path, path)
    if ok or code == 13 then return true end
    return false
end
local function mkDir(path)
    local ok, Result = os.execute('mkdir ' .. path:gsub('/', '\\'))
    if not ok then
        return nil, 'Failed to Create ' .. path .. ' Directory! - ' .. Result
    else
        return true, 'Successfully Created ' .. path .. ' Directory!'
    end
end

local json = {}
-- Internal functions.
local function kind_of(obj)
    if type(obj) ~= 'table' then return type(obj) end
    local i = 1
    for _ in pairs(obj) do
        if obj[i] ~= nil then
            i = i + 1
        else
            return 'table'
        end
    end
    if i == 1 then
        return 'table'
    else
        return 'array'
    end
end

local function escape_str(s)
    local in_char = {'\\', '"', '/', '\b', '\f', '\n', '\r', '\t'}
    local out_char = {'\\', '"', '/', 'b', 'f', 'n', 'r', 't'}
    for i, c in ipairs(in_char) do s = s:gsub(c, '\\' .. out_char[i]) end
    return s
end

-- Returns pos, did_find; there are two cases:
-- 1. Delimiter found: pos = pos after leading space + delim; did_find = true.
-- 2. Delimiter not found: pos = pos after leading space;     did_find = false.
-- This throws an error if err_if_missing is true and the delim is not found.
local function skip_delim(str, pos, delim, err_if_missing)
    pos = pos + #str:match('^%s*', pos)
    if str:sub(pos, pos) ~= delim then
        if err_if_missing then
            error('Expected ' .. delim .. ' near position ' .. pos)
        end
        return pos, false
    end
    return pos + 1, true
end

-- Expects the given pos to be the first character after the opening quote.
-- Returns val, pos; the returned pos is after the closing quote character.
local function parse_str_val(str, pos, val)
    val = val or ''
    local early_end_error = 'End of input found while parsing string.'
    if pos > #str then error(early_end_error) end
    local c = str:sub(pos, pos)
    if c == '"' then return val, pos + 1 end
    if c ~= '\\' then return parse_str_val(str, pos + 1, val .. c) end
    -- We must have a \ character.
    local esc_map = {b = '\b', f = '\f', n = '\n', r = '\r', t = '\t'}
    local nextc = str:sub(pos + 1, pos + 1)
    if not nextc then error(early_end_error) end
    return parse_str_val(str, pos + 2, val .. (esc_map[nextc] or nextc))
end

-- Returns val, pos; the returned pos is after the number's final character.
local function parse_num_val(str, pos)
    local num_str = str:match('^-?%d+%.?%d*[eE]?[+-]?%d*', pos)
    local val = tonumber(num_str)
    if not val then error('Error parsing number at position ' .. pos .. '.') end
    return val, pos + #num_str
end

-- Public values and functions.

function json.stringify(obj, as_key)
    local s = {} -- We'll build the string as an array of strings to be concatenated.
    local kind = kind_of(obj) -- This is 'array' if it's an array or type(obj) otherwise.
    if kind == 'array' then
        if as_key then error('Can\'t encode array as key.') end
        s[#s + 1] = '['
        for i, val in ipairs(obj) do
            if i > 1 then s[#s + 1] = ', ' end
            s[#s + 1] = json.stringify(val)
        end
        s[#s + 1] = ']'
    elseif kind == 'table' then
        if as_key then error('Can\'t encode table as key.') end
        s[#s + 1] = '{'
        for k, v in pairs(obj) do
            if #s > 1 then s[#s + 1] = ', ' end
            s[#s + 1] = json.stringify(k, true)
            s[#s + 1] = ':'
            s[#s + 1] = json.stringify(v)
        end
        s[#s + 1] = '}'
    elseif kind == 'string' then
        return '"' .. escape_str(obj) .. '"'
    elseif kind == 'number' then
        if as_key then return '"' .. tostring(obj) .. '"' end
        return tostring(obj)
    elseif kind == 'boolean' then
        return tostring(obj)
    elseif kind == 'nil' then
        return 'null'
    else
        error('Unjsonifiable type: ' .. kind .. '.')
    end
    return table.concat(s)
end

json.null = {} -- This is a one-off table to represent the null value.

function json.parse(str, pos, end_delim)
    pos = pos or 1
    if pos > #str then error('Reached unexpected end of input.') end
    local pos = pos + #str:match('^%s*', pos) -- Skip whitespace.
    local first = str:sub(pos, pos)
    if first == '{' then -- Parse an object.
        local obj, key, delim_found = {}, true, true
        pos = pos + 1
        while true do
            key, pos = json.parse(str, pos, '}')
            if key == nil then return obj, pos end
            if not delim_found then
                error('Comma missing between object items.')
            end
            pos = skip_delim(str, pos, ':', true) -- true -> error if missing.
            obj[key], pos = json.parse(str, pos)
            pos, delim_found = skip_delim(str, pos, ',')
        end
    elseif first == '[' then -- Parse an array.
        local arr, val, delim_found = {}, true, true
        pos = pos + 1
        while true do
            val, pos = json.parse(str, pos, ']')
            if val == nil then return arr, pos end
            if not delim_found then
                error('Comma missing between array items.')
            end
            arr[#arr + 1] = val
            pos, delim_found = skip_delim(str, pos, ',')
        end
    elseif first == '"' then -- Parse a string.
        return parse_str_val(str, pos + 1)
    elseif first == '-' or first:match('%d') then -- Parse a number.
        return parse_num_val(str, pos)
    elseif first == end_delim then -- End of an object or array.
        return nil, pos + 1
    else -- Parse true, false, or null.
        local literals = {
            ['true'] = true,
            ['false'] = false,
            ['null'] = json.null
        }
        for lit_str, lit_val in pairs(literals) do
            local lit_end = pos + #lit_str - 1
            if str:sub(pos, lit_end) == lit_str then
                return lit_val, lit_end + 1
            end
        end
        local pos_info_str = 'position ' .. pos .. ': ' ..
                                 str:sub(pos, pos + 10)
        error('Invalid json syntax starting at ' .. pos_info_str)
    end
end

--- MisDB2 Main Object
---@type fun(dbName:string):MisDB2
---@class MisDB2
---@field data_hook_read fun(data:any):any handles data mutation when reading from disk can be used to modify the data before it is returned
---@field data_hook_write fun(data:any):any handles data mutation before writing to disk can be overriden
local MisDB2 = {
    data_hook_read = function(data) return json.parse(data) end,
    data_hook_write = function(data) return json.stringify(data) end
}
setmetatable(MisDB2, {
    __call = function(self, ...)
        local db = setmetatable({}, {__index = MisDB2})
        local createdOk, err = db:new(...)
        if not createdOk then error(err) end
        return db
    end
})

local function load_page(path)
    local ret
    local f = io.open(path, 'rb')
    if f then
        ret = MisDB2.data_hook_read(f:read('*a'))
        f:close()
    end
    return ret
end
local function store_page(path, page)
    if page then
        local f = io.open(path, 'wb')
        if f then
            f:write(MisDB2.data_hook_write(page))
            f:close()
            return true
        end
    end
    return false
end

local pool = {}

local db_funcs = {
    save = function(db, p)
        if p then
            if (type(p) == 'string') and db[p] then
                return store_page(pool[db] .. '/' .. p, db[p])
            else
                return false
            end
        end
        for p, page in pairs(db) do
            if not store_page(pool[db] .. '/' .. p, page) then
                return false
            end
        end
        return true
    end
}
local mt = {
    __index = function(db, k)
        if db_funcs[k] then return db_funcs[k] end
        if isFile(pool[db] .. '/' .. k) then
            db[k] = load_page(pool[db] .. '/' .. k)
        end
        return rawget(db, k)
    end
}
pool.hook = db_funcs
local dbcontroller = setmetatable(pool, {
    __mode = 'kv',
    __call = function(pool, path)
        assert(isDir(path), path .. ' is not a directory.')
        if pool[path] then return pool[path] end
        local db = {}
        setmetatable(db, mt)
        pool[path] = db
        pool[db] = path
        return db
    end
})

function MisDB2:new(baseDir)
    if (not baseDir) then return false, 'invalid basedir' end
    local dbDir = getPath('./MisDB2_Data', baseDir)
    if not isDir(dbDir) then
        if not mkDir(dbDir) then
            return false, 'could not create db directory'
        end
    end
    self.baseDir = dbDir
    self.Collections = {}
    return self
end

---@class MisDB2.Collection
---@overload fun(name:string):MisDB2.Collection
local Collection = setmetatable({}, {
    __call = function(self, source)
        local collection = setmetatable({}, {__index = self})
        collection:new(source)
        return collection
    end
})

function Collection:new(source) self.data = (source or {}) end

function Collection:GetPage(pageId)
    local data = self.data[pageId]
    if (data == nil) or (data == json.null) then
        return false, 'no page data for pageId:' .. pageId
    end
    return self.data[pageId]
end

function Collection:SetPage(pageId, data)
    self.data[pageId] = (data or json.null)
    self.data:save()
    local dataRead, error = self:GetPage(pageId)
    if dataRead then
        if dataRead == data then
            return true, 'Page Data updated'
        else
            return false, 'failed to update Page Data: ' .. error
        end
    end
    return false, 'failed to verify Page Data'
end

function Collection:Save(pageId) return self.data:save(pageId) end

function MisDB2:Collection(name)
    if not self.Collections[name] then
        local collectionDir = getPath(self.baseDir, name)
        if not isDir(collectionDir) then mkDir(collectionDir) end
        self.Collections[name] = dbcontroller(getPath(self.baseDir, name))
    end
    return Collection(self.Collections[name])
end

---@class MisDB2.DataStore_Opts
---@field name string name this DataStore
---@field persistance_dir string base directory for this DataStore

---@type fun(config:MisDB2.DataStore_Opts):MisDB2.DataStore
---@class MisDB2.DataStore
---@field DataSource table
---@field new fun(self:MisDB2.DataStore,config:MisDB2.DataStore_Opts):MisDB2.DataStore
local DataStore = setmetatable({}, {
    __call = function(self, config)
        local store = setmetatable({}, {__index = self})
        store:new(config)
        return store
    end
})
---* Defines a MisDB2 Backed Key/Value storage

---* DataStore(config)
-- Create a New DataStore
---@param config table Config
---@usage
--      local MisDB2 = require 'MisDB2' ---@type MisDB2
--      local DataStore = MisDB2.DataStore
--      local MyClass = Class {}
--      function MyClass:new()
--          ---@type MisDB2.DataStore
--          self.DataStore = DataStore {name = 'DataStoreName', persistance_dir = 'dataDir'}
--      end
function DataStore:new(config)
    if not type(config) == 'table' then
        return nil, 'you must provide a DataStore config'
    elseif not config['persistance_dir'] then
        return nil, 'must specify persistance_dir'
    elseif not config['name'] then
        return nil, 'must specify a name'
    end
    self.DataSource = {
        Source = MisDB2(config.persistance_dir) ---@type MisDB2
    }
    self.DataSource['Data'] = self.DataSource['Source']:Collection(config.name) ---@type MisDB2.Collection
    return self
end
---* Fetches a Value from this DataStore
---@param key string ConfigKey
---@return number|string|table|boolean ConfigValue
function DataStore:GetValue(key)
    local Cache = (self.DataSource['Data'] or {})
    return Cache.data[key]
end
---* Saves a Value to this DataStore
---@param key string ConfigKey
---@param value number|string|table|boolean Value
---@return boolean Successfull
function DataStore:SetValue(key, value)
    local Cache = (self.DataSource['Data'] or {})
    Cache.data[key] = value
    local res = self.DataSource.Data:Save()
    return res
end

MisDB2.DataStore = DataStore

RegisterModule('MisModding.Common.MisDB2', MisDB2)
return MisDB2
