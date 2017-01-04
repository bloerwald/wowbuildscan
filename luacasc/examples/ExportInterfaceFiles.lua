local casc = require("casc")

local filter = {} do
	local code = arg[1] == 'code' or arg[1] == 'both' or arg[1] == nil
	local art = arg[1] == 'art' or arg[1] == 'both'
	filter.xml, filter.lua, filter.toc, filter.xsd = code, code, code, code
	filter.blp = art
end

print("If you have a local WoW installation, you can specify the path to its Data directory to avoid downloading redundant data.")
local localBase, ch = arg[2] or io.stdout:write("Local Data/ path: ") and io.read("*l")

if localBase and localBase ~= "" then
	ch = casc.open(localBase)
else
	ch = assert(casc.open("http://eu.patch.battle.net/wowt/#eu", {cache="./cache"}))
end

local dbcFileData = ch:readFile("DBFilesClient/FileData.dbc")

local dbc, files = require("casc.dbc"), {}
for i, name, path in dbc.rows(dbcFileData, '.ss') do
	if path:match("^[Ii][Nn][Tt][Ee][Rr][Ff][Aa][Cc][Ee][\\/]") and filter[(name:match("%.(...)$") or ""):lower()] then
		files[#files+1] = (path .. name):gsub("[/\\]+", "/")
	end
end

local l = setmetatable({}, {__index=function(s, a) s[a] = a:lower() return s[a] end})
table.sort(files, function(a, b) return l[a] < l[b] end)

local dirs = {}
for i=1,#files do
	local p = files[i]
	for ep in p:gmatch("()/") do
		local p = p:sub(1,ep-1)
		local lc, _, tc = p:lower(), p:match("[^/]+$"):gsub("[A-Z][a-z]", "%0")
		if (dirs[lc] and dirs[lc][1] or -1) < tc then
			dirs[lc] = {tc, p}
		end
	end
end

local plat, makeDirs = require("casc.platform"), {}
for k, v in pairs(dirs) do
	table.insert(makeDirs, v[2])
end
table.sort(makeDirs, function(a,b) return #a < #b end)
plat.mkdir("BlizzardInterfaceFiles")
for i=1,#makeDirs do
	plat.mkdir(plat.path("BlizzardInterfaceFiles", makeDirs[i]))
end

for i=1,#files do
	local f = files[i]
	local fixedCase = (files[i]:gsub("[^/]+()/", function(b)
		local s = f:sub(1,b-1)
		return dirs[s:lower()][2]:match("([^/]+/)$")
	end))
	local h = io.open(plat.path("BlizzardInterfaceFiles", fixedCase), "wb")
	h:write(ch:readFile(f))
	h:close()
	print(fixedCase)
end