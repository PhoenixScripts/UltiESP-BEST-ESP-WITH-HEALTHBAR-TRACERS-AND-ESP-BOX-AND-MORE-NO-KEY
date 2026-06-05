-- 1. FRAMEWORK SERVICES
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- 2. STATE LOGIC CONFIGS
local Config = {
    ESP_Enabled = true,
    Tracers_Enabled = true,
    HealthBar_Enabled = true,
    
    BoxColor = Color3.fromRGB(255, 0, 0),       
    TracerColor = Color3.fromRGB(255, 255, 0),   
    
    RainbowBoxes = false,                       
    RainbowTracers = false,                     
    
    HealthBarPosition = "Right",

    -- UI Customization Options (Script Settings)
    MenuBgColor = Color3.fromRGB(35, 20, 50),       -- Default Deep Purple
    SidebarBgColor = Color3.fromRGB(25, 12, 38),    -- Darker Purple Accent
    ToggleOnColor = Color3.fromRGB(0, 180, 80),     -- Default Green
    ToggleOffColor = Color3.fromRGB(180, 40, 40),   -- Default Red
    
    Menu_Visible = true                             -- Menu UI Window state tracker
}

local ESPCache = {}
local UI_Toggle_Buttons = {} 
local UI_Elements_To_Theme = { Buttons = {}, Backgrounds = {}, Sidebars = {} }
local MainFrameRef = nil -- Global placeholder to reference the UI window frame

-- Real-time UI Theme Painter
local function updateUIColors()
    for _, bg in ipairs(UI_Elements_To_Theme.Backgrounds) do bg.BackgroundColor3 = Config.MenuBgColor end
    for _, sb in ipairs(UI_Elements_To_Theme.Sidebars) do sb.BackgroundColor3 = Config.SidebarBgColor end
    for configKey, callback in pairs(UI_Toggle_Buttons) do callback() end
end

-- Universal Hotkey Event Listeners (E, T, H, and RightShift to Hide Menu)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end -- Avoids triggering while typing in game chat
    
    -- RightShift keypress seamlessly hides or shows the control window
    if input.KeyCode == Enum.KeyCode.RightShift then
        Config.Menu_Visible = not Config.Menu_Visible
        if MainFrameRef then
            MainFrameRef.Visible = Config.Menu_Visible
        end
    -- Standard feature toggles
    elseif input.KeyCode == Enum.KeyCode.E then
        Config.ESP_Enabled = not Config.ESP_Enabled
        if UI_Toggle_Buttons["ESP_Enabled"] then UI_Toggle_Buttons["ESP_Enabled"]() end
    elseif input.KeyCode == Enum.KeyCode.T then
        Config.Tracers_Enabled = not Config.Tracers_Enabled
        if UI_Toggle_Buttons["Tracers_Enabled"] then UI_Toggle_Buttons["Tracers_Enabled"]() end
    elseif input.KeyCode == Enum.KeyCode.H then
        Config.HealthBar_Enabled = not Config.HealthBar_Enabled
        if UI_Toggle_Buttons["HealthBar_Enabled"] then UI_Toggle_Buttons["HealthBar_Enabled"]() end
    end
end)
-- 3. CORE WINDOW LAYOUT GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "UltiESP_Menu"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = CoreGui 

local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 480, 0, 320)
MainFrame.Position = UDim2.new(0.5, -240, 0.5, -160)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true 
MainFrame.Parent = ScreenGui
table.insert(UI_Elements_To_Theme.Backgrounds, MainFrame)

MainFrameRef = MainFrame -- Links the main frame to the hotkey visibility script

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 12)
MainCorner.Parent = MainFrame

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 150, 0, 35)
TitleLabel.Position = UDim2.new(1, -160, 0, 5)
TitleLabel.Text = "UltiESP"
TitleLabel.Font = Enum.Font.SourceSansBold
TitleLabel.TextSize = 22
TitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TitleLabel.BackgroundTransparency = 1
TitleLabel.TextXAlignment = Enum.TextXAlignment.Right
TitleLabel.Parent = MainFrame

