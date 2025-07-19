-- OVERLORDRecruit.lua
-- Reclutador para la Guild OVERLORD en Taberna
-- Pueden editar el message y el channel por default, para tener el mismo en todos sus PJ's
-- Está activado la opción /overlord
local defaults = {
    message = "La Guild {calavera}OVERLORD{calavera} Recluta jugadores para sus raids {estrella}ICC 25 / SR 25{estrella} de fines de semana. {cuadrado}No importa tu Nivel de GS{cuadrado}",
    interval = 1,
    channel = "Taberna",
    active = false,
}

OVERLORDRecruitDB = OVERLORDRecruitDB or {}
local db = setmetatable({}, { __index = function(_, key)
    return OVERLORDRecruitDB[key] ~= nil and OVERLORDRecruitDB[key] or defaults[key]
end})

local sending = false
local elapsed = 0
local frame

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ff00[OVERLORDRecruit]:|r " .. msg)
end

local function StartSending()
    if db.message == "" then
        Print("|cffff0000Debes escribir un mensaje.|r")
        return
    end
    if db.channel == "" then
        Print("|cffff0000Debes escribir el nombre del canal.|r")
        return
    end

    local channelId = GetChannelName(db.channel)
    if not channelId or channelId == 0 then
        Print("|cffff0000No estás en el canal: " .. db.channel .. ".|r")
        return
    end

    sending = true
    elapsed = 0
    db.active = true
    Print("Iniciado. Canal: " .. db.channel .. " | Cada " .. db.interval .. " min.")

    if not frame then
        frame = CreateFrame("Frame")
    end
    frame:SetScript("OnUpdate", function(_, delta)
        if sending then
            elapsed = elapsed + delta
            if elapsed >= db.interval * 60 then
                elapsed = 0
                local channelId = GetChannelName(db.channel)
                if channelId and channelId > 0 then
                    SendChatMessage(db.message, "CHANNEL", nil, channelId)
                else
                    Print("|cffff0000No estás en el canal: " .. db.channel .. ".|r")
                end
            end
        end
    end)
end

local function StopSending()
    sending = false
    db.active = false
    if frame then
        frame:SetScript("OnUpdate", nil)
    end
    Print("Envío detenido.")
end

local function CreateParentPanel()
    local parent = CreateFrame("Frame", "OVERLORDParentPanel", UIParent)
    parent.name = "OVERLORD"
    InterfaceOptions_AddCategory(parent)
end

