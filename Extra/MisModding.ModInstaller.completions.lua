---@diagnostic disable: lowercase-global
-- Copyright (C) 2022 Theros <MisModding|SvalTek>
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
local _M = {
	_NAME = "MisModding.ModInstaller.Completions",
	_VERSION = "0.1.0",
	_DESCRIPTION = "ModInstaller Completions for VSC sumneko.lua"
}

--- MisModding ModInstaller API
---@class MisModding.ModInstaller
---@field Mods ModInstaller.Mod[]	All Registered Mods
---@field BaseDirectory string		Directory where mods are located
---@overload fun(baseDirectory:string):MisModding.ModInstaller
local ModInstaller

--- Create a new ModInstaller instance
---@param baseDirectory string	Directory where mods are located
---@return MisModding.ModInstaller
function ModInstaller:new(baseDirectory) end

--- create a new mod
---@param modName string
---@param modVersion string
---@param modAuthor string
---@param modDescription string
---@return ModInstaller.Mod
function ModInstaller:CreateMod(modName, modVersion, modAuthor, modDescription) end

--- Install Mod
---@param modName string Mod to install
---@return boolean success		True if installation was successful
---@return string? error		Error message if installation failed
function ModInstaller:InstallMod(modName) end

---@type MisModding.ModInstaller
g_ModInstaller = ModInstaller('')