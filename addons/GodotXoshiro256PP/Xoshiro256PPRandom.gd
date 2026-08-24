## A helper for generating uniformly distributed random integers and floats
## using an [class Xoshiro256PP] generator.[br]
##
## The helper advances its generator each time it produces a random value. It
## can be initialized with an integer seed, a 32-byte [PackedByteArray] seed,
## or an existing [class Xoshiro256PP] instance. If no seed is provided, the
## generator is initialized with integer seed 0.[br]
##
## Example:
##[codeblock]
## var random := Xoshiro256PPRandom.new(12345)
## var roll := random.randi_range(1, 6)
## var chance := random.randf_range(0.0, 1.0)
##[/codeblock]
##
## Use [method get_seed] and [method set_seed] to save and restore the
## generator state.
class_name Xoshiro256PPRandom
extends RefCounted

const U64Math := preload("res://addons/GodotXoshiro256PP/u64_math.gd")


var _rng: Xoshiro256PP


func _init(seed: Variant = 0) -> void:
	if seed is PackedByteArray:
		self._rng = Xoshiro256PP.from_seed(seed)
	elif seed is int:
		self._rng = Xoshiro256PP.from_seed_int(seed)
	elif seed is Xoshiro256PP:
		self._rng = seed
	else:
		self._rng = Xoshiro256PP.from_seed_int(0)


## Returns the current generator state encoded as a 32-byte
## [PackedByteArray].[br]
##
## The returned state can be saved and later passed to [method set_seed], or
## used to create a new [class Xoshiro256PPRandom] instance with the same state.[br]
## Example:
##[codeblock]
## var saved_state := random.get_seed()
## var restored_random := Xoshiro256PPRandom.new(saved_state)
##[/codeblock]
func get_seed() -> PackedByteArray:
	return _rng.get_seed()


## Replaces the current generator state with the state encoded in
## [param u8_array].[br]
##
## [param u8_array] must contain exactly 32 bytes and must not represent an
## all-zero state. Invalid seeds cause an error and are replaced with the
## state produced from integer seed 0.[br]
## Example:
##[codeblock]
## var saved_state := random.get_seed()
## random.set_seed(saved_state)
##[/codeblock]
func set_seed(u8_array: PackedByteArray) -> void:
	_rng.set_seed(u8_array)


func randi() -> int:
	return _rng.next_u64()


## Returns a uniformly distributed integer in the inclusive range
## [param min_value]..[param max_value].[br]
## Example:
##[codeblock]
## var roll := random.randi_range(1, 6)
##[/codeblock]
##
## Both bounds are included in the result: the returned value can be equal to
## [param min_value] or [param max_value].
##
## Both parameters must fit in a signed 64-bit integer. If [param min_value]
## is greater than [param max_value], the bounds are swapped automatically.
## The complete signed 64-bit range, from [code]-2^63[/code] to
## [code]2^63 - 1[/code], is supported.
func randi_range(min_value: int, max_value: int) -> int:
	if min_value > max_value:
		var min_temp = min_value
		min_value = max_value
		max_value = min_temp


	if min_value == max_value:
		return min_value

	if min_value == U64Math.INT64_MIN && max_value == U64Math.INT64_MAX:
		return _rng.next_u64()

	var diff := max_value - min_value

	# A negative diff indicates signed 64-bit overflow, not invalid bounds.
	# The inclusive range contains more than 2^63 values, so its unsigned
	# size wraps to a negative signed value and requires a separate rejection
	# sampling path.
	if diff < 0:
		while true:
			var x: int = _rng.next_u64()
			# Calculate the unsigned offset of x relative to min_value.
			var offset: int = x - min_value
			
			# If offset >= 0, the unsigned offset is less than 2^63.
			# Since our range is larger than 2^63, this value is guaranteed to be in range.
			if offset >= 0:
				return x
			
			# If offset < 0, it is in the upper range [2^63, 2^64 - 1].
			# Check whether it falls within the excluded rejection region.
			if offset < diff + 1:
				return x

	# For ranges up to 2^63 values, diff does not overflow and diff + 1
	# is the exact number of values in the inclusive range. The threshold
	# removes the incomplete part of the 2^64 sample space before mapping
	# accepted samples to the requested range.
	var range: int = diff + 1
	var threshold: int = _threshold_u64(range)

	while true:
		var x: int = _rng.next_u64()

		var p: Array[int] = U64Math.mul_u64(x, range)

		var low: int = p[1]
		var high: int = p[0]

		if low < 0 or low >= threshold:
			return min_value + high

	return min_value
	
	
## Returns a uniformly distributed float in the half-open interval [0, 1).[br]
## Example:
##[codeblock]
## var chance := random.randf()
##[/codeblock]
func randf() -> float:
	var x: int = _rng.next_u64()

	# Use the 53 most significant random bits.
	var bits: int = Xoshiro256PP.logical_shr(x, 11)

	return float(bits) * (1.0 / 9007199254740992.0)

## Returns a uniformly distributed float starting at [param min_value] and
## normally less than [param max_value]. [param min_value] is included in the
## result. If both bounds are equal, that value is returned.[br]
## Example:
##[codeblock]
## var speed := random.randf_range(2.5, 7.5)
##[/codeblock]
##
## If [param min_value] is greater than [param max_value], the bounds are
## swapped automatically.[br]
##
## NaN and infinity are rejected with an error and return 0.0. Due to floating
## point rounding, the result can equal [param max_value] for some very large
## or very close values.
func randf_range(min_value: float, max_value: float) -> float:
	if is_nan(min_value) or is_nan(max_value):
		push_error("randf_range: NaN is not allowed")
		return 0.0

	if is_inf(min_value) or is_inf(max_value):
		push_error("randf_range: infinity is not allowed")
		return 0.0

	if min_value > max_value:
		var min_temp = min_value
		min_value = max_value
		max_value = min_temp

	if min_value == max_value:
		return min_value

	var weight := self.randf()
	var result := min_value * (1.0 - weight) + max_value * weight

	return clampf(result, min_value, max_value)


## Computes the rejection threshold for unbiased bounded multiplication.[br]
## Example:
##[codeblock]
## var threshold := Xoshiro256PPRandom._threshold_u64(6)
##[/codeblock]
##
## This internal helper returns the rejection threshold, 2^64 modulo
## [param range], without using an overflowing 64-bit multiplication.
static func _threshold_u64(range: int) -> int:
	# If the range is exactly 2^63 (represented by the INT64_MIN bit pattern),
	# then 2^64 mod 2^63 is 0.
	if range == U64Math.INT64_MIN:
		return 0
		
	assert(range > 0)

	# Calculate (2^63 mod range).
	# Since INT64_MAX is (2^63 - 1), adding 1 safely offsets the remainder 
	# to represent the 2^63 bit pattern without signed integer overflow.
	var remainder: int = (U64Math.INT64_MAX % range) + 1

	# Handle the case where the remainder reaches the divisor boundary.
	if remainder == range:
		remainder = 0

	# Scale the remainder up to calculate (2^64 mod range).
	# Perform (remainder * 2) % range using subtraction to prevent signed int64 overflow.
	if remainder >= range - remainder:
		return remainder - (range - remainder)

	return remainder + remainder
