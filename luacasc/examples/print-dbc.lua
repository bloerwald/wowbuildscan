local f = assert(arg[1], '[1] should be the DBC file name or path')
local h, dat = io.open(f, 'rb')
if h then
	dat = h:read('*a')
	h:close()
else
	local h = require("casc").open("http://eu.patch.battle.net/wow/#eu", {cache="./cache"})
	dat = h:readFile("DBFilesClient/" .. f)
end

local dbc, r, l = require("casc.dbc"), {}, {}
for a,t in dbc.rows(dat, '{*?}') do
	r[#r+1] = t
	for j=1,#t do
		local s = tostring(t[j])
		if #s > 99 then s = s:sub(1, 96) .. "..." end
		t[j], l[j] = s, math.max(l[j] or 0, #s, 4)
	end
end

local f = "%" .. table.concat(l, "s | %") .. "s"
local h = {}
for i=1,#r[1] do
	h[i] = "C" .. i
end
h = f:format(unpack(h))
print(h)
print(("-"):rep(#h))
for i=1, #r do
	print(f:format(unpack(r[i])))
end