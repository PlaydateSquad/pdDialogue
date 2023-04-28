import "CoreLibs/object"
import "CoreLibs/graphics"

import "pdDialogue"

local gfx <const> = playdate.graphics

local width, height, padding = 390, 48, 8
local x, y = 5, 186
local text = [[Hey.

Yeah?

You ever wonder why we're here?

It's one of life's great mysteries isn't it?
Why are we here?

I mean, are we the product of some cosmic coincidence, or is there really a God watching everything? You know, with a plan for us and stuff.

I don't know, man, but it keeps me up at night.

...What?!

I mean why are we out here, in this canyon?

Oh. Uh... yeah.

What was all that stuff about God?

Uh...hm?
Nothing.

You wanna talk about it?

No.

You sure?

Yeah.]]

-- Create the box with the text and dimensions
local dialogue = pdDialogueBox(text, width, height, padding)
-- Add input handlers from our class's default
playdate.inputHandlers.push(dialogue:getInputHandlers())
-- When the box closes, pop the handlers
function dialogue:onClose()
    playdate.inputHandlers.pop()
end
dialogue:enable()

function playdate.update()
	gfx.clear(gfx.kColorWhite)
	-- You only want to draw the box when it's enabled
	if dialogue.enabled then
		dialogue:update()
		dialogue:draw(x, y)
	end
end
