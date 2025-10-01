# Physics Configuration
## Physics Settings
- `physics/common/physics_ticks_per_second = 60` to align with FPS target.
- Global gravity `Vector3(0, -9.81, 0)`; an interior `Area3D` applies a −20% gravity modifier for freezer viscosity.
- Continuous collision detection enabled on claw gripper, seafood soft bodies, and anchor points.
- Soft-body iteration count set to 15 to prevent jitter while remaining mobile-friendly.
- Solver iterations set to 16 for stable articulated joints interacting with soft bodies.

## Rigidbody & Soft-Body Patterns
- **Claw Rig:** Articulated via `Generic6DOFJoint3D` with preconfigured limits controlled by the typed GDScript solver; no runtime joint mutation.
- **Grabbable Seafood:** Implemented as `SoftBody3D` meshes (rounded cube, sphere, rounded pyramid, rounded cylinder variations) with pinned vertices allowing gentle deformation when gripped. Collision proxies use `ConcavePolygonShape3D` for accurate contact tests. Solver transitions items to kinematic attachment when grabbed, preserving deformation until release.
- **Fallback Mode:** Settings toggle can swap in pooled rigid bodies for low-end devices, handled by `CabinetItemPool`.
- **Cabinet Debris:** Pooled `RigidBody3D` nodes forced to sleep off-camera to conserve CPU.
