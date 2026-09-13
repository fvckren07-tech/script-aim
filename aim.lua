local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local AIM_PART = "Head"
local FOV = 360
local ONLY_KILLER = true
local KILLER_NAMES = {"Killer","TheHidden","TheSlasher","TheCure","Monster"}

local function isAlive(p)
    local c = p.Character
    return c and c:FindFirstChild("Humanoid") and c.Humanoid.Health > 0
end

local function isKiller(p)
    if not ONLY_KILLER then return true end
    local c = p.Character
    if not c then return false end
    for _, n in ipairs(KILLER_NAMES) do
        if p.Name:lower():find(n:lower()) or c.Name:lower():find(n:lower()) then return true end
    end
    if p.Team and p.Team.Name:lower():find("killer") then return true end
    return false
end

local function inFOV(pos)
    local sp, on = Camera:WorldToViewportPoint(pos)
    if not on then return false end
    local c = Vector2.new(Camera.ViewportSize.X/2, Camera.ViewportSize.Y/2)
    return (Vector2.new(sp.X, sp.Y) - c).Magnitude <= FOV/2
end

local function getKiller()
    local best, bd = nil, math.huge
    local myPos = Camera.CFrame.Position
    for _, p in ipairs(Players:GetPlayers()) do
        if p == LocalPlayer then continue end
        if not isAlive(p) then continue end
        if not isKiller(p) then continue end
        local part = p.Character:FindFirstChild(AIM_PART)
        if not part then continue end
        if not inFOV(part.Position) then continue end
        local d = (part.Position - myPos).Magnitude
        if d < bd then bd, best = d, part end
    end
    return best
end

local mt = getrawmetatable(game)
local oldNamecall = mt.__namecall
setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    if method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" then
        local target = getKiller()
        if target then
            local args = {...}
            if typeof(args[1]) == "Vector3" and typeof(args[2]) == "Vector3" then
                args[2] = (target.Position - args[1])
            end
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)

setreadonly(mt, true)

workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("BasePart") and (obj.Name:lower():find("bullet") or obj.Name:lower():find("projectile") or obj.Name:lower():find("ray")) then
        task.spawn(function()
            for _ = 1, 60 do
                if not obj or not obj.Parent then break end
                local target = getKiller()
                if target then
                    local dir = (target.Position - obj.Position).Unit
                    obj.CFrame = CFrame.new(obj.Position, obj.Position + dir)
                    obj.AssemblyLinearVelocity = dir * 300
                end
                RunService.RenderStepped:Wait()
            end
        end)
    end
end)
