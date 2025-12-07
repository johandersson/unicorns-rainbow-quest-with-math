describe("Game", function()
    before_each(function()
        love.graphics.getWidth = function() return 800 end
        love.graphics.getHeight = function() return 600 end
    end)

    it("should create with unicorn and rainbow", function()
        local g = Game:new()
        assert.is_not_nil(g.unicorn)
        assert.is_not_nil(g.rainbow)
        assert.are.equal(0, g.score)
        assert.are.equal(false, g.game_over)
        assert.are.equal(1, g.stage)
    end)

    it("should update and add rainbow when up key", function()
        local g = Game:new()
        love.keyboard.isDown = function(key) return key == 'up' end
        g:update(0.15)
        assert.are.equal(1, #g.rainbow.segments)
    end)

    it("should increase score when rainbow complete", function()
        local g = Game:new()
        love.keyboard.isDown = function(key) return key == 'up' end
        for i = 1, 7 do
            g:update(0.15)
        end
        assert.are.equal(1, g.score)
        assert.are.equal(2, g.stage)
        assert.are.equal(0, #g.rainbow.segments) -- Reset
    end)

    it("should handle restart on R key", function()
        local g = Game:new()
        g.game_over = true
        g.score = 5
        love.keypressed = function(key) return key == 'r' end
        g:keypressed('r')
        assert.are.equal(false, g.game_over)
        assert.are.equal(0, g.score)
        assert.are.equal(1, g.stage)
    end)
end)