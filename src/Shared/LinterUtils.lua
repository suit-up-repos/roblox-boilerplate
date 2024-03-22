--[=[
@class LinterUtils

Author: Rick Hocker
Date: 03/22/2024
Project: Boilerplate

Description: Utility functions for casting to various types
]=]

local LinterUtils = {}

--[=[
	Get BasePart from BasePart?

	@return BasePart
]=]
function LinterUtils.GetBasePart(part: BasePart?): BasePart
	if part == nil then
		warn("LinterUtils: nil BasePart passed as argument!")
		return Instance.new("Part")
	else
		return part
	end
end

--[=[
	Get Model from Model?

	@return Model
]=]
function LinterUtils.GetModel(model: Model?): Model
	if model == nil then
		warn("LinterUtils: nil Model passed as argument!")
		return Instance.new("Model")
	else
		return model
	end
end

--[=[
	Get Model from Instance?

	@return Model
]=]
function LinterUtils.GetModelInstance(instance: Instance?): Model
	if instance == nil then
		warn("LinterUtils: nil instance passed as argument!")
		return Instance.new("Model")
	else
		--force instance to be untyped and return that
		local model = instance
		return model
	end
end

--[=[
	Get child Instance from BasePart?

	@return Instance
]=]
function LinterUtils.GetBasePartChild(part: BasePart?, name: string): Instance
	if part == nil then
		warn("LinterUtils: nil BasePart passed as argument!")
		return Instance.new("Part")
	else
		--get child instance
		local child: Instance? = part:FindFirstChild(name)
		if child == nil then
			warn("LinterUtils: child ", name, " is not found in BasePart!")
			return Instance.new("Part")
		else
			return child
		end
	end
end

--[=[
	Wait for child Instance from BasePart?

	@return Instance
]=]
function LinterUtils.WaitBasePartChild(part: BasePart?, name: string): Instance
	if part == nil then
		warn("LinterUtils: nil BasePart passed as argument!")
		return Instance.new("Part")
	else
		--get child instance
		local child: Instance? = part:WaitForChild(name)
		if child == nil then
			warn("LinterUtils: child ", name, " is not found in BasePart!")
			return Instance.new("Part")
		else
			return child
		end
	end
end

--[=[
	Get child Instance from Frame?

	@return Instance
]=]
function LinterUtils.GetFrameChild(frame: Frame?, name: string): Instance
	if frame == nil then
		warn("LinterUtils: nil Frame passed as argument!")
		return Instance.new("Frame")
	else
		--get child instance
		local child: Instance? = frame:FindFirstChild(name)
		if child == nil then
			warn("LinterUtils: child ", name, " is not found in Frame!")
			return Instance.new("Frame")
		else
			return child
		end
	end
end

--[=[
	Wait for child Instance from Frame?

	@return Instance
]=]
function LinterUtils.WaitFrameChild(frame: Frame?, name: string): Instance
	if frame == nil then
		warn("LinterUtils: nil Frame passed as argument!")
		return Instance.new("Frame")
	else
		--get child instance
		local child: Instance? = frame:WaitForChild(name)
		if child == nil then
			warn("LinterUtils: child ", name, " is not found in Frame!")
			return Instance.new("Frame")
		else
			return child
		end
	end
end

return LinterUtils