local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.Text = "X"
CloseBtn.Font = Enum.Font.SourceSansBold
CloseBtn.TextSize = 20
CloseBtn.TextColor3 = Color3.fromRGB(255, 80, 80)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Parent = MainFrame

CloseBtn.MouseButton1Click:Connect(function()
    ScreenGui:Destroy()
    for player, visuals in pairs(ESPCache) do
        for _, obj in pairs(visuals) do
            obj.Visible = false
            obj:Remove()
        end
    end
    ESPCache = {}
    script:Destroy()
end)

local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, 0)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
table.insert(UI_Elements_To_Theme.Sidebars, Sidebar)

local SidebarCorner = Instance.new("UICorner")
SidebarCorner.CornerRadius = UDim.new(0, 12)
SidebarCorner.Parent = Sidebar

local ContentContainer = Instance.new("Frame")
ContentContainer.Size = UDim2.new(1, -140, 1, -45)
ContentContainer.Position = UDim2.new(0, 135, 0, 40)
ContentContainer.BackgroundTransparency = 1
ContentContainer.Parent = MainFrame

-- Page Allocation Registers
local Pages = {
    ESP = Instance.new("Frame"),
    Settings = Instance.new("Frame"),
    ScriptSettings = Instance.new("Frame"),
    Credits = Instance.new("Frame")
}

for name, frame in pairs(Pages) do
    frame.Size = UDim2.new(1, 0, 1, 0)
    frame.BackgroundTransparency = 1
    frame.Visible = (name == "ESP")
    frame.Parent = ContentContainer
end

local function createNavBtn(text, yPos, pageTarget)
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, -10, 0, 35)
    btn.Position = UDim2.new(0, 5, 0, yPos)
    btn.Text = text
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.TextColor3 = Color3.fromRGB(220, 200, 240)
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 0.3
    btn.BorderSizePixel = 0
    btn.Parent = Sidebar
    
    local btnCorner = Instance.new("UICorner")
    btnCorner.CornerRadius = UDim.new(0, 6)
    btnCorner.Parent = btn
    
    btn.MouseButton1Click:Connect(function()
        for _, frame in pairs(Pages) do frame.Visible = false end
        Pages[pageTarget].Visible = true
    end)
end

createNavBtn("ESP Settings", 15, "ESP")
createNavBtn("Settings Page", 55, "Settings")
createNavBtn("Script Settings", 95, "ScriptSettings")
createNavBtn("Credits", 135, "Credits")
-- 4. PAGE 1: ESP SWITCH CONTROLS (Live Red/Green Customisable Switches)
local function createMainToggleSwitch(parent, text, yPos, configKey)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 180, 0, 30)
    label.Position = UDim2.new(0, 10, 0, yPos)
    label.Text = text
    label.Font = Enum.Font.SourceSans
    label.TextSize = 16
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 65, 0, 26)
    btn.Position = UDim2.new(0, 220, 0, yPos + 2)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.BorderSizePixel = 0
    btn.Parent = parent
    
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = btn

    local function updateVisuals()
        if Config[configKey] then
            btn.Text = "ON"
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.BackgroundColor3 = Config.ToggleOnColor
        else
            btn.Text = "OFF"
            btn.TextColor3 = Color3.fromRGB(255, 255, 255)
            btn.BackgroundColor3 = Config.ToggleOffColor
        end
    end

    btn.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        updateVisuals()
    end)
    
    UI_Toggle_Buttons[configKey] = updateVisuals
    updateVisuals()
end

createMainToggleSwitch(Pages.ESP, "ESP Boxes [E]", 10, "ESP_Enabled")
createMainToggleSwitch(Pages.ESP, "Tracer Lines [T]", 50, "Tracers_Enabled")
createMainToggleSwitch(Pages.ESP, "Health Bars [H]", 90, "HealthBar_Enabled")

