-- Just a simple script for github workflows to figure out
-- release information (like version)

local path = "./release/release"
for i = 1, #arg, 2 do
	if arg[i] == "--rel" then
		path = arg[i + 1]
	end
end

local release = require(path)
if release.debug then
	local version = release.version .. os.date(".%Y.%m.%d.%H.%M.%S.debug")
	local oldVersion = string.gsub(release.version, "%.", "%%.")

	local file = io.open(path .. ".lua")
	local content = file:read("*a")
	file:close()

	file = io.open(path .. ".lua", "w")
	file:write((string.gsub(
		content,
		"(version%s*=%s*[\"'])" .. oldVersion .. "([\"'])",
		"%1" .. version .. "%2",
		1
	)))
	file:flush()

	print("::set-output name=version::v" .. version)
else
	print("::set-output name=version::v" .. release.version)
end
