--!strict
--!native

local BufferStream = {}
BufferStream.ClassName = "BufferStream"
BufferStream.__index = BufferStream

type BufferStreamImpl = {
	__index: BufferStreamImpl,
	__tostring: (self: BufferStream) -> string,

	new: (buffer: (buffer | string)?) -> BufferStream,

	-------------------------------

	expand: (self: BufferStream, length: number) -> (),

	-------------------------------

	readf32: (self: BufferStream, offset: number?) -> number,
	readf64: (self: BufferStream, offset: number?) -> number,
	readi16: (self: BufferStream, offset: number?) -> number,
	readi32: (self: BufferStream, offset: number?) -> number,
	readi8: (self: BufferStream, offset: number?) -> number,
	readbytes: (self: BufferStream, length: number, offset: number?) -> BufferStream,
	readu16: (self: BufferStream, offset: number?) -> number,
	readu32: (self: BufferStream, offset: number?) -> number,
	readu8: (self: BufferStream, offset: number?) -> number,

	---------------------------------

	writef32: (self: BufferStream, value: number, offset: number?) -> (),
	writef64: (self: BufferStream, value: number, offset: number?) -> (),
	writei16: (self: BufferStream, value: number, offset: number?) -> (),
	writei32: (self: BufferStream, value: number, offset: number?) -> (),
	writei8: (self: BufferStream, value: number, offset: number?) -> (),
	writebytes: (self: BufferStream, value: buffer | string, offset: number?) -> (),
	writeu16: (self: BufferStream, value: number, offset: number?) -> (),
	writeu32: (self: BufferStream, value: number, offset: number?) -> (),
	writeu8: (self: BufferStream, value: number, offset: number?) -> (),

	---------------------------------

	slice: (self: BufferStream, start: number, finish: number?) -> BufferStream,

	tostring: (self: BufferStream) -> string,
}

type BufferStreamProto = {
	ClassName: "BufferStream",

	-------------------------------

	length: number,
	buffer: buffer,
	byteOffset: number,
}

export type BufferStream = typeof(setmetatable({} :: BufferStreamProto, {} :: BufferStreamImpl))

function BufferStream.new(data: (buffer | string)?): BufferStream
	local self = setmetatable({} :: BufferStreamProto, BufferStream)
	self.byteOffset = 0

	local buf

	if data and typeof(data) == "string" then
		buf = buffer.fromstring(data)
	elseif data and typeof(data) == "buffer" then
		buf = buffer.create(buffer.len(data))
		buffer.copy(buf, 0, data)
	elseif data then
		error(`bad argument #1 to 'new' (buffer or string expected, got {typeof(data)})`)
	else
		buf = buffer.create(0)
	end

	self.buffer = buf
	self.length = buffer.len(buf)

	return self
end

function BufferStream.expand(self: BufferStream, length: number)
	local newLength = self.length + length
	local newBuf = buffer.create(newLength)
	buffer.copy(newBuf, 0, self.buffer, 0)
	self.buffer = newBuf
	self.length = newLength
end

-------------------------------------------------------------------------------

function BufferStream.readf32(self: BufferStream, offset: number?): number
	local value = buffer.readf32(self.buffer, offset or self.byteOffset)
	if not offset then
		self.byteOffset += 4
	end
	return value
end

function BufferStream.readf64(self: BufferStream, offset: number?): number
	local value = buffer.readf64(self.buffer, offset or self.byteOffset)
	if not offset then
		self.byteOffset += 8
	end
	return value
end

function BufferStream.readi16(self: BufferStream, offset: number?): number
	local value = buffer.readi16(self.buffer, offset or self.byteOffset)
	if not offset then
		self.byteOffset += 2
	end
	return value
end

function BufferStream.readi32(self: BufferStream, offset: number?): number
	local value = buffer.readi32(self.buffer, offset or self.byteOffset)
	if not offset then
		self.byteOffset += 4
	end
	return value
end

function BufferStream.readi8(self: BufferStream, offset: number?): number
	local value = buffer.readi8(self.buffer, offset or self.byteOffset)
	if not offset then
		self.byteOffset += 1
	end
	return value
end

function BufferStream.readbytes(self: BufferStream, length: number, offset: number?): BufferStream
	local value = buffer.readstring(self.buffer, offset or self.byteOffset, length)
	if not offset then
		self.byteOffset += length
	end
	return BufferStream.new(value)
end

function BufferStream.readu16(self: BufferStream, offset: number?): number
	local value = buffer.readu16(self.buffer, offset or self.byteOffset)
	if not offset then
		self.byteOffset += 2
	end
	return value
end

function BufferStream.readu32(self: BufferStream, offset: number?): number
	local value = buffer.readu32(self.buffer, offset or self.byteOffset)
	if not offset then
		self.byteOffset += 4
	end
	return value
end

function BufferStream.readu8(self: BufferStream, offset: number?): number
	local value = buffer.readu8(self.buffer, offset or self.byteOffset)
	if not offset then
		self.byteOffset += 1
	end
	return value
