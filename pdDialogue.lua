pdDialogue = {}

function pdDialogue.wrap(lines, width, font)
    -- lines: array of strings
    -- width: width to limit text (in pixels)
    -- font: optional, will get current font if not provided

    local _font = pdDialogue.getNormalFont(font)
    local result = {}
    for _, line in ipairs(lines) do
        local currentWidth = 0
        local currentLine = ""
        if line == "" then
            -- Insert blank lines without processing
            table.insert(result, line)
        elseif _font:getTextWidth(line) <= width then
            -- Insert short enough lines without processing
            table.insert(result, line)
        else
            -- Iterate through every word (split by whitespace) in the line
            for word in line:gmatch("%S+") do
                local wordWidth = _font:getTextWidth(word)
                if currentWidth == 0 then
                    -- If current line is empty, set to word
                    currentWidth = wordWidth
                    currentLine = word
                else
                    -- If not, concatonate the strings and get width
                    local newLine = currentLine .. " " .. word
                    local newWidth = _font:getTextWidth(newLine)
                    if newWidth >= width then
                        table.insert(result, currentLine)
                        currentWidth = wordWidth
                        currentLine = word
                    else
                        currentWidth = newWidth
                        currentLine = newLine
                    end
                end
            end
            -- If line is complete and currentLine is not empty, add to result
            if currentWidth ~= 0 then
                table.insert(result, currentLine)
            end
        end
    end
    return result
end

function pdDialogue.window(text, start_index, height, font)
    -- lines: array of strings (pre-wrapped)
    -- start_index: row index to start window
    -- rows: number of rows to render
    local result = {text[start_index]}
    local _font = pdDialogue.getNormalFont(font)
    -- Subtract one because we start with 1 row
    local rows = pdDialogue.getRows(height, _font) - 1
    for index = 1, rows do
        -- Check if index is out of range of the text
        if start_index + index > #text then
            break
        end

        table.insert(result, text[start_index + index])
    end
    -- Return a single string
    return table.concat(result, "\n")
end

function pdDialogue.paginate(lines, height, font)
    -- lines: array of strings (pre-wrapped)
    -- height: height to limit text (in pixels)
    -- font: optional, will get current font if not provided
    local result = {}
    local currentLine = {}
    local _font = pdDialogue.getNormalFont(font)
    local rows = pdDialogue.getRows(height, _font)
    for _, line in ipairs(lines) do
        if line == "" then
            -- If line is empty and currentLine has text...
            if #currentLine ~= 0 then
                -- Merge currentLine and add to result
                table.insert(result, table.concat(currentLine, "\n"))
                currentLine = {}
            end
        else
            -- If over row count...
            if #currentLine >= rows then
                -- Concat currentLine, add to result, and start new line
                table.insert(result, table.concat(currentLine, "\n"))
                currentLine = {line}
            else
                table.insert(currentLine, line)
            end
        end
    end
    -- If all lines are complete and currentLine is not empty, add to result
    if #currentLine ~= 0 then
        table.insert(result, table.concat(currentLine, "\n"))
        currentLine = {}
    end
    return result
end

function pdDialogue.process(text, width, height, font)
    -- lines: array of strings (pre-wrapped)
    -- width: width to limit text (in pixels)
    -- height: height to limit text (in pixels)
    local lines = {}
    local _font = pdDialogue.getNormalFont(font)

    -- Split newlines in text
    for line in text:gmatch("([^\n]*)\n?") do
        table.insert(lines, line)
    end
    local wrapped = pdDialogue.wrap(lines, width, _font)
    local paginated = pdDialogue.paginate(wrapped, height, _font)
    return paginated
end

function pdDialogue.getNormalFont(font)
    if font == nil then
        return playdate.graphics.getFont()
    elseif type(font) == "table" then
        return font[playdate.graphics.font.kVariantNormal]
    end
    return font
end

function pdDialogue.getRows(height, font)
    local _font = pdDialogue.getNormalFont(font)
    -- Use integer division
    return height // (_font:getHeight() + _font:getLeading())
end

