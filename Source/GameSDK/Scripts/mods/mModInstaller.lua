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
local _M = {
	__name = "mModInstaller",
	__version = "1.0.0",
	__author = "Theros [MisModding|SvalTek]",
	__description = "mModInstaller Loader",
	__license = "GPLv3"
}

-- load MisModding.Common
Script.ReloadScript 'MisModding/common.lua';
-- load common scripts/utils/classes
Script.LoadScriptFolder 'MisModding/Common';
Script.LoadScriptFolder 'MisModding/ModInstaller';
Script.ReloadScript 'MisModding/ModInstaller.lua';
local ModInstaller = require 'MisModding.ModInstaller';

-- Global ModInstaller instance
---@diagnostic disable-next-line: lowercase-global
g_ModInstaller = ModInstaller(".");
g_ModInstaller:LoadConfig();
