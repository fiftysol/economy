local files = require("./files.lua")

print("v" .. require("./release.lua").version)

files.unload() -- called at the very end