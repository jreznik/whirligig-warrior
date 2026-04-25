import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/timer"
import "CoreLibs/ui"

local gfx <const> = playdate.graphics

-- Random Seed
math.randomseed(playdate.getSecondsSinceEpoch())

-- Constants
local kMaxRPM <const> = 20
local kLethalRPM <const> = 10
local kSafeLandingSpeed <const> = 2.0
local kGroundY <const> = 211 -- Perfectly sits on the 225 line

-- Game States
local kStateTitle = 0
local kStateCountdown = 1
local kStatePlaying = 2
local kStateGameOver = 3
local gameState = kStateTitle

-- Global Variables
local score = 0
local highscore = 0
local player = nil
local spawnTimer = nil
local bgX = 0
local countdownMsg = ""
local showCrankIndicator = false

-- --- Sound Synthesis ---
local synth = playdate.sound.synth.new(playdate.sound.kWaveSquare)
local noiseSynth = playdate.sound.synth.new(playdate.sound.kWaveNoise)
local motorSynth = playdate.sound.synth.new(playdate.sound.kWaveSquare)
local motorTick = 0

function playSfx(type)
    if type == "kill" then
        -- Crunchier noise sound instead of a beep
        noiseSynth:playNote("C4", 0.15, 0.08)
    elseif type == "die" then
        synth:playNote("C2", 0.4, 0.3)
    elseif type == "land" then
        synth:playNote("G1", 0.1, 0.1)
    elseif type == "descend" then
        -- Shorter, slightly lower pitched thruster sound
        noiseSynth:playNote("G5", 0.15, 0.15)
    end
end

-- Rhythmic motor sound (buzzing ticks)
function updateEngineSound(rpm)
    if rpm > 1 then
        motorTick -= 1
        if motorTick <= 0 then
            -- Trigger a short buzz
            motorSynth:playNote(30 + rpm * 5, 0.1, 0.02)
            -- Timing of next tick decreases as RPM increases (faster buzz)
            motorTick = math.max(1, 6 - math.floor(rpm / 4))
        end
    end
end

-- Assets
local droneBodyImg = nil
local enemyImagetable = nil
local groundImg = nil
local cloudImg = nil

function initAssets()
    if droneBodyImg then return end -- Only init once

    droneBodyImg = gfx.image.new(30, 30)
    gfx.pushContext(droneBodyImg)
        gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(2)
        gfx.drawRect(8, 16, 14, 10); gfx.fillRect(10, 18, 10, 6)
        gfx.drawLine(8, 26, 6, 29); gfx.drawLine(22, 26, 24, 29)
    gfx.popContext()

    -- UFO Imagetable (Animated Enemy)
    enemyImagetable = gfx.imagetable.new(2, 20, 20)
    
    -- UFO Frame 1
    local f1 = gfx.image.new(20, 20)
    gfx.pushContext(f1)
        gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(1)
        gfx.drawEllipseInRect(6, 2, 8, 8) -- Dome
        gfx.fillEllipseInRect(2, 7, 16, 8) -- Body
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(5, 11, 1); gfx.fillCircleAtPoint(10, 12, 1); gfx.fillCircleAtPoint(15, 11, 1)
    gfx.popContext()
    enemyImagetable:setImage(1, f1)
    
    -- UFO Frame 2
    local f2 = gfx.image.new(20, 20)
    gfx.pushContext(f2)
        gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(1)
        gfx.drawEllipseInRect(6, 2, 8, 8) -- Dome
        gfx.fillEllipseInRect(2, 7, 16, 8) -- Body
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(7, 12, 1); gfx.fillCircleAtPoint(13, 12, 1)
    gfx.popContext()
    enemyImagetable:setImage(2, f2)

    groundImg = gfx.image.new(400, 20)
    gfx.pushContext(groundImg)
        gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 5, 400, 15)
        gfx.setColor(gfx.kColorWhite); gfx.setLineWidth(1)
        for i=0, 50 do
            local x = math.random(0, 399)
            local y = math.random(7, 18)
            gfx.drawLine(x, y, x + 1, y - 1)
        end
        gfx.setLineWidth(2)
        for i=0, 8 do
            local x = i * 50 + 10
            gfx.drawLine(x, 5, x - 10, 20)
        end
    gfx.popContext()
    
    cloudImg = gfx.image.new(50, 25)
    gfx.pushContext(cloudImg)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(25, 12, 10); gfx.fillCircleAtPoint(15, 15, 8); gfx.fillCircleAtPoint(35, 15, 8)
        gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(1)
        gfx.drawCircleAtPoint(25, 12, 10); gfx.drawCircleAtPoint(15, 15, 8); gfx.drawCircleAtPoint(35, 15, 8)
        gfx.setColor(gfx.kColorWhite)
        gfx.fillCircleAtPoint(25, 12, 9); gfx.fillCircleAtPoint(15, 15, 7); gfx.fillCircleAtPoint(35, 15, 7)
    gfx.popContext()