local function CreateOptionsPanel()
    local panel = CreateFrame("Frame", "OVERLORDRecruitOptions", UIParent)
    panel.name = "Reclutador"
    panel.parent = "OVERLORD" 

    local scrollPanel = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollPanel:SetPoint("TOPLEFT", 0, -8)
    scrollPanel:SetPoint("BOTTOMRIGHT", -30, 8)

    local content = CreateFrame("Frame", nil, scrollPanel)
    content:SetSize(400, 650)
    scrollPanel:SetScrollChild(content)

    local title = content:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("OVERLORD Reclutador")

    local msgLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    msgLabel:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -20)
    msgLabel:SetText("Mensaje:")

    local bg = CreateFrame("Frame", nil, content)
    bg:SetSize(310, 100)
    bg:SetPoint("TOPLEFT", msgLabel, "BOTTOMLEFT", 0, -8)
    bg:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = { left = 3, right = 3, top = 3, bottom = 3 }
    })

    local msgBox = CreateFrame("EditBox", "OVERLORDRecruitMessageBox", bg)
    msgBox:SetMultiLine(true)
    msgBox:SetSize(300, 100)
    msgBox:SetPoint("TOPLEFT", 5, -5)
    msgBox:SetFontObject(GameFontHighlight)
    msgBox:SetTextColor(1, 1, 1)
    msgBox:SetText(db.message)
    msgBox:SetAutoFocus(false)
    msgBox:SetMaxLetters(500)
    msgBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    msgBox:SetScript("OnTextChanged", function(self) self:SetTextColor(1, 1, 1) end)

    msgBox:SetScript("OnEnterPressed", function(self)
        self:Insert("\n") 
    end)

    local channelLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    channelLabel:SetPoint("TOPLEFT", bg, "BOTTOMLEFT", 0, -15)
    channelLabel:SetText("Canal:")

    local channelBox = CreateFrame("EditBox", "OVERLORDRecruitChannelBox", content, "InputBoxTemplate")
    channelBox:SetSize(150, 25)
    channelBox:SetPoint("TOPLEFT", channelLabel, "BOTTOMLEFT", 0, -5)
    channelBox:SetAutoFocus(false)
    channelBox:SetText(db.channel)
    channelBox:SetTextColor(1, 1, 1)
    channelBox:SetScript("OnTextChanged", function(self) self:SetTextColor(1, 1, 1) end)
    channelBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus()
        self:SetText(db.channel)
    end)
    channelBox:SetScript("OnEnterPressed", function(self)
        db.channel = self:GetText()
        self:ClearFocus()
        Print("Canal actualizado: " .. db.channel)
    end)

    local saveBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    saveBtn:SetPoint("TOPLEFT", channelBox, "BOTTOMLEFT", 0, -15)
    saveBtn:SetSize(100, 25)
    saveBtn:SetText("Guardar")
    saveBtn:SetScript("OnClick", function()
        db.message = msgBox:GetText()
        db.channel = channelBox:GetText()
        Print("Datos guardados.")
    end)

    local intervalLabel = content:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    intervalLabel:SetPoint("TOPLEFT", saveBtn, "BOTTOMLEFT", 0, -20)
    intervalLabel:SetText("Intervalo (minutos):")

    local intervalSlider = CreateFrame("Slider", "OVERLORDRecruitIntervalSlider", content, "OptionsSliderTemplate")
    intervalSlider:SetPoint("TOPLEFT", intervalLabel, "BOTTOMLEFT", 10, -10)
    intervalSlider:SetWidth(200)
    intervalSlider:SetMinMaxValues(1, 60)
    intervalSlider:SetValueStep(1)
    intervalSlider:SetValue(db.interval)
    getglobal(intervalSlider:GetName() .. 'Low'):SetText('1')
    getglobal(intervalSlider:GetName() .. 'High'):SetText('60')
    getglobal(intervalSlider:GetName() .. 'Text'):SetText(db.interval .. " min")

    intervalSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        db.interval = value
        getglobal(self:GetName() .. 'Text'):SetText(value .. " min")
    end)

    local startBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    startBtn:SetPoint("TOPLEFT", intervalSlider, "BOTTOMLEFT", 0, -40)
    startBtn:SetSize(100, 25)
    startBtn:SetText("Iniciar")
    startBtn:SetScript("OnClick", StartSending)

    local stopBtn = CreateFrame("Button", nil, content, "UIPanelButtonTemplate")
    stopBtn:SetPoint("LEFT", startBtn, "RIGHT", 10, 0)
    stopBtn:SetSize(100, 25)
    stopBtn:SetText("Detener")
    stopBtn:SetScript("OnClick", StopSending)

    InterfaceOptions_AddCategory(panel)
end

SLASH_OVERLORD1 = "/overlord"
SlashCmdList["OVERLORD"] = function()
    InterfaceOptionsFrame_OpenToCategory("OVERLORDRecruitOptions")
    InterfaceOptionsFrame_OpenToCategory("OVERLORDRecruitOptions")
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(_, _, addonName)
    if addonName == "OVERLORDRecruit" then
        for k,v in pairs(defaults) do
            if OVERLORDRecruitDB[k] == nil then
                OVERLORDRecruitDB[k] = v
            end
        end
        db = setmetatable(OVERLORDRecruitDB, { __index = defaults })
        Print("Addon cargado correctamente.")
        CreateParentPanel()
        CreateOptionsPanel()
        if db.active then StartSending() end
    end
end)
