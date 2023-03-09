import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/nineslice"

import "pdDialogue"

local gfx <const> = playdate.graphics

local directionText = "✛"
local sign = gfx.sprite.new(gfx.image.new("assets/sign"))
sign:setScale(2)
sign:moveTo(200, 100)
sign:add()
local thief = gfx.sprite.new(gfx.image.new("assets/thief"))
thief:setScale(2)
thief:moveTo(230, 130)
thief:add()
local switch = gfx.sprite.new(gfx.image.new("assets/switch"))
switch:setScale(2)
switch:moveTo(200, 154)
switch:add()
local wizard = gfx.sprite.new(gfx.image.new("assets/wizard"))
wizard:setScale(2)
wizard:moveTo(166, 130)
wizard:add()

local asheville = gfx.font.new("assets/fonts/Asheville/Asheville Sans 14 Bold/Asheville-Sans-14-Bold")
local newsleak = gfx.font.new("assets/fonts/Newsleak Serif/Newsleak-Serif")
local oklahoma = gfx.font.new("assets/fonts/Oklahoma/Oklahoma-Bold")
local sasser_slab_family = gfx.font.newFamily({
    [playdate.graphics.font.kVariantNormal] = "assets/fonts/Sasser Slab/Sasser-Slab",
    [playdate.graphics.font.kVariantBold] = "assets/fonts/Sasser Slab/Sasser-Slab-Bold",
    [playdate.graphics.font.kVariantItalic] = "assets/fonts/Sasser Slab/Sasser-Slab-Italic"
})

local nineslice_1 = gfx.nineSlice.new("assets/nineslice-kenney-1", 4, 4, 8, 8)
local nineslice_2 = gfx.nineSlice.new("assets/nineslice-kenney-2", 6, 6, 4, 4)


pdDialogue.setup({
    font=asheville,
    onClose = function()
        directionText = "✛"
    end
})

playdate.inputHandlers.push({
    upButtonUp = function()
        directionText = "⬆️"
        pdDialogue.say("Hello! I'm currently talking to you through the pdDialogue library! I am a default styled sign :)")
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
            drawPrompt=function(dialogue, x, y)
                DialogueBox.arrowPrompt(x + dialogue.width - 12, y + dialogue.height - 10, gfx.kColorWhite)
            end
        })
    end,
    downButtonUp = function()
        directionText = "⬇️"
        switch:setImageFlip(gfx.kImageFlippedX)
        pdDialogue.say("You flipped the switch.", {
            width=134,
            height=24,
            x=130,
            font = oklahoma,
            nineSlice=nineslice_1,
            drawPrompt=function() end,
            onClose=function()
                directionText = "✛"
                switch:setImageFlip(gfx.kImageUnflipped)
                pdDialogue.say(". . . But it flipped back!", {
                    width=134,
                    height=24,
                    x=130,
                    font = oklahoma,
                    nineSlice=nineslice_1,
                    drawPrompt=function() end
                })
            end
        })
    end,
    leftButtonUp = function()
        directionText = "⬅️"
        pdDialogue.say([[What did the wizard order at the hotel?

*Broom* service! _Nyuck_ _nyuck_ _nyuck_]], {
            font=sasser_slab_family,
            nineSlice=nineslice_2
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