end
initAssets()

-- --- Background Sprite ---
class('BackgroundSprite').extends(gfx.sprite)
function BackgroundSprite:init()
    BackgroundSprite.super.init(self)
    self:setSize(400, 240); self:setZIndex(-100); self:setCenter(0, 0); self:moveTo(0, 0); self:add()
end
function BackgroundSprite:draw()
    gfx.setColor(gfx.kColorWhite); gfx.fillRect(0, 0, 400, 240)
    for i=0, 3 do
        local cx = (i * 140 + bgX) % 480 - 50
        local cy = (i * 40 + 30) % 180
        cloudImg:draw(cx, cy)
    end
    gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 220, 400, 20)
    groundImg:draw(0, 220)
    gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(2)
    gfx.drawLine(0, 225, 400, 225)
end

-- --- Player Class ---
class('Player').extends(gfx.sprite)
function Player:init()
    Player.super.init(self)
    self:setSize(30, 30); self:setZIndex(100); self:add(); self:setCollideRect(5, 12, 20, 15)
    self.xPos, self.yPos = 200, kGroundY
    self.vx, self.vy, self.rpm, self.angle = 0, 0, 0, 0
end
function Player:draw(x, y, width, height)
    droneBodyImg:draw(x, y)
    gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(self.rpm > kLethalRPM and 3 or 1)
    local bx = (x + 15) + 14 * math.cos(math.rad(self.angle))
    local by = (y + 12) + 14 * math.sin(math.rad(self.angle))
    gfx.drawLine(x + 15, y + 12, bx, by); gfx.drawLine(x + 15, y + 12, (x + 15) - (bx - (x + 15)), (y + 12) - (by - (y + 12)))
    gfx.fillCircleAtPoint(x + 15, y + 12, 2)
end
function Player:update()
    local change = playdate.getCrankChange()
    self.rpm = math.min(kMaxRPM, math.max(0, self.rpm + math.max(0, change) * 0.25))
    self.rpm *= 0.95 
    
    updateEngineSound(self.rpm)

    if gameState == kStatePlaying then
        local lift = self.rpm * 0.45
        self.vy += 0.4; self.vy -= lift * 0.1
        
        -- D-pad controls work if in the air OR lifting off
        if self.yPos < kGroundY or self.vy < 0 then
            -- D-pad Down Thruster (Stronger & more consistent)
            if playdate.buttonIsPressed(playdate.kButtonDown) then 
                self.vy += 1.2 -- Increased from 0.8
                if playdate.buttonJustPressed(playdate.kButtonDown) then
                    playSfx("descend")
                end
            end
            
            if playdate.buttonIsPressed(playdate.kButtonLeft) then self.vx -= 0.8
            elseif playdate.buttonIsPressed(playdate.kButtonRight) then self.vx += 0.8 end
        end
        
        self.vy *= 0.94
        self.vx *= 0.8; self.xPos += self.vx; self.yPos += self.vy

        -- Bounds & Ground
        if self.xPos < 15 then self.xPos = 15; self.vx = 0 end
        if self.xPos > 385 then self.xPos = 385; self.vx = 0 end
        if self.yPos < 20 then self.yPos = 20; self.vy = 0.5 end 
        if self.yPos > kGroundY then 
            if self.vy > kSafeLandingSpeed then 
                playSfx("die")
                gameOver()
            else 
                if self.vy > 0.5 then playSfx("land") end
                self.yPos = kGroundY; self.vy = 0 
            end
        end
    else
        self.yPos = kGroundY
        self.vy = 0
    end
    
    self:moveTo(self.xPos, self.yPos)
    self.angle += self.rpm * 6; self:markDirty()
end

-- --- Enemy Class ---
class('Enemy').extends(gfx.sprite)
function Enemy:init()
    Enemy.super.init(self)
    self.xPos, self.yPos = math.random(15, 385), -30
    self.speed = math.random(15, 40) / 10 + (score / 350)
    
    -- Animation state
    self.frame = 1
    self.animDelay = math.random(8, 12)
    self.animTimer = self.animDelay
    
    self:setImage(enemyImagetable:getImage(1))
    self:setZIndex(50); self:add(); self:setCollideRect(2, 4, 16, 12)