-- 5. CONFIG CYCLER CREATOR TOOLS
local function createCycleButton(parent, text, yPos, optionsList, configKey, onUpdateCallback)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 180, 0, 30)
    label.Position = UDim2.new(0, 10, 0, yPos)
    label.Text = text
    label.Font = Enum.Font.SourceSans
    label.TextSize = 16
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 0, 26)
    btn.Position = UDim2.new(0, 210, 0, yPos + 2)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 0.4
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BorderSizePixel = 0
    btn.Parent = parent
    
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = btn

    local currentIndex = 1
    for i, val in ipairs(optionsList) do
        if typeof(val) == "table" and val.Value == Config[configKey] then currentIndex = i
        elseif val == Config[configKey] then currentIndex = i end
    end

    local function applyValue()
        local currentOption = optionsList[currentIndex]
        if typeof(currentOption) == "table" then
            btn.Text = currentOption.Name
            Config[configKey] = currentOption.Value
        else
            btn.Text = tostring(currentOption)
            Config[configKey] = currentOption
        end
        if onUpdateCallback then onUpdateCallback() end
    end

    btn.MouseButton1Click:Connect(function()
        currentIndex = currentIndex + 1
        if currentIndex > #optionsList then currentIndex = 1 end
        applyValue()
    end)

    applyValue()
end

local function createSettingsToggle(parent, text, yPos, configKey)
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(0, 180, 0, 30)
    label.Position = UDim2.new(0, 10, 0, yPos)
    label.Text = text
    label.Font = Enum.Font.SourceSans
    label.TextSize = 16
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = parent

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 100, 0, 26)
    btn.Position = UDim2.new(0, 210, 0, yPos + 2)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 14
    btn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    btn.BackgroundTransparency = 0.4
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.BorderSizePixel = 0
    btn.Parent = parent
    
    local c = Instance.new("UICorner") c.CornerRadius = UDim.new(0, 4) c.Parent = btn

    local function updateVisuals()
        btn.Text = Config[configKey] and "Rainbow" or "Static"
        btn.TextColor3 = Config[configKey] and Color3.fromRGB(200, 255, 200) or Color3.fromRGB(255, 255, 255)
    end

    btn.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        updateVisuals()
    end)
    
    updateVisuals()
end
-- 6. PAGE 2: GAMEPLAY ESP SETTINGS
local colorOptions = {
    { Name = "Red", Value = Color3.fromRGB(255, 0, 0) },
    { Name = "Green", Value = Color3.fromRGB(0, 255, 0) },
    { Name = "Blue", Value = Color3.fromRGB(0, 120, 255) },
    { Name = "White", Value = Color3.fromRGB(255, 255, 255) },
    { Name = "Yellow", Value = Color3.fromRGB(255, 255, 0) }
}
local positionOptions = { "Right", "Top", "Left" }

createCycleButton(Pages.Settings, "Box Color Border", 10, colorOptions, "BoxColor")
createCycleButton(Pages.Settings, "Tracer Line Color", 45, colorOptions, "TracerColor")
createCycleButton(Pages.Settings, "Health Position", 80, positionOptions, "HealthBarPosition")
createSettingsToggle(Pages.Settings, "Box Rainbow FX", 125, "RainbowBoxes")
createSettingsToggle(Pages.Settings, "Tracer Rainbow FX", 160, "RainbowTracers")

-- 7. PAGE 3: SCRIPT THEME SETTINGS (UI Theme Editors)
local uiBgOptions = {
    { Name = "Deep Purple", Value = Color3.fromRGB(35, 20, 50) },
    { Name = "Midnight Black", Value = Color3.fromRGB(15, 15, 15) },
    { Name = "Charcoal Gray", Value = Color3.fromRGB(30, 30, 30) },
    { Name = "Ocean Blue", Value = Color3.fromRGB(15, 30, 60) }
}
local sidebarOptions = {
    { Name = "Darker Purple", Value = Color3.fromRGB(25, 12, 38) },
    { Name = "Pitch Black", Value = Color3.fromRGB(8, 8, 8) },
    { Name = "Dark Gray", Value = Color3.fromRGB(22, 22, 22) },
    { Name = "Deep Blue", Value = Color3.fromRGB(10, 20, 40) }
}
local switchOnOptions = {
    { Name = "Green", Value = Color3.fromRGB(0, 180, 80) },
    { Name = "Cyan Blue", Value = Color3.fromRGB(0, 160, 220) },
    { Name = "Lime Green", Value = Color3.fromRGB(120, 220, 0) },
    { Name = "Hot Pink", Value = Color3.fromRGB(230, 30, 130) }
}
local switchOffOptions = {
    { Name = "Crimson Red", Value = Color3.fromRGB(180, 40, 40) },
    { Name = "Dark Gray", Value = Color3.fromRGB(70, 70, 70) },
    { Name = "Orange", Value = Color3.fromRGB(220, 100, 0) }
}

