describe("Game", function()
    before_each(function()
        love.graphics.getWidth = function() return 800 end
        love.graphics.getHeight = function() return 600 end
        love.graphics.newCanvas = function() return {} end
        love.graphics.setCanvas = function() end
        love.graphics.setColor = function() end
        love.graphics.arc = function() end
        love.graphics.circle = function() end
        love.graphics.rectangle = function() end
        love.graphics.line = function() end
        love.graphics.newFont = function() return {} end
    end)

    it("should create with unicorn and managers", function()
        local g = Game:new()
        assert.is_not_nil(g.unicorn)
        assert.is_not_nil(g.stateManager)
        assert.is_not_nil(g.progressionSystem)
        assert.is_not_nil(g.backgroundRenderer)
        assert.is_not_nil(g.uiManager)
        assert.is_not_nil(g.coinManager)
        assert.are.equal(false, g.stateManager.game_over)
        assert.are.equal(1, g.progressionSystem.stage)
        assert.are.equal(100, g.progressionSystem.coins)
        assert.are.equal(3, g.stateManager.lives)
    end)

    it("should delegate state to managers", function()
        local g = Game:new()
        assert.are.equal(3, g.stateManager.lives)
        assert.are.equal(100, g.progressionSystem:getCoins())
        assert.are.equal(0, g.coinManager:getProgress())
    end)

    it("should handle restart on R key", function()
        local g = Game:new()
        g.stateManager.game_over = true
        g.progressionSystem.stage = 5
        g:keypressed('r')
        assert.are.equal(false, g.stateManager.game_over)
        assert.are.equal(1, g.progressionSystem.stage)
        assert.are.equal(3, g.stateManager.lives)
    end)

    it("should toggle pause on P key", function()
        local g = Game:new()
        assert.are.equal(false, g.stateManager.manual_pause)
        g:keypressed('p')
        assert.are.equal(true, g.stateManager.manual_pause)
        g:keypressed('p')
        assert.are.equal(false, g.stateManager.manual_pause)
    end)

    it("should dismiss welcome screen on enter", function()
        local g = Game:new()
        assert.are.equal(true, g.stateManager.show_welcome)
        g:keypressed('return')
        assert.are.equal(false, g.stateManager.show_welcome)
    end)

    it("should not pause flight when reaching the sun on level up", function()
        local g = Game:new()
        g.stateManager.show_welcome = false
        g.name_input_active = false
        g.unicorn.x = g.sun_x
        g.unicorn.y = g.sun_y
        g.unicorn.update = function() return false end
        g.trollManager.update = function() end
        g.progressionSystem.sun_hits = g.progressionSystem.sun_hits_required - 1
        g.coinManager.progress_coins = g.progressionSystem.coins_to_advance

        g:update(0.1)

        assert.is_not_nil(g.level_up_alert)
        assert.is_false(g.stateManager.paused)
    end)

    it("should leave enough room to fly completely above the sun", function()
        local g = Game:new()
        local sun_top = g.sun_y - 40
        local unicorn_bottom_at_top_edge = g.unicorn.height

        assert.is_true(unicorn_bottom_at_top_edge < sun_top)
    end)
end)