------------------------------------------------
--- Dialogue classes intended to ease the    ---
--- implementation of dialogue into playdate ---
--- games. Developed by:                     ---
--- GammaGames, PizzaFuelDev and NickSr      ---
------------------------------------------------

-- You can find examples and docs at https://github.com/PizzaFuel/pdDialogue

local pd = playdate
local gfx = pd.graphics

----------------------------------------------------------------------------
-- #Section: pdDialogue
----------------------------------------------------------------------------
pdDialogue = {}

function pdDialogue.wrap(lines, width, font)
    --[[
    lines: an array of strings
    width: the maximum width of each line (in pixels)
    font: the font to use (optional, uses default font if not provided)
    ]]--
    font = font or gfx.getFont()

    local result = {}

    for _, line in ipairs(lines) do
        local currentWidth, currentLine = 0, ""

        if line == "" or font:getTextWidth(line) <= width then
            table.insert(result, line)
            goto continue
        end

        for word in line:gmatch("%S+") do
            local wordWidth = font:getTextWidth(word)
            local newLine = currentLine .. (currentLine ~= "" and " " or "") .. word
            local newWidth = font:getTextWidth(newLine)

            if newWidth >= width then
                table.insert(result, currentLine)
                currentWidth, currentLine = wordWidth, word
            else
                currentWidth, currentLine = newWidth, newLine
            end
        end

        if currentWidth ~= 0 then
            table.insert(result, currentLine)
        end

        ::continue::
    end

    return result
end

function pdDialogue.window(text, startIndex, height, font)
    --[[
    text: an array of strings (pre-wrapped)
    startIndex: the row index to start the window
    height: the height (in pixels) of the window
    font: the font to use (optional, uses default font if not provided)
    ]]--
    font = font or gfx.getFont()

    local result = {text[start_index]}
    local rows = pdDialogue.getRows(height, font) - 1

    for index = 1, rows do
        -- Check if index is out of range of the text
        if start_index + index > #text then
            break
        end

        table.insert(result, text[i])
    end

    return table.concat(result, "\n")
end

function pdDialogue.paginate(lines, height, font)
    --[[
        lines: array of strings (pre-wrapped)
        height: height to limit text (in pixels)
        font: optional, will get current font if not provided
    ]]--

    local result = {}
    local currentLine = {}

    font = font or gfx.getFont()

    local rows = pdDialogue.getRows(height, font)

    for _, line in ipairs(lines) do
        if line == "" then
            -- If line is empty and currentLine has text...
            if #currentLine > 0 then
                -- Merge currentLine and add to result
                table.insert(result, table.concat(currentLine, "\n"))
                currentLine = {}
            end
        else
            -- If over row count...
            if #currentLine >= rows then
                -- Concat currentLine, add to result, and start new line
                table.insert(result, table.concat(currentLine, "\n"))
                currentLine = { line }
            else
                table.insert(currentLine, line)
            end
        end
    end

    -- If all lines are complete and currentLine is not empty, add to result
    if #currentLine > 0 then
        table.insert(result, table.concat(currentLine, "\n"))
        currentLine = {}
    end

    return result
end

function pdDialogue.process(text, width, height, font)
    --[[
    text: string containing the text to be processed
    width: width to limit text (in pixels)
    height: height to limit text (in pixels)
    font: optional, will get current font if not provided
    ]]--
    local lines = {}
    font = font or gfx.getFont()

    -- Split newlines in text
    for line in text:gmatch("([^\n]*)\n?") do
        table.insert(lines, line)
    end

    -- Wrap the text
    local wrapped = pdDialogue.wrap(lines, width, font)

    -- Paginate the wrapped text
    local paginated = pdDialogue.paginate(wrapped, height, font)

    return paginated
end

function pdDialogue.getRows(height, font)
    font = font or gfx.getFont()
    local lineHeight = font:getHeight() + font:getLeading()
    return math.floor(height / lineHeight)
end

function pdDialogue.getRowsf(height, font)
    font = font or gfx.getFont()
    local lineHeight = font:getHeight() + font:getLeading()
    return height / lineHeight
end

----------------------------------------------------------------------------
-- #Section: pdDialogueSprite
----------------------------------------------------------------------------
pdDialogueSprite = {}
class("pdDialogueSprite").extends(gfx.sprite)

