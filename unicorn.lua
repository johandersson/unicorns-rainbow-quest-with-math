-- unicorn.lua
Unicorn = {}

function Unicorn:new(x, y)
    local obj = {
        x = x or 400,
        y = y or 200,
        vx = 0,
        vy = 0,
        speed = 200,
        gravity = 400,  -- Strong gravity for challenge
        width = 40,
        height = 30
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Unicorn:update(dt)
    -- Horizontal movement
    if love.keyboard.isDown('left') then
        self.vx = -self.speed
    elseif love.keyboard.isDown('right') then
        self.vx = self.speed
    else
        self.vx = 0
    end

    -- Vertical movement (flying up only, gravity pulls down)
    if love.keyboard.isDown('up') then
        self.vy = -self.speed
    else
        -- Apply gravity
        self.vy = self.vy + self.gravity * dt
    end

    self.x = self.x + self.vx * dt
    self.y = self.y + self.vy * dt

    -- Keep in bounds
    if self.x - self.width / 2 < 0 then self.x = self.width / 2 end
    if self.x + self.width / 2 > 800 then self.x = 800 - self.width / 2 end
    if self.y - self.height / 2 < 0 then self.y = self.height / 2 end
    if self.y + self.height / 2 > 550 then
        self.y = 550 - self.height / 2
        -- Game over if touch ground
        return true -- signal game over
    end
    return false
end

function Unicorn:draw()
    drawUnicorn(self.x, self.y)
end

function drawUnicorn(x, y)
    -- Body (slimmer pink oval, more horse-like, facing left)
    love.graphics.setColor(1, 0.7, 0.8)
    love.graphics.ellipse('fill', x - 5, y, 15, 20)  -- Shifted left

    -- Neck (elongated, angled left)
    love.graphics.ellipse('fill', x - 8, y - 12, 8, 12)

    -- Head (small oval, facing left)
    love.graphics.ellipse('fill', x - 12, y - 22, 10, 8)

    -- Horn (longer, on the left side)
    love.graphics.setColor(1, 1, 0)
    love.graphics.polygon('fill', x - 16, y - 28, x - 14, y - 28, x - 15, y - 40)

    -- Eyes (on the left side of head)
    love.graphics.setColor(0, 0, 0)
    love.graphics.circle('fill', x - 18, y - 24, 2)
    love.graphics.setColor(1, 1, 1)
    love.graphics.circle('fill', x - 17, y - 25, 0.5)

    -- Mane (flowing left)
    love.graphics.setColor(1, 1, 1)
    love.graphics.arc('fill', x - 20, y - 18, 10, math.pi/2, 3*math.pi/2)
    love.graphics.arc('fill', x - 16, y - 20, 8, math.pi/2, 3*math.pi/2)
    love.graphics.arc('fill', x - 12, y - 22, 6, math.pi/2, 3*math.pi/2)

    -- Tail (on the right)
    love.graphics.arc('fill', x + 10, y + 5, 10, -math.pi/2, math.pi/2)

    -- Legs (horse-like, positioned accordingly)
    love.graphics.setColor(1, 0.7, 0.8)
    love.graphics.rectangle('fill', x - 15, y + 12, 4, 20)
    love.graphics.rectangle('fill', x - 7, y + 12, 4, 20)
    love.graphics.rectangle('fill', x + 1, y + 12, 4, 20)
    love.graphics.rectangle('fill', x + 9, y + 12, 4, 20)
    -- Hooves (black)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle('fill', x - 16, y + 30, 6, 4)
    love.graphics.rectangle('fill', x - 8, y + 30, 6, 4)
    love.graphics.rectangle('fill', x, y + 30, 6, 4)
    love.graphics.rectangle('fill', x + 8, y + 30, 6, 4)

    -- Ears (pointed, on left)
    love.graphics.setColor(1, 0.7, 0.8)
    love.graphics.polygon('fill', x - 20, y - 28, x - 17, y - 33, x - 14, y - 28)
end

return Unicorn