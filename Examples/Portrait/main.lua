import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/animation"

import "pdDialogue"

local gfx <const> = playdate.graphics

local portrait = gfx.animation.loop.new(150, gfx.imagetable.new("assets/portrait"), true)
local width, height, padding = 390, 50, 8
local x, y = 5, 170
local text = [[Dialogue... *it's pretty rad!*]]

local dialogue = pdPortraitDialogueBox("pd", portrait, text, width, height, padding)
function dialogue:onPageComplete()
    portrait.shouldLoop = false
    portrait.frame = 1
    self.dirty = true
end

playdate.inputHandlers.push(dialogue:getInputHandlers())
function dialogue:onClose()
    playdate.inputHandlers.pop()
end

local dialogueSprite = dialogue:asSprite()
dialogueSprite.image = gfx.image.new(width, height)
dialogueSprite:setImage(dialogueSprite.image)
dialogueSprite:setCenter(0, 0)
dialogueSprite:moveTo(x, y)
dialogueSprite:add()

function playdate.update()
    gfx.sprite.update()
end
