--[[
    MobService.lua
    Author: Aaron (se_yai)

    Description: Manage player spawning and interactions with the server involving data
]]
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local buildRagdoll = require(Shared.Ragdoll.buildRagdoll)
local ImpulseFling = require(Shared.ImpulseFling)
local Utils = require(Shared.Utils)

local Mobs = ReplicatedStorage.Assets.Mobs

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)
local WaitFor = require(Packages.WaitFor)

local MobService = Knit.CreateService {
    Name = "MobService";
    Client = {};
}

local PlayerService

local MAX_MOBS = 30
local MOBS_PER_PLAYER = 18
local BASE_DAMAGE = 10
local MAX_CHARGE_MULT = 10

local SPAWNS = workspace:WaitForChild("MobSpawns"):GetChildren()

function MobService.Client:DamageMobs(player, mob_list, chargeRatio)
    -- TODO: add sanity check to prevent client abuse
    local multiplier = MAX_CHARGE_MULT * (chargeRatio - 1)
    local damage = BASE_DAMAGE *  multiplier
    for _, mob in mob_list do
        local mobnoid = mob:FindFirstChild("Humanoid")
        if mobnoid then
            mobnoid:SetAttribute("LastDamage", player.UserId)
            mobnoid:TakeDamage(damage)
            mobnoid:ChangeState(Enum.HumanoidStateType.Physics)
            local direction = CFrame.lookAt(
                player.Character.PrimaryPart.Position,
                mob.PrimaryPart.Position).LookVector
            ImpulseFling(mob, direction, multiplier)
            task.delay(2, function()
                mobnoid:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
            end)
        end
    end
end

function MobService:KnitStart()

    local function recalculateMobs()
        self._maxMobs = MAX_MOBS + (MOBS_PER_PLAYER * #Players:GetPlayers())
    end

    Players.PlayerAdded:Connect(recalculateMobs)

    Players.PlayerRemoving:Connect(recalculateMobs)

    -- create new mob
    while self._running do
        task.wait(2)
        for i = 1, self._maxMobs - #self._MOBS:GetChildren() do
            local newMob = Mobs.BasicMob:Clone()
            local hum = newMob:WaitForChild("Humanoid")

            -- disable unnecessary states
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.PlatformStanding, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
            hum:SetStateEnabled(Enum.HumanoidStateType.Flying, false)

            CollectionService:AddTag(newMob, "TargetableCharacter")
            local isDead = false
            hum.Died:Connect(function()
                if isDead then return end
                isDead = true
                local kill_id = hum:GetAttribute("LastDamage")
                local killer = Players:GetPlayerByUserId(kill_id)
                if killer then
                    local sos = killer:FindFirstChild("H/Rs", true)
                    if sos then
                        sos.Value += 1
                    end
                end
                task.delay(2, function()
                    newMob:Destroy()
                end)
            end)

            newMob.Parent = self._MOBS
            task.wait()
            buildRagdoll(hum)

            local randomSpawn = SPAWNS[math.random(1, #SPAWNS)]
            newMob:SetPrimaryPartCFrame(Utils.getRandomInPart(randomSpawn))
            

            for _, v in ipairs(newMob:GetChildren()) do
                if v:IsA("BasePart") then
                    PhysicsService:SetPartCollisionGroup(v, "Mobs")
                end
            end
        end
    end
end


function MobService:KnitInit()
    self._running = true
    self._MOBS = Instance.new("Folder")
    self._MOBS.Name = "ActorMobs"
    self._MOBS.Parent = workspace

    self._maxMobs = MAX_MOBS + (MOBS_PER_PLAYER * #Players:GetPlayers())

    game:BindToClose(function()
        self._running = false
    end)

    PlayerService = Knit.GetService("PlayerService")
end


return MobService