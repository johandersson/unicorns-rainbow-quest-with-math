--[[
  Rainbow Quest - Unicorn Flight with Math
  Copyright (C) 2026 Johan Andersson

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program. If not, see <https://www.gnu.org/licenses/>.
--]]

local SoundManager = {}
SoundManager.__index = SoundManager

function SoundManager:new()
    local self = setmetatable({}, SoundManager)
    self.sounds = {}
    self.enabled = true
    
    -- Generate procedural sounds using LÖVE's SoundData
    self:generateSounds()
    
    return self
end

function SoundManager:generateSounds()
    -- Coin collect sound: short, bright, ascending tone
    self.sounds.coin = self:generateTone(0.1, 800, 1200, 0.3)
    
    -- Death sound: descending, harsh tone
    self.sounds.death = self:generateTone(0.3, 600, 200, 0.5)
    
    -- Level up sound: triumphant, ascending sequence
    self.sounds.levelup = self:generateTone(0.4, 400, 800, 0.6)
    
    -- Sun reach sound: gentle, smooth, pleasant chime
    self.sounds.sun = self:generateSmoothChime()
    
    -- Troll warning sound: ominous, low growl
    self.sounds.troll = self:generateTrollGrowl()
end

function SoundManager:generateTone(duration, startFreq, endFreq, volume)
    local sampleRate = 22050
    local samples = math.floor(duration * sampleRate)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local progress = i / samples
        
        -- Frequency sweep from startFreq to endFreq
        local freq = startFreq + (endFreq - startFreq) * progress
        
        -- Envelope: fade in quickly, fade out smoothly
        local envelope = 1.0
        if progress < 0.1 then
            envelope = progress / 0.1
        elseif progress > 0.7 then
            envelope = (1.0 - progress) / 0.3
        end
        
        -- Generate sine wave with envelope
        local sample = math.sin(2 * math.pi * freq * t) * envelope * volume
        
        soundData:setSample(i, sample)
    end
    
    return love.audio.newSource(soundData)
end

function SoundManager:generateSmoothChime()
    local duration = 0.3
    local sampleRate = 22050
    local samples = math.floor(duration * sampleRate)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local progress = i / samples
        
        -- Smooth exponential decay envelope
        local envelope = math.exp(-progress * 5) * 0.4
        
        -- Pleasant harmonic frequencies (major chord: C, E, G)
        local freq1 = 523.25  -- C5
        local freq2 = 659.25  -- E5
        local freq3 = 783.99  -- G5
        
        -- Mix harmonics for pleasant sound
        local sample = (
            math.sin(2 * math.pi * freq1 * t) * 0.5 +
            math.sin(2 * math.pi * freq2 * t) * 0.3 +
            math.sin(2 * math.pi * freq3 * t) * 0.2
        ) * envelope
        
        soundData:setSample(i, sample)
    end
    
    return love.audio.newSource(soundData)
end

function SoundManager:generateTrollGrowl()
    local duration = 0.25
    local sampleRate = 22050
    local samples = math.floor(duration * sampleRate)
    local soundData = love.sound.newSoundData(samples, sampleRate, 16, 1)
    
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local progress = i / samples
        
        -- Envelope: quick attack, sustained, quick release
        local envelope = 1.0
        if progress < 0.05 then
            envelope = progress / 0.05
        elseif progress > 0.85 then
            envelope = (1.0 - progress) / 0.15
        end
        
        -- Low frequency rumble with slight modulation for "growl" effect
        local base_freq = 150
        local modulation = math.sin(2 * math.pi * 8 * t) * 30
        local freq = base_freq + modulation
        
        -- Add some noise for gritty texture
        local noise = (math.random() * 2 - 1) * 0.15
        
        -- Mix sine wave with noise
        local sample = (math.sin(2 * math.pi * freq * t) * 0.7 + noise * 0.3) * envelope * 0.35
        
        soundData:setSample(i, sample)
    end
    
    return love.audio.newSource(soundData)
end

function SoundManager:play(soundName)
    if not self.enabled then return end
    
    local sound = self.sounds[soundName]
    if sound then
        -- Clone the source to allow overlapping sounds
        local clone = sound:clone()
        clone:play()
    end
end

function SoundManager:toggle()
    self.enabled = not self.enabled
end

function SoundManager:setEnabled(enabled)
    self.enabled = enabled
end

return SoundManager