function pdDialogue.getRowsf(height, font)
    local _font = pdDialogue.getNormalFont(font)
    -- Use integer division
    return height / (_font:getHeight() + _font:getLeading())
end

DialogueBox = {}
class("DialogueBox").extends()

function DialogueBox.buttonPrompt(x, y)
    playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillBlack)
    playdate.graphics.getSystemFont():drawText("Ⓐ", x, y)
end

function DialogueBox.arrowPrompt(x, y, color)
    playdate.graphics.setColor(color or playdate.graphics.kColorBlack)
    playdate.graphics.fillTriangle(
        x, y,
        x + 5, y + 5,
        x + 10, y
    )
end

function DialogueBox:init(text, width, height, padding, font)
    -- text: optional string of text to process
    -- width: width of dialogue box (in pixels)
    -- height: height of dialogue box (in pixels)
    -- padding: internal padding of dialogue box (in pixels)
    -- font: font to use for drawing text
    DialogueBox.super.init(self)
    self.speed = 0.5 -- char per frame
    self.padding = padding or 0
    self.width = width
    self.height = height
    self.font = font
    self.enabled = false
    self.line_complete = false
    self.dialogue_complete = false

    if text ~= nil then
        self:setText(text)
    end
end

function DialogueBox:getInputHandlers()
    return {
        AButtonDown = function()
            self:setSpeed(2)
            if self.dialogue_complete then
                self:disable()
            elseif self.line_complete then
                self:nextPage()
            end
        end,
        AButtonUp = function()
            self:setSpeed(0.5)
        end,
        BButtonDown = function()
            if self.line_complete then
                if self.dialogue_complete then
                    self:disable()
                else
                    self:nextPage()
                    self:finishLine()
                end
            else
                self:finishLine()
            end
        end,
        BButtonUp = function()
            self:setSpeed(0.5)
        end
    }
end

function DialogueBox:enable()
    self.enabled = true
    self:onOpen()
end

function DialogueBox:disable()
    self.enabled = false
    self:onClose()
end

function DialogueBox:setText(text)
    self.text = text
    self.pages = pdDialogue.process(text, self.width - self.padding, self.height - self.padding, self.font)
    self:restartDialogue()
end

function DialogueBox:getText()
    return self.text
end

function DialogueBox:setPages(pages)
    self.pages = pages
    self:restartDialogue()
end

function DialogueBox:getPages()
    return self.pages
end

function DialogueBox:setWidth(width)
    self.width = width
    if self.text ~= nil then
        self:setText(self.text)
    end
end

function DialogueBox:getWidth()
    return self.width
end

function DialogueBox:setHeight(height)
    self.height = height
    if self.text ~= nil then
        self:setText(self.text)
    end
end

function DialogueBox:getHeight()
    return self.height
end

function DialogueBox:setPadding(padding)
    self.padding = padding
    self:setText(self.text)
end

function DialogueBox:getPadding()
    return self.padding
end

function DialogueBox:setFont(font)
    self.font = font
end

function DialogueBox:getFont()
    return self.font
end

function DialogueBox:setNineSlice(nineSlice)
    self.nineSlice = nineSlice
end

function DialogueBox:getNineSlice()
    return self.nineSlice
end

function DialogueBox:setSpeed(speed)
    self.speed = speed
end

function DialogueBox:getSpeed()
    return self.speed
end

function DialogueBox:restartDialogue()
    self.currentPage = 1
    self.currentChar = 1
    self.line_complete = false
    self.dialogue_complete = false
end

function DialogueBox:finishDialogue()
    self.currentPage = #self.pages
    self:finishLine()
end

function DialogueBox:restartLine()
    self.currentChar = 1
    self.line_complete = false
    self.dialogue_complete = false
end

function DialogueBox:finishLine()
    self.currentChar = #self.pages[self.currentPage]
    self.line_complete = true
    self.dialogue_complete = self.currentPage == #self.pages
end

function DialogueBox:previousPage()
    if self.currentPage - 1 >= 1 then
        self.currentPage -= 1
        self:restartLine()
    end
