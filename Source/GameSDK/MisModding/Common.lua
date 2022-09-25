---@diagnostic disable: lowercase-global
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
local _M = {
	_VERSION = '0.0.1',
	_DESCRIPTION = 'MisModding Common Library',
	_URL = 'https://github.com/MisModding/CodeLibrary'
}

-- ───────────────────────────────────────────────────────────── COMMON TOOLS ─────
_ = nil -- ignore

if not g_Script_RunOnceCache then g_Script_RunOnceCache = {} end

function __FILE__(offset) return debug.getinfo(1 + (offset or 1), 'S').source end
function __LINE__(offset) return debug.getinfo(1 + (offset or 1), 'l').currentline end
--- trys to get the name of the function at current stack `offset`, default to the calling function
function __FUNC__(offset) return debug.getinfo(1 + (offset or 1), 'n').name end

-- @function OnlyRunOnce
---* Function Wrapper Explicitly ensures the Provided Function Only Runs Once (Does not work with anon funcs)
---@param f function
-- function to run
-- all Further parameters are passed to the Provided Function call.
function OnlyRunOnce(f, ...)
	local found
	for k, v in ipairs(g_Script_RunOnceCache) do if (v == f) then found = true end end
	if not found then
		table.insert(g_Script_RunOnceCache, f)
		return f(...)
	end
end

-- @function ServerOnly
---* Function Wrapper Explicitly ensures the Provided Function Only Runs on Server.
---@param f function
-- function to run
-- all Further parameters are passed to the Provided Function call.
function ServerOnly(f, ...) if System.IsEditor() or CryAction.IsDedicatedServer() then return f(...) end end

-- @function ClientOnly
---* Function Wrapper Explicitly ensures the Provided Function Only Runs on Client.
---@param f function
-- function to run
-- all Further parameters are passed to the Provided Function call.
function ClientOnly(f, ...) if System.IsEditor() or CryAction.IsClient() then return f(...) end end

function ScriptDir() return debug.getinfo(2).source:match('@?(.*/)') end

function isSteam64Id(query)
	if type(query) ~= 'string' then return false, 'must be a string' end
	if (string.len(query:gsub('%s', '')) ~= 17) then
		return false, 'string must be 17 characters'
	else
		local i = 1
		for c in string.gmatch(query, '.') do
			if (type(tonumber(c)) ~= 'number') then return false, 'failed to cast char: ' .. tostring(i) .. ' to number' end
			i = i + 1
		end
		return true, 'appears to be a steam id'
	end
end

---* Create a function that returns the value of t[k] ,
-- | The returned function is Bound to the Provided Table,Key.
--- @param t table      table to access
--- @param k any        key to return
--- @return function returned getter function
function bind_getter(t, k)
	return function()
		if (not type(t) == 'table') then
			return nil, 'Bound object is not a table'
		elseif (t == {}) then
			return nil, 'Bound table is Empty'
		elseif (t[k] == nil) then
			return nil, 'Bound Key does not Exist'
		else
			return t[k], 'Fetched Bound Key'
		end
	end
end

---* Create a function that sets the value of t[k] ,
---| The returned function is Bound to the Provided Table,Key ,
---| The argument passed to the returned function is used as the value to set.
--- @param t table       table to access
--- @param k table       key to set
--- @return function     returned setter function
function bind_setter(t, k)
	return function(v)
		if (not type(t) == 'table') then
			return nil, 'Bound object is not a table'
		elseif (t == {}) then
			return nil, 'Bound table is Empty'
		elseif (t[k] == nil) then
			return nil, 'Bound Key does not Exist'
		else
			t[k] = v
			return true, 'Set Bound Key'
		end
	end
end

---* Create a function that returns the value of t[k] ,
---| The argument passed to the returned function is used as the Key.
---@param t table           table to access
---@return function|nil     getter function
---@return string?          error message
function getter(t)
	if (not type(t) == 'table') then
		return nil, 'Bound object is not a table'
	elseif (t == {}) then
		return nil, 'Bound table is Empty'
	else
		return function(k) return t[k] end
	end
end

---* Create a function that sets the value of t[k] ,
---| The argument passed to the returned function is used as the Key.
---@param t table           table to access
---@return function|nil     setter function
---@return string?          error message
function setter(t)
	if (not type(t) == 'table') then
		return nil, 'Bound object is not a table'
	elseif (t == {}) then
		return nil, 'Bound table is Empty'
	else
		return function(k, v)
			t[k] = v
			return true
		end
	end
end

--
-- ──────────────────────────────────────────────────────────────────── EXTRA ─────
--

