-- Copyright (C) 2022 Theros < MisModding | SvalTek >
-- 
-- This file is part of ModInstaller.
-- 
-- ModInstaller is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- ModInstaller is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with ModInstaller.  If not, see <http://www.gnu.org/licenses/>.
local Class = require 'MisModding.Common.Class';
local FileSystem = require 'MisModding.Common.FileSystem';

---@class ModInstaller.Content : MisModding.Class
---@field path      string  The path to the content, relative to the mod's root directory
---@field kind      string  The kind of content, e.g. `file` or `directory`
---@field content   string|ModInstaller.Content  The content of the file or directory, this must be a string for files and an array of ModInstaller.Content for directories
local Content = Class('ModInstaller.Content', {})
function Content:__tostring()
    return string.format('Content(%s, %s)', self.path, self.kind)
end

--- Creates a new content object
---@param path string
---@param kind string
function Content:new(path, kind)
    self.path = path;
    self.kind = kind;
    self.content = {}
end

--- Adds a new file to the content
---@param path string
---@param content string
function Content:AddFile(path, content)
    if (self.kind ~= "directory") then error("Cannot add file to non-directory content!"); end
    local file = Content(path, 'file');
    file.content = content;
---@diagnostic disable-next-line: param-type-mismatch
    table.insert(self.content, file);
    return file;
end

--- Adds a new directory to the content
---@param path string
---@return ModInstaller.Content
function Content:AddDirectory(path)
    if (self.kind ~= "directory") then error("Cannot add directory to non-directory content!"); end
    local content = Content(path, 'directory');
---@diagnostic disable-next-line: param-type-mismatch
    table.insert(self.content, content);
    return content;
end


---@class ModInstaller.Mod : MisModding.Class
---@field name          string              The name of the mod
---@field version       string              The version of the mod
---@field description   string              The description of the mod
---@field content ModInstaller.Content      The content of the mod
local Mod = Class('ModInstaller.Mod', {})

--- ModInstaller Mod constructor
---@param name string
---@param version string
function Mod:new(name, version)
	if assert_arg(1, name, 'string') then error('name must be a string', 2) end
	self.name = name
	if assert_arg(3, version, 'string') then error('version must be a string', 2) end
	self.version = version
    self.content = Content(self.name, 'directory');
    -- has this mod been installed?
    self.installed = false;
end

--- Adds a new file to the mod
---@param path string
---@param content string
function Mod:AddFile(path, content)
    return self.content:AddFile(path, content);
end

--- Adds a new directory to the mod
---@param path string
---@return ModInstaller.Content
function Mod:AddDirectory(path)
    return self.content:AddDirectory(path);
end

RegisterModule('MisModding.ModInstaller.Mod', Mod)
return Mod