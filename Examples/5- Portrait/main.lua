import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/animation"

import "pdDialogue"

local gfx <const> = playdate.graphics

local portrait = gfx.animation.loop.new(150, gfx.imagetable.new("assets/portrait"), true)
local width, height = 390, 50
local x, y = 6, 180
local text = [[Dialogue... *it's pretty rad!*]]

-- Create the portrait box with the name, portrait, and inherited init parameters
local dialogue = pdPortraitDialogueBox("pd", portrait, text, width, height)
-- If it's an animated sprite, you should restart the animation whenever the page changes
function dialogue:nextPage()
    pdPortraitDialogueBox.super.nextPage(self)
    portrait.shouldLoop = true
end
-- You also have to tell the animation to stop when the page is done
function dialogue:onPageComplete()
    portrait.shouldLoop = false
    portrait.frame = 1
    self.dirty = true
end

playdate.inputHandlers.push(dialogue:getInputHandlers())
function dialogue:onClose()
    playdate.inputHandlers.pop()
end

-- Add the box as a sprite because it's easier
local dialogueSprite = dialogue:asSprite()
dialogueSprite.image = gfx.image.new(width, height)
dialogueSprite:setImage(dialogueSprite.image)
dialogueSprite:setCenter(0, 0)
dialogueSprite:moveTo(x, y)
dialogueSprite:add()

function playdate.update()
    gfx.sprite.update()
end
