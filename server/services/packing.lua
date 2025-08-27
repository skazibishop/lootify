local Packing = {}

-- Build a 2D occupancy grid (1-based indices) from item list for a given grid size and grid_key
function Packing.buildGrid(items, gridW, gridH, grid_key)
    local g = {}
    for y=1,gridH do
        g[y] = {}
        for x=1,gridW do g[y][x] = false end
    end
    for _, it in ipairs(items) do
        if (it.grid_key or 'main') == (grid_key or 'main') then
            local w, h = it.size_w, it.size_h
            local x0, y0 = it.pos_x+1, it.pos_y+1
            for y=y0, y0+h-1 do
                for x=x0, x0+w-1 do
                    if g[y] and g[y][x] ~= nil then g[y][x] = true end
                end
            end
        end
    end
    return g
end

local function fits(g, gridW, gridH, w, h, x0, y0)
    if x0 < 1 or y0 < 1 or x0 + w - 1 > gridW or y0 + h - 1 > gridH then return false end
    for y=y0, y0+h-1 do
        for x=x0, x0+w-1 do
            if g[y][x] then return false end
        end
    end
    return true
end

-- Try first-fit scan with optional rotation. Returns x,y,rot,grid_key or nil
function Packing.findSlotFor(items, invDef, sizeW, sizeH, allowRotate, preferGridKey)
    -- invDef: { grids = { {key='main', w=10, h=18}, ... } }
    local grids = invDef.grids or { { key = 'main', w = invDef.w, h = invDef.h } }
    -- prefer specific grid first if provided
    if preferGridKey then
        table.sort(grids, function(a,b) return (a.key==preferGridKey and 1 or 0) > (b.key==preferGridKey and 1 or 0) end)
    end

    for _, gdef in ipairs(grids) do
        local occ = Packing.buildGrid(items, gdef.w, gdef.h, gdef.key)
        for y=1,gdef.h do
            for x=1,gdef.w do
                if fits(occ, gdef.w, gdef.h, sizeW, sizeH, x, y) then
                    return { x=x-1, y=y-1, rot=0, grid_key=gdef.key }
                end
                if allowRotate and fits(occ, gdef.w, gdef.h, sizeH, sizeW, x, y) then
                    return { x=x-1, y=y-1, rot=1, grid_key=gdef.key }
                end
            end
        end
    end
    return nil
end

return Packing
