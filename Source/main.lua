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
local kGroundY <const> = 211
local kShieldDuration <const> = 10
local kAntigravDuration <const> = 10

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
local powerupTimer = nil
local firstPowerupTimer = nil
local antigravTimer = nil
local firstAntigravTimer = nil
local countdownTimer = nil
local bgX = 0
local countdownMsg = ""
local statusMsg = ""
local statusTimer = nil
local showCrankIndicator = false

function showStatus(msg)
    statusMsg = msg
    if statusTimer then statusTimer:remove() end
    statusTimer = playdate.timer.performAfterDelay(2000, function()
        statusMsg = ""
    end)
end

-- --- Sound Synthesis ---
local synth = playdate.sound.synth.new(playdate.sound.kWaveSquare)
local noiseSynth = playdate.sound.synth.new(playdate.sound.kWaveNoise)
local motorSynth = playdate.sound.synth.new(playdate.sound.kWaveSquare)
local motorTick = 0

function playSfx(type)
    if type == "kill" then noiseSynth:playNote("C4", 0.15, 0.08)
    elseif type == "die" then synth:playNote("C2", 0.4, 0.3)
    elseif type == "land" then synth:playNote("G1", 0.1, 0.1)
    elseif type == "descend" then noiseSynth:playNote("G5", 0.15, 0.15)
    elseif type == "powerup" then synth:playNote("C5", 0.1, 0.05); synth:playNote("E5", 0.1, 0.05); synth:playNote("G5", 0.2, 0.1)
    elseif type == "warning" then synth:playNote("A4", 0.05, 0.02)
    elseif type == "antigrav" then synth:playNote("G4", 0.1, 0.05); synth:playNote("B4", 0.1, 0.05); synth:playNote("D5", 0.2, 0.1) end
end

function updateEngineSound(rpm)
    if rpm > 1 then
        motorTick -= 1
        if motorTick <= 0 then
            motorSynth:playNote(30 + rpm * 5, 0.1, 0.02)
            motorTick = math.max(1, 6 - math.floor(rpm / 4))
        end
    end
end

-- Assets
local droneBodyImg = nil
local enemyImagetable = nil
local groundImg = nil
local cloudImg = nil
local shieldImg = nil
local antigravImg = nil
local bubbleImg = nil
local indicatorImg = nil
local antigravIndicatorImg = nil

