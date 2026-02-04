-- coin.lua
local Coin = {}
Coin.__index = Coin

function Coin:new(x, y, lifetime, radius)
    local obj = {
        x = x or 0,
        y = y or 0,
        t = lifetime or 20,
        radius = radius or 12
    }
    setmetatable(obj, self)
    return obj
end

function Coin:reset(x, y, lifetime, radius)
    self.x = x or self.x
    self.y = y or self.y
    self.t = lifetime or self.t
    self.radius = radius or self.radius
end

function Coin:update(dt)
    self.t = self.t - dt
end

function Coin:isCollectedBy(unicorn)
    -- Simple circle-circle collision (works from ANY direction - much more player-friendly)
    -- Treat unicorn as a circle with generous radius for easy collection
    local ux = unicorn.x or 0
    local uy = unicorn.y or 0
    local cx = self.x or 0
    local cy = self.y or 0
    
    -- Calculate squared distance between centers
    local dx = ux - cx
    local dy = uy - cy
    local dist_sq = dx*dx + dy*dy
    
    -- Generous collision radius: unicorn effective radius (30) + coin radius + tolerance
    -- This ensures coins are caught from ANY angle/direction
    local collision_radius = 30 + self.radius + 8
    local collision_radius_sq = collision_radius * collision_radius
    
    return dist_sq <= collision_radius_sq
end

function Coin:draw()
    love.graphics.setColor(1, 0.85, 0)
    love.graphics.circle('fill', self.x, self.y, self.radius)
    love.graphics.setColor(1, 1, 0.6)
    love.graphics.circle('fill', self.x - 4, self.y - 4, self.radius * 0.5)
    love.graphics.setColor(0.8, 0.6, 0)
    love.graphics.circle('line', self.x, self.y, self.radius)
end

return Coin
