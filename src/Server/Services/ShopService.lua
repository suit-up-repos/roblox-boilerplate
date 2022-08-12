--[[
    ShopService.lua
    Author: Aaron (se_yai)

    Description: Manage player spawning and interactions with the server involving data
]]

local ServerStorage = game:GetService("ServerStorage")
local Modules = ServerStorage:WaitForChild("Modules")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local Packages = ReplicatedStorage.Packages
local Knit = require(ReplicatedStorage.Packages.Knit)

local ShopService = Knit.CreateService {
    Name = "ShopService";
    Client = {};
}

function ShopService.Client:PurchaseItem(player, shopItemId)
    
end

function ShopService:KnitStart()
    
end


function ShopService:KnitInit()
    
end


return ShopService