createCycleButton(Pages.ScriptSettings, "UI Window Background", 10, uiBgOptions, "MenuBgColor", updateUIColors)
createCycleButton(Pages.ScriptSettings, "Sidebar Background", 50, sidebarOptions, "SidebarBgColor", updateUIColors)
createCycleButton(Pages.ScriptSettings, "Manual Switches ON", 90, switchOnOptions, "ToggleOnColor", updateUIColors)
createCycleButton(Pages.ScriptSettings, "Manual Switches OFF", 130, switchOffOptions, "ToggleOffColor", updateUIColors)

-- 8. PAGE 4: CREDITS & TRUST TRANSPARENCY NOTICE
local CreditsLabel = Instance.new("TextLabel")
CreditsLabel.Size = UDim2.new(1, -20, 1, -20)
CreditsLabel.Position = UDim2.new(0, 10, 0, 10)
CreditsLabel.Text = "This script was created by the team at PhoenixCode, running PhoenixCheats.\n\nWe will never ask for your personal info, bank or credit card details.\n\nWe will never scam or use deceptive practices.\n\nGo to phoenixcheats.com for our Security page or contact form."
CreditsLabel.Font = Enum.Font.SourceSansBold
CreditsLabel.TextSize = 15
CreditsLabel.TextColor3 = Color3.fromRGB(235, 220, 255)
CreditsLabel.BackgroundTransparency = 1
CreditsLabel.TextWrapped = true
CreditsLabel.TextYAlignment = Enum.TextYAlignment.Center
CreditsLabel.Parent = Pages.Credits

-- Paint default setup colors on loading engine execution
updateUIColors()
-- 9. ESP VECTOR GRAPHICS GENERATION ENGINE
local function createESP(player)
    if ESPCache[player] then return end

    local box = Drawing.new("Square")
    box.Visible = false
    box.Thickness = 2
    box.Filled = false

    local tracer = Drawing.new("Line")
    tracer.Visible = false
    tracer.Thickness = 1.5

    local nameTag = Drawing.new("Text")
    nameTag.Visible = false
    nameTag.Color = Color3.fromRGB(255, 255, 255)
    nameTag.Size = 16
    nameTag.Center = true
    nameTag.Outline = true

    local healthBarOutline = Drawing.new("Square")
    healthBarOutline.Visible = false
    healthBarOutline.Color = Color3.fromRGB(0, 0, 0)
    healthBarOutline.Thickness = 1
    healthBarOutline.Filled = true

    local healthBar = Drawing.new("Square")
    healthBar.Visible = false
    healthBar.Thickness = 1
    healthBar.Filled = true

    ESPCache[player] = { 
        Box = box, Tracer = tracer, NameTag = nameTag, 
        HealthBarOutline = healthBarOutline, HealthBar = healthBar 
    }
end

local function removeESP(player)
    if ESPCache[player] then
        for _, object in pairs(ESPCache[player]) do
            object.Visible = false
            object:Remove()
        end
        ESPCache[player] = nil
    end
end

