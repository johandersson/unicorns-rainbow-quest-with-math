local Coin = require('src.coin')

local ScreenshotCapture = {}
ScreenshotCapture.__index = ScreenshotCapture

local function setCommonState(game)
    game.settingsManager:setLanguage('en')
    game.name_input_active = false
    game.stateManager.show_welcome = false
    game.stateManager.game_over = false
    game.stateManager.paused = false
    game.stateManager.manual_pause = false
    game.show_highscore_celebration = false
    game.show_scoreboard_pause = false
    game.quiz_active = false
    game.quiz_result_timer = 0
    game.level_up_alert = nil
    game.level_up_flash = nil
    game.helpManager.isVisible = false
    game.settingsManager.isVisible = false
    game.trollManager.trolls = {}
    game.coinManager.field_coins = {}

    game.scoreboardManager.players = {
        {name = 'Nova', highscore = 1840},
        {name = 'Stella', highscore = 1325},
        {name = 'Luna', highscore = 980},
        {name = 'Comet', highscore = 725}
    }
    game.scoreboardManager.current_player = 'Nova'
    game.scoreboardManager.previous_highscore = 1840
    game.scoreboardManager.session_score = 1260

    game.progressionSystem.coins = 235
    game.progressionSystem.stage = 3
    game.progressionSystem.sun_hits = 2
    game.progressionSystem.sun_hits_required = 5
    game.progressionSystem.coins_to_advance = 4
    game.coinManager.progress_coins = 3
    game.stateManager.lives = 3

    game.unicorn.x = game.width * 0.65
    game.unicorn.y = game.height * 0.32
end

local function addGameplayObjects(game)
    game.trollManager:add(game.width * 0.25, game.height * 0.28, 180)
    game.trollManager:add(game.width * 0.82, game.height * 0.48, 210)
    game.coinManager.field_coins = {
        Coin:new(game.width * 0.18, game.height * 0.18, 30, 18),
        Coin:new(game.width * 0.76, game.height * 0.16, 30, 18)
    }
end

local scenarios = {
    {
        filename = 'player-name.png',
        setup = function(game)
            setCommonState(game)
            game.name_input_active = true
            game.name_input = 'Nova'
            game.scoreboardManager.current_player = nil
        end
    },
    {
        filename = 'welcome-screen.png',
        setup = function(game)
            setCommonState(game)
            game.stateManager.show_welcome = true
        end
    },
    {
        filename = 'gameplay.png',
        setup = function(game)
            setCommonState(game)
            addGameplayObjects(game)
        end
    },
    {
        filename = 'level-up.png',
        setup = function(game)
            setCommonState(game)
            addGameplayObjects(game)
            local message = string.format(game.L.level_up_msg or 'Stage %d reached!', game.progressionSystem.stage)
            game.level_up_alert = {
                title = game.L.level_up_title or 'Level Up!',
                message = message
            }
            game.level_up_flash = {t = 0.35}
        end
    },
    {
        filename = 'quiz-dialog.png',
        setup = function(game)
            setCommonState(game)
            addGameplayObjects(game)
            game.quiz_active = true
            game.quiz_problem = '14 + 9'
            game.quiz_answer = 23
            game.quiz_input = '2'
            game.quiz_timer = 24
        end
    },
    {
        filename = 'quiz-result.png',
        setup = function(game)
            setCommonState(game)
            addGameplayObjects(game)
            game.quiz_result_msg = 'Correct! Brain power rewarded! +100 coins'
            game.quiz_show_answer = false
            game.quiz_result_timer = 1
        end
    },
    {
        filename = 'scoreboard.png',
        setup = function(game)
            setCommonState(game)
            game.show_scoreboard_pause = true
            game.stateManager.manual_pause = true
        end
    },
    {
        filename = 'help.png',
        setup = function(game)
            setCommonState(game)
            game.helpManager.isVisible = true
            game.helpManager:calculateContentHeight()
        end
    },
    {
        filename = 'settings.png',
        setup = function(game)
            setCommonState(game)
            game.settingsManager.isVisible = true
        end
    }
}

function ScreenshotCapture:new(game)
    love.filesystem.createDirectory('generated-screenshots')

    local obj = {
        game = game,
        scenarioIndex = 1,
        captureRequested = false,
        captureComplete = false
    }
    setmetatable(obj, self)
    scenarios[1].setup(game)
    return obj
end

function ScreenshotCapture:update()
    if not self.captureComplete then
        return
    end

    self.scenarioIndex = self.scenarioIndex + 1
    if self.scenarioIndex > #scenarios then
        love.event.quit()
        return
    end

    self.captureRequested = false
    self.captureComplete = false
    scenarios[self.scenarioIndex].setup(self.game)
end

function ScreenshotCapture:afterDraw()
    if self.captureRequested then
        return
    end

    self.captureRequested = true
    local scenario = scenarios[self.scenarioIndex]
    love.graphics.captureScreenshot(function(imageData)
        imageData:encode('png', 'generated-screenshots/' .. scenario.filename)
        self.captureComplete = true
    end)
end

return ScreenshotCapture
