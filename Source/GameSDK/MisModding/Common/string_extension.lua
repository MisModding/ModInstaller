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
--- safely escape a given string

---@param str string    string to escape
string.escape = function(str)
    return str:gsub('([%^%$%(%)%%%.%[%]%*%+%-%?])', '%%%1')
end

--- Split a string at a given string as delimeter (defaults to a single space)
-- | local str = string.split('string | to | split', ' | ') -- split at ` | `
-- >> str = {"string", "to", "split"}
---@param str string        string to split
---@param delimiter string  optional delimiter, defaults to " "
string.split = function(str, delimiter)
    local result = {}
    local from = 1
    local delim = delimiter or ' '
    local delim_from, delim_to = string.find(str, delim, from)
    while delim_from do
        table.insert(result, string.sub(str, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(str, delim, from)
    end
    table.insert(result, string.sub(str, from))
    return result
end

--- extracts key=value styled arguments from a given string
---@param str string string to extract args from
---@return table args table containing any found key=value patterns
string.kvargs = function(str)
    local t = {}
    for k, v in string.gmatch(str, '(%w+)=(%w+)') do t[k] = v end
    return t
end

--- expand a string containing any `${var}` or `$var`.
--- Substitution values should be only numbers or strings.
--- @param s string the string
--- @param subst any either a table or a function (as in `string.gsub`)
--- @return string expanded string
function string.expand(s, subst)
    local res, k = s:gsub('%${([%w_]+)}', subst)
    if k > 0 then return res end
    return (res:gsub('%$([%w_]+)', subst))
end

function string.fromHex(str)
    return
        (str:gsub('..', function(cc) return string.char(tonumber(cc, 16)) end))
end

function string.toHex(str)
    return (str:gsub('.', function(c)
        return string.format('%02X', string.byte(c))
    end))
end

function string.ToTable(str)
    local tbl = {}

    for i = 1, string.len(str) do tbl[i] = string.sub(str, i, i) end

    return tbl
end

function string.SetChar(s, k, v)

    local start = s:sub(0, k - 1)
    local send = s:sub(k + 1)

    return start .. v .. send

end

function string.GetChar(s, k) return s:sub(k, k) end

function string.getEpochTime(epoch)
    local time = os.date('*t', epoch)
    return string.format('%d/%d/%d %d:%d:%d', time.month, time.day, time.year,
                         time.hour, time.min, time.sec)
end

function string.deserialiseTime(time)
    local year, month, day, hour, min, sec = time:match(
                                                 '(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+)')
    return os.time {
        year = year,
        month = month,
        day = day,
        hour = hour,
        min = min,
        sec = sec
    }
end

function string.serialiseTime(time) return os.date('%Y-%m-%d %H:%M:%S', time) end

--[[-----------------------------------------------------------------
        Name: FormattedTime( TimeInSeconds, Format )
        Desc: Given a time in seconds, returns formatted time
                If 'Format' is not specified the function returns a table
                conatining values for hours, mins, secs, ms
        Examples: string.FormattedTime( 123.456, "%02i:%02i:%02i")	==> "02:03:45"
                  string.FormattedTime( 123.456, "%02i:%02i")		==> "02:03"
                  string.FormattedTime( 123.456, "%2i:%02i")		==> " 2:03"
                  string.FormattedTime( 123.456 )					==> { h = 0, m = 2, s = 3, ms = 45 }
    -------------------------------------------------------------------]]
function string.FormattedTime(seconds, format)
    if (not seconds) then seconds = 0 end
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds / 60) % 60)
    local millisecs = (seconds - math.floor(seconds)) * 100
    seconds = math.floor(seconds % 60)

    if (format) then
        return string.format(format, minutes, seconds, millisecs)
    else
        return {h = hours, m = minutes, s = seconds, ms = millisecs}
    end
end

--[[---------------------------------------------------------
    Name: Old time functions
    -----------------------------------------------------------]]
function string.ToMinutesSecondsMilliseconds(TimeInSeconds)
    return string.FormattedTime(TimeInSeconds, '%02i:%02i:%02i')
end
function string.ToMinutesSeconds(TimeInSeconds)
    return string.FormattedTime(TimeInSeconds, '%02i:%02i')
end

local function pluralizeString(str, quantity)
    return str .. ((quantity ~= 1) and 's' or '')
end

function string.NiceTime(seconds)

    if (seconds == nil) then return 'a few seconds' end

    if (seconds < 60) then
        local t = math.floor(seconds)
        return t .. pluralizeString(' second', t)
    end

    if (seconds < 60 * 60) then
        local t = math.floor(seconds / 60)
        return t .. pluralizeString(' minute', t)
    end

    if (seconds < 60 * 60 * 24) then
        local t = math.floor(seconds / (60 * 60))
        return t .. pluralizeString(' hour', t)
    end

    if (seconds < 60 * 60 * 24 * 7) then
        local t = math.floor(seconds / (60 * 60 * 24))
        return t .. pluralizeString(' day', t)
    end

    if (seconds < 60 * 60 * 24 * 365) then
        local t = math.floor(seconds / (60 * 60 * 24 * 7))
        return t .. pluralizeString(' week', t)
    end

    local t = math.floor(seconds / (60 * 60 * 24 * 365))
    return t .. pluralizeString(' year', t)

end

local charset = {}
do -- [0-9a-zA-Z]
    for c = 48, 57 do table.insert(charset, string.char(c)) end
    for c = 65, 90 do table.insert(charset, string.char(c)) end
    for c = 97, 122 do table.insert(charset, string.char(c)) end
end

---* Cleans Eccess quotes from input string
function string.strip(inputString)
    local result
    result = inputString:gsub('^"', ''):gsub('"$', '')
    result = result:gsub('^\'', ''):gsub('\'$', '')
    return result
end

--- generate a random string with a given length
---@param	length number num chars to generate
---@return	string
function string.random(length)
    if not length or length <= 0 then return '' end
    math.randomseed(os.clock() ^ 5)
    return string.random(length - 1) .. charset[math.random(1, #charset)]
end