function initAssets()
    if droneBodyImg then return end 
    droneBodyImg = gfx.image.new(30, 30)
    gfx.pushContext(droneBodyImg)
        gfx.clear(gfx.kColorClear)
        gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(2); gfx.fillEllipseInRect(7, 15, 16, 10); gfx.fillRect(10, 23, 10, 3)
        gfx.setColor(gfx.kColorWhite); gfx.fillCircleAtPoint(15, 20, 3); gfx.setColor(gfx.kColorBlack); gfx.fillCircleAtPoint(16, 19, 1)
        gfx.setLineWidth(2); gfx.drawLine(9, 25, 6, 29); gfx.drawLine(21, 25, 24, 29); gfx.drawLine(4, 29, 8, 29); gfx.drawLine(22, 29, 26, 29)
    gfx.popContext()
    enemyImagetable = gfx.imagetable.new(2, 20, 20)
    for i=1, 2 do
        local f = gfx.image.new(20, 20)
        gfx.pushContext(f)
            gfx.clear(gfx.kColorClear); gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(1); gfx.drawEllipseInRect(6, 2, 8, 8); gfx.fillEllipseInRect(2, 7, 16, 8)
            gfx.setColor(gfx.kColorWhite)
            if i == 1 then gfx.fillCircleAtPoint(5, 11, 1); gfx.fillCircleAtPoint(10, 12, 1); gfx.fillCircleAtPoint(15, 11, 1)
            else gfx.fillCircleAtPoint(7, 12, 1); gfx.fillCircleAtPoint(13, 12, 1) end
        gfx.popContext()
        enemyImagetable:setImage(i, f)
    end
    shieldImg = gfx.image.new(24, 24)
    gfx.pushContext(shieldImg)
        gfx.clear(gfx.kColorClear); gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(1)
        local outerPts = {12,1, 23,5, 23,13, 12,23, 1,13, 1,5}
        gfx.drawPolygon(table.unpack(outerPts))
        local innerPts = {12,6, 18,8, 18,12, 12,18, 6,12, 6,8}
        gfx.fillPolygon(table.unpack(innerPts))
    gfx.popContext()
    antigravImg = gfx.image.new(24, 24)
    gfx.pushContext(antigravImg)
        gfx.clear(gfx.kColorClear); gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(2)
        local pts = {12,1, 23,12, 12,23, 1,12}
        gfx.drawPolygon(table.unpack(pts))
        gfx.setLineWidth(1); local ipts = {12,5, 19,12, 12,19, 5,12}
        gfx.drawPolygon(table.unpack(ipts))
        gfx.drawTextAligned("*A*", 12, 5, kTextAlignment.center)
    gfx.popContext()
    bubbleImg = gfx.image.new(44, 44)
    gfx.pushContext(bubbleImg)
        gfx.clear(gfx.kColorClear); gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(2); gfx.drawCircleInRect(1, 1, 42, 42); gfx.setLineWidth(1); gfx.drawCircleInRect(5, 5, 34, 34)
    gfx.popContext()
    indicatorImg = gfx.image.new(20, 20)
    gfx.pushContext(indicatorImg)
        gfx.clear(gfx.kColorClear); gfx.setColor(gfx.kColorBlack); gfx.fillTriangle(10, 18, 2, 5, 18, 5); gfx.drawTextAligned("!", 10, -2, kTextAlignment.center)
    gfx.popContext()
    antigravIndicatorImg = gfx.image.new(20, 20)
    gfx.pushContext(antigravIndicatorImg)
        gfx.clear(gfx.kColorClear); gfx.setColor(gfx.kColorBlack); gfx.fillTriangle(10, 18, 2, 5, 18, 5); gfx.drawTextAligned("*A*", 10, -3, kTextAlignment.center)
    gfx.popContext()
    groundImg = gfx.image.new(400, 20)
    gfx.pushContext(groundImg)
        gfx.clear(gfx.kColorClear); gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 5, 400, 15); gfx.setColor(gfx.kColorWhite); gfx.setLineWidth(1)
        for i=0, 50 do local x = math.random(0, 399); local y = math.random(7, 18); gfx.drawLine(x, y, x + 1, y - 1) end
        gfx.setLineWidth(2); for i=0, 8 do local x = i * 50 + 10; gfx.drawLine(x, 5, x - 10, 20) end
    gfx.popContext()
    cloudImg = gfx.image.new(50, 25)
    gfx.pushContext(cloudImg)
        gfx.clear(gfx.kColorClear); gfx.setColor(gfx.kColorWhite); gfx.fillCircleAtPoint(25, 12, 10); gfx.fillCircleAtPoint(15, 15, 8); gfx.fillCircleAtPoint(35, 15, 8)
        gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(1); gfx.drawCircleAtPoint(25, 12, 10); gfx.drawCircleAtPoint(15, 15, 8); gfx.drawCircleAtPoint(35, 15, 8)
        gfx.setColor(gfx.kColorWhite); gfx.fillCircleAtPoint(25, 12, 9); gfx.fillCircleAtPoint(15, 15, 7); gfx.fillCircleAtPoint(35, 15, 7)
    gfx.popContext()
end
initAssets()

-- --- Background Sprite ---
class('BackgroundSprite').extends(gfx.sprite)
function BackgroundSprite:init()
    BackgroundSprite.super.init(self); self:setSize(400, 240); self:setZIndex(-100); self:setCenter(0, 0); self:moveTo(0, 0); self:add()
end
function BackgroundSprite:draw()
    gfx.setColor(gfx.kColorWhite); gfx.fillRect(0, 0, 400, 240)
    for i=0, 3 do local cx = (i * 140 + bgX) % 480 - 50; local cy = (i * 40 + 30) % 180; cloudImg:draw(cx, cy) end
    gfx.setColor(gfx.kColorBlack); gfx.fillRect(0, 220, 400, 20); groundImg:draw(0, 220)
    gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(2); gfx.drawLine(0, 225, 400, 225)
end

-- --- Player Class ---
class('Player').extends(gfx.sprite)
function Player:init()
    Player.super.init(self); self:setSize(44, 44); self:setZIndex(100); self:add(); self:setCollideRect(12, 19, 20, 15)
    self.xPos, self.yPos, self.vx, self.vy, self.rpm, self.angle, self.shieldTime, self.antigravTime = 200, kGroundY, 0, 0, 0, 0, 0, 0
