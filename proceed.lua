local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local AIM_PART = "Head"
local KILLER_NAMES = {"Killer","TheHidden","TheSlasher","TheCure","Monster"}

local aimEnabled = true
local espEnabled = true

local function isAlive(p)
    local c = p.Character
    return c and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0
end

local function isKiller(p)
    local c = p.Character
    if not c then return false end
    for _, n in ipairs(KILLER_NAMES) do
        if p.Name:lower():find(n:lower()) or c.Name:lower():find(n:lower()) then
            return true
        end
    end
    if p.Team and p.Team.Name:lower():find("killer") then return true end
    return false
end

local function getKiller()
    local best, bd = nil, math.huge
    local myPos = Camera.CFrame.Position
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer or not isAlive(p) or not isKiller(p) then continue end
        local part = p.Character:FindFirstChild(AIM_PART)
        if not part then continue end
        local d = (part.Position - myPos).Magnitude
        if d < bd then bd, best = d, part end
    end
    return best
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SX_UI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game.CoreGui

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 180, 0, 120)
Main.Position = UDim2.new(0, 20, 0, 100)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 28)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Title.BorderSizePixel = 0
Title.Text = "SYNT∆X"
Title.TextColor3 = Color3.fromRGB(0, 255, 180)
Title.Font = Enum.Font.GothamBold
Title.TextSize = 14
Title.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = Title

local function makeToggle(y, text, default, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -20, 0, 30)
    Btn.Position = UDim2.new(0, 10, 0, y)
    Btn.BackgroundColor3 = default and Color3.fromRGB(0, 180, 120) or Color3.fromRGB(50, 50, 60)
    Btn.BorderSizePixel = 0
    Btn.Text = text .. ": " .. (default and "ON" or "OFF")
    Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    Btn.Font = Enum.Font.Gotham
    Btn.TextSize = 12
    Btn.Parent = Main

    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = Btn

    local state = default
    Btn.MouseButton1Click:Connect(function()
        state = not state
        Btn.Text = text .. ": " .. (state and "ON" or "OFF")
        Btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 120) or Color3.fromRGB(50, 50, 60)
        callback(state)
    end)
end

makeToggle(38, "Aim Killer", true, function(v) aimEnabled = v end)
makeToggle(76, "ESP Killer", true, function(v) espEnabled = v end)

local espCache = {}

local function createESP(plr)
    if espCache[plr] then return end
    local box = Instance.new("BoxHandleAdornment")
    box.Size = Vector3.new(2, 2, 1)
    box.Adornee = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
    box.AlwaysOnTop = true
    box.ZIndex = 5
    box.Transparency = 0.5
    box.Color3 = Color3.fromRGB(255, 0, 0)
    box.Parent = game.CoreGui
    espCache[plr] = box
end

local function removeESP(plr)
    if espCache[plr] then
        espCache[plr]:Destroy()
        espCache[plr] = nil
    end
end

RunService.RenderStepped:Connect(function()
    if aimEnabled then
        local target = getKiller()
        if target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, target.Position)
        end
    end

    if espEnabled then
        for _, p in ipairs(Players:GetPlayers()) do
            if p == LocalPlayer then continue end
            if isAlive(p) and isKiller(p) then
                if not espCache[p] then createESP(p) end
                local box = espCache[p]
                local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
                if box and hrp then
                    box.Adornee = hrp
                end
            else
                removeESP(p)
            end
        end
    else
        for p, box in pairs(espCache) do
            box:Destroy()
        end
        espCache = {}
    end
end)

Players.PlayerRemoving:Connect(removeESP)