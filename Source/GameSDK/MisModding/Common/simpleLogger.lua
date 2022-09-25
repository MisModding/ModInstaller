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
local _M = {_VERSION = '0.1.0', _DESCRIPTION = 'Simple logger for MisModding'}

local function simpleLogger(name, path, level, purge)
    if assert_arg(1, name, 'string') then
        return false, 'invalid Log name - Must be a String'
    end
    if assert_arg(2, path, 'string') then
        return false, 'invalid Log file path - Must be a String'
    end
    if (level == nil) then
        level = 1
    else
        if assert_arg(3, level, 'number') then
            return false, 'invalid Log Level - Must be a Number'
        end
    end

    ---@overload fun( name:string, path:string, logLevel:number ):simple_logger
    ---@class simple_logger
    local logger = {
        LOG_NAME = name,
        --- Path to File this Logger Writes to.
        LOG_FILE = path,
        --- this Loggers cuurrent Log Level
        LOG_LEVEL = level
    }

    local template = [[ ${name} [${level}:${prefix}] >> 
                ${content}"]]

    local logfile = {
        path = logger.LOG_FILE,
        update = function(self, line)
            local file = io.open(self.path, 'a+')
            if file then
                file:write(line .. '\n')
                file:close()
                return true, 'updated'
            end
            return false, 'failed to update file: ',
                   (self.path or 'invalid path')
        end,
        purge = function(self) os.remove(self.path) end
    }

    local function writer(logtype, source, message)
        local logname = logger['LOG_NAME'] or 'Logger'
        local line = string.expand(template, {
            name = logname,
            level = logtype,
            prefix = source,
            content = message
        })
        return logfile:update(os.date() .. '  >> ' .. line)
    end

    --- Writes a [Log] level entry to the mFramework log
    logger.Log = function(source, message)
        if not (logger.LOG_LEVEL >= 1) then return end
        return writer('LOG', source, message)
    end

    --- Writes a [Error] level entry to the mFramework log
    logger.Error = function(source, message)
        if not (logger.LOG_LEVEL >= 1) then return end
        return writer('ERROR', source, message)
    end

    --- Writes a [Warning] level entry to the mFramework log
    logger.Warn = function(source, message)
        if not (logger.LOG_LEVEL >= 2) then return end
        return writer('WARNING', source, message)
    end
    --- Writes a [Debug] level entry to the mFramework log
    logger.Debug = function(source, message)
        if (logger.LOG_LEVEL >= 3) then
            return writer('DEBUG', source, message)
        end
    end

    if purge then logfile:purge() end
    return logger
end

--- Create a new simple logger
--- ===
--- give it a name, a path to a file (relative tp serverDir), and a log level
--- * 1 = Log,
--- * 2 = Warn,
--- * 3 = Debug
---@param name string
---@param path string
---@param level number
---@return simple_logger|boolean logger instance or false
---@return string? message
function _M.new(name, path, level, purge)
    return simpleLogger(name, path, level, purge)
end

--- Creates a new simple logger instance
--- ===
--- give it a name, a path to a file (relative tp serverDir), and a log level
--- * 1 = Log,
--- * 2 = Warn,
--- * 3 = Debug
---@overload fun( name:string, path:string, logLevel?:number ):simple_logger|nil, string?
local SimpleLogger = setmetatable(_M, {
    __call = function(_, ...) return _M.new(...) end
})

RegisterModule('MisModding.Common.SimpleLogger', SimpleLogger)
return SimpleLogger