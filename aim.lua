local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")

local LP = Players.LocalPlayer
local Cam = Workspace.CurrentCamera
local Mouse = LP:GetMouse()

local Config = {
    Enabled = true,
    TeamCheck = false,
    TargetPart = "Head",
    FOV = 200,
    HitChance = 100
}

local function getTarget()
    local closest = nil
    local shortest = Config.FOV
    local mousePos = UIS:GetMouseLocation()

    for _, plr in pairs(Players:GetPlayers()) do
        if plr == LP then continue end
        if Config.TeamCheck and plr.Team == LP.Team then continue end
        if not plr.Character then continue end

        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
        if not hum or hum.Health <= 0 then continue end

        local part = plr.Character:FindFirstChild(Config.TargetPart) 
                  or plr.Character:FindFirstChild("HumanoidRootPart")
        if not part then continue end

        local screenPos, onScreen = Cam:WorldToViewportPoint(part.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
        if dist <= Config.FOV and dist < shortest then
            shortest = dist
            closest = part
        end
    end
    return closest
end

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if Config.Enabled and (method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList") then
        if math.random(0, 100) <= Config.HitChance then
            local target = getTarget()
            if target then
                if method == "Raycast" then
                    args[2] = (target.Position - args[1]).Unit * 1000
                elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
                    args[2] = target.Position - args[1].Origin
                end
                return oldNamecall(self, unpack(args))
            end
        end
    end
    return oldNamecall(self, ...)
end

setreadonly(mt, true)
