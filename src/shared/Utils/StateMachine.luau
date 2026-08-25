--!nonstrict
--[[
    StateMachine.luau
    OOP Class-based State Machine with state registration and lifecycle hooks (canEnter, enter, exit, update).
    Adapted from Roblox AI Workspace pattern.
    Location: src/shared/Utils/StateMachine.luau (Syncs to ReplicatedStorage.Shared.Utils.StateMachine)
--]]

local StateMachine = {}
StateMachine.__index = StateMachine

export type StateContext = {
	player: Player?,
	character: Model?,
	humanoid: Humanoid?,
	rootPart: BasePart?,
	deltaTime: number?,
	isGrounded: boolean?,
}

export type StateDefinition = {
	name: string,
	canEnter: ((context: StateContext, fromState: string?) -> (boolean, string?))?,
	enter: ((context: StateContext, fromState: string?) -> ())?,
	exit: ((context: StateContext, toState: string?) -> ())?,
	update: ((context: StateContext) -> string?)?,
}

export type StateMachineInstance = typeof(setmetatable({} :: {
	_states: { [string]: StateDefinition },
	_currentStateName: string?,
	_currentState: StateDefinition?,
	_onStateChanged: ((string?, string?) -> ())?,
}, StateMachine))

function StateMachine.new(onStateChanged: ((string?, string?) -> ())?): StateMachineInstance
	return setmetatable({
		_states = {},
		_currentStateName = nil,
		_currentState = nil,
		_onStateChanged = onStateChanged,
	}, StateMachine)
end

function StateMachine:registerState(state: StateDefinition)
	self._states[state.name] = state
end

function StateMachine:getCurrentStateName(): string?
	return self._currentStateName
end

function StateMachine:setState(nextStateName: string, context: StateContext): boolean
	local transitioned = self:trySetState(nextStateName, context)
	return transitioned
end

function StateMachine:trySetState(nextStateName: string, context: StateContext): (boolean, string?)
	local nextState = self._states[nextStateName]
	if nextState == nil then
		warn(string.format("[StateMachine] Unknown state %q", nextStateName))
		return false, "unknown_state"
	end

	local currentStateName = self._currentStateName
	if currentStateName == nextStateName then
		return false, "already_in_state"
	end

	if nextState.canEnter ~= nil then
		local canEnter, blockedReason = nextState.canEnter(context, currentStateName)
		if not canEnter then
			return false, blockedReason
		end
	end

	local currentState = self._currentState
	if currentState ~= nil and currentState.exit ~= nil then
		currentState.exit(context, nextStateName)
	end

	self._currentStateName = nextStateName
	self._currentState = nextState

	if nextState.enter ~= nil then
		nextState.enter(context, currentStateName)
	end

	if self._onStateChanged ~= nil then
		self._onStateChanged(currentStateName, nextStateName)
	end

	return true, nil
end

function StateMachine:update(context: StateContext): (boolean, string?)
	local currentState = self._currentState
	if currentState == nil or currentState.update == nil then
		return false, "no_active_state"
	end

	local nextStateName = currentState.update(context)
	if nextStateName ~= nil then
		return self:trySetState(nextStateName, context)
	end

	return false, nil
end

return StateMachine
