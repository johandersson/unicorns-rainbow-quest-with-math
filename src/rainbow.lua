-- rainbow.lua
Rainbow = {}

function Rainbow:new()
    local obj = {
        segments = {},
        colors = {
            {1, 0, 0},     -- red
            {1, 0.5, 0},   -- orange
            {1, 1, 0},     -- yellow
            {0, 1, 0},     -- green
            {0, 0, 1},     -- blue
            {0.3, 0, 0.5}, -- indigo
            {0.5, 0, 1}    -- violet
        },
        index = 1,
        last_add_time = 0,
        add_interval = 0.1 -- add segment every 0.1 seconds
    }
    setmetatable(obj, self)
    self.__index = self
    return obj
end

function Rainbow:addSegment(x, y, dt)
    self.last_add_time = self.last_add_time + dt
    if self.last_add_time >= self.add_interval then
        table.insert(self.segments, {
            x = x,
            y = y,
            color = self.colors[self.index]
        })
        self.index = self.index % #self.colors + 1
        self.last_add_time = 0
    end
end

function Rainbow:draw()
    for i, segment in ipairs(self.segments) do
        love.graphics.setColor(segment.color[1], segment.color[2], segment.color[3])
        love.graphics.circle('fill', segment.x, segment.y, 10)
    end
end

function Rainbow:isComplete()
    return #self.segments >= #self.colors
end

function Rainbow:reset()
    self.segments = {}
    self.index = 1
    self.last_add_time = 0
end

return Rainbow