local g = grid.connect()

local dj = {}

dj.mute = function(x, y, z)
    print('mute: ' .. x .. ',' .. y .. ',' .. z)
end

dj.looper = function(x, y, z, channel)
    print('looper ' .. channel .. ': ' .. x .. ',' .. y .. ',' .. z)
end

dj.fx = function(x, y, z, channel)
    print('fx ' .. channel .. ': ' .. x .. ',' .. y .. ',' .. z)
end

dj.bender = function(x, y, z, channel)
    print('bender ' .. channel .. ': ' .. x .. ',' .. y .. ',' .. z)
end

dj.upFade = function(x, y, z, channel)
    print('upFade ' .. channel .. ': ' .. x .. ',' .. y .. ',' .. z)
end

dj.filter = function(x, y, z, channel)
    print('filter ' .. channel .. ': ' .. x .. ',' .. y .. ',' .. z)
end

dj.playToggle = function(x, y, z, channel)
    print('playToggle ' .. channel .. ': ' .. x .. ',' .. y .. ',' .. z)
end

dj.cue = function(x, y, z, channel)
    print('cue ' .. channel .. ': ' .. x .. ',' .. y .. ',' .. z)
end

dj.xFade = function(x, y, z)
    print('xFade: ' .. x .. ',' .. y .. ',' .. z)
end

function init()
    g.fns = {
        ["1,8"] = dj.playToggle,
        ["4,8"] = dj.cue,
        ["13,8"] = dj.cue,
        ["16,8"] = dj.playToggle
    }

    for x = 1, 4 do
        g.fns[x .. ",1"] = {dj.looper, 1}
        g.fns[(x + 12) .. ",1"] = {dj.looper, 2}
        g.fns[(x + 6) .. ",8"] = dj.xFade

        for y = 3, 5 do
            g.fns[x .. "," .. y] = {dj.fx, 1}
            g.fns[(x + 12) .. "," .. y] = {dj.fx, 2}
        end
    end

    for x = 1, 5 do
        g.fns[x .. ",7"] = {dj.bender, 1}
        g.fns[(x + 11) .. ",7"] = {dj.bender, 2}
    end

    for y = 1, 6 do
        g.fns["6," .. y] = {dj.filter, 1}
        g.fns["11," .. y] = {dj.filter, 2}
        g.fns["8," .. y] = {dj.upFade, 1}
        g.fns["9," .. y] = {dj.upFade, 2}
    end

    extract_and_light_up()
end

local function apply(f, ...)
    return f(...)
end

local function maybe_fn_table(obj, x, y, z)
    if obj == nil then return false end

    local typ = type(obj)
    if typ == 'function' then
        obj(x, y, z)
    elseif typ == 'table' then
        apply(obj[1], x, y, z, obj[2])
    end
    return true
end

function g.key(x, y, z)
    maybe_fn_table(g.fns[x .. ',' .. y], x, y, z) -- individual key
end

function extract_and_light_up()
    local pairs_list = {}
    for key, _ in pairs(g.fns) do
        local x, y = key:match("(%d+),(%d+)")
        if x and y then
            table.insert(pairs_list, {tonumber(x), tonumber(y)})
        end
    end

    for _, pair in ipairs(pairs_list) do
        local x, y = pair[1], pair[2]
        g:led(x, y, 3)
    end
    g:refresh()
end
