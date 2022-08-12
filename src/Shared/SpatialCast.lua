--[[
    SpatialCast.lua
    Author: Aaron (se_yai)
    31 December 2021

    Use new spatial query API to gather parts within a given space, filters them based on containers (i.e characters),
    then uses Signals to trigger actions on these containers. Useful for creating real time hitboxes
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local SpatialCast = {}
SpatialCast.__index = SpatialCast

local CollectionService = game:GetService("CollectionService")
local Knit = require(game.ReplicatedStorage.Packages.Knit)
local Signal = require(game.ReplicatedStorage.Packages.Signal)
local Maid = require(game.ReplicatedStorage.Packages.Maid)

local TIMESTEP = RunService.Heartbeat

SpatialCast.Axis = {
    X = 1,
    Y = 2,
    Z = 3
}

-- instantiate new SpatialCast object
function SpatialCast.new(originPart, enableVisualizer)
    local self = setmetatable({}, SpatialCast)
    self._alreadyHit = {originPart:FindFirstAncestorOfClass("Model")}
    self._active = false
    self._maid = Maid.new()
    self._origin = originPart
    self.Visualizer = false

    self._isCleaning = false

    self.OnHit = Signal.new()

    local overlapParams = OverlapParams.new()
    overlapParams.FilterDescendantsInstances = self._alreadyHit
    overlapParams.FilterType = Enum.RaycastFilterType.Blacklist
    self._params = overlapParams

    if enableVisualizer then
        local vis = Instance.new("Part")
        table.insert(self._alreadyHit, vis)
        vis.Anchored = true
        vis.CanCollide = false
        vis.CanQuery = false
        vis.Transparency = 0.5
        vis.Material = Enum.Material.Neon
        vis.Color = Color3.new(0.701960, 0.329411, 0.329411)
        vis.Parent = ReplicatedStorage
        self.Visualizer = vis
    end

    return self
end

--- "Turn on" SpatialCast for a given space and range, starting at the origin of the SpatialCast
-- Can be set to automatically turn off after `activeTime`, but can be turned off manually as well
function SpatialCast:Activate(size: Vector2, range: number, axis: string, activeTime: number)
    self._active = true
    self._maid:Add(function()
        self._active = false

        table.clear(self._alreadyHit)
        table.insert(self._alreadyHit, self._origin:FindFirstAncestorOfClass("Model"))
    end)

    local boxSize
    if axis == "X" then
        boxSize = Vector3.new(range, size.X, size.Y)
    elseif axis == "Y" then
        boxSize = Vector3.new(size.X, range, size.Y)
    elseif axis == "Z" then
        boxSize = Vector3.new(size.X, size.Y, range)
    end

    if self.Visualizer then
        self.Visualizer.Parent = workspace.Runtime
        self._maid:Add(function()
            self.Visualizer.Parent = ReplicatedStorage
        end)
    end

    local function runHitbox()
        if not self._active then return end
        local newpos = self._origin.Position + self._origin.CFrame.LookVector * (range * 0.5)
        local new_origin = CFrame.lookAt(
            newpos, newpos +  self._origin.CFrame.LookVector * (range * 0.5)
        )

        local objects = workspace:GetPartBoundsInBox(new_origin, boxSize, self._params)

        if self.Visualizer then
            self.Visualizer.Size = boxSize
            self.Visualizer.CFrame = new_origin
        end
        -- parse
        for _, object in ipairs(objects) do
            if object:IsA("BasePart") then
                local model = object:FindFirstAncestorOfClass("Actor") or object:FindFirstAncestorOfClass("Model")
                if model then
                    if CollectionService:HasTag(model, "TargetableCharacter") then
                        if not table.find(self._alreadyHit, model) then
                            table.insert(self._alreadyHit, model)

                            self.OnHit:Fire(model)
                        end
                    end
                end
            end
        end
    end

    self._maid:Add(TIMESTEP:Connect(runHitbox))
    task.delay(activeTime, function()
        self._maid:Cleanup()
    end)
end

--- "Turns off" any running SpatialCasts
function SpatialCast:Deactivate()
    if self._active then
        self._maid:Cleanup()
    end
end

--- Destroys the SpatialCast object
function SpatialCast:Destroy()
    self._alreadyHit = nil
    self._maid:Destroy()
    print("destroyed spatial cast")
end


return SpatialCast