function pdDialogueSprite:init(dialogue)
    --[[
        dialogue: an instance of pdDialogueBox
    ]]--
    pdDialogueSprite.super.init(self)
	self.image = gfx.image.new(dialogue.width, dialogue.height)
	self:setImage(self.image)
    self.dialogue = dialogue
    -- Remove sprite when dialogue is closed
    local onClose = self.dialogue.onClose
    function self.dialogue.onClose()
        onClose()
        self:remove()
    end
end

function pdDialogueSprite:add()
	pdDialogueSprite.super.add(self)
	if not self.dialogue.enabled then
		self.dialogue:enable()
	end
end

function pdDialogueSprite:update()
    pdDialogueSprite.super.update(self)
    -- Redraw dialogue if it has changed (update returns true)
	if self.dialogue:update() then
		self.image:clear(gfx.kColorClear)
		gfx.pushContext(self.image)
			self.dialogue:draw(0, 0)
		gfx.popContext()
		self:markDirty()
	end
end

----------------------------------------------------------------------------
-- #Section: pdDialogueBox
----------------------------------------------------------------------------
pdDialogueBox = {}
class("pdDialogueBox").extends()

function pdDialogueBox.buttonPrompt(x, y)
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    gfx.getSystemFont():drawText("Ⓐ", x, y)
end

function pdDialogueBox.arrowPrompt(x, y, color)
    gfx.setColor(color or gfx.kColorBlack)
    gfx.fillTriangle(
        x, y,
        x + 5, y + 5,
        x + 10, y
    )
end

function pdDialogueBox:init(text, width, height, font)
    --[[
        text: optional string of text to process
        width: width of dialogue box (in pixels)
        height: height of dialogue box (in pixels)
        font: font to use for drawing text
    ]]--

    pdDialogueBox.super.init(self)
    self.speed = 0.5 -- char per frame
    self.padding = 2
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

function pdDialogueBox:asSprite()
    return pdDialogueSprite(self)
end

function pdDialogueBox:getInputHandlers()
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
        end
    }
end

function pdDialogueBox:enable()
    self.enabled = true
    self:onOpen()
end

function pdDialogueBox:disable()
    self.enabled = false
    self:onClose()
end

function pdDialogueBox:setText(text)
    local font = self.font or gfx.getFont()

    if type(font) == "table" then
        font = font[gfx.font.kVariantNormal]
    end
    self.text = text
    if text ~= nil then
        self.pages = pdDialogue.process(text, self.width - self.padding * 2, self.height - self.padding * 2, font)
    end
    self:restartDialogue()
end

function pdDialogueBox:getText()
    return self.text
end

function pdDialogueBox:setPages(pages)
    self.pages = pages
    self:restartDialogue()
end

function pdDialogueBox:getPages()
    return self.pages
end

function pdDialogueBox:setWidth(width)
    self.width = width
    if self.text ~= nil then
        self:setText(self.text)
    end
end

function pdDialogueBox:getWidth()
    return self.width
end

function pdDialogueBox:setHeight(height)
    self.height = height
    if self.text ~= nil then
        self:setText(self.text)
    end
end

function pdDialogueBox:getHeight()
    return self.height
end

function pdDialogueBox:setPadding(padding)
    self.padding = padding
    -- Set text again because padding affects text wrapping
    self:setText(self.text)
end

function pdDialogueBox:getPadding()
    return self.padding
end

function pdDialogueBox:setFont(font)
    self.font = font
end

function pdDialogueBox:getFont()
    return self.font
end

function pdDialogueBox:setNineSlice(nineSlice)
    self.nineSlice = nineSlice
end

function pdDialogueBox:getNineSlice()
    return self.nineSlice
end

function pdDialogueBox:setSpeed(speed)
    self.speed = speed
end

function pdDialogueBox:getSpeed()
    return self.speed
end

function pdDialogueBox:restartDialogue()
    self.currentPage = 1
    self.currentChar = 1
    self.line_complete = false
    self.dialogue_complete = false
end

function pdDialogueBox:finishDialogue()
    self.currentPage = #self.pages
    self:finishLine()
end

function pdDialogueBox:restartLine()
    self.currentChar = 1
    self.line_complete = false
    self.dialogue_complete = false
    self.dirty = true
end

