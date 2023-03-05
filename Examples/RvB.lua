import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/nineslice"

import "pdDialogue"

local gfx <const> = playdate.graphics

local sprites = gfx.imagetable.new("kenney-1-bit")
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

local width, height = 390, 40
local x, y = 5, 190

local dialogue = DialogueBox(text, width, height)
dialogue:setPadding(8)
dialogue:setNineSlice(gfx.nineSlice.new("nineslice-kenney-1", 4, 4, 8, 8))
function dialogue:drawPrompt(x, y, width, height, padding)
	DialogueBox.arrowPrompt(x, y, width, height, padding)
end

function playdate.AButtonDown()
    dialogue:setSpeed(2)
	if dialogue.line_complete and not dialogue.done_talking then
		dialogue:nextPage()
	end
end

function playdate.AButtonUp()
	dialogue:setSpeed(0.5)
end

function playdate.BButtonDown()
	if dialogue.line_complete then
        if not dialogue.done_talking then
			dialogue:nextPage()
			dialogue:finishLine()
		end
	else
		dialogue:finishLine()
	end
end

function playdate.BButtonUp()
	dialogue:setSpeed(0.5)
end

function playdate.update()
	gfx.clear(gfx.kColorWhite)
    dialogue:update()
	dialogue:draw(x, y)
end
