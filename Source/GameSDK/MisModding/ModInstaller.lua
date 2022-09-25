-- Copyright (C) 2022 Theros < MisModding | SvalTek >
-- 
-- This file is part of ServerPluginLoader.
-- 
-- ServerPluginLoader is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- ServerPluginLoader is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with ServerPluginLoader.  If not, see <http://www.gnu.org/licenses/>.
local FileSystem = require 'MisModding.Common.FileSystem';
local toml = require 'MisModding.Common.toml';
local Class = require 'MisModding.Common.Class';
local Mod = require 'MisModding.ModInstaller.Mod';

--- MisModding ModInstaller API
---@class MisModding.ModInstaller
---@field Mods ModInstaller.Mod[]	All Registered Mods
---@field BaseDirectory string		ModInstallers Base Directory
---@field ConfigPath string			Path to the ModInstaller.toml
---@field ModDirectory string		ModInstallers Mod Directory
---@field Debug boolean				Enable Debug Messages
---@overload fun(baseDirectory:string):MisModding.ModInstaller
local ModInstaller = Class("MisModding.ModInstaller", {
	-- all registered mods
	Mods = {},
	-- modinstaller base directory
	BaseDirectory = "./ServerMods",
	-- path to the modinstaller.toml
	ConfigPath = "./ServerMods/ModInstaller.toml",
	-- modinstaller mods directory
	ModDirectory = "./ServerMods",
	-- modinstaller debug mode
	Debug = false
})

--- Create a new ModInstaller instance
---@param baseDirectory string	ModInstallers Base Directory
---@param modDirectory string	ModInstallers Mod Directory
function ModInstaller:new(baseDirectory, modDirectory)
	self.BaseDirectory = baseDirectory or self.BaseDirectory;
	self.ModDirectory = modDirectory or FileSystem.joinpath(self.BaseDirectory, "ServerMods");
	self.ConfigPath = FileSystem.joinpath(self.BaseDirectory, "ModInstaller.toml")
	self.Debug = false;
end

local function LoadConfig(configPath)
	local configFile, configFileError = FileSystem.readfile(configPath);
	if (configFileError) then return false, configFileError; end
	local config = toml.parse(configFile);
	if (not config) then return false, "Failed to parse config file" end
	return config, "Config loaded";
end

local DEFAULT_CONFIG = {
	Enabled = true,
	-- debug mode
	Debug = false,
}

function ModInstaller:LoadConfig()
	local config, configError = LoadConfig(self.ConfigPath);
	if (not config) then
		Log(string.format("Failed to load config: %s >> falling back to default config", configError));
		config = DEFAULT_CONFIG;
	end
	if config.Enabled then self.Enabled = config.Enabled; end
	if config.Debug then self.Debug = config.Debug; end
	return true, "Config loaded";
end

--- create a new mod
---@param modName string
---@param modVersion string
---@param modAuthor string
---@param modDescription string
---@return ModInstaller.Mod
function ModInstaller:CreateMod(modName, modVersion, modAuthor, modDescription)
	-- check if mod already exists
	for _, mod in pairs(self.Mods) do
		if mod.name == modName then error('Mod with name "' .. modName .. '" already exists!'); end
	end
	-- new mod
	local mod = Mod(modName, modVersion, modAuthor, modDescription) ---@type ModInstaller.Mod
	self.Mods[modName] = mod;
	return mod
end

--- Install content
---@param content ModInstaller.Content Content to install
---@param base_dir string Base directory to install to
local function InstallContent(content, base_dir)
	local target = FileSystem.joinpath(base_dir, content.path);
	if (content.kind == "directory") then
		if FileSystem.isDir(target) then
			Log(string.format('Content Directory: "%s", already exists, Skipping!', target));
		else
			Log(string.format('Content Directory: "%s", does not exist, Creating!', target));
			local dirCreated, dirErr = FileSystem.mkDir(target);
			if not dirCreated then return false, dirErr end
		end
		-- process sub contents
		for _, subContent in pairs(content.content) do
			local subContentInstalled, subContentErr = InstallContent(subContent, target);
			if not subContentInstalled then return false, subContentErr; end
		end
	elseif (content.kind == "file") then
		if not FileSystem.isFile(target) then
			--- create file
			Log(string.format('Content File: "%s", does not exist, Creating!', target));
			local fileWrittenOk, fileWriteErr = FileSystem.writefile(target, tostring(content.content));
			if not fileWrittenOk then return false, fileWriteErr; end
		else
			Log(string.format('Content File: "%s", already exists, Skipping!', target));
		end
	end
	return true, string.format('Content: "%s", installed!', target);
end

--- Install Mod
---@param modName string Mod to install
---@return boolean success		True if installation was successful
---@return string? error		Error message if installation failed
function ModInstaller:InstallMod(modName)
	local mod = self.Mods[modName];
	if mod == nil then error('Mod with name "' .. modName .. '" does not exist!'); end
	Log(string.format('Installing Mod: "%s" v%s', mod.name, mod.version));
	local installed, message = InstallContent(mod.content, self.ModDirectory);
	if not installed then error('Failed to install mod "' .. modName .. '"! - Error: ' .. message); end
	mod.installed = true;
	return installed, message;
end

RegisterModule("MisModding.ModInstaller", ModInstaller);
return ModInstaller;
