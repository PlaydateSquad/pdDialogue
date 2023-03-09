import "CoreLibs/object"
import "CoreLibs/graphics"

import "pdDialogue"

pdDialogue.say("Hello, World!")

function playdate.update()
    pdDialogue.update()
end
