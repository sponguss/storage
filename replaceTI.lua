local function didHitRegion(a : number, b : number, x : number, y : number) : boolean
    local xInside = x >= a and x <= b
    local yInside = y >= a and y <= b
    local xOutside = x <= a
    local yOutside = y >= b

    if xInside or yInside then
        return true
    end
    
    if xOutside and yOutside then
        return true
    end

    return false
end
local function computeAABBForPart(part)
    local abs = math.abs
    local inf = math.huge

    local cf = part.CFrame
    local size = part.Size
    local sx, sy, sz = size.X, size.Y, size.Z

    local x, y, z, R00, R01, R02, R10, R11, R12, R20, R21, R22 = cf:components()

    local wsx = 0.5 * (abs(R00) * sx + abs(R01) * sy + abs(R02) * sz)
    local wsy = 0.5 * (abs(R10) * sx + abs(R11) * sy + abs(R12) * sz)
    local wsz = 0.5 * (abs(R20) * sx + abs(R21) * sy + abs(R22) * sz)
            
    local minx = x - wsx
    local miny = y - wsy
    local minz = z - wsz

    local maxx = x + wsx
    local maxy = y + wsy
    local maxz = z + wsz
    
    return Vector3.new(minx, miny, minz), Vector3.new(maxx, maxy, maxz)
end

local function didHitBox(part1 : Part, part2 : Part) : boolean
    local part1Min, part1Max = computeAABBForPart(part1)
    local part2Min, part2Max = computeAABBForPart(part2)

    local xOverlaps = didHitRegion(part1Min.X, part1Max.X, part2Min.X, part2Max.X)
    if not xOverlaps then
        return false
    end

    local yOverlaps = didHitRegion(part1Min.Y, part1Max.Y, part2Min.Y, part2Max.Y)
    if not yOverlaps then
        return false
    end

    local zOverlaps = didHitRegion(part1Min.Z, part1Max.Z, part2Min.Z, part2Max.Z)
    if not zOverlaps then
        return false
    end

    return true
end   
