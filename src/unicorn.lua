-- unicorn.lua
-- Cache sprite and quads globally (singleton pattern for O(1) access)
local unicorn_sprite = nil
local quadUp = nil
local quadDown = nil
local sprite_width = 0
local sprite_height = 0

-- Pre-load sprite once (memoization for image loading)
if not unicorn_sprite then
    unicorn_sprite = love.graphics.newImage('unicorn-sprite.png')
    sprite_width, sprite_height = unicorn_sprite:getDimensions()
    quadUp = love.graphics.newQuad(0, 0, sprite_width, sprite_height/2, sprite_width, sprite_height)
    quadDown = love.graphics.newQuad(0, sprite_height/2, sprite_width, sprite_height/2, sprite_width, sprite_height)
end

Unicorn = {}

function Unicorn:new(x, y, ground, width)
    local obj = {
        x = x or 400,
        y = y or 200,
        vx = 0,
        vy = 0,
        speed = 260,
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

    -- Update position
    local new_x = self.x + self.vx * dt
    local new_y = self.y + self.vy * dt
    
    -- Cache half dimensions (avoid repeated division)
    local half_w = self.width * 0.5
    local half_h = self.height * 0.5
    
    -- Clamp bounds (optimized with single assignment)
    self.x = math.max(half_w, math.min(new_x, self.screen_width - half_w))
    self.y = math.max(half_h, math.min(new_y, self.ground - half_h))
    
    -- Check ground collision (early return optimization)
    if new_y + half_h > self.ground then
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