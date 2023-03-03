DialogueBox = {}
class("DialogueBox").extends(Graphics.sprite)

function DialogueBox:init(text, width, height, nineSlice)
    DialogueBox.super.init(self)

    self.currentPage = 1
    self.currentIndex = 1  -- Goes from 1 to #self.text[self.currentPage]
    self.speed = 1 -- char per frame
    self.width = width
    self.height = height
    self.nineSlice = nineSlice

    self:setText(text)
    self:setImage(Graphics.image.new(width, height))
end

function DialogueBox:setText(text)
    self.text = Paginate.process(text)
    self.currentPage = 0
    self.currentIndex = 0
    self:drawDialogue()
end

function DialogueBox:setSpeed(speed)
    self.speed = speed
end

function DialogueBox:finishLine()
    self.progress = #self.text[self.currentPage]
    self:drawDialogue()
end

function DialogueBox:advance()
    -- CHeck if last in pages, if it is then close
    self.currentPage += 1
    self:drawDialogue()
end

function DialogueBox:drawDialogue()
    local image = self:getImage()
    image:clear(Graphics.kColorWhite)
    Graphics.pushContext(image)
        -- If ninSlice, draw nineSlice
        -- Else draw rectangle
        -- Add text to image using currentPage to pick the page and currentIndex to animate
    Graphics.popContext()
end

function DialogueBox:update()
    self.progress += self.speed
    self:drawDialogue()
end