-- unicorn.lua
local unicorn_sprite = nil
local quadUp = nil
local quadDown = nil

if not unicorn_sprite then
    unicorn_sprite = love.graphics.newImage('unicorn-sprite.png')
    local w, h = unicorn_sprite:getDimensions()
    quadUp = love.graphics.newQuad(0, 0, w, h/2, w, h)
    quadDown = love.graphics.newQuad(0, h/2, w, h/2, w, h)
end

Unicorn = {}

function Unicorn:new(x, y, ground, width)
    local obj = {
        x = x or 400,
        y = y or 200,
        vx = 0,
        vy = 0,
        speed = 200,
        gravity = 400,  -- Strong gravity for challenge
        width = 40,
        height = 30,
        ground = ground or 550,
        screen_width = width or 800,
        sprite = unicorn_sprite,
        quadUp = quadUp,
        quadDown = quadDown
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
    if self.x + self.width / 2 > self.screen_width then self.x = self.screen_width - self.width / 2 end
    if self.y - self.height / 2 < 0 then self.y = self.height / 2 end
    if self.y + self.height / 2 > self.ground then
        self.y = self.ground - self.height / 2
        -- Game over if touch ground
        return true -- signal game over
    end
    return false
end

function Unicorn:draw()
    self:drawUnicorn()
end

function Unicorn:drawUnicorn()
    local quad = self.vy < 0 and self.quadDown or self.quadUp
    love.graphics.draw(self.sprite, quad, self.x - self.width/2, self.y - self.height/2)
end

return Unicorn