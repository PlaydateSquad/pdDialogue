import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/nineslice"

import "pdDialogue"

local gfx <const> = playdate.graphics

local directionText = "✛"
local sign = gfx.sprite.new(gfx.image.new("Examples/assets/sign"))
sign:setScale(2)
sign:moveTo(200, 100)
sign:add()
local thief = gfx.sprite.new(gfx.image.new("Examples/assets/thief"))
thief:setScale(2)
thief:moveTo(230, 130)
thief:add()
local switch = gfx.sprite.new(gfx.image.new("Examples/assets/switch"))
switch:setScale(2)
switch:moveTo(200, 154)
switch:add()
local wizard = gfx.sprite.new(gfx.image.new("Examples/assets/wizard"))
wizard:setScale(2)
wizard:moveTo(166, 130)
wizard:add()

local asheville = gfx.font.new("Examples/assets/fonts/Asheville/Asheville Sans 14 Bold/Asheville-Sans-14-Bold")
local newsleak = gfx.font.new("Examples/assets/fonts/Newsleak Serif/Newsleak-Serif")
local oklahoma = gfx.font.new("Examples/assets/fonts/Oklahoma/Oklahoma-Bold")
local sasser_slab_family = gfx.font.newFamily({
    [playdate.graphics.font.kVariantNormal] = "Examples/assets/fonts/Sasser Slab/Sasser-Slab",
    [playdate.graphics.font.kVariantBold] = "Examples/assets/fonts/Sasser Slab/Sasser-Slab-Bold",
    [playdate.graphics.font.kVariantItalic] = "Examples/assets/fonts/Sasser Slab/Sasser-Slab-Italic"
})
local pedallica = gfx.font.new("Examples/assets/fonts/Pedallica/font-pedallica-fun-16")

local nineslice_1 = gfx.nineSlice.new("Examples/assets/nineslice-kenney-1", 4, 4, 8, 8)
local nineslice_2 = gfx.nineSlice.new("Examples/assets/nineslice-kenney-2", 6, 6, 4, 4)


pdDialogue.setup({
    font=asheville,
    onClose = function()
        directionText = "✛"
    end
})

playdate.inputHandlers.push({
    upButtonUp = function()
        directionText = "⬆️"
        pdDialogue.say([[Hello, and thank you for checking out pdDialogue!

I am a default styled sign
:)]])
    end,
    rightButtonUp = function()
        directionText = "➡️"
        pdDialogue.say([[I would really advise against talking to that wizard...
He's annoying.]], {
            width=400,
            height=30,
            x=0,
            y=214,
            font=newsleak,
            drawText=function(_, x, y, text)
                playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
                newsleak:drawText(text, x, y)
            end,
            drawBackground=function(dialogue, x, y)
                playdate.graphics.setColor(playdate.graphics.kColorBlack)
                playdate.graphics.fillRect(x, y, dialogue.width, dialogue.height)
            end,
            drawPrompt=function() end
        })
    end,
    downButtonUp = function()
        directionText = "⬇️"
        if switch:getImageFlip() == gfx.kImageUnflipped then
            switch:setImageFlip(gfx.kImageFlippedX)
        else
            switch:setImageFlip(gfx.kImageUnflipped)
        end
        pdDialogue.say("You flipped the switch!", {
            width=134,
            height=24,
            x=130,
            font = oklahoma,
            nineSlice=nineslice_1,
            drawPrompt=function() end
        })
    end,
    leftButtonUp = function()
        directionText = "⬅️"
        pdDialogue.say([[What did the wizard order at the hotel?

*Broom* service!
_Nyuck_ _nyuck_ _nyuck_]], {
            font=pedallica,
            nineSlice=nineslice_2,
            drawText=function(_, x, y, text)
                playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillBlack)
                playdate.graphics.drawText(text, x, y, sasser_slab_family)
            end,
        })
    end,
})

function playdate.update()
    gfx.clear(gfx.kColorWhite)
    gfx.sprite.update()
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    gfx.drawTextAligned(directionText, 200, 120, kTextAlignment.center)

    pdDialogue.update()
end