end
function Player:updateImage()
    local img = gfx.image.new(44, 44)
    gfx.pushContext(img)
        gfx.clear(gfx.kColorClear); droneBodyImg:draw(7, 7)
        gfx.setColor(gfx.kColorBlack); gfx.setLineWidth(self.rpm > kLethalRPM and 3 or 1)
        local bx = 22 + 14 * math.cos(math.rad(self.angle)); local by = 19 + 14 * math.sin(math.rad(self.angle))
        gfx.drawLine(22, 19, bx, by); gfx.drawLine(22, 19, 22 - (bx - 22), 19 - (by - 19)); gfx.fillCircleAtPoint(22, 19, 2)
        if self.shieldTime > 0 then
            local showBubble = true; if self.shieldTime < 2 and (math.floor(playdate.getElapsedTime() * 15) % 2 == 0) then showBubble = false end
            if showBubble then bubbleImg:draw(0, 0) end
        end
        if self.antigravTime > 0 then
            local showAura = true; if self.antigravTime < 2 and (math.floor(playdate.getElapsedTime() * 15) % 2 == 0) then showAura = false end
            if showAura then
                gfx.setColor(gfx.kColorBlack)
                gfx.setLineWidth(2); gfx.drawRect(2, 2, 40, 40) -- Outer
                gfx.setLineWidth(1); gfx.drawRect(6, 6, 32, 32) -- Inner
            end
        end
    gfx.popContext()
    self:setImage(img)
end
function Player:update()
    local change = playdate.getCrankChange(); self.rpm = math.min(kMaxRPM, math.max(0, self.rpm + math.max(0, change) * 0.25)); self.rpm *= 0.95 
    updateEngineSound(self.rpm)
    if self.shieldTime > 0 then self.shieldTime -= 0.033 end
    if self.antigravTime > 0 then self.antigravTime -= 0.033 end
    if gameState == kStatePlaying then
        local lift = self.rpm * 0.45
        if self.antigravTime <= 0 then self.vy += 0.4 end -- Apply gravity only if NO antigrav
        self.vy -= lift * 0.1
        if self.yPos < kGroundY or self.vy < 0 or self.antigravTime > 0 then
            if playdate.buttonIsPressed(playdate.kButtonDown) then self.vy += 1.2; if playdate.buttonJustPressed(playdate.kButtonDown) then playSfx("descend") end
            elseif self.antigravTime > 0 and playdate.buttonIsPressed(playdate.kButtonUp) then self.vy -= 1.2 end -- Enable UP in antigrav
            if playdate.buttonIsPressed(playdate.kButtonLeft) then self.vx -= 0.8 elseif playdate.buttonIsPressed(playdate.kButtonRight) then self.vx += 0.8 end
        end
        self.vy *= 0.94; self.vx *= 0.8; self.xPos += self.vx; self.yPos += self.vy
        if self.xPos < 22 then self.xPos = 22; self.vx = 0 end; if self.xPos > 378 then self.xPos = 378; self.vx = 0 end
        if self.yPos < 22 then self.yPos = 22; self.vy = 0.5 end 
        if self.yPos > kGroundY then 
            if self.shieldTime > 0 or self.antigravTime > 0 then self.yPos = kGroundY; self.vy = 0
            elseif self.vy > kSafeLandingSpeed then playSfx("die"); gameOver()
            else if self.vy > 0.5 then playSfx("land") end; self.yPos = kGroundY; self.vy = 0 end
        end
    else self.yPos = kGroundY; self.vy = 0 end
    self:moveTo(self.xPos, self.yPos); self.angle += self.rpm * 6; self:updateImage()
end

-- --- Enemy Class ---
class('Enemy').extends(gfx.sprite)
function Enemy:init()
    Enemy.super.init(self); self.xPos, self.yPos = math.random(15, 385), -30
    self.speed = math.random(15, 40) / 10 + (score / 350)
    self.frame, self.animDelay = 1, math.random(8, 12); self.animTimer = self.animDelay
    self:setImage(enemyImagetable:getImage(1)); self:setZIndex(50); self:add(); self:setCollideRect(2, 4, 16, 12)
