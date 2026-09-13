local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local AIM_PART = "Head"
local KILLER_NAMES = {"Killer","TheHidden","TheSlasher","TheCure","Monster"}
local BULLET_KEYWORDS = {"bullet","projectile","ray","beam","shot","pellet","tof"}

local silentEnabled = true

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
Main.Size = UDim2.new(0, 180, 0, 80)
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

local Btn = Instance.new("TextButton")
Btn.Size = UDim2.new(1, -20, 0, 30)
Btn.Position = UDim2.new(0, 10, 0, 38)
Btn.BackgroundColor3 = Color3.fromRGB(0, 180, 120)
Btn.BorderSizePixel = 0
Btn.Text = "Silent Aim: ON"
Btn.TextColor3 = Color3.fromRGB(255, 255, 255)
Btn.Font = Enum.Font.Gotham
Btn.TextSize = 12
Btn.Parent = Main

local BtnCorner = Instance.new("UICorner")
BtnCorner.CornerRadius = UDim.new(0, 6)
BtnCorner.Parent = Btn

Btn.MouseButton1Click:Connect(function()
    silentEnabled = not silentEnabled
    Btn.Text = "Silent Aim: " .. (silentEnabled and "ON" or "OFF")
    Btn.BackgroundColor3 = silentEnabled and Color3.fromRGB(0, 180, 120) or Color3.fromRGB(50, 50, 60)
end)

local function isBullet(obj)
    if not obj:IsA("BasePart") then return false end
    local n = obj.Name:lower()
    for _, k in ipairs(BULLET_KEYWORDS) do
        if n:find(k) then return true end
    end
    return false
end

local function redirectBullet(obj)
    task.spawn(function()
        for _ = 1, 120 do
            if not obj or not obj.Parent then break end
            if not silentEnabled then break end

            local target = getKiller()
            if target then
                local dir = (target.Position - obj.Position).Unit
                obj.CFrame = CFrame.new(obj.Position, obj.Position + dir)

                if obj:IsA("BasePart") then
                    obj.AssemblyLinearVelocity = dir * obj.AssemblyLinearVelocity.Magnitude
                end
            end
            RunService.RenderStepped:Wait()
        end
    end)
end

workspace.DescendantAdded:Connect(function(obj)
    if isBullet(obj) then
        local owner = obj:FindFirstAncestorOfClass("Model")
        if owner and owner.Name:lower():find(LocalPlayer.Name:lower()) then
            redirectBullet(obj)
        end
    end
end)
