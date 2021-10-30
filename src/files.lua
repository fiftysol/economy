local utils = require("./utils.lua")
local loaded = {}

local debugFileFormat = "debug-economy-%s-%d"
local mainFileFormat = "economy-%s-%d"
@#IF DEBUG
local fileFormat = debugFileFormat
@#ELSE
local filePrefix = mainFileFormat
@#END

local actions = {
	-- keeps track of what has been done until now
	loaded = false,
	unloaded = false,
	debug = false,
}

local function load(name, default)
	if loaded[name] then
		return loaded[name]
	end
	if actions.unloaded then
		error("Can not load files after some have been unloaded.", 2)
	end
	if actions.debug then
		error("Can not do any action with files after wiping or restoring the debug db.", 2)
	end
	actions.loaded = true

	local count = tonumber(discord.getData(string.format(fileFormat, name, 0)))
	local content = default
	if count then
		content = {}
		for i = 1, count do
			content[i] = discord.getData(string.format(fileFormat, name, i))
		end
		content = table.concat(content, "", 1, count)
	end

	loaded[name] = setmetatable({
		__modified = not count, -- if used default, set modified to true
		__content = content,
	}, {
		__newindex = function(self, key, value)
			rawset(content, key, value)
			self.__modified = true
		end,
		__index = content,
		__pairs = function()
			return next, content
		end,
		__len = function()
			return #content
		end,
	})
	return loaded[name]
end

local function unload()
	if actions.debug or actions.unloaded or not actions.loaded then
		-- if debug has been wiped or restored, don't unload
		-- don't unload if already unloaded
		-- don't unload if nothing has been loaded
		return
	end
	actions.unloaded = true

	-- list of all files, just in case we need a backup
	-- or we need to dump all our files from production to debug
	local list = load("file-list", {})
	for name in next, loaded do
		list[name] = true
	end

	local slices
	for name, data in next, loaded do
		if data.__modified then
			slices = utils.splitText(json.encode(data), 8000)

			discord.saveData(string.format(fileFormat, name, 0), #slices)
			for i, slice in next, slices do
				discord.saveData(string.format(fileFormat, name, i), slice)
			end
		end
	end
end

local function wipeDebug()
	if actions.loaded then
		error("Can not wipe debug database after loading a file", 2)
	end
	if actions.debug then
		error("Can not wipe debug database after wiping or restoring debug DB", 2)
	end

	local list = load("file-list", {})
	actions.loaded = false
	actions.debug = true

	for name in next, list do
		-- just set all file counts to 0
		discord.saveData(string.format(debugFileFormat, name, 0), "")
	end
end

local function restoreDebug()
	if actions.loaded then
		error("Can not restore debug database after loading a file", 2)
	end
	if actions.debug then
		error("Can not restore debug database after wiping or restoring debug DB", 2)
	end

	local list = load("file-list", {})
	actions.loaded = false
	actions.debug = true

	for name in next, list do
		local count = tonumber(discord.getData(string.format(mainFileFormat, name, 0)))
		if not count then count = 0 end

		discord.saveData(string.format(debugFileFormat, name, 0), count)
		for i = 1, count do
			discord.saveData(
				string.format(debugFileFormat, name, i),
				discord.getData(string.format(mainFileFormat, name, i))
			)
		end
	end
end

return {
	load = load,
	unload = unload,

	debug = {
		wipe = wipeDebug,
		restore = restoreDebug,
	},
}