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
    local dx = unicorn.x - self.x
    local dy = unicorn.y - self.y
    local ur = math.max(unicorn.width or 0, unicorn.height or 0) / 2
    -- add a small tolerance so approach direction doesn't block collection
    local tolerance = 4
    local combined = (self.radius or 0) + ur + tolerance
    return (dx*dx + dy*dy) <= (combined * combined)
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
