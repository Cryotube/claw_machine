extends Resource
class_name ComboCurveProfile

@export var bake_resolution: int = 16
@export var points: Array[Dictionary] = [
    {"x": 0.0, "y": 1.0, "left": 0.0, "right": 0.0},
    {"x": 2.0, "y": 1.4, "left": 0.0, "right": 0.0},
    {"x": 4.0, "y": 1.8, "left": 0.0, "right": 0.0},
    {"x": 6.0, "y": 2.2, "left": 0.0, "right": 0.0},
]

func to_curve() -> Curve:
    var curve := Curve.new()
    curve.bake_resolution = maxi(bake_resolution, 4)
    for entry in points:
        var position := float(entry.get("x", 0.0))
        var value := float(entry.get("y", 0.0))
        curve.add_point(Vector2(position, value))
    return curve
