Troll = {}

function Troll:new(x, y, speed)
    local obj = {
        x = x,
        y = y,
        speed = speed
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Troll:reset(x, y, speed)
    self.x = x
    self.y = y
    self.speed = speed
end