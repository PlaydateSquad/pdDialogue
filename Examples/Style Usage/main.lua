-- Library imports needed
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/nineslice"

-- pdDialogue import
import "pdDialogue"

-- Locals to be used throughout this demo
local gfx <const> = playdate.graphics

local directionText = "✛"
local nineslice_1 = gfx.nineSlice.new("assets/nineslice-kenney-1", 4, 4, 8, 8)
local nineslice_2 = gfx.nineSlice.new("assets/nineslice-kenney-2", 6, 6, 4, 4)

local font1 = gfx.font.new("assets/fonts/Charlie Ninja")
local font2 = gfx.font.new("assets/fonts/Dark Seal")
local font3 = gfx.font.new("assets/fonts/Hydra")

-- Note: To use the sasser slab font please import this font yourself on usage
local sasser_slab_family = gfx.font.newFamily({
    [playdate.graphics.font.kVariantNormal] = "assets/fonts/Sasser Slab/Sasser-Slab",
    [playdate.graphics.font.kVariantBold] = "assets/fonts/Sasser Slab/Sasser-Slab-Bold",
    [playdate.graphics.font.kVariantItalic] = "assets/fonts/Sasser Slab/Sasser-Slab-Italic"
})

-- Base setup of pdDialogue:
pdDialogue.setup({
    font=font1,
    onClose = function()
        directionText = "✛"
    end
})

playdate.inputHandlers.push({
    -- Up pushed:
    upButtonUp = function()
        directionText = "⬆️"
        pdDialogue.say("Hello I am a default styled sign currently talking to you through the pdDialogue library")
    end,
    -- Right pushed:
    rightButtonUp = function()
        directionText = "➡️"
        pdDialogue.say([[I would really advise against talking to that wizard
He is annoying]], {
            width=400,
            height=30,
            x=0,
            y=214,
            font=font2,
            drawText=function(_, x, y, text)
                playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillWhite)
                font2:drawText(text, x, y)
            end,
            drawBackground=function(dialogue, x, y)
                playdate.graphics.setColor(playdate.graphics.kColorBlack)
                playdate.graphics.fillRect(x, y, dialogue.width, dialogue.height)
            end,
            drawPrompt=function(dialogue, x, y)
                pdDialogueBox.arrowPrompt(x + dialogue.width - 12, y + dialogue.height - 10, gfx.kColorWhite)
            end
        })
    end,
    -- Down pushed:
    downButtonUp = function()
        directionText = "⬇️"
        switch:setImageFlip(gfx.kImageFlippedX)
        pdDialogue.say("You just flipped the switch", {
            width=134,
            height=24,
            x=130,
            font = font3,
            nineSlice=nineslice_1,
            drawPrompt=function() end,
            onClose=function()
                directionText = "✛"
                switch:setImageFlip(gfx.kImageUnflipped)
                pdDialogue.say("But it flipped back flip flip", {
                    width=134,
                    height=24,
                    x=130,
                    font = font3,
                    nineSlice=nineslice_1,
                    drawPrompt=function() end
                })
            end
        })
    end,
    -- Left pushed:
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
    gfx.sprite.update()
    gfx.setImageDrawMode(gfx.kDrawModeCopy)
    gfx.drawTextAligned(directionText, 200, 120, kTextAlignment.center)
    pdDialogue.update()
end

function addSprite(spriteName, x, y)
    local sprite = gfx.sprite.new(gfx.image.new("assets/" .. spriteName))
    sprite:setScale(2)
    sprite:moveTo(x, y)
    sprite:add()
    return sprite
end

addSprite("sign", 200, 100)
addSprite("thief", 230, 130)
switch = addSprite("switch", 200, 154)
addSprite("wizard", 166, 130)