end

function DialogueBox:nextPage()
    if self.currentPage + 1 <= #self.pages then
        self.currentPage += 1
        self:restartLine()
    end
end

function DialogueBox:drawBackground(x, y)
    if self.nineSlice ~= nil then
        self.nineSlice:drawInRect(x, y, self.width, self.height)
    else
        playdate.graphics.setColor(playdate.graphics.kColorWhite)
        playdate.graphics.fillRect(x, y, self.width, self.height)
        playdate.graphics.setColor(playdate.graphics.kColorBlack)
        playdate.graphics.drawRect(x, y, self.width, self.height)
    end
end

function DialogueBox:drawText(x, y, text)
    playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillBlack)
    if self.font ~= nil then
        -- variable will be table if a font family
        if type(self.font) == "table" then
            -- Draw with font family
            playdate.graphics.drawText(text, x, y, self.font)
        else
            -- Draw using font
            self.font:drawText(text, x, y)
        end
    else
        playdate.graphics.drawText(text, x, y)
    end
end

function DialogueBox:drawPrompt(x, y)
    DialogueBox.buttonPrompt(x + self.width - 20, y + self.height - 20)
end

function DialogueBox:draw(x, y)
    local currentText = self.pages[self.currentPage]
    if not self.line_complete then
        currentText = currentText:sub(1, math.floor(self.currentChar))
    end
    self:drawBackground(x, y)
    self:drawText(x + self.padding // 2, y + self.padding // 2, currentText)
    if self.line_complete then
        self:drawPrompt(x, y)
    end
end

function DialogueBox:onOpen()
    -- Override by user
end

function DialogueBox:onPageComplete()
    -- Override by user
end

function DialogueBox:onDialogueComplete()
    -- Override by user
end

function DialogueBox:onClose()
    -- Override by user
end

function DialogueBox:update()
    local pageLength = #self.pages[self.currentPage]
    self.currentChar += self.speed
    if self.currentChar > pageLength then
        self.currentChar = pageLength
    end

    local previous_line_complete = self.line_complete
    local previous_dialogue_complete = self.dialogue_complete
    self.line_complete = self.currentChar == pageLength
    self.dialogue_complete = self.line_complete and self.currentPage == #self.pages

    if previous_line_complete ~= self.line_complete then
        self:onPageComplete()
    end
    if previous_dialogue_complete ~= self.dialogue_complete then
        self:onDialogueComplete()
    end
end

local dialogue_x, dialogue_y = 5, 186
local dialogue = DialogueBox(nil, 390, 48, 8)
local callbacks = {}
local say_default, say_nils
local key_value_map = {
    width={
        set=function(value) dialogue:setWidth(value) end,
        get=function() return dialogue:getWidth() end
    },
    height={
        set=function(value) dialogue:setHeight(value) end,
        get=function() return dialogue:getHeight() end
    },
    x={
        set=function(value) dialogue_x = value end,
        get=function() return dialogue_x end
    },
    y={
        set=function(value) dialogue_y = value end,
        get=function() return dialogue_y end
    },
    padding={
        set=function(value) dialogue:setPadding(value) end,
        get=function() return dialogue:getPadding() end
    },
    font={
        set=function(value) dialogue:setFont(value) end,
        get=function() return dialogue:getFont() end
    },
    nineSlice={
        set=function(value) dialogue:setNineSlice(value) end,
        get=function() return dialogue:getNineSlice() end
    },
    speed={
        set=function(value) dialogue:setSpeed(value) end,
        get=function() return dialogue:getSpeed() end
    },
    drawBackground={
        set=function(func) callbacks["drawBackground"] = func end,
        get=function() return callbacks["drawBackground"] end
    },
    drawText={
        set=function(func) callbacks["drawText"] = func end,
        get=function() return callbacks["drawText"] end
    },
    drawPrompt={
        set=function(func) callbacks["drawPrompt"] = func end,
        get=function() return callbacks["drawPrompt"] end
    },
    onOpen={
        set=function(func) callbacks["onOpen"] = func end,
        get=function() return callbacks["onOpen"] end
    },
    onPageComplete={
        set=function(func) callbacks["onPageComplete"] = func end,
        get=function() return callbacks["onPageComplete"] end
    },
    onDialogueComplete={
        set=function(func) callbacks["onDialogueComplete"] = func end,
        get=function() return callbacks["onDialogueComplete"] end
    },
    onClose={
        set=function(func) callbacks["onClose"] = func end,
        get=function() return callbacks["onClose"] end
    }
}
function dialogue:drawBackground(x, y)
    if callbacks["drawBackground"] ~= nil then
        callbacks["drawBackground"](dialogue, x, y)
    else
        dialogue.super.drawBackground(self, x, y)
    end
end
function dialogue:drawText(x, y ,text)
    if callbacks["drawText"] ~= nil then
        callbacks["drawText"](dialogue, x, y, text)
    else
        dialogue.super.drawText(self, x, y, text)
    end
end
function dialogue:drawPrompt(x, y)
    if callbacks["drawPrompt"] ~= nil then
        callbacks["drawPrompt"](dialogue, x, y)
    else
        dialogue.super.drawPrompt(self, x, y)
    end
end
function dialogue:onOpen()
    playdate.inputHandlers.push(self:getInputHandlers(), true)
    if callbacks["onOpen"] ~= nil then
        callbacks["onOpen"]()
    end
end
function dialogue:onPageComplete()
    if callbacks["onPageComplete"] ~= nil then
        callbacks["onPageComplete"]()
    end
end
function dialogue:onDialogueComplete()
    if callbacks["onDialogueComplete"] ~= nil then
        callbacks["onDialogueComplete"]()
    end
end
function dialogue:onClose()
    -- Make a backup of the current onClose callback
    local current = callbacks["onClose"]
    -- This will reset all (including the callbacks)
    if say_default ~= nil then
        pdDialogue.setup(say_default)
        say_default = nil
    end
    if say_nils ~= nil then
        for _, key in ipairs(say_nils) do
            pdDialogue.set(key, nil)
        end
        say_nils = nil
    end

    playdate.inputHandlers.pop()
    -- If the current wasn't nil, call it
    if current ~= nil then
        current()
    end
end

function pdDialogue.set(key, value)
    if key_value_map[key] ~= nil then
        local backup = key_value_map[key].get()
        key_value_map[key].set(value)
        return backup
    end
    return nil
end

function pdDialogue.setup(config)
    -- config: table of key value pairs. Supported keys are in key_value_map
    local backup = {}
    local nils = {}
    for key, value in pairs(config) do
        local backup_value = pdDialogue.set(key, value)
        if backup_value ~= nil then
            backup[key] = backup_value
        else
            table.insert(nils, key)
        end
    end
    return backup, nils
end

function pdDialogue.say(text, config)
    -- text: string (can be multiline) to say
    -- config: optional table, will provide temporary overrides for this one dialogue box
    if config ~= nil then
        say_default, say_nils = pdDialogue.setup(config)
    end
    dialogue:setText(text)
    dialogue:enable()
    return dialogue
end

function pdDialogue.update()
    if dialogue.enabled then
        dialogue:update()
        dialogue:draw(dialogue_x, dialogue_y)
    end
end

ScrollBox = {}
class("ScrollBox").extends()

function ScrollBox:init(text, width, height, padding, font)
    -- text: optional string of text to process
    -- width: width of dialogue box (in pixels)
    -- height: height of dialogue box (in pixels)
    -- padding: internal padding of dialogue box (in pixels)
    -- font: font to use for drawing text
    DialogueBox.super.init(self)
    self.padding = padding or 0
    self.width = width
    self.height = height
    self.image = playdate.graphics.image.new(self.width - self.padding, self.height - self.padding)
    self:setFont(font)
    self.enabled = false
    self.complete = false

    if text ~= nil then
        self:setText(text)
    end
end

function ScrollBox:enable()
    self.enabled = true
    self:onOpen()
end

function ScrollBox:disable()
    self.enabled = false
    self:onClose()
end

function ScrollBox:setText(text)
    self.text = text
    self.lines = {}
    for line in text:gmatch("([^\n]*)\n?") do
        table.insert(self.lines, line)
    end
    self.lines = pdDialogue.wrap(self.lines, self.width - self.padding, self.font)
    self:setIndex(1.0)
end

function ScrollBox:setFont(font)
    self.font = font
    local font = pdDialogue.getNormalFont(self.font)
    self.line_height = font:getHeight() + font:getLeading()
end

function ScrollBox:setWidth(width)
    self.width = width
    self.image = playdate.graphics.image.new(self.width - self.padding, self.height - self.padding)
end

function ScrollBox:setHeight(height)
    self.height = height
    self.image = playdate.graphics.image.new(self.width - self.padding, self.height - self.padding)
end

function ScrollBox:setNineSlice(nineSlice)
    self.nineSlice = nineSlice
end

function ScrollBox:setIndex(value)
    self.index = value
    local maxRow = pdDialogue.getRows(self.height, self.font)
    if self.index < 1 then
        self.index = 1
    end

    if self.index > #self.lines - maxRow + 1 then
        self.index = #self.lines - maxRow + 1
        self.complete = true
        self:onComplete()
    else
        self.complete = false
    end
    self.index_remainder = self.index % 1
end

function ScrollBox:scroll(delta)
    self:setIndex(self.index + delta)
end

function ScrollBox:drawBackground(x, y)
    if self.nineSlice ~= nil then
        self.nineSlice:drawInRect(x, y, self.width, self.height)
    else
        playdate.graphics.setColor(playdate.graphics.kColorWhite)
        playdate.graphics.fillRect(x, y, self.width, self.height)
        playdate.graphics.setColor(playdate.graphics.kColorBlack)
        playdate.graphics.drawRect(x, y, self.width, self.height)
    end
end

function ScrollBox:drawText(x, y, text)
    playdate.graphics.setImageDrawMode(playdate.graphics.kDrawModeFillBlack)
    if self.font ~= nil then
        -- variable will be table if a font family
        if type(self.font) == "table" then
            -- Draw with font family
            playdate.graphics.drawText(text, x, y, self.font)
        else
            -- Draw using font
            self.font:drawText(text, x, y)
        end
    else
        playdate.graphics.drawText(text, x, y)
    end
end

function ScrollBox:drawPrompt(x, y)
    DialogueBox.buttonPrompt(x + self.width - 20, y + self.height - 20)
end

function ScrollBox:draw(x, y)
    local text = pdDialogue.window(
        self.lines,
        math.floor(self.index),
        self.height + self.line_height + self.padding
    )

    self:drawBackground(x, y)
    self.image:clear(playdate.graphics.kColorClear)
    playdate.graphics.pushContext(self.image)
        -- Draw text with y offset
        self:drawText(
            self.padding // 2,
            (self.padding // 2) - (self.index_remainder * (self.line_height + self.padding // 2)),
            text
        )
    playdate.graphics.popContext()
    self.image:draw(x + (self.padding // 2), y + (self.padding // 2))
    if self.complete then
        self:drawPrompt(x, y)
    end
end

function ScrollBox:update()
    -- local pageLength = #self.pages[self.currentPage]
    -- self.currentChar += self.speed
    -- if self.currentChar > pageLength then
        -- self.currentChar = pageLength
    -- end

    -- local previous_line_complete = self.line_complete
    -- local previous_dialogue_complete = self.dialogue_complete
    -- self.line_complete = self.currentChar == pageLength
    -- self.dialogue_complete = self.line_complete and self.currentPage == #self.pages

    -- if previous_line_complete ~= self.line_complete then
    --     self:onPageComplete()
    -- end
    -- if previous_dialogue_complete ~= self.dialogue_complete then
    --     self:onDialogueComplete()
    -- end
end

function ScrollBox:onOpen()
    -- Override by user
end

function ScrollBox:onComplete()
    -- Override by user
end

function ScrollBox:onClose()
    -- Override by user
end
