local ProjectionGizmos = {}

export type ProjectionData = {
	rawDirection: Vector3,
	projectedDirection: Vector3?,
	lateralVector: Vector3?,
}

export type ProjectionConfig = {
	origin: Vector3,
	lineLength: number,
	projection: ProjectionData,
	moveLine: BasePart,
	projectedLine: BasePart,
	lateralLine: BasePart,
}

function ProjectionGizmos.drawProjection(renderer: any, config: ProjectionConfig)
	local origin = config.origin
	local lineLength = config.lineLength
	local projection = config.projection
	local moveDirection = projection.rawDirection
	local projectedDirection = projection.projectedDirection
	local lateralVector = projection.lateralVector

	renderer:setLine(
		config.moveLine,
		origin,
		origin + (moveDirection * lineLength)
	)

	if projectedDirection == nil or projectedDirection.Magnitude <= 1e-4 then
		renderer:setLine(config.projectedLine, origin, origin)
		renderer:setLine(config.lateralLine, origin, origin)
		return
	end

	local projectedUnit = projectedDirection.Unit
	renderer:setLine(
		config.projectedLine,
		origin,
		origin + (projectedUnit * lineLength)
	)

	if lateralVector == nil or lateralVector.Magnitude <= 1e-4 then
		renderer:setLine(config.lateralLine, origin, origin)
		return
	end

	renderer:setLine(
		config.lateralLine,
		origin,
		origin + (lateralVector.Unit * math.min(lateralVector.Magnitude, 1) * lineLength)
	)
end

return ProjectionGizmos