function pdDialogueBox:finishLine()
    self.currentChar = #self.pages[self.currentPage]
    self.line_complete = true
    self.dialogue_complete = self.currentPage == #self.pages
    self.dirty = true
end

function pdDialogueBox:previousPage()
    if self.currentPage - 1 >= 1 then
        self.currentPage -= 1
        self:restartLine()
    end
end

function pdDialogueBox:nextPage()
    if self.currentPage + 1 <= #self.pages then
        self.currentPage += 1
        self:restartLine()
    end
end

function pdDialogueBox:drawBackground(x, y)
    if self.nineSlice ~= nil then
        gfx.setImageDrawMode(gfx.kDrawModeCopy)
        self.nineSlice:drawInRect(x, y, self.width, self.height)
    else
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(x, y, self.width, self.height)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(x, y, self.width, self.height)
    end
end

function pdDialogueBox:drawText(x, y, text)
    gfx.setImageDrawMode(gfx.kDrawModeFillBlack)
    if self.font ~= nil then
        -- variable will be table if a font family
        if type(self.font) == "table" then
            -- Draw with font family
            gfx.drawText(text, x, y, self.font)
        else
            -- Draw using font
            self.font:drawText(text, x, y)
        end
    else
        gfx.drawText(text, x, y)
    end
end

function pdDialogueBox:drawPrompt(x, y)
    pdDialogueBox.buttonPrompt(x + self.width - 20, y + self.height - 20)
end

function pdDialogueBox:draw(x, y)
    local currentText = self.pages[self.currentPage]
    if not self.line_complete then
        currentText = currentText:sub(1, math.floor(self.currentChar))
    end
    self:drawBackground(x, y)
    self:drawText(x + self.padding, y + self.padding, currentText)
    if self.line_complete then
        self:drawPrompt(x, y)
    end
end

function pdDialogueBox:onOpen()
    -- Overrideable by user
end

function pdDialogueBox:onPageComplete()
    -- Overrideable by user
end

function pdDialogueBox:onDialogueComplete()
    -- Overrideable by user
end

function pdDialogueBox:onClose()
    -- Overrideable by user
end

function pdDialogueBox:update()
    local dirty = self.dirty
    self.dirty = false
    if not self.enabled then
        return dirty
    end
    local pageLength = #self.pages[self.currentPage]
    if self.currentChar < pageLength then
        dirty = true
        self.currentChar += self.speed
        if self.currentChar > pageLength then
            self.currentChar = pageLength
        end
    end

    local previous_line_complete = self.line_complete
    local previous_dialogue_complete = self.dialogue_complete
    self.line_complete = self.currentChar == pageLength
    self.dialogue_complete = self.line_complete and self.currentPage == #self.pages

    if previous_line_complete ~= self.line_complete then
        self:onPageComplete()
        dirty = true
    end
    if previous_dialogue_complete ~= self.dialogue_complete then
        self:onDialogueComplete()
        dirty = true
    end

    return dirty
end

----------------------------------------------------------------------------
-- #Section: pdPortraitDialogueBox
----------------------------------------------------------------------------
pdPortraitDialogueBox = {}
class("pdPortraitDialogueBox").extends(pdDialogueBox)

function pdPortraitDialogueBox:init(name, drawable, text, width, height, font)
    self.name = name
    self.portrait = drawable
    if self.portrait.getSize ~= nil then
        self.portrait_width, self.portrait_height = self.portrait:getSize()
    elseif self.portrait.getImage ~= nil then
        self.portrait_width, self.portrait_height = self.portrait:getImage(1):getSize()
    elseif self.portrait.image ~= nil then
        if type(self.portrait.image) ~= "function" then
            self.portrait_width, self.portrait_height = self.portrait.image:getSize()
        else
            self.portrait_width, self.portrait_height = self.portrait:image():getSize()
        end
    end
    pdDialogueBox.init(self, text, width - self.portrait_width, height, font)
	self:setAlignment(kTextAlignment.left)
end

function pdPortraitDialogueBox:setAlignment(alignment)
    self.alignment = alignment
    if self.alignment == kTextAlignment.left then
        self.portrait_x_position = 0
    else
        self.portrait_x_position = self.width
    end
end

function pdPortraitDialogueBox:getAlignment()
    return self.alignment
end

