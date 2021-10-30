local lfs = require("lfs")
local prepdir = require("prepdir")


local generate
function generate(settings, src, dest)
	-- Preprocess a file from src and send the output to dest, recursive.
	lfs.mkdir(dest)

	for file in lfs.dir(src) do
		if file ~= "." and file ~= ".." then
			local source = src .. "/" .. file
			local destination = dest .. "/" .. file

			if lfs.attributes(source).mode == "directory" then
				-- If it is a directory, we do this again
				generate(settings, source, destination)

			else
				-- Preprocess file
				local content = io.open(source):read("*a")

				local f = io.open(destination, "w")
				f:write(prepdir(content, settings))
				f:flush()
			end
		end
	end
end


local src, dest = "./src", "./release"
local vars = {
	DEBUG = false,
}
for i = 1, #arg, 2 do
	if arg[i] == "--debug" then
		vars.DEBUG = arg[i + 1] == "true"
	elseif arg[i] == "--src" then
		src = arg[i + 1]
	elseif arg[i] == "--dest" then
		dest = arg[i + 1]
	end
end

lfs.mkdir(dest)
generate(vars, src, dest)
