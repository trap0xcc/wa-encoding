unpack = table.unpack -- LibSerialize targets Lua 5.1's global unpack.
local deflate = dofile('/app/LibDeflate.lua')
local serialize = dofile('/app/LibSerialize.lua')

local function quote(s)
    -- Lua normalizes newlines in long strings and discards an initial newline.
    -- Only use them when their contents will survive a source-code round trip.
    if s:find('\n', 1, true) and s:sub(1, 1) ~= '\n'
        and not s:find('[%z\1-\9\11-\31\127]') then
        local equals = ''
        while (s .. ']' .. equals .. ']'):find(']' .. equals .. ']', 1, true) ~= #s + 1 do
            equals = equals .. '='
        end
        return '[' .. equals .. '[' .. s .. ']' .. equals .. ']'
    end
    return '"' .. s:gsub('[%z\1-\31\127-\255\\"]', function(c)
        if c == '\\' then return '\\\\' end
        if c == '"' then return '\\"' end
        if c == '\n' then return '\\n' end
        if c == '\r' then return '\\r' end
        if c == '\t' then return '\\t' end
        return ('\\%03d'):format(c:byte())
    end) .. '"'
end

local function number(n)
    if n ~= n then return '(0/0)' end
    if n == math.huge then return '(1/0)' end
    if n == -math.huge then return '(-1/0)' end
    if math.type(n) == 'integer' then return tostring(n) end
    local s = ('%.17g'):format(n)
    if not s:find('[.eE]') then s = s .. '.0' end
    return s
end

local ranks = {boolean = 1, number = 2, string = 3}
local function render(root)
    local seen = {}
    local function value(v, depth)
        local kind = type(v)
        if kind == 'string' then return quote(v) end
        if kind == 'number' then return number(v) end
        if kind == 'boolean' then return tostring(v) end
        if kind ~= 'table' then error('unsupported value type: ' .. kind, 0) end
        if seen[v] then error('shared or cyclic table references are not supported', 0) end
        seen[v] = true
        local keys = {}
        for k in pairs(v) do
            if not ranks[type(k)] then error('unsupported table key type: ' .. type(k), 0) end
            keys[#keys + 1] = k
        end
        table.sort(keys, function(a, b)
            local ta, tb = type(a), type(b)
            if ta ~= tb then return ranks[ta] < ranks[tb] end
            if ta == 'boolean' then return a == false and b == true end
            return a < b
        end)
        if #keys == 0 then return '{}' end
        local lines = {'{'}
        local indent = string.rep('    ', depth + 1)
        for _, k in ipairs(keys) do
            lines[#lines + 1] = indent .. '[' .. value(k, depth + 1) .. '] = ' .. value(v[k], depth + 1) .. ','
        end
        lines[#lines + 1] = string.rep('    ', depth) .. '}'
        return table.concat(lines, '\n')
    end
    return 'return ' .. value(root, 0) .. '\n'
end

local function main()
    local input = io.read('*a'):match('^%s*(.-)%s*$')
    if input:sub(1, 6) ~= '!WA:2!' then error('expected !WA:2! prefix', 0) end
    local binary = deflate:DecodeForPrint(input:sub(7))
    if not binary then error('invalid printable encoding', 0) end
    local data = deflate:DecompressDeflate(binary)
    if not data then error('invalid deflate data', 0) end
    local decoded = table.pack(serialize:Deserialize(data))
    local ok, result = decoded[1], decoded[2]
    if not ok then error('deserialization failed: ' .. tostring(result), 0) end
    if type(result) ~= 'table' or decoded.n ~= 2 then error('expected a single serialized table', 0) end
    if arg[1] == '--json' then
        io.write(dofile('/app/json.lua')(result))
    else
        io.write(render(result))
    end
end

local ok, err = pcall(main)
if not ok then
    io.stderr:write('wa-encoding decode: ', tostring(err), '\n')
    os.exit(1)
end