end
function Enemy:update()
    self.yPos += self.speed; self:moveTo(self.xPos, self.yPos)
    
    -- Animate UFO
    self.animTimer -= 1
    if self.animTimer <= 0 then
        self.frame = self.frame == 1 and 2 or 1
        self:setImage(enemyImagetable:getImage(self.frame))
        self.animTimer = self.animDelay
    end
    
    if self.yPos > 280 then self:remove() end
    if player then
        local overlaps = self:overlappingSprites()
        for i=1, #overlaps do
            if overlaps[i] == player then
                if player.rpm > kLethalRPM and (self.yPos - player.yPos) < 2 then
                    self:remove(); score += 10
                    playSfx("kill")
                    playdate.display.setOffset(math.random(-2,2), math.random(-2,2))
                else 
                    playSfx("die")
                    gameOver() 
                end
                break
            end
        end
    end
end

-- --- Game Loop ---

function startCountdown()
    gfx.sprite.removeAll()
    score = 0; bgX = 0
    BackgroundSprite()
    player = Player()
    gameState = kStateCountdown
    countdownMsg = "3"
    showCrankIndicator = false
    playdate.timer.new(1000, function() countdownMsg = "2" end)
    playdate.timer.new(2000, function() countdownMsg = "1" end)
    playdate.timer.new(3000, function() 
        countdownMsg = ""
        showCrankIndicator = true
        playdate.ui.crankIndicator:start()
        gameState = kStatePlaying
        spawnTimer = playdate.timer.new(1500, function() Enemy() end); spawnTimer.repeats = true
    end)
    playdate.timer.new(5000, function() showCrankIndicator = false end)
end

function gameOver()
    gameState = kStateGameOver
    if score > highscore then highscore = score; playdate.datastore.write({highscore = highscore}, "highscore.json") end
    if spawnTimer then spawnTimer:remove() end
    playdate.display.setOffset(0, 0)
    showCrankIndicator = false
end

function drawTitle()
    gfx.clear(gfx.kColorWhite); gfx.setColor(gfx.kColorBlack)
    gfx.drawTextAligned("*WHIRLIGIG WARRIOR*", 200, 80, kTextAlignment.center)
    
    -- Manual drawing of Negative Circled A for "Press (A) to Start"
    local label = "Press        to Start"
    local lw, lh = gfx.getTextSize(label)
    local lx = 200 - lw/2
    gfx.drawText(label, lx, 140)
    
    -- Draw the Black Circle
    local cx = lx + gfx.getTextSize("Press    ") + 4
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(cx, 151, 11)
    
    -- Draw White "A" inside
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("A", cx, 142, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy) -- Reset to default
    
    -- Small attribution at bottom
    gfx.setColor(gfx.kColorBlack)
    gfx.drawTextAligned("Designed by Rezza, coded by Gemini", 200, 210, kTextAlignment.center)
end

function drawGameOver()
    gfx.setColor(gfx.kColorWhite); gfx.fillRect(50, 80, 300, 80)
    gfx.setColor(gfx.kColorBlack); gfx.drawRect(50, 80, 300, 80)
    gfx.drawTextAligned("GAME OVER", 200, 100, kTextAlignment.center)
    gfx.drawTextAligned("Score: " .. score, 200, 120, kTextAlignment.center)
    
    -- Manual drawing of Negative Circled A for "Press (A) to Restart"
    local label = "Press        to Restart"
    local lw, lh = gfx.getTextSize(label)
    local lx = 200 - lw/2
    gfx.drawText(label, lx, 140)
    
    local cx = lx + gfx.getTextSize("Press    ") + 4
    gfx.setColor(gfx.kColorBlack)
    gfx.fillCircleAtPoint(cx, 151, 11)
    
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite)
    gfx.drawTextAligned("A", cx, 142, kTextAlignment.center)
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function playdate.update()
    if gameState == kStateTitle then
        drawTitle()
        if playdate.buttonJustPressed(playdate.kButtonA) then startCountdown() end
    elseif gameState == kStateCountdown or gameState == kStatePlaying then
        bgX += 0.4
        local ox, oy = playdate.display.getOffset()
        if ox ~= 0 or oy ~= 0 then playdate.display.setOffset(0,0) end
        gfx.sprite.update(); playdate.timer.updateTimers()
        gfx.setColor(gfx.kColorBlack)
        gfx.drawText("SCORE: " .. score, 10, 10)
        gfx.drawRect(300, 22, 80, 8); gfx.fillRect(300, 22, (player.rpm / kMaxRPM) * 80, 8)
        gfx.drawLine(300 + (kLethalRPM / kMaxRPM) * 80, 20, 300 + (kLethalRPM / kMaxRPM) * 80, 32)
        
        if countdownMsg ~= "" then
            gfx.drawTextAligned("*" .. countdownMsg .. "*", 200, 100, kTextAlignment.center)
        end
        
        if showCrankIndicator then
            playdate.ui.crankIndicator:update()
        end
        
    elseif gameState == kStateGameOver then
        drawGameOver()
        if playdate.buttonJustPressed(playdate.kButtonA) then startCountdown() end
    end
end
gfx.sprite.setAlwaysRedraw(true)
