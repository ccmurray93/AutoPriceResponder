-- Create main object and load AceConsole so we can use console commands
AutoPriceResponder = LibStub("AceAddon-3.0"):NewAddon("AutoPriceResponder", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")





AutoPriceResponder.selectedEntryColor = "|cffffff00"
AutoPriceResponder.optionsPanelHeight = 150

AutoPriceResponder.selectedOptionsFrameText = nil
AutoPriceResponder.selectedOptionsFrameList = nil

local commandWord = "price"

local PREFIX = "[APR]"
local helpMsg = "Use the format `price [item name/link]` to get pricing information."


-- Create our minimap icon
AutoPriceResponder.AutoPriceResponderLDB = LibStub("LibDataBroker-1.1"):NewDataObject("AutoPriceResponderDO", {
    type = "data source",
    text = "AutoPriceResponder",
    icon = "Interface\\RAIDFRAME\\ReadyCheck-Ready.blp",
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("AutoPriceResponder")
        tooltip:AddLine("|cffffff00" .. "Click to show options")
    end,
    OnClick = function(self, button) AutoPriceResponder:HandleIconClick(button) end,
})
AutoPriceResponder.icon = LibStub("LibDBIcon-1.0")

-- Called when minimap icon is clicked
function AutoPriceResponder:HandleIconClick(button)
    InterfaceOptionsFrame_OpenToCategory(self.priceOptionsFrame)
    InterfaceOptionsFrame_OpenToCategory(self.priceOptionsFrame)
end


AutoPriceResponder.defaults = {
    profile = {
        version = "1.0",
        icon = {
            hide = false,
        },
        lists = {
            [1] = {
                name = "WTB",
                prefix = "WTB",
                entries = {
                    -- [1] = {
                    --     name = "green tea leaf",
                    --     link = "",
                    --     price = "30g",
                    --     unit = "stk",
                    -- },
                },
            },
            [2] = {
                name = "WTS",
                prefix = "WTS",
                entries = {
                    -- [1] = {
                    --     name = "jade panther",
                    --     link = "",
                    --     price = "23kg",
                    --     unit = ""
                    -- },
                },
            }
        },
        listNames = {
            ["WTB"] = 1,
            ["WTS"] = 2,
        },
    },
}





function AutoPriceResponder:OnInitialize()
    -- Create our database with default values
    self.db = LibStub("AceDB-3.0"):New("AutoPriceResponderDB", self.defaults);
    self.db.RegisterCallback(self, "OnProfileChanged", "RefreshEverything")
    self.db.RegisterCallback(self, "OnProfileCopied", "RefreshEverything")
    self.db.RegisterCallback(self, "OnProfileReset", "RefreshEverything")
    
    -- Register our minimap icon
    self.icon:Register("AutoPriceResponderDO", self.AutoPriceResponderLDB, self.db.profile.icon)
    
    -- Register chat commands
    self:RegisterChatCommand("apr", "HandleChatMessageCommands")
    self:RegisterChatCommand("AutoPriceResponder", "HandleChatMessageCommands")
    -- self:RegisterChatCommand("autopriceresponder", "HandleChatMessageCommands")

    -- Register our addon message prefix
    RegisterAddonMessagePrefix(PREFIX)
end

-- Called when the addon is enabled
function AutoPriceResponder:OnEnable()
    
    -- Notify user that AutoPriceResponder is enabled, give options command
    self:Print("Daily Checklist enabled.  Use '/apr' to open the manager.")
    
    -- Initialize number of entries that will fit in interface options panel
    self.maxEntries = math.floor((InterfaceOptionsFramePanelContainer:GetHeight() - self.optionsPanelHeight) / 20)
    
    -- Create options frame
    self:CreateOptionsFrame()
    
end


function AutoPriceResponder:HandleChatMessageCommands(msg)
    InterfaceOptionsFrame_OpenToCategory(self.priceOptionsFrame)
    InterfaceOptionsFrame_OpenToCategory(self.priceOptionsFrame)
end



-- Create the options frame under the WoW interface->addons menu
function AutoPriceResponder:CreateOptionsFrame()
    -- Create addon options frame
    self.priceOptionsFrame = CreateFrame("Frame", "PriceOptionsFrame", InterfaceOptionsFramePanelContainer)
    self.priceOptionsFrame.name = "AutoPriceResponder"
    self.priceOptionsFrame:SetAllPoints(InterfaceOptionsFramePanelContainer)
    self.priceOptionsFrame:Hide()
    InterfaceOptions_AddCategory(self.priceOptionsFrame)

    -- Create addon profiles options frame
    self.priceProfilesOptions = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("AutoPriceResponder: "..self.priceProfilesOptions.name, self.priceProfilesOptions)
    self.priceProfilesFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("AutoPriceResponder: "..self.priceProfilesOptions.name, self.priceProfilesOptions.name, "AutoPriceResponder")  
    
    local function getOpt(info)
        return AutoPriceResponder.db.profile[info[#info]]
    end
    
    local function setOpt(info, value)
        AutoPriceResponder.db.profile[info[#info]] = value
        return AutoPriceResponder.db.profile[info[#info]]
    end

    -- Create options frame
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("AutoPriceResponder: Options", {
        type = "group",
        name = "Options",
        args = {
            general = {
                type = "group",
                inline = true,
                name = "",
                args = {
                    minimap = {
                        type = "group",
                        inline = true,
                        name = "Minimap Icon",
                        order = 30,
                        args = {
                            iconLabel = {
                                type = "description",
                                name = "Requires UI restart to take effect",
                                order = 10
                            },
                            icon = {
                                type = "toggle",
                                name = "Hide Minimap Icon",
                                order = 20,
                                get = function(info) return AutoPriceResponder.db.profile.icon.hide end,
                                set = function(info, value)
                                    AutoPriceResponder.db.profile.icon.hide = value
                                end,
                            }
                        },
                    },

                },
            },
        },
    })
    self.priceConfigFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("AutoPriceResponder: Options", "Options", "AutoPriceResponder")


    local priceOptionsEntryLabel = self.priceOptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    priceOptionsEntryLabel:SetPoint("TOPLEFT", 10, -10)
    priceOptionsEntryLabel:SetPoint("TOPRIGHT", 0, -10)
    priceOptionsEntryLabel:SetJustifyH("LEFT")
    priceOptionsEntryLabel:SetHeight(18)
    priceOptionsEntryLabel:SetText("New Entry") -- todo, format as New Entry: WTB/S based on list selected

    local priceOptionsEntryTextFieldLabel = self.priceOptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    priceOptionsEntryTextFieldLabel:SetPoint("TOPLEFT", 10, -30)
    priceOptionsEntryTextFieldLabel:SetPoint("TOPRIGHT", 0, -30)
    priceOptionsEntryTextFieldLabel:SetJustifyH("LEFT")
    priceOptionsEntryTextFieldLabel:SetHeight(18)
    priceOptionsEntryTextFieldLabel:SetText("Create a new entry by filling out the price information. Output format is `item price[/unit]`.")

    --[[ Add entry creation form to options frame ]]--
    -- Add item name input label
    local priceOptionsNameTextFieldLabel = self.priceOptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    priceOptionsNameTextFieldLabel:SetPoint("TOPLEFT", 89, -50)
    priceOptionsNameTextFieldLabel:SetJustifyH("LEFT")
    priceOptionsNameTextFieldLabel:SetHeight(18)
    priceOptionsNameTextFieldLabel:SetText("Item Name:")
    -- Add item name input box
    self.priceOptionsNameTextField = CreateFrame("EditBox", "PriceOptionsNameTextField", self.priceOptionsFrame, "InputBoxTemplate")
    self.priceOptionsNameTextField:SetSize(150, 28)
    self.priceOptionsNameTextField:SetPoint("TOPLEFT", 158, -46)
    self.priceOptionsNameTextField:SetMaxLetters(255)
    self.priceOptionsNameTextField:SetMultiLine(false)
    self.priceOptionsNameTextField:SetAutoFocus(false)

    -- Add item price input label
    local priceOptionsPriceTextFieldLabel = self.priceOptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    priceOptionsPriceTextFieldLabel:SetPoint("TOPLEFT", 314, -50)
    priceOptionsPriceTextFieldLabel:SetJustifyH("LEFT")
    priceOptionsPriceTextFieldLabel:SetHeight(18)
    priceOptionsPriceTextFieldLabel:SetText("Price:")
    -- Add item price input box
    self.priceOptionsPriceTextField = CreateFrame("EditBox", "PriceOptionsPriceTextField", self.priceOptionsFrame, "InputBoxTemplate")
    self.priceOptionsPriceTextField:SetSize(75, 28)
    self.priceOptionsPriceTextField:SetPoint("TOPLEFT", 349, -46)
    self.priceOptionsPriceTextField:SetMaxLetters(255)
    self.priceOptionsPriceTextField:SetMultiLine(false)
    self.priceOptionsPriceTextField:SetAutoFocus(false)

    -- Add item price unit input label
    local priceOptionsUnitTextFieldLabel = self.priceOptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    priceOptionsUnitTextFieldLabel:SetPoint("TOPLEFT", 430, -50)
    priceOptionsUnitTextFieldLabel:SetJustifyH("LEFT")
    priceOptionsUnitTextFieldLabel:SetHeight(18)
    priceOptionsUnitTextFieldLabel:SetText("Unit:")
     -- Add item price unit input box
    self.priceOptionsUnitTextField = CreateFrame("EditBox", "PriceOptionsUnitTextField", self.priceOptionsFrame, "InputBoxTemplate")
    self.priceOptionsUnitTextField:SetSize(75, 28)
    self.priceOptionsUnitTextField:SetPoint("TOPLEFT", 463, -46)
    self.priceOptionsUnitTextField:SetMaxLetters(255)
    self.priceOptionsUnitTextField:SetMultiLine(false)
    self.priceOptionsUnitTextField:SetAutoFocus(false)

    -- Add item create button
    self.priceOptionsEntryFieldsButton = CreateFrame("Button",  nil, self.priceOptionsFrame, "UIPanelButtonTemplate")
    self.priceOptionsEntryFieldsButton:SetSize(60, 24)
    self.priceOptionsEntryFieldsButton:SetPoint("TOPRIGHT", -15, -48)
    self.priceOptionsEntryFieldsButton:SetText("Create")
    self.priceOptionsEntryFieldsButton:SetScript("OnClick", function(frame)
        AutoPriceResponder:CreateListEntry()
    end)

    -- Add clear button
    self.priceOptionsEntryFieldsButton = CreateFrame("Button",  nil, self.priceOptionsFrame, "UIPanelButtonTemplate")
    self.priceOptionsEntryFieldsButton:SetSize(60, 24)
    self.priceOptionsEntryFieldsButton:SetPoint("TOPRIGHT", -15, -73)
    self.priceOptionsEntryFieldsButton:SetText("Clear")
    self.priceOptionsEntryFieldsButton:SetScript("OnClick", function(frame)
        AutoPriceResponder:ClearEditBoxes()
    end)
    
    -- Add wtb/s list dropdown
    self.priceOptionsListDropDown = CreateFrame("Button",  "PriceOptionsListDropDown", self.priceOptionsFrame, "UIDropDownMenuTemplate")
    self.priceOptionsListDropDown:SetPoint("TOPLEFT", self.priceOptionsFrame, "TOPLEFT", 0, -46)
    self.priceOptionsListDropDown:Show()
    
    -- Initialize list drop down menu
    UIDropDownMenu_Initialize(self.priceOptionsListDropDown, 
        function(self, level)
            -- Gather list of names
            local listNames = {}
            
            for _, list in pairs(AutoPriceResponder.db.profile.lists) do
                table.insert(listNames, list.name)
            end
    
            local info = UIDropDownMenu_CreateInfo()
            for k,v in pairs(listNames) do
                info = UIDropDownMenu_CreateInfo()
                info.text = v
                info.value = v
                info.func = function(self)
                    AutoPriceResponder.selectedOptionsFrameList = self:GetID()
                    UIDropDownMenu_SetSelectedID(AutoPriceResponder.priceOptionsListDropDown, self:GetID())
                    AutoPriceResponder:UpdateEntriesForScrollFrame()
                end
                UIDropDownMenu_AddButton(info, level)
            end
        end
    )
    UIDropDownMenu_SetWidth(self.priceOptionsListDropDown, 50);
    UIDropDownMenu_SetButtonWidth(self.priceOptionsListDropDown, 70)
    UIDropDownMenu_SetSelectedID(self.priceOptionsListDropDown, 1)
    UIDropDownMenu_JustifyText(self.priceOptionsListDropDown, "LEFT")
    
    -- Set initial selected list entry
    if table.getn(self.db.profile.lists) > 0 then
        self.selectedOptionsFrameList = self.selectedOptionsFrameList or 1
    end

    -- Create scrollable frame
    self.priceOptionsFrameScroll = CreateFrame("ScrollFrame", "priceOptionsFrameScroll", self.priceOptionsFrame, "FauxScrollFrameTemplate")
    local sizeX, sizeY = self.priceOptionsFrame:GetSize()
    self.priceOptionsFrameScroll:SetSize(sizeX-40, sizeY - self.optionsPanelHeight )
    self.priceOptionsFrameScroll:SetPoint("TOPLEFT",10, -100)
    self.priceOptionsFrameScroll:SetScript("OnVerticalScroll", function(self, offset) FauxScrollFrame_OnVerticalScroll(self, offset, 20, function()  
            AutoPriceResponder:UpdateEntriesForScrollFrame()
        end) 
    end)
    self.priceOptionsFrameScroll:SetScript("OnShow", function()  
        AutoPriceResponder:UpdateEntriesForScrollFrame()
    end)
    

    -- Create empty tables
    self.priceOptionsFrameText = {}
    self.priceOptionsFrameClickable = {}

    -- Set up vertical offset for the list
    local offset = self.optionsPanelHeight - 50
    
    -- Create a set amount of labels for reuse on the scrollable frame
    for i=1,self.maxEntries do
        self.priceOptionsFrameClickable[i] = CreateFrame("Frame", "ClickableFrame"..i, self.priceOptionsFrame)
        self.priceOptionsFrameClickable[i]:SetPoint("TOPLEFT", 20, -offset)
        self.priceOptionsFrameClickable[i]:SetWidth(255)
        self.priceOptionsFrameClickable[i]:SetHeight(25)
        self.priceOptionsFrameClickable[i]:SetScript("OnEnter", function(self)
            self.inside = true
        end)
        self.priceOptionsFrameClickable[i]:SetScript("OnLeave", function(self)
            self.inside = false
        end)
        self.priceOptionsFrameClickable[i]:SetScript("OnMouseUp", function(self)
            if self.inside then
                if AutoPriceResponder.priceOptionsFrameText[i]:IsShown() then
                    AutoPriceResponder.priceOptionsFrameText[i]:SetText(AutoPriceResponder.selectedEntryColor..AutoPriceResponder.priceOptionsFrameText[i]:GetText())
                    AutoPriceResponder:ResetSelectedOptionsFrameText()
                    AutoPriceResponder.selectedOptionsFrameText = i
                end
            end
        end)
        
        self.priceOptionsFrameText[i] = self.priceOptionsFrame:CreateFontString(nil, "OVERLAY", "ChatFontNormal")
        self.priceOptionsFrameText[i]:SetPoint("TOPLEFT", 20, -offset - 5)
        self.priceOptionsFrameText[i]:SetHeight(23)
        self.priceOptionsFrameText[i]:SetText("")
        self.priceOptionsFrameText[i]:Hide()

        offset = offset + 20
    end

    -- Add selected list title
    self.priceOptionsTitle = self.priceOptionsFrame:CreateFontString("OptionsTitleText", nil, "GameFontNormalLarge")
    self.priceOptionsTitle:SetPoint("TOPLEFT", self.priceOptionsFrame, "TOPLEFT", 10, -90)
    self.priceOptionsTitle:Show()

    -- Create delete button
    self.priceOptionsFrameDelete = CreateFrame("Button",  nil, self.priceOptionsFrame, "UIPanelButtonTemplate")
    self.priceOptionsFrameDelete:SetPoint("BOTTOMRIGHT", -15, 10)
    self.priceOptionsFrameDelete:SetSize(70, 24)
    self.priceOptionsFrameDelete:SetText("Delete")
    self.priceOptionsFrameDelete:SetScript("OnClick", function(self) 
        AutoPriceResponder:DeleteSelectedEntry()
    end)

    -- Create edit button
    self.priceOptionsFrameEdit = CreateFrame("Button",  nil, self.priceOptionsFrame, "UIPanelButtonTemplate")
    self.priceOptionsFrameEdit:SetPoint("BOTTOMRIGHT", -90, 10)
    self.priceOptionsFrameEdit:SetSize(70, 24)
    self.priceOptionsFrameEdit:SetText("Edit")
    self.priceOptionsFrameEdit:SetScript("OnClick", function(self) 
        AutoPriceResponder:EditSelectedEntry()
    end)

    -- information on editing/deleting
    local priceOptionsDeleteLabel = self.priceOptionsFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    priceOptionsDeleteLabel:SetPoint("BOTTOMLEFT", 10, 5)
    priceOptionsDeleteLabel:SetPoint("BOTTOMRIGHT", -175, 5)
    priceOptionsDeleteLabel:SetJustifyH("LEFT")
    priceOptionsDeleteLabel:SetHeight(40)
    priceOptionsDeleteLabel:SetText("Select an entry from the list by clicking the white text and use the delete button to remove it, or the edit button to edit it.")
    
end


-- Create new entry if it does not exist and update entry if it does exist
function AutoPriceResponder:CreateListEntry()
    if not self.selectedOptionsFrameList then
        return
    end
    
    local listId = self.selectedOptionsFrameList
    
    -- Grab text from editboxes and make an entry object
    local newEntry = {
        name = strtrim(self.priceOptionsNameTextField:GetText()),
        price = strtrim(self.priceOptionsPriceTextField:GetText()),
        unit = strtrim(self.priceOptionsUnitTextField:GetText()),
    }    

    -- Discard if name or price was empty
    if newEntry.name == "" or newEntry.price == "" then
        return
    end
    
    -- Keep track if we are creating a new entry or overwriting an old
    local overwrite = false
    
    -- Keep track of index of existing or new
    local index = 0
    
    -- Check if entry exists already, if so overwrite
    for entryId, entry in ipairs(self.db.profile.lists[listId].entries) do
        if entry.name == newEntry.name then
            overwrite = true
            index = entryId
            self.db.profile.lists[listId].entries[index] = newEntry
            break
        end
    end
    
    if not overwrite then
        -- Add new entry to database
        index = table.getn(self.db.profile.lists[listId].entries)+1
        self.db.profile.lists[listId].entries[index] = newEntry
    end
    
    -- Update scroll frame
    self:UpdateEntriesForScrollFrame()
    
    -- Reset text for editbox
    self.priceOptionsNameTextField:SetText("")
    self.priceOptionsPriceTextField:SetText("")
    self.priceOptionsUnitTextField:SetText("")
end

-- Creates a new list entry in the database using the current fields
function AutoPriceResponder:CreateDatabaseEntry(name, price, unit, link)
    link = link == nil and "" or link
    unit = unit == nil and "" or unit
    local entry = {
        name = name,
        link = link,
        price = price,
        unit = unit,
    }
    return entry
end

-- Removes the selected entry from the options frame and database
function AutoPriceResponder:DeleteSelectedEntry()
    -- If nothing is selected, do nothing
    if not self.selectedOptionsFrameList or not self.selectedOptionsFrameText then
        return 
    end
    
    local listId = self.selectedOptionsFrameList
    local entryId = self.priceOptionsFrameText[self.selectedOptionsFrameText].entryId
    table.remove(self.db.profile.lists[listId].entries, entryId)
    self:UpdateEntriesForScrollFrame()
end

-- Adds the selected entries data to the edit boxes so it is easy to edit
function AutoPriceResponder:EditSelectedEntry()
    -- If nothing is selected, do nothing
    if not self.selectedOptionsFrameList or not self.selectedOptionsFrameText then
        return 
    end

    local listId = self.selectedOptionsFrameList
    local entryId = self.priceOptionsFrameText[self.selectedOptionsFrameText].entryId
    local entry = self.db.profile.lists[listId].entries[entryId]
    self.priceOptionsNameTextField:SetText(entry.name)
    self.priceOptionsPriceTextField:SetText(entry.price)
    self.priceOptionsUnitTextField:SetText(entry.unit)
end

-- Clears the edit boxes
function AutoPriceResponder:ClearEditBoxes()
    self.priceOptionsNameTextField:SetText("")
    self.priceOptionsPriceTextField:SetText("")
    self.priceOptionsUnitTextField:SetText("")
end

-- Update list title text
function AutoPriceResponder:UpdateListTitleText()
    local listId = self.selectedOptionsFrameList
    local listTitle = self.db.profile.lists[listId].name
    self.priceOptionsTitle:SetText(listTitle.." Entries")
end

-- Update entries in dropdown list entries scroll frame when scrollbar moves
function AutoPriceResponder:UpdateEntriesForScrollFrame()
    -- Update list title text
    AutoPriceResponder:UpdateListTitleText()

    -- Remove highlight from selected entry, if any
    self:ResetSelectedOptionsFrameText()
        
    -- Save selected listId
    local listId = self.selectedOptionsFrameList
    
    -- Save number of checkboxes used
    local numberOfRows = 1
    
    -- Save number of entries in entries
    local numberOfEntries = 0
    
    if listId and self.db.profile.lists and self.db.profile.lists[listId] then 
        numberOfEntries = table.getn(self.db.profile.lists[listId].entries)
        for entryId, entry in ipairs(self.db.profile.lists[listId].entries) do
            if numberOfRows <= self.maxEntries then
                if entryId > self.priceOptionsFrameScroll.offset then
                    local label = self.priceOptionsFrameText[numberOfRows]
                    label.entryId = entryId
                    label.listId = listId
                    local unit = entry.unit == "" and "" or "/"..entry.unit
                    label:SetText(entry.name..": "..entry.price..unit)
                    label:Show()
                    
                    numberOfRows = numberOfRows + 1
                end
            end
        end
    end
    
    for i = numberOfRows, self.maxEntries do
        self.priceOptionsFrameText[i]:Hide()
    end
    
    -- Execute scroll bar update 
    FauxScrollFrame_Update(self.priceOptionsFrameScroll, numberOfEntries, self.maxEntries, 20, nil, nil, nil, nil, nil, nil, true)
end

-- Called when profile changes, reloads options, list dropdown, manager, and checklist
function AutoPriceResponder:RefreshEverything()
    -- Reload list dropdown
    ToggleDropDownMenu(1, nil, self.priceOptionsListDropDown)
    
    CloseDropDownMenus()
    
    UIDropDownMenu_SetSelectedID(self.priceOptionsListDropDown, 1)
    self.selectedOptionsFrameList = 1
    
    -- Reload list manager
    self:UpdateEntriesForScrollFrame()    
end

-- Resets the color of the previously selected options text
function AutoPriceResponder:ResetSelectedOptionsFrameText()
    if self.selectedOptionsFrameText then
        local text = self.priceOptionsFrameText[self.selectedOptionsFrameText]:GetText()
        if string.find(text, self.selectedEntryColor) then
            self.priceOptionsFrameText[self.selectedOptionsFrameText]:SetText(string.sub(text, 11))
        end
    end
    self.selectedOptionsFrameText = nil
end

-- Hide addon whispers from chat frame
local function HideMsgWhisper(_, event, msg, player)
    if (event == "CHAT_MSG_WHISPER_INFORM") then
        if string.find(msg,PREFIX) then
            return true
        end
    elseif (event == "CHAT_MSG_WHISPER") then
        if (msg:sub(1,6) == commandWord.." ") then
            return true
        end
    end
end

-- Returns an items name and ingame link from given item (can be item name/link.)
function AutoPriceResponder:GetItemNameAndLink(item)
    item = strtrim(item)
    local itemName, itemLink = GetItemInfo(item)
    return itemName == nil and item or itemName, itemLink
end

-- Processes incoming whispers for command word
function AutoPriceResponder:CHAT_MSG_WHISPER(event,msg,player)
    msg = strtrim(msg)
    local response = ""
    if (msg:sub(1,6) == commandWord.." ") then
        local item, itemLink = self:GetItemNameAndLink(strtrim(msg:sub(7,-1)))
        local itemLower = item:lower()
        if (itemLower == "") then
            response = helpMsg
        else
            local found = false
            for listId,list in pairs(self.db.profile.lists) do
                for entryId,entry in pairs(list.entries) do
                    local entryNameLower = entry.name:lower()
                    if (itemLower == entryNameLower) then
                        found = true
                        local itemName = entry.name
                        local unit = entry.unit == "" and "" or "/"..entry.unit
                        if (itemLink ~= nil or entry.link ~= nil) then
                            if (entry.link == nil) then
                                entry.link = itemLink
                            end
                            itemName = entry.link
                        end
                        response = list.prefix.." "..itemName.." "..entry.price..unit
                    end
                    if found then break end
                end
                if found then break end
            end
            if not found then
                local itemName = itemLink == nil and item or itemLink
                response = "Sorry, I'm not currently buying/selling \""..itemName.."\"."
            end
        end
    elseif (msg:sub(1,5) == commandWord) then
        response = helpMsg
    end
    if (response ~= "") then
        SendChatMessage(PREFIX.." "..response, "WHISPER", nil, player)
    end
end

--[[ Add Filters ]]--
AutoPriceResponder:RegisterEvent("CHAT_MSG_WHISPER")
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER", HideMsgWhisper)
ChatFrame_AddMessageEventFilter("CHAT_MSG_WHISPER_INFORM", HideMsgWhisper)
