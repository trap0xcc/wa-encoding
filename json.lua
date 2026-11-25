-- Convert Lua values to JSON. Empty tables have no array/object distinction in Lua.
local function quote(s)
    if not utf8.len(s) then error('JSON strings must contain valid UTF-8', 0) end
    return '"' .. s:gsub('[%z\1-\31\\"]', function(c)
        local escapes = {['"'] = '\\"', ['\\'] = '\\\\', ['\b'] = '\\b',
            ['\f'] = '\\f', ['\n'] = '\\n', ['\r'] = '\\r', ['\t'] = '\\t'}
        return escapes[c] or ('\\u%04x'):format(c:byte())
    end) .. '"'
end

return function(root)
    local seen = {}
    local function render(v, depth)
        local kind = type(v)
        if kind == 'string' then return quote(v) end
        if kind == 'boolean' then return tostring(v) end
        if kind == 'number' then
            if v ~= v or v == math.huge or v == -math.huge then
                error('JSON does not support non-finite numbers', 0)
            end
            if math.type(v) == 'integer' then return tostring(v) end
            return ('%.17g'):format(v)
        end
        if kind ~= 'table' then error('unsupported JSON value type: ' .. kind, 0) end
        if seen[v] then error('shared or cyclic table references are not supported', 0) end
        seen[v] = true
        local count, max, array = 0, 0, true
        for k in pairs(v) do
            count = count + 1
            if type(k) ~= 'number' or k < 1 or k % 1 ~= 0 then
                array = false
            elseif k > max then max = k end
        end
        array = array and count > 0 and max == count
        if count == 0 then return '{}' end
        local indent = string.rep('    ', depth + 1)
        local lines = {array and '[' or '{'}
        if array then
            for i = 1, count do lines[#lines + 1] = indent .. render(v[i], depth + 1) end
        else
            local keys, names = {}, {}
            for k in pairs(v) do
                local keytype = type(k)
                if keytype ~= 'string' and keytype ~= 'number' then
                    error('unsupported JSON object key type: ' .. keytype, 0)
                end
                if keytype == 'number' and (k ~= k or k == math.huge or k == -math.huge) then
                    error('JSON does not support non-finite object keys', 0)
                end
                local name = tostring(k)
                if names[name] then error('JSON object key collision: ' .. name, 0) end
                names[name] = true
                keys[#keys + 1] = {key = k, name = name}
            end
            table.sort(keys, function(a, b) return a.name < b.name end)
            for _, entry in ipairs(keys) do
                lines[#lines + 1] = indent .. quote(entry.name) .. ': ' .. render(v[entry.key], depth + 1)
            end
        end
        return lines[1] .. '\n' .. table.concat(lines, ',\n', 2, #lines) .. '\n' .. string.rep('    ', depth) .. (array and ']' or '}')
    end
    return render(root, 0) .. '\n'
end