end

-------------------------------------------------------------------------------

function BufferStream.writef32(self: BufferStream, value: number, offset: number?): ()
	if typeof(value) ~= "number" then
		error(`bad argument #1 to 'writef32' (number expected, got {typeof(value)})`)
	end

	if value < -3.4028234663852886e+38 or value > 3.4028234663852886e+38 then
		error(
			"bad argument #1 to 'writef32' (number must be between -3.4028234663852886e+38 and 3.4028234663852886e+38)"
		)
	end

	if offset and typeof(offset) ~= "number" then
		error(`bad argument #2 to 'writef32' (number expected, got {typeof(offset)})`)
	end

	if offset and offset % 1 ~= 0 then
		error("bad argument #2 to 'writef32' (number must be an integer)")
	end

	local offsetToUse = offset or self.byteOffset

	if offsetToUse + 4 > self.length then
		self:expand((offsetToUse + 4) - self.length)
	end

	buffer.writef32(self.buffer, offsetToUse, value)

	if not offset then
		self.byteOffset += 4
	end
end

function BufferStream.writef64(self: BufferStream, value: number, offset: number?): ()
	if typeof(value) ~= "number" then
		error(`bad argument #1 to 'writef64' (number expected, got {typeof(value)})`)
	end

	if value < -1.7976931348623157e+308 or value > 1.7976931348623157e+308 then
		error(
			"bad argument #1 to 'writef64' (number must be between -1.7976931348623157e+308 and 1.7976931348623157e+308)"
		)
	end

	if offset and typeof(offset) ~= "number" then
		error(`bad argument #2 to 'writef64' (number expected, got {typeof(offset)})`)
	end

	if offset and offset % 1 ~= 0 then
		error("bad argument #2 to 'writef64' (number must be an integer)")
	end

	local offsetToUse = offset or self.byteOffset

	if offsetToUse + 8 > self.length then
		self:expand((offsetToUse + 8) - self.length)
	end

	buffer.writef64(self.buffer, offsetToUse, value)

	if not offset then
		self.byteOffset += 8
	end
end

function BufferStream.writei16(self: BufferStream, value: number, offset: number?): ()
	if typeof(value) ~= "number" then
		error(`bad argument #1 to 'writei16' (number expected, got {typeof(value)})`)
	end

	if value < -32768 or value > 32767 then
		error("bad argument #1 to 'writei16' (number must be between -32768 and 32767)")
	end

	if offset and typeof(offset) ~= "number" then
		error(`bad argument #2 to 'writei16' (number expected, got {typeof(offset)})`)
	end

	if offset and offset % 1 ~= 0 then
		error("bad argument #2 to 'writei16' (number must be an integer)")
	end

	local offsetToUse = offset or self.byteOffset

	if offsetToUse + 2 > self.length then
		self:expand((offsetToUse + 2) - self.length)
	end

	buffer.writei16(self.buffer, offsetToUse, value)

	if not offset then
		self.byteOffset += 2
	end
end

function BufferStream.writei32(self: BufferStream, value: number, offset: number?): ()
	if typeof(value) ~= "number" then
		error(`bad argument #1 to 'writei32' (number expected, got {typeof(value)})`)
	end

	if value < -2147483648 or value > 2147483647 then
		error("bad argument #1 to 'writei32' (number must be between -2147483648 and 2147483647)")
	end

	if offset and typeof(offset) ~= "number" then
		error(`bad argument #2 to 'writei32' (number expected, got {typeof(offset)})`)
	end

	if offset and offset % 1 ~= 0 then
		error("bad argument #2 to 'writei32' (number must be an integer)")
	end

	local offsetToUse = offset or self.byteOffset

	if offsetToUse + 4 > self.length then
		self:expand((offsetToUse + 4) - self.length)
	end

	buffer.writei32(self.buffer, offsetToUse, value)

	if not offset then
		self.byteOffset += 4
	end
end

function BufferStream.writei8(self: BufferStream, value: number, offset: number?): ()
	if typeof(value) ~= "number" then
		error(`bad argument #1 to 'writei8' (number expected, got {typeof(value)})`)
	end

	if value < -128 or value > 127 then
		error("bad argument #1 to 'writei8' (number must be between -128 and 127)")
	end

	if offset and typeof(offset) ~= "number" then
		error(`bad argument #2 to 'writei8' (number expected, got {typeof(offset)})`)
	end

	if offset and offset % 1 ~= 0 then
		error("bad argument #2 to 'writei8' (number must be an integer)")
	end

	local offsetToUse = offset or self.byteOffset

	if offsetToUse + 1 > self.length then
		self:expand((offsetToUse + 1) - self.length)
	end

	buffer.writei8(self.buffer, offsetToUse, value)

	if not offset then
		self.byteOffset += 1
	end
end

