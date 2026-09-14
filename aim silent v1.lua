local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

local PLAYER = Players.LocalPlayer
local GUI = PLAYER:WaitForChild("PlayerGui")
local CAMERA = workspace.CurrentCamera

local AUTO_AIM_ENABLED = true
local AUTO_SHOOT_ENABLED = false
local AIM_PART = "Head"
local SHOOT_DELAY = 0.12
local KILLER_KEYWORDS = {"Killer","TheHidden","TheSlasher","TheCure","Monster","Killer_"}

local lastShot = 0

local FireRemote = ReplicatedStorage
    :WaitForChild("Remotes")
    :WaitForChild("Items")
    :WaitForChild("Twist of Fate")
    :WaitForChild("Fire")

local function GetCharacter()
    return PLAYER.Character
end

local function IsAlive(p)
    local c = p.Character
    return c and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0
end

local function IsKiller(p)
    local c = p.Character
    if not c then return false end
    for _, n in ipairs(KILLER_KEYWORDS) do
        if p.Name:lower():find(n:lower()) or c.Name:lower():find(n:lower()) then
            return true
        end
    end
    if p.Team and p.Team.Name:lower():find("killer") then return true end
    for _, obj in ipairs(c:GetChildren()) do
        if obj.Name:lower():find("killer") or obj.Name == "Lookscriptkiller" then
            return true
        end
    end
    return false
end

local function GetKillerPart()
    local best, bd = nil, math.huge
    local myChar = GetCharacter()
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    for _, p in ipairs(Players:GetPlayers()) do
        if p == PLAYER or not IsAlive(p) or not IsKiller(p) then continue end
        local part = p.Character:FindFirstChild(AIM_PART)
            or p.Character:FindFirstChild("UpperTorso")
            or p.Character:FindFirstChild("Torso")
            or p.Character:FindFirstChild("HumanoidRootPart")
        if not part then continue end
        local d = (part.Position - myHRP.Position).Magnitude
        if d < bd then bd, best = d, part end
    end
    return best
end

local function GetGun()
    local char = GetCharacter()
    if not char then return nil end
    local twist = char:FindFirstChild("Twist of Fate")
    if not twist then return nil end
    local rightArm = twist:FindFirstChild("Right Arm")
    if not rightArm then return nil end
    return rightArm:FindFirstChild("EmperorGun")
end

local function GetAimDirection()
    if not AUTO_AIM_ENABLED then
        return CAMERA.CFrame.LookVector
    end
    local myChar = GetCharacter()
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return CAMERA.CFrame.LookVector end
    local target = GetKillerPart()
    if target then
        local dir = target.Position - myHRP.Position
        if dir.Magnitude > 0.001 then return dir.Unit end
    end
    return CAMERA.CFrame.LookVector
end

local function Shoot()
    local gun = GetGun()
    if not gun then return end
    local dir = GetAimDirection()
    FireRemote:FireServer(gun, dir)
end

if GUI:FindFirstChild("SX_AimUI") then GUI.SX_AimUI:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SX_AimUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = GUI

local Main = Instance.new("Frame")
Main.Size = UDim2.new(0, 200, 0, 150)
Main.Position = UDim2.new(0, 20, 0, 100)
Main.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
Main.BorderSizePixel = 0
Main.Active = true
Main.Draggable = true
Main.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 10)
MainCorner.Parent = Main

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 30)
Title.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
Title.BorderSizePixel = 0
Title.Text = ""
Title.Parent = Main

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 10)
TitleCorner.Parent = Title

local function MakeToggle(y, default, callback)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, -20, 0, 32)
    Btn.Position = UDim2.new(0, 10, 0, y)
    Btn.BackgroundColor3 = default and Color3.fromRGB(0, 180, 120) or Color3.fromRGB(50, 50, 60)
    Btn.BorderSizePixel = 0
    Btn.Text = ""
    Btn.Parent = Main
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 6)
    c.Parent = Btn
    local state = default
    Btn.MouseButton1Click:Connect(function()
        state = not state
        Btn.BackgroundColor3 = state and Color3.fromRGB(0, 180, 120) or Color3.fromRGB(50, 50, 60)
        callback(state)
    end)
end

MakeToggle(40, true, function(v) AUTO_AIM_ENABLED = v end)
MakeToggle(78, false, function(v) AUTO_SHOOT_ENABLED = v end)

local Status = Instance.new("TextLabel")
Status.Size = UDim2.new(1, -20, 0, 22)
Status.Position = UDim2.new(0, 10, 0, 118)
Status.BackgroundTransparency = 1
Status.Text = ""
Status.Parent = Main

local connectedShootButtons = {}
local function ConnectShootButton(button)
    if not button or connectedShootButtons[button] then return end
    connectedShootButtons[button] = true
    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch then
            Shoot()
        end
    end)
end

local function ScanForShootButton()
    local survivorMob = GUI:FindFirstChild("Survivor-mob")
    if not survivorMob then return end
    for _, obj in ipairs(survivorMob:GetDescendants()) do
        if obj:IsA("ImageButton") and obj.Name == "Gui-mob" then
            ConnectShootButton(obj)
        end
    end
end

ScanForShootButton()

GUI.DescendantAdded:Connect(function(obj)
    if obj:IsA("ImageButton") and obj.Name == "Gui-mob" then
        ConnectShootButton(obj)
    end
end)

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then return end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        Shoot()
    end
end)

PLAYER.CharacterAdded:Connect(function()
    task.wait(0.5)
    ScanForShootButton()
end)

RunService.RenderStepped:Connect(function()
    if AUTO_SHOOT_ENABLED and AUTO_AIM_ENABLED then
        local target = GetKillerPart()
        if target and GetGun() then
            if tick() - lastShot >= SHOOT_DELAY then
                lastShot = tick()
                Shoot()
            end
        end
    end
end)