end
function Enemy:update()
    self.yPos += self.speed; self:moveTo(self.xPos, self.yPos)
    self.animTimer -= 1; if self.animTimer <= 0 then self.frame = self.frame == 1 and 2 or 1; self:setImage(enemyImagetable:getImage(self.frame)); self.animTimer = self.animDelay end
    if self.yPos > 280 then self:remove() end
    if player then
        local overlaps = self:overlappingSprites()
        for i=1, #overlaps do
            if overlaps[i] == player then
                if player.shieldTime > 0 or (player.rpm > kLethalRPM and (self.yPos - player.yPos) < 2) then self:remove(); score += 10; playSfx("kill"); if player.shieldTime <= 0 then playdate.display.setOffset(math.random(-2,2), math.random(-2,2)) end
                else playSfx("die"); gameOver() end
                break
            end
        end
    end
end

-- --- Indicators ---
class('Indicator').extends(gfx.sprite)
function Indicator:init(x, img)
    Indicator.super.init(self); self.x = x; self:setImage(img); self:setZIndex(10); self:moveTo(x, 15); self:add()
    self.blink = 0; playSfx("warning")
end
function Indicator:update()
    self.blink += 1; if math.floor(self.blink / 5) % 2 == 0 then self:setVisible(true) else self:setVisible(false) end
end

-- --- Power-Ups ---
class('ShieldPowerUp').extends(gfx.sprite)
function ShieldPowerUp:init(x)
    ShieldPowerUp.super.init(self); self.xPos, self.yPos = x, -20; self.speed = 2
    self:setImage(shieldImg); self:setZIndex(40); self:add(); self:setCollideRect(0, 0, 24, 24)
end
function ShieldPowerUp:update()
    self.yPos += self.speed; self:moveTo(self.xPos, self.yPos)
    if self.yPos > 280 then self:remove() end
    if player then
        local overlaps = self:overlappingSprites()
        for i=1, #overlaps do
            if overlaps[i] == player then 
                player.shieldTime = kShieldDuration; 
                playSfx("powerup"); 
                showStatus("Shields: ON")
                self:remove(); break 
            end
        end
    end
end

class('AntigravPowerUp').extends(gfx.sprite)
function AntigravPowerUp:init(x)
    AntigravPowerUp.super.init(self); self.xPos, self.yPos = x, -20; self.speed = 2
    self:setImage(antigravImg); self:setZIndex(40); self:add(); self:setCollideRect(0, 0, 24, 24)
end
function AntigravPowerUp:update()
    self.yPos += self.speed; self:moveTo(self.xPos, self.yPos)
    if self.yPos > 280 then self:remove() end
    if player then
        local overlaps = self:overlappingSprites()
        for i=1, #overlaps do
            if overlaps[i] == player then 
                player.antigravTime = kAntigravDuration; 
                playSfx("antigrav"); 
                showStatus("Antigravity: ON")
                self:remove(); break 
            end
        end
    end
end

-- --- Game Loop ---
function stopAllTimers()
    local all = playdate.timer.allTimers(); for _, t in ipairs(all) do t:remove() end
end

function startCountdown()
    stopAllTimers(); gfx.sprite.removeAll(); score = 0; bgX = 0; BackgroundSprite(); player = Player(); gameState = kStateCountdown; countdownMsg = "3"; statusMsg = ""; showCrankIndicator = false
    playdate.timer.new(1000, function() countdownMsg = "2" end); playdate.timer.new(2000, function() countdownMsg = "1" end)
    countdownTimer = playdate.timer.new(3000, function() 
        countdownMsg = ""; showCrankIndicator = true; playdate.ui.crankIndicator:start(); gameState = kStatePlaying
        spawnTimer = playdate.timer.new(1500, function() Enemy() end); spawnTimer.repeats = true
        
        -- Rare Antigrav Cycle (First at 45s, then 60-90s)
        firstAntigravTimer = playdate.timer.performAfterDelay(45000, function()
            local function spawnAntigrav()
                local x = math.random(30, 370); local ind = Indicator(x, antigravIndicatorImg)
                playdate.timer.new(1000, function() ind:remove(); AntigravPowerUp(x) end)
                antigravTimer = playdate.timer.performAfterDelay(math.random(60000, 90000), spawnAntigrav)
            end
            spawnAntigrav()
        end)

        -- Shield Cycle
        firstPowerupTimer = playdate.timer.performAfterDelay(25000, function()
            local function spawnShield()
                local x = math.random(30, 370); local ind = Indicator(x, indicatorImg)
                playdate.timer.new(1000, function() ind:remove(); ShieldPowerUp(x) end)
                powerupTimer = playdate.timer.performAfterDelay(math.random(25000, 45000), spawnShield)
            end
            spawnShield()
        end)
    end)
    playdate.timer.new(5000, function() showCrankIndicator = false end)
