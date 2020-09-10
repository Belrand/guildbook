--[==[

Copyright ©2020 Samuel Thomas Pain

The contents of this addon, excluding third-party resources, are
copyrighted to their authors with all rights reserved.

This addon is free to use and the authors hereby grants you the following rights:

1. 	You may make modifications to this addon for private use only, you
    may not publicize any portion of this addon.

2. 	Do not modify the name of this addon, including the addon folders.

3. 	This copyright notice shall be included in all copies or substantial
    portions of the Software.

All rights not explicitly addressed in this license are reserved by
the copyright holders.

]==]--

local addonName, Guildbook = ...

---------------------------------------------------------------------------------------------------------------------------------------------------------------
--slash commands
---------------------------------------------------------------------------------------------------------------------------------------------------------------
SLASH_GUILDHELPERCLASSIC1 = '/guildbook'
SLASH_GUILDHELPERCLASSIC2 = '/g-k'
SlashCmdList['GUILDHELPERCLASSIC'] = function(msg)
    if msg == '-help' then
    
    end
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------
--local variables
---------------------------------------------------------------------------------------------------------------------------------------------------------------
local L = Guildbook.Locales
local DEBUG = Guildbook.DEBUG
local PRINT = Guildbook.PRINT
local tinsert, tsort = table.insert, table.sort
local ceil, floor = math.ceil, math.floor

--set constants
local FRIENDS_FRAME_WIDTH = FriendsFrame:GetWidth()
local GUILD_FRAME_WIDTH = GuildFrame:GetWidth()
local GUILD_INFO_FRAME_WIDTH = GuildInfoFrame:GetWidth()

-- config stuff
Guildbook.GuildFrame = {
    ColumnHeaders = {
        { Text = 'Rank', Width = 70, },
        { Text = 'Note', Width = 80, },
        { Text = 'Main Spec', Width = 90, },
        { Text = 'Profession 1', Width = 110, },
        { Text = 'Profession 2', Width = 110, },
    },
    ColumnTabs = {},
    ColumnWidths = {
        Rank = 67.0,
        Note = 77.0,
        MainSpec = 87.0,
        Profession1 = 107.0,
        Profession2 = 107.0,
    },
    ColumnMarginX = 1.0,
}
Guildbook.FONT_COLOUR = ''
Guildbook.PlayerMixin = nil
Guildbook.CharDataMsgkeys = {
    [1] = 'guid',
    [2] = 'name',
    [3] = 'class',
    [4] = 'level',
    [5] = 'fishing',
    [6] = 'cooking',
    [7] = 'firstaid',
    [8] = 'prof1',
    [9] = 'prof1level',
    [10] = 'prof2',
    [11] = 'prof2level',
    [12] = 'main',
    [13] = 'mainspec',
    [14] = 'offspec',
    [15] = 'mainspecispvp',
    [16] = 'offspecispvp',
}

