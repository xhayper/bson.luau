--!strict
--!native

local BufferStream = require(script.Parent.BufferStream)

local Decoder = {}

function Decoder.decode<T>(data: buffer | string): T
	local buf: buffer

	if typeof(data) == "buffer" then
		buf = data
	elseif typeof(data) == "string" then
		buf = buffer.fromstring(data)
	else
		error(`bad argument #1 to 'decode' (buffer or string expected, got {typeof(data)})`)
	end

	return (Decoder.__readDocument(buf) :: any) :: T
end

local function le_bytes_to_int64(bytes: string): number
	local b1, b2, b3, b4, b5, b6, b7, b8 = string.byte(bytes, 1, 8)

	local n = b1 + b2 * 2 ^ 8 + b3 * 2 ^ 16 + b4 * 2 ^ 24 + b5 * 2 ^ 32 + b6 * 2 ^ 40 + b7 * 2 ^ 48 + b8 * 2 ^ 56

	return n
end

function Decoder.__readDocument(data: buffer): { [string]: unknown }
	local result = {}

	local stream = BufferStream.new(data)
	local size = stream:readi32()

	repeat
		if stream:readbytes(1):tostring() == "\x00" and stream.byteOffset == size then
			break
		end
		stream.byteOffset -= 1

		if stream.byteOffset >= size then
			error("Can't find null terminator!")
		end

		local dataType = stream:readbytes(1):tostring()

		local key = Decoder.__readCString(stream)
		key = key:sub(1, -2)

		local resultData: unknown?

		-- double, int64
		if dataType == "\x01" or dataType == "\x12" then
			resultData = le_bytes_to_int64(stream:readbytes(8):tostring())
			-- string, JS Code, Symbol (Deprecated)
		elseif dataType == "\x02" or dataType == "\x0D" or dataType == "\x0E" then
			local len = stream:readi32()
			resultData = stream:readbytes(len):tostring()

			local lastByte = { string.byte(resultData :: string, len, len) }
			if 0 >= #lastByte or lastByte[1] ~= 0 then
				error("Invalid string!")
			end

			-- remove trailing \x00, we expect lua to not have \x00 in their string
			resultData = (dataType == "\x0E" and "(Symbol) " or "") .. (resultData :: string):sub(1, -2)
			-- Object (document)
		elseif dataType == "\x03" then
			local len = stream:readi32()
			stream.byteOffset -= 4
			local documentBuffer = stream:readbytes(len)
			resultData = Decoder.__readDocument(documentBuffer.buffer)
			-- Array (document)
		elseif dataType == "\x04" then
			local len = stream:readi32()
			stream.byteOffset -= 1
			local documentBuffer = stream:readbytes(len)
			local documentData = Decoder.__readDocument(documentBuffer.buffer)

			resultData = {}

			for k, v in documentData do
				local tryParse = tonumber(k)

				if not tryParse then
					error("Invalid array!")
				end

				(resultData :: { unknown })[tryParse] = v
			end
			-- Binary
		elseif dataType == "\x05" then
			local len = stream:readi32()
			stream:readbytes(1)
			resultData = stream:readbytes(len):tostring()

			-- undefined value (deprecated)
			--elseif dataType == "\x06" then
			-- resultData = nil
		elseif dataType == "\x07" then
			warn("TODO: ObjectId support")
			stream:readbytes(12)
			-- boolean
		elseif dataType == "\x08" then
			resultData = stream:readbytes(1):tostring() == "\x01"
			-- UTC date time
		elseif dataType == "\x09" then
			resultData = DateTime.fromUnixTimestampMillis(stream:readf32())
			-- unnessecary imo
			-- null value
			--elseif dataType == "\x0A" then
			-- resultData = nil
			-- Regex
		elseif dataType == "\x0B" then
			local pattern = Decoder.__readCString(stream)
			local options = Decoder.__readCString(stream)

			-- TODO: Add Regex class
			resultData = {
				pattern = pattern,
				options = options,
			}

			-- DBPointer (deprecated)
		elseif dataType == "\x0C" then
			local len = stream:readi32()
			stream:readbytes(len + 12)

			warn("DBPointer is deprecated and won't be implemented")

			-- code_w_s (deprecated)
		elseif dataType == "\x0F" then
			error("code_w_s is deprecated and too hard to implement")
		elseif dataType == "\x10" then
			resultData = stream:readi32()
		elseif dataType == "\x11" then
			-- First 4 bytes are an increment, second 4 are a timestamp.
			stream:readbytes(8)
			warn("TODO: timestamp support")
		elseif dataType == "\x13" then
			error("Decimal128 is not supported!")
		end

		result[key] = resultData

		if stream:readbytes(1):tostring() == "\x00" and stream.byteOffset == size then
			break
		end
	until false

	return result
end

function Decoder.__readCString(stream: BufferStream.BufferStream): string
	local str = ""

	repeat
		if stream.byteOffset >= stream.length then
			error("Can't find null terminator!")
		end

		local char = stream:readbytes(1):tostring()
		str = str .. char
	until char == "\x00"

	return str
end

return Decoder
