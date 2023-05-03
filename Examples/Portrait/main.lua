import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"

import "pdDialogue"

local gfx <const> = playdate.graphics

local portrait = gfx.image.new("assets/icon"):scaledImage(2)
local width, height, padding = 390, 65, 8
local x, y = 5, 170
local text = [[Dialogue... *it's pretty rad!*]]

pdPortraitDialogueBox = {}
class("pdPortraitDialogueBox").extends(pdDialogueBox)

function pdPortraitDialogueBox:init(name, drawable, text, width, height, padding)
    self.name = name
    self.portrait = drawable
    self.portrait_width, self.portrait_height = self.portrait:getSize()
	self:setAlignment(kTextAlignment.left)
    pdDialogueBox.init(self, text, width - self.portrait_width, height, padding)
end
function pdPortraitDialogueBox:setAlignment(alignment)
    self.alignment = alignment
	self.portrait_x_position = self.alignment == kTextAlignment.left and 0 or self.width + self.portrait_width
end
function pdPortraitDialogueBox:draw(x, y)
	local offset = self.alignment == kTextAlignment.left and self.portrait_width or 0
    pdPortraitDialogueBox.super.draw(self, x + offset, y)
end
function pdPortraitDialogueBox:drawBackground(x, y)
    pdPortraitDialogueBox.super.drawBackground(self, x, y)

    self.portrait:drawCentered(x + self.portrait_x_position - self.portrait_width / 2, y + self.portrait_height / 2)
    gfx.drawTextAligned(self.name, x + self.portrait_x_position - self.portrait_width / 2, y + self.portrait_height - 8, kTextAlignment.center)
end

local dialogue = pdPortraitDialogueBox("pd", portrait, text, width, height, padding)
dialogue:setAlignment(kTextAlignment.right)
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
