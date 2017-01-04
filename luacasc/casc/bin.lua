local M, sbyte, schar, sgsub, sformat, ssub = {}, string.byte, string.char, string.gsub, string.format, string.sub
local inf, nan, floor, min = math.huge, math.huge-math.huge, math.floor, math.min
local MAX_SLICE_SIZE = 4096
local CM do
	local ok, m = pcall(require, "casc.binc")
	CM = ok and m
end

local hexbin = {} for i=0,255 do
	local h, b = sformat("%02x", i), schar(i)
	hexbin[sformat("%02X", i)], hexbin[h], hexbin[b] = b, b, h
end

function M.uint16_le(s, pos)
	local a, b = sbyte(s, (pos or 0)+1, (pos or 0) + 2)
	return b*256 + a
end
function M.uint32_le(s, pos)
	local a, b, c, d = sbyte(s, (pos or 0)+1, (pos or 0) + 4)
	return d*256^3 + c*256^2 + b*256 + a
end
function M.uint16_be(s, pos)
	local a,b = sbyte(s, (pos or 0)+1, (pos or 0) + 2)
	return a*256 + b
end
function M.uint32_be(s, pos)
	local a,b,c,d = sbyte(s, (pos or 0)+1, (pos or 0) + 4)
	return a*256^3 + b*256^2 + c*256 + d
end
function M.uint40_be(s, pos)
	local a, b, c, d, e = sbyte(s, (pos or 0)+1, (pos or 0) + 5)
	return a*256^4 + b*256^3 + c*256^2 + d*256 + e
end
function M.float32_le(s, pos)
	local a, b, c, d = sbyte(s, (pos or 0) + 1, (pos or 0) + 4)
	local s, e, f = d > 127 and -1 or 1, (d % 128)*2 + (c > 127 and 1 or 0), a + b*256 + (c % 128)*256^2
	if e > 0 and e < 255 then
		return s * (1+f/2^23) * 2^(e-127)
	else
		return e == 0 and (s * f/2^23 * 2^-126) or f == 0 and (s * inf) or nan
	end
end
function M.int32_le(s, pos)
	local d, c, b, a = sbyte(s, (pos or 0)+1, (pos or 0) + 4)
	return a*256^3 + b*256^2 + c*256 + d - (a < 128 and 0 or 2^32)
end
function M.int64ish_le(s, pos)
	local a, b, c, d, e, f, g, h = sbyte(s, (pos or 0)+1, (pos or 0) + 8)
	return ((h % 128) * 256^7 + g * 256^6 + f*256^5 + e*256^4 + d*256^3 + c*256^2 + b*256 + a) * (h > 127 and -1 or 1)
end

function M.to_le32(n)
	local n = n % 2^32
	return schar(floor(n) % 256, floor(n / 256) % 256, floor(n / 256^2) % 256, floor(n / 256^3) % 256)
end

function M.to_bin(hs)
	return hs and sgsub(hs, "%x%x", hexbin)
end
function M.to_hex(bs)
	return bs and sgsub(bs, ".", hexbin)
end

M.sadd = CM and CM.sadd or function(a, ap, b, bp, length, out, on)
	local bsz, rx, unpack = #b, length, unpack or table.unpack
	while rx > 0 do
		if bp > bsz then
			out[on], on, bp, ap, rx = ssub(a, ap, ap+rx-1), on+1, bp + rx, ap + rx, 0
		else
			local slice = min(rx, bsz-bp+1, MAX_SLICE_SIZE)
			local t1, t2 = {sbyte(b, bp, bp+slice-1)}, {sbyte(a, ap, ap+slice-1)}
			for i=1,slice do
				t1[i] = (t1[i] + t2[i]) % 256
			end
			out[on], on, ap, bp, rx = schar(unpack(t1)), on+1, ap + slice, bp + slice, rx - slice
		end
	end
	return on
end

return M