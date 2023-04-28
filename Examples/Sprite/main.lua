import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

import "pdDialogue"

local gfx <const> = playdate.graphics

local width, height, padding = 390, 48, 8
local x, y = 5, 186
local text = [[This text uses a sprite, which only draws when it changes!

This is a lot more efficient than redrawing the text every frame.]]

local dialogue = pdDialogueBox(text, width, height, padding)
playdate.inputHandlers.push(dialogue:getInputHandlers())
function dialogue:onClose()
    playdate.inputHandlers.pop()
end

local dialogueSprite = dialogue:asSprite()
dialogueSprite:setCenter(0, 0)
dialogueSprite:moveTo(x, y)
dialogueSprite:add()

function playdate.update()
    gfx.sprite.update()
end
