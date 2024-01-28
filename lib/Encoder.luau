--!strict
--!native

local BufferStream = require(script.Parent.BufferStream)

local Encoder = {}

function Encoder.encode(data: unknown): buffer
	if typeof(data) ~= "table" then
		error(`bad argument #1 to 'encode' (table expected, got {typeof(data)})`)
	end

	return Encoder.__encodeDocument(data :: any).buffer
end

local function int64_to_le_bytes(data: number)
	local low = data % 2 ^ 32
	local high = (data - low) / 2 ^ 32

	return string.char(
		low % 256,
		math.floor(low / 256) % 256,
		math.floor(low / 65536) % 256,
		math.floor(low / 16777216) % 256,
		high % 256,
		math.floor(high / 256) % 256,
		math.floor(high / 65536) % 256,
		math.floor(high / 16777216) % 256
	)
end

function Encoder.__encodeDocument(data: { [string]: unknown }): BufferStream.BufferStream
	local result = BufferStream.new()
	result:writei32(0)

	local function encode_e_name(name: string)
		Encoder.__encodeCString(result, name)
	end

	for k, v in data do
		if typeof(v) == "number" then
			if v % 1 == 0 then
				if v > 2_147_483_647 or -2_147_483_648 > v then
					result:writebytes("\x12")
					encode_e_name(k)
					result:writebytes(int64_to_le_bytes(v))
				else
					result:writebytes("\x10")
					encode_e_name(k)
					result:writei32(v)
				end
			else
				result:writebytes("\x01")
				encode_e_name(k)
				result:writef64(v)
			end
		elseif typeof(v) == "table" then
			if #(v :: { unknown }) > 0 then
				result:writebytes("\x04")
				encode_e_name(k)

				local newArr = {} :: { [string]: unknown }
				for k2, v2 in v :: { unknown } do
					newArr[tostring(k2)] = v2
				end

				result:writebytes(Encoder.__encodeDocument(newArr).buffer)
			else
				result:writebytes("\x03")
				encode_e_name(k)
				result:writebytes(Encoder.__encodeDocument(v :: any).buffer)
			end
		elseif typeof(v) == "string" then
			local length = utf8.len(v)

			if not length then
				error(`bad argument #1 to '__encodeDocument' (utf8 string expected, got {typeof(v)})`)
			end

			result:writebytes("\x02")
			encode_e_name(k)
			Encoder.__encodeString(result, v)
		elseif typeof(v) == "boolean" then
			result:writebytes("\x08")
			encode_e_name(k)
			result:writebytes(v and "\x01" or "\x00")
		elseif typeof(v) == "DateTime" then
			result:writebytes("\x09")
			encode_e_name(k)
			result:writef64(v.UnixTimestampMillis)
		elseif typeof(v) == "buffer" then
			result:writebytes("\x05")
			encode_e_name(k)
			result:writei32(buffer.len(v))
			result:writebytes("\x00")
			result:writebytes(v)
		else
			local d = tostring(v)
			local length = utf8.len(d)

			if not length then
				error(`bad argument #1 to '__encodeDocument' (utf8 string expected, got {typeof(v)})`)
			end

			result:writebytes("\x02")
			encode_e_name(k)
			Encoder.__encodeString(result, d)
		end
	end

	result:writebytes("\x00")
	result:writei32(result.length, 0)

	return result
end

function Encoder.__encodeString(stream: BufferStream.BufferStream, str: string)
	if typeof(stream) ~= "table" or stream.ClassName ~= "BufferStream" then
		error(`bad argument #1 to '__encodeCString' (BufferStream expected, got {typeof(stream)})`)
	end

	local length = utf8.len(str)

	if not length then
		error(`bad argument #1 to '__encodeCString' (utf8 string expected, got {typeof(str)})`)
	end

	stream:writei32(length + 1)
	stream:writebytes(str)
	stream:writebytes("\x00")
end

function Encoder.__encodeCString(stream: BufferStream.BufferStream, str: string)
	if typeof(stream) ~= "table" or stream.ClassName ~= "BufferStream" then
		error(`bad argument #1 to '__encodeCString' (BufferStream expected, got {typeof(stream)})`)
	end

	local length = utf8.len(str)

	if not length then
		error(`bad argument #1 to '__encodeCString' (utf8 string expected, got {typeof(str)})`)
	end

	stream:writebytes(str)
	stream:writebytes("\x00")
end

return Encoder
