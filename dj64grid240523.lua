--- abstracted grid key mappings from functionality
-- demonstrate a simple string-based grid-layout system where each key is
-- addressed with a standard structure. direct handling for row and column
-- groups of keys that all call the same underlying function.
--
-- concept is to have a generic grid handler function, and wrap all of the
-- script specific functionality into a simple table of locations and
-- matching functions that will be called when that key is pressed or
-- released.
--
-- functions can instead be tables where the first element is the function to
-- be called, followed by an arguments that should be appended on call. this
-- allows for the same function to be shared among many keys and can make
-- the mapping explicit when it's not a linear range as per row or col.
--
-- main benefits are separating key matching logic from script specific logic.
-- this is often intertwined and creates a giant function with endless if/else
-- chains that make the grid layout opaque & bugs hard to find. and the second
-- benefit is to enforce the idea that every action the grid articulates must
-- be wrapped in a function, ideally in a separate table's namespace for ease
-- of separation. this is particularly beneficial in a collaborative project
-- where the grid layout could be designed & implemented in parallel to the
-- underlying dsp/events. all that would need to be agreed upon beforehand is
-- the API that grid will call, and dsp/events will implement.
--
-- side effect is that it basically stop you from having the grid key parser
-- capture any state. the only state you may want is to manage grid "paging"
-- where you can switch between different tables of mappings. if you do this
-- you still want to wrap that switching in a function!

local g = grid.connect()

local dj = {}

dj.mute = function(x,y,z)
    print('mute: ' .. x .. ',' .. y .. ',' .. z)
end

dj.looper = function(x,y,z)
    print('looper: ' .. x .. ',' .. y .. ',' .. z)
end

dj.fx = function(x,y,z, channel)
    print('fx: ' .. x .. ',' .. y .. ',' .. z)
    local channel = 0
end

dj.bender = function(x,y,z)
    print('bender: ' .. x .. ',' .. y .. ',' .. z)
end

dj.upFade = function(x, y, z)
    print('upfade: ' .. x .. ',' .. y .. ',' .. z)
end

dj.filter = function(x, y, z)
    print('filter: ' .. x .. ',' .. y .. ',' .. z)
end

dj.playToggle = function(x,y,z)
    print('playToggle: ' .. x .. ',' .. y .. ',' .. z)
end

dj.cue = function(x,y,z)
    print('cue: ' .. x .. ',' .. y .. ',' .. z)
end

dj.xFade = function(x,y,z)
    print('xFade: ' .. x .. ',' .. y .. ',' .. z)
end

function init()
    g.fns =

    {["1,8"] = dj.playToggle,
    ["4,8"] = dj.cue,
    ["13,8"] = dj.cue,
    ["16,8"] = dj.playToggle}

    for x = 1, 4 do 
        g.fns[x..",1"] = {dj.looper, 1}
        g.fns[(x + 12) .. ",1"] = {dj.looper, 2}
        g.fns[(x + 6) .. ",8"] = dj.xFade
        
        for y = 3, 5 do
            g.fns[x..","..y] = {dj.fx, 1}
            g.fns[(x + 12)..","..y] = {dj.fx, 2}
        end
    end
    
    for x = 1, 5 do
        g.fns[x..",7"] = {dj.bender, 1}
        g.fns[(x + 11) .. ",7"] = {dj.bender, 2}
    end
    
    for y = 1, 6 do
        g.fns["6,"..y] = {dj.filter, 1}
        g.fns["11,"..y] = {dj.filter, 2}
        g.fns["8,"..y] = {dj.upFader, 1}
        g.fns["9,"..y] = {dj.upFader, 2}
    end
    
    extract_and_light_up()
    
end

-- must use the following formats
-- where X and Y are the numbers representing column and row of grid
-- origin (0,0) is in top left of grid
-- single keys: X,Y eg "0,0" "3,4" "15,2"
-- columns: xX eg "x12" "x0"
-- rows: yY eg "y3" "y10"



-- helper fn to unpack varargs, call the first arg as fn & pass remainder as args
-- use it to call a "fn_table" aka table of a function along with n-args.
local function apply(f, ...)
    return f(...)
end

local function maybe_fn_table(obj,...)
    -- false signals the obj doesn't exist
    if obj == nil then return false end

    local typ = type(obj)
    if typ == 'function' then
        obj(...)
    elseif typ == 'table' then
        apply(table.unpack(obj),...)
    end
    -- true signals this mapping was eval'd
    return true
end

-- lookup is *very* fast as it's a single hash-table address for each category
-- of single, row & column. should be at least as fast as a standard deeply
-- nested if/else chain, and likely 2-3x faster.
-- benefit is really the simplicity, and fact that the grid mappings are
-- declarative & non-code. it also greatly reduces chances of edge-case bugs
-- and typos in general, especially when managing deeply nested conditionals.
--
-- plus it's all re-usable! copy & paste this whole file and provide g.fns at
-- runtime. could be called "autogrid" and has an init function that just
-- takes a grid object & a g.fns table.
-- later we could add a fancier init function that takes multiple g.fns tables
-- and expose an autogrid.x function that swithces the active layer.

function g.key(x,y,z)
    -- TODO wrap multiples of the g.fns table if paging
    -- must reproduce the switching mappings in both layouts
    -- but they can both call the same underlying function
    --
    maybe_fn_table(g.fns[x .. ',' .. y],x,y,z) -- individual key

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

-- note that this is the input side of grid. i actually really the idea that the
-- grid presses & lights are managed by entirely different libraries. they are
-- fundamentally disconnected, and it could be nice not to think about the key
-- presses at all when programming the lighting