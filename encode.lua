unpack = table.unpack -- LibSerialize targets Lua 5.1's global unpack.
local deflate = dofile('/app/LibDeflate.lua')
local serialize = dofile('/app/LibSerialize.lua')

local function main()
    local input = io.read('*a')
    local chunk, err = load(input, 'input', 't', {})
    if not chunk then error('invalid Lua input: ' .. err, 0) end
    local results = table.pack(chunk())
    if results.n ~= 1 or type(results[1]) ~= 'table' then
        error('expected a single table', 0)
    end
    local data = serialize:Serialize(results[1])
    local compressed = deflate:CompressDeflate(data)
    if not compressed then error('compression failed', 0) end
    io.write('!WA:2!', deflate:EncodeForPrint(compressed), '\n')
end

local ok, err = pcall(main)
if not ok then
    io.stderr:write('wa-encoding encode: ', tostring(err), '\n')
    os.exit(1)
end
