# Gizmo Debug Visualization System

The Gizmo system provides high-performance, object-pooled 3D debug rendering (lines, hit markers, wire spheres, labels, and vector projections) for client-side physics and raycasting debuggers in Roblox.

---

## 📁 File Structure

```
src/client/Debug/
├── DebugConfig.luau        # Central feature flags for debug rendering domains
├── GizmoRenderer.luau      # Core object-pooled gizmo renderer class
└── ProjectionGizmos.luau   # Helper for vector projection visualizers
```

---

## 🚀 Quick Start Example

```luau
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local GizmoRenderer = require(script.Parent.Debug.GizmoRenderer)
local DebugConfig = require(script.Parent.Debug.DebugConfig)

if not RunService:IsStudio() or not DebugConfig.WallDetection.ShowGizmos then
	return
end

-- Initialize renderer pointing to Workspace folder "WallDetectionDebug"
local renderer = GizmoRenderer.new("WallDetectionDebug", {
	lineThickness = 0.16,
	markerSize = 0.45,
})

RunService.RenderStepped:Connect(function()
	local origin = Vector3.new(0, 5, 0)
	local target = Vector3.new(0, 5, 10)

	-- Retrieve pooled line and marker
	local line = renderer:getLine("Ray_01", Color3.fromRGB(80, 255, 140))
	local marker = renderer:getMarker("Hit_01", Color3.fromRGB(255, 170, 70))

	-- Update position & orientation every frame
	renderer:setLine(line, origin, target)
	renderer:setMarker(marker, target)
end)

-- Clean up on character removal
Players.LocalPlayer.CharacterRemoving:Connect(function()
	renderer:hideAll()
end)
```

---

## 📖 API Reference

### `GizmoRenderer`

#### Constructor
```luau
GizmoRenderer.new(folderName: string, config: table?): GizmoRenderer
```
Creates or retrieves a `Folder` in `Workspace` named `folderName`.

**Config Options:**
* `lineThickness` *(number, default: 0.2)*: Diameter of line parts.
* `lineTransparency` *(number, default: 0.1)*: Transparency of lines.
* `markerSize` *(number, default: 0.45)*: Size of sphere markers.
* `markerTransparency` *(number, default: 0.05)*: Transparency of markers.
* `wireSphereTransparency` *(number, default: 0.75)*: Transparency of wire spheres.
* `labelTextSize` *(number, default: 14)*: Text size of point labels.
* `labelStudsOffset` *(Vector3, default: (0, 1.2, 0))*: World offset for point labels.

#### Primitive Getters (Pooled Instantiation)
* `renderer:getLine(name: string, color: Color3): BasePart`
* `renderer:getMarker(name: string, color: Color3): BasePart`
* `renderer:getWireSphere(name: string, color: Color3, radius: number?): SphereHandleAdornment`
* `renderer:getPointLabel(name: string, text: string, color: Color3): BasePart`

#### Primitive Setters (Per-Frame Positioning)
* `renderer:setLine(line: BasePart, fromPosition: Vector3, toPosition: Vector3, color: Color3?)`
* `renderer:setMarker(marker: BasePart, position: Vector3, color: Color3?)`
* `renderer:setWireSphere(sphere: SphereHandleAdornment, position: Vector3, radius: number?, color: Color3?)`
* `renderer:setPointLabel(anchor: BasePart, position: Vector3, text: string, color: Color3?)`

#### Hiding & Reset Methods
* `renderer:hideLine(line: BasePart)`
* `renderer:hideMarker(marker: BasePart)`
* `renderer:hideWireSphere(sphere: SphereHandleAdornment)`
* `renderer:hidePointLabel(anchor: BasePart)`
* `renderer:hideAll()` — Hides all primitives in the debug folder.

---

### `ProjectionGizmos`

#### Vector Projection Renderer
```luau
ProjectionGizmos.drawProjection(renderer: GizmoRenderer, config: ProjectionConfig)
```
Renders a 3-way vector projection diagram (Raw movement vector, projected direction along a surface, and lateral vector).

---

## 🛠️ Best Practices

1. **Always Gate Behind Debug Flags**: Ensure debug scripts check `RunService:IsStudio()` and the relevant `DebugConfig` toggle before subscribing to `RenderStepped`.
2. **Reuse Named Instances**: Use standard identifier patterns (e.g. `string.format("Ray_%02d", index)`) so the pooling engine reuses existing `Part` instances across frames.
3. **Hide Inactive Elements**: Call `renderer:hideLine()` or `renderer:hideAll()` when debug visualization is paused or character respawns to avoid leftover floating geometry.
