local M = {}

local jenkins96, bin = require("casc.jenkins96"), require("casc.bin")
local uint32_le, to_bin, ssub = bin.uint32_le, bin.to_bin, string.sub

local function toBinHash(h)
	return #h == 32 and to_bin(h) or h
end
local function noop() end

local wow_mt = {__index={}} do
	local wow = wow_mt.__index
	local function iter(e, i)
		i = (i or -1) + 2
		local h = e[i]
		if h then
			return i, h, e[i+1]
		end
	end
	function wow:getFileVariants(name)
		local e = self[1][jenkins96.hash_path(name)]
		return e and iter or noop, e
	end
	function wow:addFileVariant(path, chash, flags)
		local r, h = self[1], jenkins96.hash_path(path)
		local t = r[h] or {}
		r[h], t[#t+1], t[#t+2] = t, toBinHash(chash), flags
	end
end


function M.parse(data)
	local ret, pos, dl, sig = {}, 1, #data, uint32_le(data, 0)
	if sig * 28 + 23 > dl then
		return false, "Unsupported or corrupt root file"
	end
	while pos < dl do
		local n, info = uint32_le(data, pos-1), {uint32_le(data, pos+3), uint32_le(data, pos+7)}
		pos = pos + 12 + 4*n
		for i=1,n do
			local chash, nhash = ssub(data, pos, pos+15), ssub(data, pos+16, pos+23)
			local t, j = ret[nhash] or {}
			ret[nhash], j, pos = t, #t, pos + 24
			t[j+1], t[j+2] = chash, info
		end
	end
	return setmetatable({ret}, wow_mt)
end
function M.empty()
	return setmetatable({{}}, wow_mt)
end

return M