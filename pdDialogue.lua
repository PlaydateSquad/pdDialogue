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
    for line in text:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end
    local wrapped = pdDialogue.wrap(lines, width, font)
    return pdDialogue.paginate(wrapped, height, font)
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
class("DialogueBox").extends(playdate.graphics.sprite)

function DialogueBox:init(text, width, height, nineSlice)
    DialogueBox.super.init(self)

    self.currentPage = 1
    self.currentIndex = 1  -- Goes from 1 to #self.text[self.currentPage]
    self.speed = 1 -- char per frame
    self.width = width
    self.height = height
    self.nineSlice = nineSlice

    self:setText(text)
    self:setImage(playdate.graphics.image.new(width, height))
end

function DialogueBox:setText(text)
    self.text = pdDialogue.process(text)
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
    image:clear(playdate.graphics.kColorWhite)
    playdate.graphics.pushContext(image)
        -- If ninSlice, draw nineSlice
        -- Else draw rectangle
        -- Add text to image using currentPage to pick the page and currentIndex to animate
    playdate.graphics.popContext()
end

function DialogueBox:update()
    self.progress += self.speed
    self:drawDialogue()
end
