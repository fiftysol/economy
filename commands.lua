-- Source for the commands in the bot (they reference this repo)
local src = discord.getData("economy-src")
if src and src ~= "" then
	src = json.decode(src)
else
	src = {
		branches = {},
		expires = 0,
	}
end

if os.time() >= src.expires then
	local repo = "fiftysol/economy"
	local head, body = discord.http("https://api.github.com/repos/" .. repo .. "/releases", {
		{
			"user-agent",
			"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/95.0.4638.54 Safari/537.36"
		}
	})
	local releases = json.decode(body)

	local branches = {}
	local release, branch, asset
	for i = 1, #releases do
		release = releases[i]
		branch = release.target_commitish

		if not branches[branch] then
			branches[branch] = {}
			for j = 1, #release.assets do
				asset = release.assets[j]
				branches[branch][asset.name] = asset.browser_download_url
			end
		end
	end

	src.branches = branches
	src.expires = os.time() + 3600
	discord.saveData("economy-src", json.encode(src))
end

local branch = "main"
if not discord.message.isDM then
	local channel = string.match(discord.message.link, "https://discord.com/channels/%d+/(%d+)")
	if channel == "474253217421721600" then -- #code-test
		branch = "develop"
	end
end

local head, body = discord.http(src.branches[branch]["dist.lua"])
local fnc, err = discord.load(body)
if not fnc then
	error(err)
end
return fnc()
