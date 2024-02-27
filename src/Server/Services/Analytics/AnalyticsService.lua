--!strict

local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages: any = ReplicatedStorage.Packages
local GameAnalytics: any = require(Packages.GameAnalytics)
local HttpApi: any = require(Packages._Index:FindFirstChild("gameanalytics-sdk", true).GameAnalytics.HttpApi)
local Knit: any = require(Packages.Knit)
local Promise: any = require(Packages.Promise)

--[=[
	@class AnalyticsService
	
	Author: Javi M (dig1t)
	
	Knit service that handles GameAnalytics API requests.
	
	The API keys can be found inside game settings of your GameAnalytics game page.
	
	Events that happen during a mission (kills, deaths, rewards) should be
	tracked and logged after the event ends	to avoid hitting API limits.
	For example, if a player kills an enemy during a mission, the kill should be
	tracked and logged (sum of kills) at the end of the mission.
	
	Refer to [GameAnalytics docs](https://docs.gameanalytics.com/integrations/sdk/roblox/event-tracking) for more information and use cases.
	
	### Quick Start
	
	In order to use this service, you must first configure it with `AnalyticsService:SetOptions()` (example: in the main server script)
	
	To configure AnalyticsService:
	```lua
	local AnalyticsService: any = Knit.GetService("AnalyticsService")
	
	AnalyticsService:SetOptions({
		currencies = { "Coins" },
		build = "1.1.0",
		gameKey = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
		secretKey = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx",
		logDevProductPurchases = false,
		resourceEventTypes = {
			"Reward",
			"Purchase",
			"Shop",
			"Loot",
			"Combat"
		},
		gamepassIds = { 000000000, 111111111 }
	})
	```
	
	Using AnalyticsService to track events on the client:
	```lua
	-- Inside a LocalScript
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	
	local Packages: any = ReplicatedStorage.Packages
	local Knit: any = require(Packages.Knit)
	
	Knit.Start():await() -- Wait for Knit to start
	
	AnalyticsService.AddTrackedValue:Fire({ -- This adds a value to a tracked event
		event = "UIEvent:OpenedShop",
		value = 1
	})
	
	AnalyticsService.LogEvent:Fire({ -- This logs an event
		event = "UIEvent:FTUE:Completed"
	})
	
	AnalyticsService.AddDelayedEvent:Fire({ -- This adds a delayed event that fires when the player leaves
		event = "UIEvent:ClaimedReward"
	})
	```
	```
]=]
local AnalyticsService = Knit.CreateService({
	Name = "AnalyticsService",
	Client = {
		LogEvent = Knit.CreateSignal(),
		AddDelayedEvent = Knit.CreateSignal(),
		AddTrackedValue = Knit.CreateSignal(),
	},
})

--[=[
	@interface CustomDimensions
	.dimension01 string?
	.dimension02 string?
	.dimension03 string?
	@within AnalyticsService
]=]
export type CustomDimensions = {
	dimension01: string?,
	dimension02: string?,
	dimension03: string?,
}

--[=[
	@interface AnalyticsOptions
	.currencies { string? }? -- List of all in-game currencies (defaults to { "Coins" })
	.build string? -- Game version
	.gameKey string -- GameAnalytics game key
	.secretKey string -- GameAnalytics secret key
	.logDevProductPurchases boolean? -- Whether or not to automatically log developer product purchases (defaults to true)
	.resourceEventTypes { string? }? -- List of all resource event types (example: player gained coins in a mission is a "Reward" event type, player purchasing coins with Robux is a "Purchase" event type)
	.gamepassIds { number? }? -- List of all gamepass ids in the game
	.customDimensions01 CustomDimension? -- Custom dimensions to be used in GameAnalytics (refer to [GameAnalytics docs](https://docs.gameanalytics.com/advanced-tracking/custom-dimensions) about dimensions)
	@within AnalyticsService
]=]
export type AnalyticsOptions = {
	currencies: { string? }?,
	build: string?,
	gameKey: string,
	secretKey: string,
	logDevProductPurchases: boolean?,
	resourceEventTypes: { string? }?,
	gamepassIds: { number? }?,
	customDimensions: CustomDimensions?,
}

--[=[
	@interface PlayerEvent
	.userId number
	.event string
	.value number?
	@within AnalyticsService
]=]
export type PlayerEvent = {
	userId: number,
	event: string,
	value: number?,
}

--[=[
	@interface MarketplacePurchaseEvent
	.userId number
	.itemType string
	.id string
	.amount number?
	.cartType string
	@within AnalyticsService
]=]
export type MarketplacePurchaseEvent = {
	userId: number,
	itemType: string,
	id: string,
	amount: number?,
	cartType: string,
}

--[=[
	@interface PurchaseEvent
	.userId number
	.eventType string -- 1 by default
	.itemId string
	.currency string -- In-game currency type used
	.flowType string? -- Allowed flow types: "Sink", "Source" (defaults to "Sink")
	.amount number?
	@within AnalyticsService
	
	- Currency is the in-game currency type used, it must be defined in `AnalyticsService:SetOptions()`
]=]
export type PurchaseEvent = {
	userId: number,
	eventType: string,
	itemId: string,
	currency: string,
	flowType: string?,
	amount: number?,
}

--[=[
	@interface ResourceEvent
	.userId number
	.eventType string
	.itemId string -- unique id of item (example: "100 Coins", "Coin Pack", "Red Loot Box", "Extra Life")
	.currency string
	.flowType string
	.amount number
	@within AnalyticsService
	
	- Currency is the in-game currency type used, it must be defined in `AnalyticsService:SetOptions()`
]=]
export type ResourceEvent = {
	userId: number,
	eventType: string,
	itemId: string,
	currency: string,
	flowType: string,
	amount: number,
}

--[=[
	@interface ErrorEvent
	.message string
	.severity string? -- Allowed severities: "Debug", "Info", "Warning", "Error", "Critical" (defaults to "Error")
	.userId number
	@within AnalyticsService
]=]
export type ErrorEvent = {
	message: string,
	severity: string?,
	userId: number,
}

--[=[
	@interface ProgressionEvent
	.userId number
	.status string -- Allowed statuses: "Start", "Fail", "Complete"
	.progression01 string -- Mission, Level, etc.
	.progression02 string? -- Location, etc.
	.progression03 string? -- Level, etc. (if used then progression02 is required)
	.score number? -- Adding a score is optional
	@within AnalyticsService
]=]
export type ProgressionEvent = {
	userId: number,
	status: string,
	progression01: string,
	progression02: string?,
	progression03: string?,
	score: number?,
}

--[=[
	@interface DelayedEvent
	.userId number?
	.event string
	.value number?
	@within AnalyticsService
]=]
export type DelayedEvent = {
	userId: number?,
	event: string,
	value: number?,
}

--[=[
	@interface TrackedValueEvent
	.userId number?
	.event string
	.value number?
	@within AnalyticsService
]=]
export type TrackedValueEvent = {
	userId: number?,
	event: string,
	value: number?,
}

--[=[
	@interface RemoteConfig
	.player Player?
	.name string
	.defaultValue string
	.value string?
	@within AnalyticsService
]=]
export type RemoteConfig = {
	player: Player?,
	name: string,
	defaultValue: string,
	value: string?,
}

function AnalyticsService:KnitInit()
	self._events = {}
	self._trackedEvents = {}
end

--- @private
function AnalyticsService:_start(): nil
	GameAnalytics:configureBuild(self._options.build)

	if self._options.customDimensions then
		if self._options.customDimensions.dimension01 then
			GameAnalytics:configureAvailableCustomDimensions01(self._options.customDimensions.dimension01)
		end

		if self._options.customDimensions.dimension02 then
			GameAnalytics:configureAvailableCustomDimensions02(self._options.customDimensions.dimension02)
		end

		if self._options.customDimensions.dimension03 then
			GameAnalytics:configureAvailableCustomDimensions03(self._options.customDimensions.dimension03)
		end
	end

	GameAnalytics:configureAvailableResourceCurrencies(self._options.currencies)
	GameAnalytics:configureAvailableResourceItemTypes(self._options.resourceEventTypes)
	GameAnalytics:configureAvailableGamepasses(self._options.gamepassIds)

	GameAnalytics:setEnabledInfoLog(false)
	GameAnalytics:setEnabledVerboseLog(false)
	GameAnalytics:setEnabledDebugLog(false)

	GameAnalytics:setEnabledAutomaticSendBusinessEvents(false)
	GameAnalytics:setEnabledReportErrors(false)

	GameAnalytics:initServer(self._options.gameKey, self._options.secretKey)

	self.Client.LogEvent:Connect(function(
		player: Player,
		data: {
			event: string,
			value: number?,
		}
	)
		self:LogPlayerEvent({
			userId = player.UserId,
			event = data.event,
			value = data.value,
		})
	end)

	-- Logs an event to be sent once the player is leaving the game
	self.Client.AddDelayedEvent:Connect(function(player: Player, data: DelayedEvent)
		self:AddDelayedEvent({
			userId = player.UserId,
			event = data.event,
			value = data.value,
		})
	end)

	-- Adds a value to a tracked event, it will be sent once the player is leaving the game
	self.Client.AddTrackedValue:Connect(function(player: Player, data: TrackedValueEvent)
		self:AddTrackedValue({
			userId = player.UserId,
			event = data.event,
			value = data.value,
		})
	end)

	MarketplaceService.PromptBundlePurchaseFinished:Connect(function(player: Player, bundleId: number, purchased: boolean)
		if not purchased then
			return
		end

		self:LogMarketplacePurchase({
			userId = player.UserId,
			itemType = "Bundle",
			id = bundleId,
			cartType = "PromptPurchase",
		})
	end)

	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, gamePassId: number, purchased: boolean)
		if not purchased then
			return
		end

		self:LogMarketplacePurchase({
			userId = player.UserId,
			itemType = "GamePass",
			id = gamePassId,
			cartType = "PromptPurchase",
		})
	end)

	if self._options.logDevProductPurchases then
		MarketplaceService.PromptProductPurchaseFinished:Connect(function(player: Player, productId: number, purchased: boolean)
			if not purchased then
				return
			end

			self:LogMarketplacePurchase({
				userId = player.UserId,
				itemType = "Product",
				id = productId,
				cartType = "PromptPurchase",
			})
		end)
	end

	MarketplaceService.PromptPurchaseFinished:Connect(function(player: Player, assetId: number, purchased: boolean)
		if not purchased then
			return
		end

		self:LogMarketplacePurchase({
			userId = player.UserId,
			itemType = "Asset",
			id = assetId,
			cartType = "PromptPurchase",
		})
	end)

	MarketplaceService.PromptSubscriptionPurchaseFinished:Connect(function(player: Player, subscriptionId: string, didTryPurchasing: boolean)
		if not didTryPurchasing then
			return
		end

		self:LogMarketplacePurchase({
			userId = player.UserId,
			itemType = "Subscription",
			id = subscriptionId,
			cartType = "PromptPurchase",
		})
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		self:_flushTrackedEvents(player)
	end)

	return
end

--- @private
function AnalyticsService:_flushTrackedEvents(player: Player): nil
	if not player or not self._enabled then
		return
	end

	local userId: number = player.UserId

	if self._events[userId] then
		for _, event in pairs(self._events[userId]) do
			self:LogPlayerEvent({
				userId = userId,
				event = event,
			})
		end

		self._events[userId] = nil
	end

	if self._trackedEvents[userId] then
		for event, value in pairs(self._trackedEvents[userId]) do
			self:LogPlayerEvent({
				userId = userId,
				event = event,
				value = value,
			})
		end

		self._trackedEvents[userId] = nil
	end

	return
end

--[=[
	Used to set the options for AnalyticsService
	
	@param options table
	@return nil
]=]
function AnalyticsService:SetOptions(options: AnalyticsOptions): nil
	if self._enabled then
		return
	end

	assert(typeof(options) == "table", "AnalyticsService.SetConfig - options is required")
	assert(options.gameKey, "AnalyticsService.SetConfig - gameKey is required")
	assert(options.secretKey, "AnalyticsService.SetConfig - secretKey is required")

	self._options = {}
	self._enabled = true

	self._options.currencies = options.currencies or { "Coins" }
	self._options.build = options.build or "0.0.1"
	self._options.gameKey = options.gameKey
	self._options.secretKey = options.secretKey
	self._options.logDevProductPurchases = options.logDevProductPurchases or true
	self._options.resourceEventTypes = options.resourceEventTypes
	self._options.gamepassIds = options.gamepassIds or {}
	self._options.customDimensions = options.customDimensions or {}

	self:_start()

	return
end

--[=[
	Used to track player events (example: player killed an enemy, player completed a mission, etc.)
	
	Examples
	```lua
	AnalyticsService:LogPlayerEvent({
		userId = player.UserId,
		event = "Player:KilledEnemy",
		value = 1 -- Killed 1 enemy
	})
	AnalyticsService:LogPlayerEvent({
		userId = player.UserId,
		event = "Player:CompletedMission",
		value = 1 -- Completed 1 mission
	})
	AnalyticsService:LogPlayerEvent({
		userId = player.UserId,
		event = "Player:Death",
		value = 1
	})
	```
	
	@param data PlayerEvent
	@return { [any]: any }
]=]
function AnalyticsService:LogPlayerEvent(data: PlayerEvent): { [any]: any }
	return Promise.new(function(resolve, reject)
		if not self._enabled then
			return reject("AnalyticsService must be configured with :SetOptions()")
		elseif not data then
			return reject("AnalyticsService.LogPlayerEvent - data is required")
		elseif not data.userId then
			return reject("AnalyticsService.LogPlayerEvent - userId is required")
		elseif not data.event then
			return reject("AnalyticsService.LogPlayerEvent - event is required")
		elseif data.value ~= nil and typeof(data.value) ~= "number" then
			return reject("AnalyticsService.LogPlayerEvent - value must be a number")
		end

		-- Trim trailing colon
		if string.sub(data.event, #data.event) == ":" then
			data.event = string.sub(data.event, 1, #data.event - 1)
		end

		GameAnalytics:addDesignEvent(data.userId, {
			eventId = data.event,
			value = data.value,
		})

		return resolve()
	end)
end

--[=[
	This function should be called when a successful marketplace purchase is made
	such as a gamepass or developer product
	
	Set `logDevProductPurchases` to false when configuring AnalyticsService if you prefer to log
	developer product purchases within MarketplaceService.ProcessReceipt
	
	```lua
	-- Inside MarketplaceService.ProcessReceipt
	-- before returning Enum.ProductPurchaseDecision.PurchaseGranted
	AnalyticsService:LogMarketplacePurchase({
		userId = player.UserId,
		itemType = "Product",
		id = 000000000, -- Developer product id
		cartType = "PromptPurchase",
	})
	```
	
	@param data MarketplacePurchaseEvent
	@return { [any]: any }
]=]
function AnalyticsService:LogMarketplacePurchase(data: MarketplacePurchaseEvent): { [any]: any }
	return Promise.new(function(resolve, reject)
		if not self._enabled then
			return reject("AnalyticsService must be configured with :SetOptions()")
		elseif not data.userId then
			return reject("userId is required")
		elseif not data.itemType then
			return reject("itemType is required")
		elseif not data.id then
			return reject("id is required")
		elseif not data.cartType then
			return reject("cartType is required")
		end

		GameAnalytics:addBusinessEvent(data.userId, {
			itemType = data.itemType,
			itemId = data.id,
			amount = data.amount or 1,
			cartType = data.cartType,
		})

		return resolve()
	end)
end

--[=[
	Shortcut function for LogResourceEvent
	Used to log in-game currency purchases
	
	Example Use:
	```lua
	AnalyticsService:LogPurchase({
		userId = player.UserId,
		eventType = "Shop",
		currency = "Coins",
		itemId = "Red Paintball Gun"
	})
	```
	
	@param data PurchaseEvent
	@return { [any]: any }
]=]
function AnalyticsService:LogPurchase(data: PurchaseEvent): { [any]: any }
	return Promise.new(function(resolve, reject)
		if not self._enabled then
			return reject("AnalyticsService must be configured with :SetOptions()")
		elseif not data.userId then
			return reject("userId is required")
		elseif not data.eventType then
			return reject("eventType is required")
		elseif not self._options.resourceEventTypes then
			return reject("resource event types must be configured during AnalyticsService:SetOptions() in order to log resource events")
		elseif not table.find(self._options.resourceEventTypes, data.eventType) then
			return reject("eventType " .. data.eventType .. " is invalid. Please define it in AnalyticsService:SetOptions()")
		elseif not data.itemId then
			return reject("itemId is required")
		elseif not data.currency then
			return reject("currency is required")
		elseif not table.find(self._options.currencies, data.currency) then
			return reject("currency type is invalid")
		elseif data.amount ~= nil and typeof(data.amount) ~= "number" then
			return reject("amount is required")
		elseif data.flowType ~= nil and not GameAnalytics.EGAResourceFlowType[data.flowType] then
			return reject("flow type is invalid")
		end

		self:LogResourceEvent({
			userId = data.userId,
			amount = data.amount or 1,
			currency = data.currency,
			flowType = (data.flowType == GameAnalytics.EGAResourceFlowType.Source and GameAnalytics.EGAResourceFlowType.Source)
				or (data.flowType == GameAnalytics.EGAResourceFlowType.Sink and GameAnalytics.EGAResourceFlowType.Sink)
				or GameAnalytics.EGAResourceFlowType.Sink,
			eventType = data.eventType,
			itemId = data.itemId,
		})

		return resolve()
	end)
end

--[=[
	Used to log in-game currency changes (example: player spent coins in a shop,
	player purchased coins, player won coins in a mission)
	
	Example Use:
	```lua
	-- Player purchased 100 coins with Robux
	AnalyticsService:LogResourceEvent({
		userId = player.UserId,
		eventType = "Purchase",
		currency = "Coins",
		itemId = "100 Coins",
		flowType = "Source",
		amount = 100
	})
	```
	
	@param data ResourceEvent
	@return { [any]: any }
]=]
function AnalyticsService:LogResourceEvent(data: ResourceEvent): { [any]: any }
	return Promise.new(function(resolve, reject)
		if not self._enabled then
			return reject("AnalyticsService must be configured with :SetOptions()")
		elseif not data.userId then
			return reject("userId is required")
		elseif not data.eventType then
			return reject("eventType is required")
		elseif not self._options.resourceEventTypes then
			return reject("resource event types must be configured during AnalyticsService:SetOptions() in order to log resource events")
		elseif not table.find(self._options.resourceEventTypes, data.eventType) then
			return reject("eventType " .. data.eventType .. " is invalid. Please define it in AnalyticsService:SetOptions()")
		elseif not data.itemId then
			return reject("itemId is required")
		elseif not data.currency then
			return reject("currency is required")
		elseif not table.find(self._options.currencies, data.currency) then
			return reject("currency type is invalid")
		elseif not GameAnalytics.EGAResourceFlowType[data.flowType] then
			return reject("flow type is invalid")
		elseif typeof(data.amount) ~= "number" then
			return reject("amount is required")
		end

		GameAnalytics:addResourceEvent(data.userId, {
			-- FlowType is Sink by default
			flowType = data.flowType,
			currency = data.currency,
			amount = data.amount,
			itemType = data.eventType,
			itemId = data.itemId,
		})

		return resolve()
	end)
end

--[=[
	Used to log errors
	
	Example Use:
	```lua
	local missionName: string = "Invalid Mission Name"
	
	AnalyticsService:LogError({
		userId = player.UserId,
		message = "Player tried to join a mission that doesn't exist named " .. missionName,
		severity = "Error"
	})
	```
	
	@param data ErrorEvent
	@return { [any]: any }
]=]
function AnalyticsService:LogError(data: ErrorEvent): { [any]: any }
	return Promise.new(function(resolve, reject)
		if not self._enabled then
			return reject("AnalyticsService must be configured with :SetOptions()")
		elseif not data.userId then
			return reject("userId is required")
		elseif not data.message then
			return reject("message is required")
		elseif data.severity ~= nil and not GameAnalytics.EGAErrorSeverity[data.severity] then
			return reject("severity is invalid")
		end

		local errorSeverity: string = data.severity or GameAnalytics.EGAErrorSeverity.Error

		GameAnalytics:addErrorEvent(data.userId, {
			message = data.message,
			severity = GameAnalytics.EGAErrorSeverity[errorSeverity],
		})

		return resolve()
	end)
end

--[=[
	Used to track player progression (example: player score in a mission or level).
	
	A progression can have up to 3 levels (example: Mission 1, Location 1, Level 1)
	
	If a progression has 3 levels, then progression01, progression02, and progression03 are required.
	
	If a progression has 2 levels, then progression01 and progression02 are required.
	
	Otherwise, only progression01 is required.
	
	Example:
	```lua
	AnalyticsService:LogProgression({
		userId = player.UserId,
		status = "Start",
		progression01 = "Mission X",
		progression02 = "Location X",
		score = 100 -- Started with score of 100
	})
	AnalyticsService:LogProgression({
		userId = player.UserId,
		status = "Complete",
		progression01 = "Mission X",
		progression02 = "Location X",
		score = 400 -- Completed the mission with a score of 400
	})
	```
	
	For more information on progression events, refer to [GameAnalytics docs](https://docs.gameanalytics.com/integrations/sdk/roblox/event-tracking?_highlight=teleportdata#progression) on progression.
	
	@param data ProgressionEvent
	@return { [any]: any }
]=]
function AnalyticsService:LogProgression(data: ProgressionEvent): { [any]: any }
	return Promise.new(function(resolve, reject)
		if not self._enabled then
			return reject("AnalyticsService must be configured with AnalyticsService:SetOptions()")
		elseif not data.userId then
			return reject("userId is required")
		elseif not data.status then
			return reject("status is required")
		elseif not GameAnalytics.EGAProgressionStatus[data.status] then
			return reject("status is invalid")
		elseif not data.progression01 then
			return reject("progression01 is required")
		elseif data.progression02 ~= nil and typeof(data.progression02) ~= "string" then
			return reject("progression02 must be a string")
		elseif data.progression03 ~= nil and typeof(data.progression03) ~= "string" then
			return reject("progression03 must be a string")
		elseif data.progression03 ~= nil and not data.progression02 then
			return reject("progression02 is required if progression03 is used")
		elseif data.score ~= nil and typeof(data.score) ~= "number" then
			return reject("score must be a number")
		end

		GameAnalytics:addProgressionEvent(data.userId, {
			progressionStatus = GameAnalytics.EGAProgressionStatus[data.status],
			progression01 = data.progression01,
			progression02 = data.progression02,
			progression03 = data.progression03,
			score = data.score or 0,
		})

		return resolve()
	end)
end

--[=[
	Used to add a delayed event that fires when the player leaves
	
	Example Use:
	```lua
	AnalyticsService:AddDelayedEvent({
		userId = player.UserId,
		event = "Player:ClaimedReward"
	})
	```
	
	Example client use:
	```lua
	AnalyticsService.AddDelayedEvent:Fire({
		event = "UIEvent:FTUE:Completed"
	})
	```
	
	@param data DelayedEvent
	@return nil
]=]
function AnalyticsService:AddDelayedEvent(data: DelayedEvent): nil
	if not self._enabled or not data.userId then
		return
	end

	if not self._events[data.userId] then
		self._events[data.userId] = {}
	end

	if not data.event then
		return
	elseif data.value ~= nil and typeof(data.value) ~= "number" then
		return
	end

	self._events[data.userId][#self._events[data.userId] + 1] = {
		event = data.event,
		value = data.value,
	}

	return
end

--[=[
	Used to add a value to a tracked event
	
	Example Use:
	```lua
	AnalyticsService:AddTrackedValue({
		userId = player.UserId,
		event = "Player:Kills",
		value = 2 -- Optional, defaults to 1
	})
	```
	
	Example client use:
	```lua
	AnalyticsService.AddTrackedValue:Fire({
		event = "UIEvent:OpenedShop"
	})
	```
	
	@param data TrackedValueEvent
	@return nil
]=]
function AnalyticsService:AddTrackedValue(data: TrackedValueEvent): nil
	if not self._enabled or not data.userId or not data.event then
		return
	end

	if data.value ~= nil and typeof(data.value) ~= "number" then
		return
	end

	if not self._trackedEvents[data.userId] then
		self._trackedEvents[data.userId] = {}
	end

	if not data.event then
		return
	elseif data.value ~= nil and typeof(data.value) ~= "number" then
		return
	end

	if not self._trackedEvents[data.userId][data.event] then
		self._trackedEvents[data.userId][data.event] = 0
	end

	self._trackedEvents[data.userId][data.event] += data.value or 1

	return
end

--[=[
	Get the psuedo server player data that's used to communicate with GameAnalytics APIs
	
	@private
	@within AnalyticsService
	@return any
]=]
function AnalyticsService:_getServerPsuedoPlayer(): { [any]: any }
	return {
		id = "DummyId",
		PlayerData = {
			OS = "uwp_desktop 0.0.0",
			Platform = "uwp_desktop",
			SessionID = HttpService:GenerateGUID(false):lower(),
			Sessions = 1,
			CustomUserId = "Server",
		},
	}
end

--[=[
	Get the value of a remote configuration or A/B test given context ( player.UserId )
	
	Example Use:
	```lua
	local remoteValue = AnalyticsService:GetRemoteConfig({
		player = player,
		name = "Test",
		defaultValue = "Default"
	}):await()
	```
	
	```lua
	AnalyticsService:GetRemoteConfig({
		player = player,
		name = "Test",
		defaultValue = "Default"
	})
		:andThen(
		function(remoteValue)
			print(remoteValue)
		end)
		:catch(function(err)
			warn(err)
		end)
	```
	
	@within AnalyticsService
	@param remote RemoteConfig -- The name, default value, and context of the remote configuration
	@return string
]=]
function AnalyticsService:GetRemoteConfig(remote: RemoteConfig): { [any]: any }
	return Promise.new(function(resolve, reject)
		if not remote then
			return reject("AnalyticsService.GetRemoteConfig - remote is required")
		elseif not remote.name then
			return reject("AnalyticsService.GetRemoteConfig - remote.name is required")
		elseif not remote.defaultValue then
			return reject("AnalyticsService.GetRemoteConfig - remote.defaultValue is required")
		end

		if not self._enabled then
			return resolve(remote.defaultValue)
		end

		local player: Player? = remote.player
		local context: any = self:_getServerPsuedoPlayer()
		local server: any = not player and HttpApi:initRequest(self._options.gameKey, self._options.secretKey, self._options.build, context.PlayerData, "")

		if server and server.statusCode >= 9 then
			for _, config in (server.body.configs or {}) do
				if config.key == remote.name then
					return resolve(config.value)
				end
			end
		end

		if player and not GameAnalytics:isRemoteConfigsReady(player.UserId) then
			return resolve(remote.defaultValue)
		end

		return resolve(player and GameAnalytics:getRemoteConfigsValueAsString(player.UserId, {
			key = remote.name,
			defaultValue = remote.defaultValue,
		}) or remote.defaultValue)
	end)
end

return AnalyticsService
