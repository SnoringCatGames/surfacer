extends Node2D
class_name CameraShake

var decay := 0.8
var max_offset := Vector2(100.0, 50.0)
var max_roll := 0.1

var strength := 0.0
var strength_exponent := 2.0
var noise: OpenSimplexNoise
var noise_y := 0.0

func _ready() -> void:
    randomize()
    noise = OpenSimplexNoise.new()
    noise.seed = randi()
    noise.period = 4.0
    noise.octaves = 2.0

func _process(delta_sec: float) -> void:
    if strength > 0.0:
        # This should end up calling _update_shake exactly once with a strength
        # of zero, which is important for resetting the camera.
        strength = max(strength - decay * delta_sec, 0)
        _update_shake()

func _update_shake() -> void:
    var amount := pow(strength, strength_exponent)
    noise_y += 1.0
    rotation = max_roll * amount * noise.get_noise_2d(noise.seed, noise_y)
    position.x = \
            max_offset.x * amount * \
            noise.get_noise_2d(noise.seed * 2.0, noise_y)
    position.y = \
            max_offset.y * amount * \
            noise.get_noise_2d(noise.seed * 3.0, noise_y)

func shake(strength: float) -> void:
    self.strength = min(self.strength + strength, 1.0)
