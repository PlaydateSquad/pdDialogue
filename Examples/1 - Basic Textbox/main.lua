-- Library imports needed
import "CoreLibs/object"
import "CoreLibs/graphics"

-- pdDialogue import
import "pdDialogue"

-- Say hello world
pdDialogue.say("Hello, World!")

function playdate.update()
    -- Make sure to clear the screen on every update (can be left out if sprite update gets called)
    playdate.graphics.clear(playdate.graphics.kColorWhite)
    pdDialogue.update()
end