---------------------------------------------------------------------------------------------------------------------------------------------------------------
--init
---------------------------------------------------------------------------------------------------------------------------------------------------------------
function Guildbook:Init()
    DEBUG('running init')

    -- adjust blizz layout and add widget
    GuildFrameGuildListToggleButton:Hide()

    GuildFrame:HookScript('OnShow', function(self)
        self:SetWidth(800)
        FriendsFrame:SetWidth(800)
    end)
    
    GuildFrame:HookScript('OnHide', function(self)
        self:SetWidth(GUILD_FRAME_WIDTH)
        FriendsFrame:SetWidth(FRIENDS_FRAME_WIDTH)
    end)
    
    --extend the guild info frame to full guild frame height
    GuildInfoFrame:SetPoint('TOPLEFT', GuildFrame, 'TOPRIGHT', 1, 0)
    GuildInfoFrame:SetPoint('BOTTOMLEFT', GuildFrame, 'BOTTOMRIGHT', 1, 0) 
    
    --extend the player detail frame to full height
    GuildMemberDetailFrame:SetPoint('TOPLEFT', GuildFrame, 'TOPRIGHT', 1, 0)
    GuildMemberDetailFrame:SetPoint('BOTTOMLEFT', GuildFrame, 'BOTTOMRIGHT', 1, 0)

    GuildInfoTextBackground:ClearAllPoints()
    GuildInfoTextBackground:SetPoint('TOPLEFT', GuildInfoFrame, 'TOPLEFT', 11, -32)
    GuildInfoTextBackground:SetPoint('BOTTOMRIGHT', GuildInfoFrame, 'BOTTOMRIGHT', -11, 40)
    GuildInfoFrameScrollFrame:SetPoint('BOTTOMRIGHT', GuildInfoTextBackground, 'BOTTOMRIGHT', -31, 7)
    
    for k, col in ipairs(self.GuildFrame.ColumnHeaders) do
        local tab = CreateFrame('BUTTON', 'GuildbookGuildFrameColumnHeader'..col.Text, GuildFrame)--, "OptionsFrameTabButtonTemplate")
        if col.Text == 'Rank' then
            tab:SetPoint('LEFT', GuildFrameColumnHeader4, 'RIGHT', -2.0, 0.0)
        else
            tab:SetPoint('LEFT', self.GuildFrame.ColumnTabs[k-1], 'RIGHT', -2.0, 0.0)
        end
        tab:SetSize(col.Width, GuildFrameColumnHeader4:GetHeight())
        tab.text = tab:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
        tab.text:SetPoint('LEFT', tab, 'LEFT', 8.0, 0.0)
        tab.text:SetText(col.Text)
        tab.text:SetFont("Fonts\\FRIZQT__.TTF", 10)
        tab.text:SetTextColor(1,1,1,1)
        tab.background = tab:CreateTexture('$parentBackground', 'BACKGROUND')
        tab.background:SetAllPoints(tab)
        tab.background:SetTexture(131139)
        tab.background:SetTexCoord(0.0, 0.00, 0.0 ,0.75, 0.97, 0.0, 0.97, 0.75)
        self.GuildFrame.ColumnTabs[k] = tab
    end
    
    GuildFrameNotesText:ClearAllPoints()
    GuildFrameNotesText:SetPoint('TOPLEFT', GuildFrameNotesLabel, 'BOTTOMLEFT', 0.0, -3.0)
    GuildFrameNotesText:SetPoint('BOTTOMRIGHT', GuildFrame, 'BOTTOMRIGHT', -12.0, 30.0)
    
    GuildListScrollFrame:ClearAllPoints()
    GuildListScrollFrame:SetPoint('TOPLEFT', GuildFrame, 'TOPLEFT', 11.0, -87.0)
    GuildListScrollFrame:SetPoint('TOPRIGHT', GuildFrame, 'TOPRIGHT', -32.0, -87.0)
    
    GuildFrameButton1:ClearAllPoints()
    GuildFrameButton1:SetPoint('TOPLEFT', GuildFrame, 'TOPLEFT', 8.0, -82.0)
    GuildFrameButton1:SetPoint('TOPRIGHT', GuildFrame, 'TOPRIGHT', -32.0, -82.0)
    GuildFrameButton1:GetHighlightTexture():SetAllPoints(GuildFrameButton1)
    
    for i = 1, 13 do
        -- adjust Name column position
        _G['GuildFrameButton'..i..'Name']:ClearAllPoints()
        _G['GuildFrameButton'..i..'Name']:SetPoint('TOPLEFT', _G['GuildFrameButton'..i], 'TOPLEFT', 7.0, -3.0)
        -- hook the click event
        _G['GuildFrameButton'..i]:HookScript('OnClick', function(self, button)
            if (button == 'LeftButton') and (GuildMemberDetailFrame:IsVisible()) then
                print(_G['GuildFrameButton'..i..'Name']:GetText())
                Guildbook.GuildMemberDetailFrame:ClearText()
                local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID = GetGuildRosterInfo(GetGuildRosterSelection())
                if isOnline then
                    local requestSent = C_ChatInfo.SendAddonMessage('gb-mdf-req', 'requestdata', 'WHISPER', name)
                    if requestSent then
                        DEBUG('sent data request to '..name)
                    end
                end
                Guildbook.GuildMemberDetailFrame:UpdateLabels()
            end
        end)
    end
    
    local function formatGuildFrameButton(button, col)
        --button:SetFont("Fonts\\FRIZQT__.TTF", 10)
        button:SetJustifyH('LEFT')
        button:SetTextColor(col[1], col[2], col[3], col[4])
    end
    
    GuildFrameButton1.GuildbookColumnRank = GuildFrameButton1:CreateFontString('$parentGuildbookRank', 'OVERLAY', 'GameFontNormalSmall')
    GuildFrameButton1.GuildbookColumnRank:SetPoint('LEFT', _G['GuildFrameButton1Class'], 'RIGHT', -12.0, 0)
    GuildFrameButton1.GuildbookColumnRank:SetSize(self.GuildFrame.ColumnWidths['Rank'], GuildFrameButton1:GetHeight())
    formatGuildFrameButton(GuildFrameButton1.GuildbookColumnRank, {1,1,1,1})
    
    GuildFrameButton1.GuildbookColumnNote = GuildFrameButton1:CreateFontString('$parentGuildbookNote', 'OVERLAY', 'GameFontNormalSmall')
    GuildFrameButton1.GuildbookColumnNote:SetPoint('LEFT', GuildFrameButton1.GuildbookColumnRank, 'RIGHT', self.GuildFrame.ColumnMarginX, 0)
    GuildFrameButton1.GuildbookColumnNote:SetSize(self.GuildFrame.ColumnWidths['Note'], GuildFrameButton1:GetHeight())
    formatGuildFrameButton(GuildFrameButton1.GuildbookColumnNote, {1,1,1,1})
    
    GuildFrameButton1.GuildbookColumnMainSpec = GuildFrameButton1:CreateFontString('$parentGuildbookMainSpec', 'OVERLAY', 'GameFontNormalSmall')
    GuildFrameButton1.GuildbookColumnMainSpec:SetPoint('LEFT', GuildFrameButton1.GuildbookColumnNote, 'RIGHT', self.GuildFrame.ColumnMarginX, 0)
    GuildFrameButton1.GuildbookColumnMainSpec:SetSize(self.GuildFrame.ColumnWidths['MainSpec'], GuildFrameButton1:GetHeight())
    formatGuildFrameButton(GuildFrameButton1.GuildbookColumnMainSpec, {1,1,1,1})
    
    GuildFrameButton1.GuildbookColumnProfession1 = GuildFrameButton1:CreateFontString('$parentGuildbookProfession1', 'OVERLAY', 'GameFontNormalSmall')
    GuildFrameButton1.GuildbookColumnProfession1:SetPoint('LEFT', GuildFrameButton1.GuildbookColumnMainSpec, 'RIGHT', self.GuildFrame.ColumnMarginX, 0)
    GuildFrameButton1.GuildbookColumnProfession1:SetSize(self.GuildFrame.ColumnWidths['Profession1'], GuildFrameButton1:GetHeight())
    formatGuildFrameButton(GuildFrameButton1.GuildbookColumnProfession1, {1,1,1,1})
    
    GuildFrameButton1.GuildbookColumnProfession2 = GuildFrameButton1:CreateFontString('$parentGuildbookProfession2', 'OVERLAY', 'GameFontNormalSmall')
    GuildFrameButton1.GuildbookColumnProfession2:SetPoint('LEFT', GuildFrameButton1.GuildbookColumnProfession1, 'RIGHT', self.GuildFrame.ColumnMarginX, 0)
    GuildFrameButton1.GuildbookColumnProfession2:SetSize(self.GuildFrame.ColumnWidths['Profession2'], GuildFrameButton1:GetHeight())
    formatGuildFrameButton(GuildFrameButton1.GuildbookColumnProfession2, {1,1,1,1})
    
    for i = 2, 13 do
        _G['GuildFrameButton'..i]:ClearAllPoints()
        _G['GuildFrameButton'..i]:SetPoint('TOPLEFT', _G['GuildFrameButton'..(i-1)], 'BOTTOMLEFT', 0.0, 0.0)
        _G['GuildFrameButton'..i]:SetPoint('TOPRIGHT', _G['GuildFrameButton'..(i-1)], 'BOTTOMRIGHT', 0.0, 0.0)
        _G['GuildFrameButton'..i]:GetHighlightTexture():SetAllPoints(_G['GuildFrameButton'..i])
    
        _G['GuildFrameButton'..i].GuildbookColumnRank = _G['GuildFrameButton'..i]:CreateFontString('$parentGuildbookRank', 'OVERLAY', 'GameFontNormalSmall')
        _G['GuildFrameButton'..i].GuildbookColumnRank:SetPoint('LEFT', _G['GuildFrameButton'..i..'Class'], 'RIGHT', -12.0, 0)
        _G['GuildFrameButton'..i].GuildbookColumnRank:SetSize(self.GuildFrame.ColumnWidths['Rank'], _G['GuildFrameButton'..i]:GetHeight())
        formatGuildFrameButton(_G['GuildFrameButton'..i].GuildbookColumnRank, {1,1,1,1})
    
        _G['GuildFrameButton'..i].GuildbookColumnNote = _G['GuildFrameButton'..i]:CreateFontString('$parentGuildbookNote', 'OVERLAY', 'GameFontNormalSmall')
        _G['GuildFrameButton'..i].GuildbookColumnNote:SetPoint('LEFT', _G['GuildFrameButton'..i].GuildbookColumnRank, 'RIGHT', self.GuildFrame.ColumnMarginX, 0)
        _G['GuildFrameButton'..i].GuildbookColumnNote:SetSize(self.GuildFrame.ColumnWidths['Note'], _G['GuildFrameButton'..i]:GetHeight())
        formatGuildFrameButton(_G['GuildFrameButton'..i].GuildbookColumnNote, {1,1,1,1})
    
        _G['GuildFrameButton'..i].GuildbookColumnMainSpec = _G['GuildFrameButton'..i]:CreateFontString('$parentGuildbookMainSpec', 'OVERLAY', 'GameFontNormalSmall')
        _G['GuildFrameButton'..i].GuildbookColumnMainSpec:SetPoint('LEFT', _G['GuildFrameButton'..i].GuildbookColumnNote, 'RIGHT', self.GuildFrame.ColumnMarginX, 0)
        _G['GuildFrameButton'..i].GuildbookColumnMainSpec:SetSize(self.GuildFrame.ColumnWidths['MainSpec'], _G['GuildFrameButton'..i]:GetHeight())
        formatGuildFrameButton(_G['GuildFrameButton'..i].GuildbookColumnMainSpec, {1,1,1,1})  
    
        _G['GuildFrameButton'..i].GuildbookColumnProfession1 = _G['GuildFrameButton'..i]:CreateFontString('$parentGuildbookProfession1', 'OVERLAY', 'GameFontNormalSmall')
        _G['GuildFrameButton'..i].GuildbookColumnProfession1:SetPoint('LEFT', _G['GuildFrameButton'..i].GuildbookColumnMainSpec, 'RIGHT', self.GuildFrame.ColumnMarginX, 0)
        _G['GuildFrameButton'..i].GuildbookColumnProfession1:SetSize(self.GuildFrame.ColumnWidths['Profession1'], _G['GuildFrameButton'..i]:GetHeight())
        formatGuildFrameButton(_G['GuildFrameButton'..i].GuildbookColumnProfession1, {1,1,1,1})   
    
        _G['GuildFrameButton'..i].GuildbookColumnProfession2 = _G['GuildFrameButton'..i]:CreateFontString('$parentGuildbookProfession2', 'OVERLAY', 'GameFontNormalSmall')
        _G['GuildFrameButton'..i].GuildbookColumnProfession2:SetPoint('LEFT', _G['GuildFrameButton'..i].GuildbookColumnProfession1, 'RIGHT', self.GuildFrame.ColumnMarginX, 0)
        _G['GuildFrameButton'..i].GuildbookColumnProfession2:SetSize(self.GuildFrame.ColumnWidths['Profession2'], _G['GuildFrameButton'..i]:GetHeight())
        formatGuildFrameButton(_G['GuildFrameButton'..i].GuildbookColumnProfession2, {1,1,1,1})   
    end
    
    hooksecurefunc("GuildStatus_Update", function()
        for i = 1, 13 do
            if Guildbook.GuildFrame.SummaryFrame:IsVisible() then
                _G['GuildFrameButton'..i]:Hide()
            else
                local name, rankName, rankIndex, level, classDisplayName, zone, publicNote, officerNote, isOnline, status, class, achievementPoints, achievementRank, isMobile, canSoR, repStanding, GUID = GetGuildRosterInfo(tonumber(_G['GuildFrameButton'..i].guildIndex))
                -- update font colours
                if isOnline == false then
                    formatGuildFrameButton(_G['GuildFrameButton'..i].GuildbookColumnRank, {0.5,0.5,0.5,1})
                    formatGuildFrameButton(_G['GuildFrameButton'..i].GuildbookColumnNote, {0.5,0.5,0.5,1})
                    formatGuildFrameButton(_G['GuildFrameButton'..i].GuildbookColumnMainSpec, {0.5,0.5,0.5,1})
                    formatGuildFrameButton(_G['GuildFrameButton'..i].GuildbookColumnProfession1, {0.5,0.5,0.5,1})
                    formatGuildFrameButton(_G['GuildFrameButton'..i].GuildbookColumnProfession2, {0.5,0.5,0.5,1})
                else
                    formatGuildFrameButton(_G['GuildFrameButton'..i].GuildbookColumnRank, {1,1,1,1})
                    formatGuildFrameButton(_G['GuildFrameButton'..i].GuildbookColumnNote, {1,1,1,1})
                    formatGuildFrameButton(_G['GuildFrameButton'..i].GuildbookColumnMainSpec, {1,1,1,1})
                    formatGuildFrameButton(_G['GuildFrameButton'..i].GuildbookColumnProfession1, {1,1,1,1})
                    formatGuildFrameButton(_G['GuildFrameButton'..i].GuildbookColumnProfession2, {1,1,1,1})
                end                
                --change class text colour
                _G['GuildFrameButton'..i..'Class']:SetText(string.format('%s%s|r', self.Data.Class[class].FontColour, classDisplayName))
                -- set known columns
                _G['GuildFrameButton'..i].GuildbookColumnRank:SetText(rankName)    
                _G['GuildFrameButton'..i].GuildbookColumnNote:SetText(publicNote)
                -- clear unknown columns
                _G['GuildFrameButton'..i].GuildbookColumnMainSpec:SetText('-')
                _G['GuildFrameButton'..i].GuildbookColumnProfession1:SetText('-')
                _G['GuildFrameButton'..i].GuildbookColumnProfession2:SetText('-')
                -- loop local cache and update columns
                if GUILDBOOK_GLOBAL and next(GUILDBOOK_GLOBAL.GuildRosterCache) then
                    if GUILDBOOK_GLOBAL.GuildRosterCache[GUID] then
                        local ms, os = GUILDBOOK_GLOBAL.GuildRosterCache[GUID]['MainSpec'], GUILDBOOK_GLOBAL.GuildRosterCache[GUID]['OffSpec']
                        local prof1 = GUILDBOOK_GLOBAL.GuildRosterCache[GUID]['Profession1']
                        local prof2 = GUILDBOOK_GLOBAL.GuildRosterCache[GUID]['Profession2']
                        _G['GuildFrameButton'..i].GuildbookColumnMainSpec:SetText(string.format('%s %s', self.Data.SpecFontStringIconSMALL[GUILDBOOK_GLOBAL.GuildRosterCache[GUID]['Class']][ms], ms))                
                        _G['GuildFrameButton'..i].GuildbookColumnProfession1:SetText(string.format('%s %s', self.Data.Profession[prof1].FontStringIconSMALL, prof1))
                        _G['GuildFrameButton'..i].GuildbookColumnProfession2:SetText(string.format('%s %s', self.Data.Profession[prof2].FontStringIconSMALL, prof2))
                    end
                end
            end
        end
    end)
    
    self.GuildFrame.SummaryFrame = CreateFrame('FRAME', 'GuildbookGuildFrameSummaryFrame', GuildFrame)
    self.GuildFrame.SummaryFrame:SetBackdrop({
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        edgeSize = 16,
        bgFile = "interface/framegeneral/ui-background-marble",
        tile = true,
        tileEdge = false,
        tileSize = 200,
        insets = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    self.GuildFrame.SummaryFrame:SetPoint('TOPLEFT', GuildFrame, 'TOPLEFT', 2.00, -55.0)
    self.GuildFrame.SummaryFrame:SetPoint('BOTTOMRIGHT', GuildFrame, 'TOPRIGHT', -4.00, -325.0)
    self.GuildFrame.SummaryFrame:SetFrameLevel(6)
    self.GuildFrame.SummaryFrame:Hide()

    self.GuildFrame.StatsButton = CreateFrame('BUTTON', 'GuildbookGuildFrameStatsButton', GuildFrame, "UIPanelButtonTemplate")
    self.GuildFrame.StatsButton:SetPoint('RIGHT', GuildFrameGuildInformationButton, 'LEFT', -2, 0)
    self.GuildFrame.StatsButton:SetSize(100, GuildFrameGuildInformationButton:GetHeight())
    self.GuildFrame.StatsButton:SetText('Guild Stats')
    self.GuildFrame.StatsButton:SetNormalFontObject(GameFontNormalSmall)
    self.GuildFrame.StatsButton:SetHighlightFontObject(GameFontNormalSmall)
    self.GuildFrame.StatsButton:SetScript('OnClick', function(self)
        if Guildbook.GuildFrame.SummaryFrame:IsVisible() then
            Guildbook.GuildFrame.SummaryFrame:Hide()
            self:SetText('Guild Stats')
            for i = 1, 13 do
                _G['GuildFrameButton'..i]:Show()
            end
        else
            Guildbook.GuildFrame.SummaryFrame:Show()
            self:SetText('Guild Roster')
            for i = 1, 13 do
                _G['GuildFrameButton'..i]:Hide()
            end
        end
    end)
    
    self:SetupSummaryFrame()

    --register the addon message prefixes
    -- TODO: remove these mdf message, use local cache data instead to populate frame, add events for level up, skill up etc
    local memberDetailFrameRequestPrefix = C_ChatInfo.RegisterAddonMessagePrefix('gb-mdf-req')
    DEBUG('registered details request prefix: '..tostring(memberDetailFrameRequestPrefix))

    local memberDetailFrameSentPrefix = C_ChatInfo.RegisterAddonMessagePrefix('gb-mdf-data')
    DEBUG('registered details sent prefix: '..tostring(memberDetailFrameSentPrefix))

    --this is a string of character info
    local requestCharacterInfo = C_ChatInfo.RegisterAddonMessagePrefix('gb-char-stats')
    DEBUG('registered char data req prefix: '..tostring(requestCharacterInfo))

    --draw the additional labels and text for the guild member detail frame
    self.GuildMemberDetailFrame:DrawLabels()          
    self.GuildMemberDetailFrame:DrawText()

    --create stored variable tables
    if GUILDBOOK_GLOBAL == nil then
        GUILDBOOK_GLOBAL = self.Data.DefaultGlobalSettings
        DEBUG('created global saved variable table')
    else
        DEBUG('global variables exists')
    end
    if GUILDBOOK_CHARACTER == nil then
        GUILDBOOK_CHARACTER = self.Data.DefaultCharacterSettings
        DEBUG('created character saved variable table')
    else
        DEBUG('character variables exists')
    end
    --added later
    if not GUILDBOOK_GLOBAL['GuildRosterCache'] then
        GUILDBOOK_GLOBAL['GuildRosterCache'] = {}
    end

    self.LOADED = true
    self.FONT_COLOUR = '|cffFF7D0A'

    local ldb = LibStub("LibDataBroker-1.1")
    self.MinimapButton = ldb:NewDataObject('GuildbookMinimapIcon', {
        type = "data source",
        icon = 134939,
        OnClick = function(self, button)
            if button == "LeftButton" then
                if InterfaceOptionsFrame:IsVisible() then
                    InterfaceOptionsFrame:Hide()
                else
                    InterfaceOptionsFrame_OpenToCategory(addonName)
                    InterfaceOptionsFrame_OpenToCategory(addonName)
                end
            elseif button == 'RightButton' then
                ToggleFriendsFrame(3)
            end
        end,
        OnTooltipShow = function(tooltip)
            if not tooltip or not tooltip.AddLine then return end
            tooltip:AddLine(tostring(self.FONT_COLOUR..addonName))
            tooltip:AddDoubleLine('|cffffffffLeft Click|r Options')
            tooltip:AddDoubleLine('|cffffffffRight Click|r Guild')
        end,
    })
    self.MinimapIcon = LibStub("LibDBIcon-1.0")
    if not GUILDBOOK_GLOBAL['MinimapButton'] then GUILDBOOK_GLOBAL['MinimapButton'] = {} end
    self.MinimapIcon:Register('GuildbookMinimapIcon', self.MinimapButton, GUILDBOOK_GLOBAL['MinimapButton'])
    if GUILDBOOK_GLOBAL['ShowMinimapButton'] == false then
        self.MinimapIcon:Hide('GuildbookMinimapIcon')
    end

    GuildbookOptionsMainSpecDD_Init()
    GuildbookOptionsOffSpecDD_Init()

    --the OnShow event doesnt fire for the first time the options frame is shown? set the values here
    UIDropDownMenu_SetText(GuildbookOptionsMainSpecDD, GUILDBOOK_CHARACTER['MainSpec'])
    UIDropDownMenu_SetText(GuildbookOptionsOffSpecDD, GUILDBOOK_CHARACTER['OffSpec'])
    GuildbookOptionsMainCharacterNameInputBox:SetText(GUILDBOOK_CHARACTER['MainCharacter'])
    GuildbookOptionsMainSpecIsPvpSpecCB:SetChecked(GUILDBOOK_CHARACTER['MainSpecIsPvP'])
    GuildbookOptionsOffSpecIsPvpSpecCB:SetChecked(GUILDBOOK_CHARACTER['OffSpecIsPvP'])
    GuildbookOptionsDebugCB:SetChecked(GUILDBOOK_GLOBAL['Debug'])
    GuildbookOptionsShowMinimapButton:SetChecked(GUILDBOOK_GLOBAL['ShowMinimapButton'])

    local version = GetAddOnMetadata(addonName, "Version")
    PRINT(self.FONT_COLOUR, 'loaded (version '..version..')')

    -- allow time for loading and whats nots, then send character data
    C_Timer.After(5, function()
        local profs = self:GetCharacterProfessions()
        local spec = self:GetCharacterSpecs()
        local guid = UnitGUID('player')
        local level = UnitLevel('player')
        if not self.PlayerMixin then
            self.PlayerMixin = PlayerLocation:CreateFromGUID(guid)
        else
            self.PlayerMixin:SetGUID(guid)
        end
        if self.PlayerMixin:IsValid() then
            local _, class, _ = C_PlayerInfo.GetClass(self.PlayerMixin)
            local name = C_PlayerInfo.GetName(self.PlayerMixin)
            local profs = self:GetCharacterProfessions()
            local specs = self:GetCharacterSpecs()
            local msg = tostring(guid..'$'..name..'$'..class..'$'..level..'$'..profs..'$'..GUILDBOOK_CHARACTER['MainCharacter']..'$'..specs)
            ChatThrottleLib:SendAddonMessage("NORMAL",  "gb-char-stats", msg, "GUILD")
        end
    end)

end

function Guildbook:GetCharacterProfessions()
    local myCharacter = { Fishing = 0, Cooking = 0, FirstAid = 0, Prof1 = '-', Prof1Level = 0, Prof2 = '-', Prof2Level = 0 }
    for s = 1, GetNumSkillLines() do
        local skill, _, _, level, _, _, _, _, _, _, _, _, _ = GetSkillLineInfo(s)
        if skill == 'Fishing' then 
            myCharacter.Fishing = level
        elseif skill == 'Cooking' then
            myCharacter.Cooking = level
        elseif skill == 'First Aid' then
            myCharacter.FirstAid = level
        else
            for k, prof in pairs(Guildbook.Data.Profession) do
                if skill == prof.Name then
                    if myCharacter.Prof1 == '-' then
                        myCharacter.Prof1 = skill
                        myCharacter.Prof1Level = level
                    elseif myCharacter.Prof2 == '-' then
                        myCharacter.Prof2 = skill
                        myCharacter.Prof2Level = level
                    end
                end
            end
        end
    end
    if GUILDBOOK_CHARACTER then
        GUILDBOOK_CHARACTER['Profession1'] = myCharacter.Prof1
        GUILDBOOK_CHARACTER['Profession1Level'] = myCharacter.Prof1Level
        GUILDBOOK_CHARACTER['Profession2'] = myCharacter.Prof2
        GUILDBOOK_CHARACTER['Profession2Level'] = myCharacter.Prof2Level
    end
    local prof1Id = self.Data.ProfToID[myCharacter.Prof1]
    local prof2Id = self.Data.ProfToID[myCharacter.Prof2]
    return string.format('%s$%s$%s$%s$%s$%s$%s', myCharacter.Fishing, myCharacter.Cooking, myCharacter.FirstAid, prof1Id, myCharacter.Prof1Level, prof2Id, myCharacter.Prof2Level)
end

function Guildbook:GetCharacterSpecs()
    local ms = self.Data.SpecToID[GUILDBOOK_CHARACTER['MainSpec']]
    local os = self.Data.SpecToID[GUILDBOOK_CHARACTER['OffSpec']]
    local mspvp, ospvp = 0, 0
    if GUILDBOOK_CHARACTER['MainSpecIsPvP'] == true then
        mspvp = 1
    end
    if GUILDBOOK_CHARACTER['OffSpecIsPvP'] == true then
        ospvp = 1
    end
    return string.format('%s$%s$%s$%s', ms, os, mspvp, ospvp)
end

function Guildbook:ParseCharacterData(msg)
    if not GUILDBOOK_GLOBAL['GuildRosterCache'] then
        GUILDBOOK_GLOBAL['GuildRosterCache'] = {}
    end
    local i, t = 1, {}
    for d in string.gmatch(msg, '[^$]+') do
        t[Guildbook.CharDataMsgkeys[i]] = d
        i = i + 1
    end
    --convert values back
    local prof1 = self.Data.ProfFromID[t['prof1']]
    local prof2 = self.Data.ProfFromID[t['prof2']]
    local ms = self.Data.SpecFromID[t['mainspec']]
    local os = self.Data.SpecFromID[t['offspec']]
    local mspvp, ospvp = false, false
    if GUILDBOOK_CHARACTER['MainSpecIsPvP'] == 1 then
        mspvp = true
    end
    if GUILDBOOK_CHARACTER['OffSpecIsPvP'] == 1 then
        ospvp = true
    end
    GUILDBOOK_GLOBAL.GuildRosterCache[t['guid']] = {
        Name = t['name'],
        Class = t['class'],
        Level = tonumber(t['level']),
        MainSpec = ms,
        OffSpec = os,
        MainSpecIsPvP = mspvp,
        OffSpecIsPvP = ospvp,
        Profession1 = prof1,
        Profession1Level = tonumber(t['prof1level']),
        Profession2 = prof2,
        Profession2Level = tonumber(t['prof2level']),
        MainCharacter = t['main'],
        Fishing = tonumber(t['fishing']),
        Cooking = tonumber(t['cooking']),
        FirstAid = tonumber(t['firstaid']),
    }
end

function Guildbook:ADDON_LOADED(...)
    if tostring(...):lower() == addonName:lower() then
        self:Init()
    end
end

function Guildbook:GUILD_ROSTER_UPDATE(...)
    if GuildMemberDetailFrame:IsVisible() then     
        self.GuildMemberDetailFrame:HandleRosterUpdate()
    end
end

function Guildbook:CHAT_MSG_ADDON(...)
    local prefix = select(1, ...)
    local msg = select(2, ...)
    local sender = select(5, ...)
    if string.find(prefix, 'mdf') then
        DEBUG('member detail frame msg event')
        self.GuildMemberDetailFrame:HandleAddonMessage(...)
    elseif prefix == 'gb-char-stats' then
        DEBUG('character stats msg event')
        self:ParseCharacterData(msg)
    end
end

--set up event listener
Guildbook.EventFrame = CreateFrame('FRAME', 'GuildbookEventFrame', UIParent)
Guildbook.EventFrame:RegisterEvent('GUILD_ROSTER_UPDATE')
Guildbook.EventFrame:RegisterEvent('CHAT_MSG_ADDON')
Guildbook.EventFrame:RegisterEvent('ADDON_LOADED')
Guildbook.EventFrame:SetScript('OnEvent', function(self, event, ...)
    --DEBUG('EVENT='..tostring(event))
    Guildbook[event](Guildbook, ...)
end)