local M, bin = {}, require("casc.bin")

local uint32_le, int32_le, float32_le = bin.uint32_le, bin.int32_le, bin.float32_le

local function guessType(s, first, stride, rows, sbase)
	if rows < 1 then return "u" end
	local t, sc, ic, fc, sl = {}, 0, 0, 0, sbase and (#s - sbase) or 0
	for i=-5,4 do t[i % rows] = 1 end
	for i=10, rows-5, math.max(1, math.min(10, (rows - rows % 10)/10)) do t[i] = 1 end
	for r in pairs(t) do
		local p = first + stride*r
		local uv, fv = uint32_le(s, p), float32_le(s, p)
		if uv ~= 0 then
			if uv < sl and s:match("^%z%Z", sbase + uv - 1) and uv >= 10 then
				sc, ic = sc + 1, ic - 1
			else
				fv = math.abs(fv)
				sc, ic, fc = sc - 1, ic + 1, fc + (fv >= 1e-7 and fv <= 1e7 and 1 or -1)
			end
		end
	end
	return sc > ic and "s" or (fc > 0 and fc >= ic/1.25 and "f" or "i")
end

local function unpacker(data, format, rows, stride, hsize, sbase, tfunc)
	tfunc = type(tfunc) == "function" and tfunc or nil
	
	local skip, p, n = 0, {[=[-- casc.dbc:iterator
		local smatch, uint32_le, int32_le, float32_le, tfunc, data, rows, stride, sbase, rpos, i = ...
		return function()
			if i < rows then
				rpos, i = rpos + stride, i + 1
				return ]=] .. (tfunc and "tfunc(i" or "i")}, 2
	local openTables = 0
	
	for r, t in format:gmatch("(%*?%d*)(.)") do
		for i=1,r == '*' and (stride-skip)/4 or tonumber(r) or 1 do
			local t = t == '?' and guessType(data, hsize + skip, stride, rows, sbase) or t
			if t == '.' then
				skip = skip + 4
			elseif t == '{' then
				p[n], n, openTables = '{', n + 1, openTables + 1
			elseif t == '}' then
				assert(openTables > 0, 'invalid signature: no table to close here')
				for j=n-1, 2, -1 do
					if p[j] == '{' then
						p[j], n, openTables = '{' .. table.concat(p, ', ', j+1, n-1) .. '}', j + 1, openTables - 1
						break
					end
				end
			elseif t == 'u' then
				p[n], n, skip = 'uint32_le(data, rpos+' .. skip .. ')', n + 1, skip + 4
			elseif t == 'i' then
				p[n], n, skip = 'int32_le(data, rpos+' .. skip .. ')', n + 1, skip + 4
			elseif t == 'f' then
				p[n], n, skip = 'float32_le(data, rpos+' .. skip .. ')', n + 1, skip + 4
			elseif t == 's' then
				assert(sbase, "invalid signature: 's' requires a string block")
				p[n], n, skip = 'smatch(data, "%Z*", sbase + uint32_le(data,rpos+' .. skip .. '))', n + 1, skip + 4
			else
				error('Unknown signature field type "' .. t .. '"')
			end
		end
	end
	assert(openTables == 0, 'invalid signature: missing closing table marker' .. (openTables > 1 and "s" or ""))
	p = table.concat(p, ", ", 1, n-1) .. (tfunc and ")" or "") .. '\nend\nend'
	
	return (loadstring or load)(p)(string.match, uint32_le, int32_le, float32_le,
		tfunc, data, rows, stride, sbase, hsize - stride, 0), skip
end

local header do
	local function dbc(data)
		assert(data:sub(1,4) == "WDBC", "DBC magic signature")
		local rows, fields, stride, stringSize = uint32_le(data, 4), uint32_le(data, 8), uint32_le(data, 12), uint32_le(data, 16)
		assert(20 + rows*stride + stringSize <= #data, "Data too short")
	
		return rows, fields, stride, 20, 21 + rows * stride
	end
	local function db2(data)
		local hsize = 48
		local rows, fields, stride, stringSize = uint32_le(data, 4), uint32_le(data, 8), uint32_le(data, 12), uint32_le(data, 16)
		local build, minId, maxId, locale, rid = uint32_le(data, 24), uint32_le(data, 32), uint32_le(data, 36), uint32_le(data, 40)
	
		if maxId > 0 then
			local n, p = maxId-minId + 1, hsize
			rid, hsize = {}, hsize + 6 * n
			for i=1,n do
				rid[i], p = uint32_le(data, p), p + 6
			end
		end
		assert(hsize + rows*stride + stringSize <= #data, "Data too short")
	
		return rows, fields, stride, hsize, hsize + 1 + rows * stride, rid, minId, maxId, build, locale
	end
	header = {WDBC=dbc, WDB2=db2, WCH2=db2}
end

function M.header(data)
	assert(type(data) == "string", 'Syntax: casc.dbc.header("data")')
	local fourCC = data:sub(1,4)
	return assert(header[fourCC], "Unsupported format")(data)
end

function M.rows(data, sig, loose)
	assert(type(data) == "string" and type(sig) == "string", 'Syntax: casc.dbc.rows("data", "rowSignature"[, loose])')
	
	local rows, _, stride, hsize, sbase, rid = M.header(data)
	local iter, skip = unpacker(data, sig, rows, stride, hsize, sbase, rid and function(i, ...) return rid[i], ... end)
	assert(skip <= stride, 'signature exceeds stride')
	assert(loose or skip == stride, 'signature/stride mismatch')

	return iter
end

return M