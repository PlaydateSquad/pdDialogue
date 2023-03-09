pdDialogue = {}

function pdDialogue.wrap(lines, width, font)
    -- lines: array of strings
    -- width: width to limit text (in pixels)
    -- font: optional, will get current font if not provided
    if font == nil then
        font = playdate.graphics.getFont()
    end

    local result = {}
    for _, line in ipairs(lines) do
        local currentWidth = 0
        local currentLine = ""
        if line == "" then
            -- Insert blank lines without processing
            table.insert(result, line)
        elseif font:getTextWidth(line) <= width then
            -- Insert short enough lines without processing
            table.insert(result, line)
        else
            -- Iterate through every word (split by whitespace) in the line
            for word in line:gmatch("%S+") do
                local wordWidth = font:getTextWidth(word)
                if currentWidth == 0 then
                    -- If current line is empty, set to word
                    currentWidth = wordWidth
                    currentLine = word
                else
                    -- If not, concatonate the strings and get width
                    local newLine = currentLine .. " " .. word
                    local newWidth = font:getTextWidth(newLine)
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
    if font == nil then
        font = playdate.graphics.getFont()
    end
    -- Subtract one because we start with 1 row
    local rows = pdDialogue.getRows(height, font) - 1
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
    if font == nil then
        font = playdate.graphics.getFont()
    end
    local rows = pdDialogue.getRows(height, font)
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
    if font == nil then
        font = playdate.graphics.getFont()
    end

    -- Split newlines in text
    for line in text:gmatch("([^\n]*)\n?") do
        table.insert(lines, line)
    end
    local wrapped = pdDialogue.wrap(lines, width, font)
    local paginated = pdDialogue.paginate(wrapped, height, font)
    return paginated
end

function pdDialogue.getRows(height, font)
    if font == nil then
        font = playdate.graphics.getFont()
    end
    local leading = font:getLeading()
    -- Use integer division
    return height // (font:getHeight() + leading)
end

function pdDialogue.getRowsf(height, font)
    if font == nil then
        font = playdate.graphics.getFont()
    end
    local leading = font:getLeading()
    return height / (font:getHeight() + leading)
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
                self:onClose()
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
                    self:onClose()
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
    playdate.inputHandlers.push(self:getInputHandlers(), true)
end

function DialogueBox:disable()
    if self.enabled then
        self.enabled = false
        playdate.inputHandlers.pop()
    end
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
        self.font:drawText(text, x, y)
    else
        playdate.graphics.drawText(text, x, y)
    end
end

function DialogueBox:drawPrompt(x, y)
    DialogueBox.buttonPrompt(x + self.width - 20, y + self.height - 20)
end

function DialogueBox:draw(x, y)
    if not self.enabled then
        return
    end

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
    if not self.enabled then
        return
    end

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
    fontFamily={
        set=function(value) dialogue.fontFamily = value end,
        get=function() return dialogue.fontFamily end
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

    if callbacks["onClose"] ~= nil then
        callbacks["onClose"]()
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
