-- Just a simple script for github workflows to figure out
-- release information (like version)

local path = "./release/release.lua"
for i = 1, #arg, 2 do
	if arg[i] == "--rel" then
		path = arg[i + 1]
	end
end

local content = require(path)
print("::set-output name=version::v" .. content.version)
