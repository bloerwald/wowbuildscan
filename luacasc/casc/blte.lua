local M, plat, bin = {}, require("casc.platform"), require("casc.bin")
local uint32_le, uint32_be, decompress = bin.uint32_le, bin.uint32_be, plat.decompress

local string_cursor do
	local function read(self, n)
		local p = self.pos
		self.pos = p + n
		return self.str:sub(p, p+n-1)
	end
	local function seek(self, dir, n)
		assert(dir == 'cur', 'String cursor only supports relative seeks')
		self.pos = self.pos + n
	end
	function string_cursor(s)
		return {str=s, read=read, seek=seek, pos=1}
	end
end
local function closeAndReturn(h, ...)
	h:close()
	return ...
end

local function decodeChunk(chunk, s, e)
	local format = chunk:sub(s, s)
	if format == 'N' then
		return chunk:sub(s+1, e)
	elseif format == 'Z' then
		return decompress(chunk:sub(s+1, e))
	else
		return nil, 'Unknown BLTE chunk format: ' .. tostring(format)
	end
end
local function parseBLTE(h, dataSize)
	local header = h:read(8)
	if type(header) ~= "string" or header:sub(1,4) ~= 'BLTE' then
		-- TODO: this can throw if header is not a string or if there are fewer than 4 bytes
		return nil, ('expected BLTE signature; got %02x%02x%02x%02x'):format(header:byte(1,4))
	end
	local ofs = uint32_be(header, 4)
	
	local chunks, ret, err = ofs > 0 and {}
	if ofs > 0 then
		local sz, dsize = h:read(4), 0
		local buf, cn = h:read(uint32_be(sz) % 2^16 * 24), 1
		header = header .. sz .. buf
		if #header > ofs then
			return nil, 'BLTE header overread'
		end
		h:seek("cur", ofs-#header)
		for p=0, #buf-1, 24 do
			local sz = uint32_be(buf, p)
			chunks[cn], dsize, cn = sz, dsize + sz, cn + 1
		end
		local buf, p = h:read(dsize), 0
		for i=1, #chunks do
			p, chunks[i], err = p+chunks[i], decodeChunk(buf, p+1, p+chunks[i])
			if not chunks[i] then
				return nil, err
			end
		end
		ret = table.concat(chunks, "")
	else
		local chunk = h:read(dataSize-8)
		header, ret, err = header .. chunk, decodeChunk(chunk, 1, -1)
	end
	return ret, ret and header or err
end

function M.readArchive(path, offset)
	assert(type(path) == "string" and type(offset) == "number", 'Syntax: "content", "header" = blte.readArchive("path", offset)')

	local h, err = io.open(path, "rb")
	if not h then
		return nil, err
	end
	h:seek("set", offset)
	
	return closeAndReturn(h, parseBLTE(h, uint32_le(h:read(30), 16)-30))
end
function M.readData(str)
	assert(type(str) == "string", 'Syntax: "content", "header" = blte.readData("data")')
	return parseBLTE(string_cursor(str), #str)
end

return M