function BufferStream.writebytes(self: BufferStream, value: buffer | string, offset: number?): ()
	local str: string = ""

	if typeof(value) == "buffer" then
		str = buffer.tostring(value)
	elseif typeof(value) == "string" then
		str = value
	else
		error(`bad argument #1 to 'writebytes' (buffer or string expected, got {typeof(value)})`)
	end

	if offset and typeof(offset) ~= "number" then
		error(`bad argument #2 to 'writebytes' (number expected, got {typeof(offset)})`)
	end

	if offset and offset % 1 ~= 0 then
		error("bad argument #2 to 'writebytes' (number must be an integer)")
	end

	local offsetToUse = offset or self.byteOffset

	if offsetToUse + #str > self.length then
		self:expand((offsetToUse + #str) - self.length)
	end

	buffer.writestring(self.buffer, offsetToUse, str)

	if not offset then
		self.byteOffset += #str
	end
end

function BufferStream.writeu16(self: BufferStream, value: number, offset: number?): ()
	if typeof(value) ~= "number" then
		error(`bad argument #1 to 'writeu16' (number expected, got {typeof(value)})`)
	end

	if value < 0 or value > 0xFFFF then
		error("bad argument #1 to 'writeu16' (number must be between 0 and 65535)")
	end

	if offset and typeof(offset) ~= "number" then
		error(`bad argument #2 to 'writeu16' (number expected, got {typeof(offset)})`)
	end

	if offset and offset % 1 ~= 0 then
		error("bad argument #2 to 'writeu16' (number must be an integer)")
	end

	local offsetToUse = offset or self.byteOffset

	if offsetToUse + 2 > self.length then
		self:expand((offsetToUse + 2) - self.length)
	end

	buffer.writeu16(self.buffer, offsetToUse, value)

	if not offset then
		self.byteOffset += 2
	end
end

function BufferStream.writeu32(self: BufferStream, value: number, offset: number?): ()
	if typeof(value) ~= "number" then
		error(`bad argument #1 to 'writeu32' (number expected, got {typeof(value)})`)
	end

	if value < 0 or value > 0xFFFFFFFF then
		error("bad argument #1 to 'writeu32' (number must be between 0 and 4294967295)")
	end

	if offset and typeof(offset) ~= "number" then
		error(`bad argument #2 to 'writeu32' (number expected, got {typeof(offset)})`)
	end

	if offset and offset % 1 ~= 0 then
		error("bad argument #2 to 'writeu32' (number must be an integer)")
	end

	local offsetToUse = offset or self.byteOffset

	if offsetToUse + 4 > self.length then
		self:expand((offsetToUse + 4) - self.length)
	end

	buffer.writeu32(self.buffer, offsetToUse, value)

	if not offset then
		self.byteOffset += 4
	end
end

function BufferStream.writeu8(self: BufferStream, value: number, offset: number?): ()
	if typeof(value) ~= "number" then
		error(`bad argument #1 to 'writeu8' (number expected, got {typeof(value)})`)
	end

	if value < 0 or value > 0xFF then
		error("bad argument #1 to 'writeu8' (number must be between 0 and 255)")
	end

	if offset and typeof(offset) ~= "number" then
		error(`bad argument #2 to 'writeu8' (number expected, got {typeof(offset)})`)
	end

	if offset and offset % 1 ~= 0 then
		error("bad argument #2 to 'writeu8' (number must be an integer)")
	end

	local offsetToUse = offset or self.byteOffset

	if offsetToUse + 1 > self.length then
		self:expand((offsetToUse + 1) - self.length)
	end
end

--------------------------------------------------------------------------------

function BufferStream.slice(self: BufferStream, start: number, finish: number?): BufferStream
	if typeof(start) ~= "number" then
		error(`bad argument #1 to 'slice' (number expected, got {typeof(start)})`)
	end

	if start % 1 ~= 0 then
		error("bad argument #1 to 'slice' (number must be an integer)")
	end

	if finish and typeof(finish) ~= "number" then
		error(`bad argument #2 to 'slice' (number expected, got {typeof(finish)})`)
	end

	if finish and finish % 1 ~= 0 then
		error("bad argument #2 to 'slice' (number must be an integer)")
	end

	if start < 0 or start > self.length then
		error(`bad argument #1 to 'slice' (number must be between 0 and {self.length})`)
	end

	if finish and (finish < 0 or finish > self.length) then
		error(`bad argument #2 to 'slice' (number must be between 0 and {self.length})`)
	end

	local finishToUse = finish or self.length

	if finishToUse < start then
		error("bad argument #2 to 'slice' (number must be greater than or equal to argument #1)")
	end

	local newBuf = buffer.create(finishToUse - start)
	buffer.copy(newBuf, 0, self.buffer, start, finishToUse)

	return BufferStream.new(newBuf)
end

function BufferStream.tostring(self: BufferStream): string
	return buffer.tostring(self.buffer)
end

--------------------------------------------------------------------------------

function BufferStream.__tostring(self: BufferStream): string
	return self:tostring()
end

return BufferStream