--- load and execute a lua script from a given path
function RequireFile(filename)
	local oldPackagePath = package.path
	package.path = './' .. filename .. ';' .. package.path
	local obj = require(filename)
	package.path = oldPackagePath
	if obj then
		return obj, 'success loading file from ' .. filename
	else
		return nil, 'Failed to Require file from path ' .. filename
	end
end

local function import_symbol(T, k, v, libname)
	local key = rawget(T, k)
	-- warn about collisions!
	if key and k ~= '_M' and k ~= '_NAME' and k ~= '_PACKAGE' and k ~= '_VERSION' then
		Log('warning: %s.%s will not override existing symbol', libname, k)
		return
	end
	rawset(T, k, v)
end

local function lookup_lib(T, t)
	for k, v in pairs(T) do if v == t then return k end end
	return '?'
end

local already_imported = {}

---* take a table and 'inject' it into the local namespace.
--- @param src table
-- The Table
--- @param dest  table
-- An optional destination table (defaults to callers environment)
function Import(src, dest)
	dest = dest or _G
	if type(src) == 'string' then src = require(src) end
	local libname = lookup_lib(dest, src)
	if already_imported[src] then return end
	already_imported[src] = libname
	for k, v in pairs(src) do import_symbol(dest, k, v, libname) end
end

local function Invoker(links, index)
	return function(...)
		local link = links[index]
		if not link then return end
		local continue = Invoker(links, index + 1)
		local returned = link(continue, ...)
		if returned then returned(function(_, ...) continue(...) end) end
	end
end

---* used to chain multiple functions/callbacks
-- Example
-- local function TimedText (seconds, text)
--     return function (go)
--         print(text)
--         millseconds = (seconds or 1) * 1000
--         Script.SetTimerForFunction(millseconds, go)
--     end
-- end
--
-- Chain(
--     TimedText(1, 'fading in'),
--     TimedText(1, 'showing splash screen'),
--     TimedText(1, 'showing title screen'),
--     TimedText(1, 'showing demo')
-- )()
---@return function chain
-- the cretedfunction chain
function Chain(...)
	local links = { ... }

	local function chain(...)
		if not (...) then return Invoker(links, 1)(select(2, ...)) end
		local offset = #links
		for index = 1, select('#', ...) do links[offset + index] = select(index, ...) end
		return chain
	end

	return chain
end

