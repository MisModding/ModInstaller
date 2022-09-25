---@diagnostic disable: undefined-global
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
describe("ModInstaller", function()
	_G.Log = Log or print
	local FileSystem, toml;
	local ModInstaller, g_ModInstaller, MyMod, MyFile, MyDir;

	setup(function()
		require 'MisModding.Common';
		FileSystem = require 'MisModding.Common.FileSystem';
		toml = require 'MisModding.Common.toml';
		ModInstaller = require 'MisModding.ModInstaller';
		assert.is_truthy(ModInstaller)
	end)

	it("Require and Use ModInstaller", function()
		---@diagnostic disable-next-line: lowercase-global
		g_ModInstaller = ModInstaller("./spec", "./spec/output")
		assert.is_truthy(g_ModInstaller);
		assert.is_truthy(g_ModInstaller.CreateMod);
		assert.is_truthy(g_ModInstaller.Mods);
		assert.is_equal(g_ModInstaller.ModDirectory, "./spec/output");
	end)

	it("Load ModInstaller Config", function()
		local configLoaded, configErr = g_ModInstaller:LoadConfig()
		assert.is_truthy(configLoaded)
		print("Config Loaded: ", configErr)
		assert.is_equal(g_ModInstaller.Debug, true)
	end)

	it("Create a new Mod", function()
		MyMod = g_ModInstaller:CreateMod("TestMod", "1.0.0", "Theros", "Test Mod");
		assert.is_truthy(MyMod);
		assert.is_equal(MyMod.name, "TestMod");
		assert.is_equal(MyMod.version, "1.0.0");
		assert.is_equal(MyMod.author, "Theros");
		assert.is_equal(MyMod.description, "Test Mod");
		assert.is_truthy(MyMod.AddFile);
		assert.is_truthy(MyMod.AddDirectory);
	end)

	it("Add a Config file to the mod", function()
		local configStr = [[
Name = "TestMod"
Author = "Theros"
Description = "Test Mod"
Version = "1.0.0"

[Settings]
Enabled = true
Debug = false

[AutoLoad]
Enabled = true
Priority = 10

[Dependencies]
TestMod2 = "1.0.0"
]]
		local ConfigFile = MyMod:AddFile("config.toml", configStr)
		assert.is_truthy(ConfigFile)
		assert.is_equal(ConfigFile.path, "config.toml")
		assert.is_equal(ConfigFile.kind, "file")
	end)

	it("Add a new Directory to Created Mod", function()
		MyDir = MyMod:AddDirectory("TestDir");
		assert.is_truthy(MyDir);
		assert.is_equal(MyDir.path, "TestDir");
		assert.is_equal(MyDir.kind, "directory");
		assert.is_truthy(MyDir.AddFile);
	end)
	local testFileContent = [[
This is a test file!
With multiple lines!
Written by ModInstaller!
]]

	it("Add a new File to Created Directory", function()
		MyFile = MyDir:AddFile("TestFile.txt", testFileContent);
		assert.is_truthy(MyFile);
		assert.is_equal(MyFile.path, "TestFile.txt");
		assert.is_equal(MyFile.kind, "file");
		assert.is_equal(MyFile.content, testFileContent);
	end)

	it('Install Mod', function()
		assert.is_truthy(g_ModInstaller.Mods["TestMod"]);
		local installed, message = g_ModInstaller:InstallMod("TestMod");
		assert.is_truthy(installed);
		assert.is_truthy(g_ModInstaller.Mods["TestMod"].installed);
		print(message)
	end)

	it('Validate Installed Content', function()
		local ModFolderExists = FileSystem.isDir("./spec/output/TestMod");
		assert.is_truthy(ModFolderExists);
		local ModConfigFile = FileSystem.readfile("./spec/output/TestMod/config.toml");
		assert.is_truthy(ModConfigFile);
		local ModConfig = toml.parse(ModConfigFile);
		assert.is_truthy(ModConfig);
		assert.is_equal(ModConfig.Name, "TestMod");
		assert.is_equal(ModConfig.Version, "1.0.0");
		assert.is_truthy(ModConfig.Settings)
		assert.is_equal(ModConfig.Settings.Enabled, true);
		local TestDirExists = FileSystem.isDir("./spec/output/TestMod/TestDir");
		assert.is_truthy(TestDirExists);
		local TestFile = FileSystem.readfile("./spec/output/TestMod/TestDir/TestFile.txt");
		assert.is_equal(TestFile, testFileContent);
	end)
end)