-- 10. LOOP EXECUTION RUNTIME MATRIX
RunService.RenderStepped:Connect(function()
    local myCharacter = LocalPlayer.Character
    local myRootPart = myCharacter and myCharacter:FindFirstChild("HumanoidRootPart")
    local rainbowColor = Color3.fromHSV(tick() % 5 / 5, 1, 1)
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if not ESPCache[player] then createESP(player) end
            
            local visuals = ESPCache[player]
            local targetCharacter = player.Character
            local targetRootPart = targetCharacter and targetCharacter:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = targetCharacter and targetCharacter:FindFirstChildOfClass("Humanoid")
            
            if Config.ESP_Enabled and myRootPart and targetRootPart and targetHumanoid then
                local targetScreenPos, targetOnScreen = Camera:WorldToViewportPoint(targetRootPart.Position)
                local myScreenPos, myOnScreen = Camera:WorldToViewportPoint(myRootPart.Position)
                
                if targetOnScreen then
                    local distance = (Camera.CFrame.Position - targetRootPart.Position).Magnitude
                    local sizeX = 2000 / distance
                    local sizeY = 3000 / distance
                    
                    local boxX = targetScreenPos.X - (sizeX / 2)
                    local boxY = targetScreenPos.Y - (sizeY / 2)

                    visuals.Box.Size = Vector2.new(sizeX, sizeY)
                    visuals.Box.Position = Vector2.new(boxX, boxY)
                    visuals.Box.Color = Config.RainbowBoxes and rainbowColor or Config.BoxColor
                    visuals.Box.Visible = true
                    
                    if Config.Tracers_Enabled then
                        visuals.Tracer.From = Vector2.new(myScreenPos.X, myScreenPos.Y)
                        visuals.Tracer.To = Vector2.new(targetScreenPos.X, targetScreenPos.Y)
                        visuals.Tracer.Color = Config.RainbowTracers and rainbowColor or Config.TracerColor
                        visuals.Tracer.Visible = true
                    else
                        visuals.Tracer.Visible = false
                    end

                    visuals.NameTag.Text = player.Name
                    visuals.NameTag.Position = Vector2.new(targetScreenPos.X, boxY - 20)
                    visuals.NameTag.Visible = true

                    if Config.HealthBar_Enabled then
                        local currentHealth = targetHumanoid.Health
                        local maxHealth = targetHumanoid.MaxHealth
                        local healthPercentage = math.clamp(currentHealth / maxHealth, 0, 1)
                        local healthColor = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(0, 255, 0), healthPercentage)

                        if Config.HealthBarPosition == "Right" then
                            visuals.HealthBarOutline.Size = Vector2.new(4, sizeY)
                            visuals.HealthBarOutline.Position = Vector2.new(boxX + sizeX + 3, boxY)
                            visuals.HealthBar.Size = Vector2.new(2, sizeY * healthPercentage)
                            visuals.HealthBar.Position = Vector2.new(boxX + sizeX + 4, boxY + (sizeY * (1 - healthPercentage)))
                        elseif Config.HealthBarPosition == "Left" then
                            visuals.HealthBarOutline.Size = Vector2.new(4, sizeY)
                            visuals.HealthBarOutline.Position = Vector2.new(boxX - 7, boxY)
                            visuals.HealthBar.Size = Vector2.new(2, sizeY * healthPercentage)
                            visuals.HealthBar.Position = Vector2.new(boxX - 6, boxY + (sizeY * (1 - healthPercentage)))
                        elseif Config.HealthBarPosition == "Top" then
                            visuals.HealthBarOutline.Size = Vector2.new(sizeX, 4)
                            visuals.HealthBarOutline.Position = Vector2.new(boxX, boxY - 7)
                            visuals.HealthBar.Size = Vector2.new(sizeX * healthPercentage, 2)
                            visuals.HealthBar.Position = Vector2.new(boxX, boxY - 6)
                        end
                        
                        visuals.HealthBar.Color = healthColor
                        visuals.HealthBarOutline.Visible = true
                        visuals.HealthBar.Visible = true
                    else
                        visuals.HealthBarOutline.Visible = false
                        visuals.HealthBar.Visible = false
                    end
                else
                    for _, object in pairs(visuals) do object.Visible = false end
                end
            else
                if visuals then
                    for _, object in pairs(visuals) do object.Visible = false end
                end
            end
        end
    end
end)

Players.PlayerRemoving:Connect(removeESP)