---* Serialise a Table and deseriase back again
---| supports basic functions
---@param payload table|string input table or string to serialise or deserialise
---@return string|table|false output serialised table as a string OR deserialised string as a table
--- OR false if failed
function SerialiseTable(payload)
	local szt = {}

	local function char(c) return ('\\%3d'):format(c:byte()) end
	local function szstr(s) return ('"%s"'):format(s:gsub('[^ !#-~]', char)) end
	local function szfun(f) return 'loadstring' .. szstr(string.dump(f)) end
	local function szany(...) return szt[type(...)](...) end

	local function sztbl(t, code, var)
		for k, v in pairs(t) do
			local ks = szany(k, code, var)
			local vs = szany(v, code, var)
			code[#code + 1] = ('%s[%s]=%s'):format(var[t], ks, vs)
		end
		return '{}'
	end

	local function memo(sz)
		return function(d, code, var)
			if var[d] == nil then
				var[1] = var[1] + 1
				var[d] = ('_[%d]'):format(var[1])
				local index = #code + 1
				code[index] = '' -- reserve place during recursion
				code[index] = ('%s=%s'):format(var[d], sz(d, code, var))
			end
			return var[d]
		end
	end

	szt['nil'] = tostring
	szt['boolean'] = tostring
	szt['number'] = tostring
	szt['string'] = szstr
	szt['function'] = memo(szfun)
	szt['table'] = memo(sztbl)

	local function serialize(d)
		local code = { 'local _ = {}' }
		local value = szany(d, code, { 0 })
		code[#code + 1] = 'return ' .. value
		if #code == 2 then
			return code[2]
		else
			return table.concat(code, '\n')
		end
	end
	if type(payload) == 'table' then
		return serialize(payload)
	elseif type(payload) == 'string' then
		local ret = loadstring(payload)
		if ret then return ret() end
	end
	return false
end

---@alias UUID string UniqueID
--- Generate a new UUID
--- using an improved randomseed function accouning for lua 5.1 vm limitations
--- Lua 5.1 has a limitation on the bitsize meaning that when using randomseed
--- numbers over the limit get truncated or set to 1 , destroying all randomness for the run
--- uses an assumed Lua 5.1 maximim bitsize of 32.
---@return UUID, number
function UUID()
	local bitsize = 32
	local initTime = os.time()
	local function better_randomseed(seed)
		seed = math.floor(math.abs(seed))
		if seed >= (2 ^ bitsize) then
			-- integer overflow, reduce  it to prevent a bad seed.
			seed = seed - math.floor(seed / 2 ^ bitsize) * (2 ^ bitsize)
		end
		math.randomseed(seed - 2 ^ (bitsize - 1))
		return seed
	end
	local uuidSeed = better_randomseed(initTime)
	local function UUID(prefix)
		local template = 'xyxxxxxx-xxyx-xxxy-yxxx-xyxxxxxxxxxx'
		local mutator = function(c)
			local v = (c == 'x') and math.random(0, 0xf) or math.random(8, 0xb)
			return string.format('%x', v)
		end
		return string.gsub(template, '[xy]', mutator)
	end
	return UUID(), uuidSeed
end

---* bind an argument to a type and throw an error if the provided param doesnt match at runtime.
-- Note this works in reverse of the normal assert in that it returns nil if the argumens provided are valid
-- if not the it either returns true plus and error message , or if it fails to grab debug info
--- @param idx number positonal index of the param to bind
--- @param val any the param to bind
--- @param tp string the params bound type
--- @usage
-- local test = function(somearg,str,somearg)
-- if assert_arg(2,str,'string') then
--    return
-- end
--
-- test(nil,1,nil) -> Invalid Param in [test()]> Argument:2 Type: number Expected: string
function assert_arg(idx, val, tp)
	if type(val) ~= tp then
		local fn = debug.getinfo(2, 'n')
		local msg = 'Invalid Param in [' .. fn.name .. '()]> ' ..
						            string.format('Argument:%s Type: %q Expected: %q', tostring(idx), type(val), tp)
		local test = function() error(msg, 4) end
		local rStat, cResult = pcall(test)
		if rStat then
			return true
		else
			return true, cResult
		end
	end
end

-- [Usable Methods]
-- ────────────────────────────────────────────────────────────────────────────────

--- Used to Register Modules/Classes
--- require doesnt work correctly with modules in pak files, this allows to register them so the can be required
---@param name string the name of the module
---@param object table|function the module table
---@return boolean success
---@return string? errorMsg
function RegisterModule(name, object)
	if (type(name) ~= 'string') or (name == ('' or ' ')) then
		return false, 'Invalid Name Passed to RegisterModule, (must be a string and not empty).'
	elseif (type(object) ~= 'table') or (object == {}) then
		return false, 'Invalid Module Passed to RegisterModule, (must be a table and not empty).'
	end

	if package.loaded[name] == nil then
		package.loaded[name] = object
		return true, 'Module Registered'
	end
	return false, "Module Already Registered"
end

--- Used to UnRegister Modules/Classes registered with RegisterModule
---@param name string the name of the module
---@return boolean success
---@return string? errorMsg
function UnRegisterModule(name)
	if (type(name) ~= 'string') or (name == ('' or ' ')) then
		return false, 'Invalid Name Passed to UnRegisterModule, (must be a string and not empty).'
	end

	if package.loaded[name] ~= nil then
		package.loaded[name] = nil
		return true, 'Module UnRegistered'
	end
	return false, "Module Not Registered"
end

--- Execute lua files in specified directory :: only for Unpacked files
--- you MUST use forward slashes and allways include a final `/` 
---@param folderPath string folder to load scripts from
function LoadScriptFolderEx(folderPath)
	---@diagnostic disable-next-line: undefined-global
	local files = System.ScanDirectory(folderPath, SCANDIR_FILES)
	for i, file in ipairs(files) do dofile(folderPath .. file) end
end

--- Iterate files in specified directory :: only for Unpacked files
--- you MUST use forward slashes and allways include a final `/` 
---@param folderPath string folder to load scripts from
---@param fn fun(fileName:string,index:number)
function IterateFolderEx(folderPath, fn)
	---@diagnostic disable-next-line: undefined-global
	local files = System.ScanDirectory(folderPath, SCANDIR_FILES)
	for index, fileName in ipairs(files) do fn(fileName, index) end
end

--- create a new lambda function
---@param expression string expression to evaluate
---@vararg string[] arguments to pass to the expression
---@return nil|fun(...:any):any
---@example
--- local add = lambda("a + b", {"a", "b"})
---
--- add(1, 2) -- 3
function lambda(expression,...)
	local args = {...}
	local fn = loadstring('return function('..table.concat(args,',')..') return '..expression..' end')
	if fn then
		return fn()
	end
	return nil
end

return _M