function pdPortraitDialogueBox:draw(x, y)
	local offset = self.alignment == kTextAlignment.left and self.portrait_width or 0
    pdPortraitDialogueBox.super.draw(self, x + offset, y)
end

function pdPortraitDialogueBox:drawBackground(x, y)
    pdPortraitDialogueBox.super.drawBackground(self, x, y)
    self:drawPortrait(x + self.portrait_x_position - self.portrait_width, y)
end

function pdPortraitDialogueBox:drawPortrait(x, y)
    if self.nineSlice ~= nil then
        self.nineSlice:drawInRect(x, y, self.portrait_width, self.portrait_height)
    else
        gfx.setColor(gfx.kColorWhite)
        gfx.fillRect(x, y, self.portrait_width, self.portrait_height)
        gfx.setColor(gfx.kColorBlack)
        gfx.drawRect(x, y, self.portrait_width, self.height)
    end

    local font = self.font or gfx.getFont()
    self.portrait:draw(x, y)
    font:drawTextAligned(
        self.name,
        x + self.portrait_width / 2,
        y + self.height - font:getHeight() - self.padding,
        kTextAlignment.center
    )
end

----------------------------------------------------------------------------
-- #Section: dialogue box used in pdDialogue
----------------------------------------------------------------------------
pdDialogue.DialogueBox_x,  pdDialogue.DialogueBox_y = 5, 186
pdDialogue.DialogueBox = pdDialogueBox(nil, 390, 48)
pdDialogue.DialogueBox_Callbacks = {}
pdDialogue.DialogueBox_Say_Default = nil
pdDialogue.DialogueBox_Say_Nils = nil
pdDialogue.DialogueBox_KeyValueMap = {
    width={
        set=function(value) pdDialogue.DialogueBox:setWidth(value) end,
        get=function() return pdDialogue.DialogueBox:getWidth() end
    },
    height={
        set=function(value) pdDialogue.DialogueBox:setHeight(value) end,
        get=function() return pdDialogue.DialogueBox:getHeight() end
    },
    x={
        set=function(value)  pdDialogue.DialogueBox_x = value end,
        get=function() return  pdDialogue.DialogueBox_x end
    },
    y={
        set=function(value)  pdDialogue.DialogueBox_y = value end,
        get=function() return  pdDialogue.DialogueBox_y end
    },
    padding={
        set=function(value) pdDialogue.DialogueBox:setPadding(value) end,
        get=function() return pdDialogue.DialogueBox:getPadding() end
    },
    font={
        set=function(value) pdDialogue.DialogueBox:setFont(value) end,
        get=function() return pdDialogue.DialogueBox:getFont() end
    },
    fontFamily={
        set=function(value) pdDialogue.DialogueBox.fontFamily = value end,
        get=function() return pdDialogue.DialogueBox.fontFamily end
    },
    nineSlice={
        set=function(value) pdDialogue.DialogueBox:setNineSlice(value) end,
        get=function() return pdDialogue.DialogueBox:getNineSlice() end
    },
    speed={
        set=function(value) pdDialogue.DialogueBox:setSpeed(value) end,
        get=function() return pdDialogue.DialogueBox:getSpeed() end
    },
    drawBackground={
        set=function(func) pdDialogue.DialogueBox_Callbacks["drawBackground"] = func end,
        get=function() return pdDialogue.DialogueBox_Callbacks["drawBackground"] end
    },
    drawText={
        set=function(func) pdDialogue.DialogueBox_Callbacks["drawText"] = func end,
        get=function() return pdDialogue.DialogueBox_Callbacks["drawText"] end
    },
    drawPrompt={
        set=function(func) pdDialogue.DialogueBox_Callbacks["drawPrompt"] = func end,
        get=function() return pdDialogue.DialogueBox_Callbacks["drawPrompt"] end
    },
    onOpen={
        set=function(func) pdDialogue.DialogueBox_Callbacks["onOpen"] = func end,
        get=function() return pdDialogue.DialogueBox_Callbacks["onOpen"] end
    },
    onPageComplete={
        set=function(func) pdDialogue.DialogueBox_Callbacks["onPageComplete"] = func end,
        get=function() return pdDialogue.DialogueBox_Callbacks["onPageComplete"] end
    },
    onDialogueComplete={
        set=function(func) pdDialogue.DialogueBox_Callbacks["onDialogueComplete"] = func end,
        get=function() return pdDialogue.DialogueBox_Callbacks["onDialogueComplete"] end
    },
    onClose={
        set=function(func) pdDialogue.DialogueBox_Callbacks["onClose"] = func end,
        get=function() return pdDialogue.DialogueBox_Callbacks["onClose"] end
    }
}
function pdDialogue.DialogueBox:drawBackground(x, y)
    if pdDialogue.DialogueBox_Callbacks["drawBackground"] ~= nil then
        pdDialogue.DialogueBox_Callbacks["drawBackground"](dialogue, x, y)
    else
        pdDialogue.DialogueBox.super.drawBackground(self, x, y)
    end