end

function gameOver()
    gameState = kStateGameOver; if score > highscore then highscore = score; playdate.datastore.write({highscore = highscore}, "highscore.json") end
    stopAllTimers(); playdate.display.setOffset(0, 0); showCrankIndicator = false; if engineActive then motorSynth:stop(); engineActive = false end
end

function drawTitle()
    gfx.clear(gfx.kColorWhite); gfx.setColor(gfx.kColorBlack); gfx.drawTextAligned("*WHIRLIGIG WARRIOR*", 200, 80, kTextAlignment.center)
    local label = "Press        to Start"; local lw, lh = gfx.getTextSize(label); local lx = 200 - lw/2; gfx.drawText(label, lx, 140)
    local cx = lx + gfx.getTextSize("Press    ") + 4; gfx.setColor(gfx.kColorBlack); gfx.fillCircleAtPoint(cx, 151, 11)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite); gfx.drawTextAligned("A", cx, 142, kTextAlignment.center); gfx.setImageDrawMode(gfx.kDrawModeCopy)
    gfx.setColor(gfx.kColorBlack); gfx.drawTextAligned("Designed by Rezza, coded by Gemini", 200, 210, kTextAlignment.center)
end

function drawGameOver()
    gfx.setColor(gfx.kColorWhite); gfx.fillRect(50, 70, 300, 100); gfx.setColor(gfx.kColorBlack); gfx.drawRect(50, 70, 300, 100)
    gfx.drawTextAligned("GAME OVER", 200, 85, kTextAlignment.center); gfx.drawTextAligned("Score: " .. score, 200, 110, kTextAlignment.center)
    local label = "Press        to Restart"; local lw, lh = gfx.getTextSize(label); local lx = 200 - lw/2; gfx.drawText(label, lx, 140)
    local cx = lx + gfx.getTextSize("Press    ") + 4; gfx.setColor(gfx.kColorBlack); gfx.fillCircleAtPoint(cx, 151, 11)
    gfx.setImageDrawMode(gfx.kDrawModeFillWhite); gfx.drawTextAligned("A", cx, 142, kTextAlignment.center); gfx.setImageDrawMode(gfx.kDrawModeCopy)
end

function playdate.update()
    if gameState == kStateTitle then drawTitle(); if playdate.buttonJustPressed(playdate.kButtonA) then startCountdown() end
    elseif gameState == kStateCountdown or gameState == kStatePlaying then
        bgX += 0.4; local ox, oy = playdate.display.getOffset()
        if ox ~= 0 or oy ~= 0 then playdate.display.setOffset(0,0) end
        gfx.sprite.update(); playdate.timer.updateTimers(); gfx.setColor(gfx.kColorBlack)
        gfx.drawText("SCORE: " .. score, 10, 10); gfx.drawRect(300, 22, 80, 8); gfx.fillRect(300, 22, (player.rpm / kMaxRPM) * 80, 8); gfx.drawLine(300 + (kLethalRPM / kMaxRPM) * 80, 20, 300 + (kLethalRPM / kMaxRPM) * 80, 32)
        if countdownMsg ~= "" then
            gfx.drawTextAligned("*" .. countdownMsg .. "*", 200, 100, kTextAlignment.center)
        end

        if statusMsg ~= "" then
            gfx.drawTextAligned("*" .. statusMsg .. "*", 200, 160, kTextAlignment.center)
        end

        if showCrankIndicator then
            playdate.ui.crankIndicator:update()
        end

    elseif gameState == kStateGameOver then drawGameOver(); if playdate.buttonJustPressed(playdate.kButtonA) then startCountdown() end end
end
gfx.sprite.setAlwaysRedraw(true)
