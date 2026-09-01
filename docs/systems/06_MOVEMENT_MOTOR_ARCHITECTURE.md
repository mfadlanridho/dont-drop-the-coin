# 📄 MOVEMENT MOTOR ARCHITECTURE (`MovementMotor.luau`)

This document specifies the architecture, configuration parameters, steering capture/release mechanisms, and physics constraint lifecycle management of **`MovementMotor.luau`** for **Don't Drop The Coin!**.

---

## 🎯 OBJECTIVES
1. Provide a unified, object-oriented physics motor wrapper (`MovementMotor.luau`) for managing client-side character motion constraints.
2. Eliminate physics constraint leaks by centralizing creation, attachment linking, and destruction of `LinearVelocity`, `VectorForce`, and `AlignOrientation` instances.
3. Manage character steering (`AutoRotate`) capture and release cleanly across gameplay states (`Normal`, `Dashing`, `SafeZone`).

---

## 📐 MOVEMENT MOTOR ARCHITECTURE DIAGRAM

```mermaid
graph TD
    State[State Definitions / DashingState] --> |1. new| Motor[MovementMotor Instance]
    State --> |2. capture| Steering[Humanoid.AutoRotate = false]
    State --> |3. ensure| Root[HumanoidRootPart Attachment & Constraints]
    
    subgraph Physics Constraints
        Root --> LV[LinearVelocity]
        Root --> Att[Attachment]
        Root --> VF[VectorForce (Gravity Comp)]
        Root --> AO[AlignOrientation]
    end

    State --> |4. destroy| Cleanup[100% Physics Constraint Destruction]
    State --> |5. release| SteeringRestore[Humanoid.AutoRotate = true]
```

---

## 📂 CLASS SPECIFICATION & API METHOD MAP

| Method / Property | Return Type | Description |
| --- | --- | --- |
| **`MovementMotor.new(config)`** | `MovementMotorInstance` | Instantiates a new motor wrapper with target attachment & constraint names |
| **`motor:ensure(rootPart)`** | `void` | Guarantees `Attachment` and `LinearVelocity` exist inside `HumanoidRootPart` |
| **`motor:capture(humanoid)`** | `void` | Saves original `AutoRotate` state and locks `humanoid.AutoRotate = false` |
| **`motor:release(humanoid)`** | `void` | Restores original `humanoid.AutoRotate` setting on state exit |
| **`motor:zeroAngularVelocity(rootPart)`** | `void` | Resets `AssemblyAngularVelocity = Vector3.zero` to prevent character spinning |
| **`motor:destroy()`** | `void` | Destroys `LinearVelocity`, `Attachment`, `VectorForce`, `AlignOrientation` |

---

## ⚙️ CONFIGURATION TABLE

```luau
export type Config = {
	attachmentName: string,
	linearVelocityName: string,
	gravityForceName: string?,
	orientationName: string?,
	orientationResponsiveness: number?,
	orientationMaxAngularVelocity: number?,
	orientationMaxTorque: number?,
}
```

---

## 💻 CODE USAGE EXAMPLE

```luau
local MovementMotor = require(script.Parent.MovementMotor)

-- Initialize motor instance for a skill state
local motor = MovementMotor.new({
    attachmentName = "DashAttachment",
    linearVelocityName = "DashLinearVelocity",
})

-- On State Enter:
motor:capture(humanoid)
motor:ensure(rootPart)
motor.linearVelocity.VectorVelocity = forwardVector * dashSpeed

-- On State Exit:
motor:release(humanoid)
motor:destroy()
```