end
function pdDialogue.DialogueBox:drawText(x, y ,text)
    if pdDialogue.DialogueBox_Callbacks["drawText"] ~= nil then
        pdDialogue.DialogueBox_Callbacks["drawText"](dialogue, x, y, text)
    else
        pdDialogue.DialogueBox.super.drawText(self, x, y, text)
    end
end
function pdDialogue.DialogueBox:drawPrompt(x, y)
    if pdDialogue.DialogueBox_Callbacks["drawPrompt"] ~= nil then
        pdDialogue.DialogueBox_Callbacks["drawPrompt"](dialogue, x, y)
    else
        pdDialogue.DialogueBox.super.drawPrompt(self, x, y)
    end
end
function pdDialogue.DialogueBox:onOpen()
    pd.inputHandlers.push(self:getInputHandlers(), true)
    if pdDialogue.DialogueBox_Callbacks["onOpen"] ~= nil then
        pdDialogue.DialogueBox_Callbacks["onOpen"]()
    end
end
function pdDialogue.DialogueBox:onPageComplete()
    if pdDialogue.DialogueBox_Callbacks["onPageComplete"] ~= nil then
        pdDialogue.DialogueBox_Callbacks["onPageComplete"]()
    end
end
function pdDialogue.DialogueBox:onDialogueComplete()
    if pdDialogue.DialogueBox_Callbacks["onDialogueComplete"] ~= nil then
        pdDialogue.DialogueBox_Callbacks["onDialogueComplete"]()
    end
end
function pdDialogue.DialogueBox:onClose()
    -- Make a backup of the current onClose callback
    local current = pdDialogue.DialogueBox_Callbacks["onClose"]
    -- This will reset all (including the callbacks)
    if pdDialogue.DialogueBox_Say_Default ~= nil then
        pdDialogue.setup(pdDialogue.DialogueBox_Say_Default)
        pdDialogue.DialogueBox_Say_Default = nil
    end
    if pdDialogue.DialogueBox_Say_Nils ~= nil then
        for _, key in ipairs(pdDialogue.DialogueBox_Say_Nils) do
            pdDialogue.set(key, nil)
        end
        pdDialogue.DialogueBox_Say_Nils = nil
    end

    pd.inputHandlers.pop()
    -- If the current wasn't nil, call it
    if current ~= nil then
        current()
    end
end

----------------------------------------------------------------------------
-- #Section: pdDialogue main user functions
----------------------------------------------------------------------------
function pdDialogue.set(key, value)
    if pdDialogue.DialogueBox_KeyValueMap[key] ~= nil then
        local backup = pdDialogue.DialogueBox_KeyValueMap[key].get()
        pdDialogue.DialogueBox_KeyValueMap[key].set(value)
        return backup
    end
    return nil
end

function pdDialogue.setup(config)
    -- config: table of key value pairs. Supported keys are in pdDialogue.DialogueBox_KeyValueMap
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
    --[[
    text: string (can be multiline) to say
    config: optional table, will provide temporary overrides for this one dialogue box
    ]]--
    if config ~= nil then
        pdDialogue.DialogueBox_Say_Default, pdDialogue.DialogueBox_Say_Nils = pdDialogue.setup(config)
    end
    pdDialogue.DialogueBox:setText(text)
    pdDialogue.DialogueBox:enable()
    return pdDialogue.DialogueBox
end

function pdDialogue.update()
    if pdDialogue.DialogueBox.enabled then
        pdDialogue.DialogueBox:update()
        pdDialogue.DialogueBox:draw(pdDialogue.DialogueBox_x, pdDialogue.DialogueBox_y)
    end
end
