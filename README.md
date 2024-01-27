# bson.luau

Luau implementation of BSON data format

# Usage

```lua
local bson = require(script.Parent)

local Encoder = bson.Encoder
local Decoder = bson.Decoder

-- { hello = "world" }
print(Decoder.decode(Encoder.encode({ hello = "world" })))
```