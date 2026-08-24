## A deterministic pseudo-random number generator based on Xoshiro256++.[br]
##
## Each instance keeps an independent 256-bit internal state and produces a
## reproducible sequence for the same initial state. Create an instance with
## [method from_seed] or [method from_seed_int], then call [method next_u64]
## to advance the generator and obtain the next 64-bit value.[br]
##
## Use [method jump] or [method long_jump] to move to a distant point in the
## sequence and create a separate non-overlapping stream.[br]
##
## Example:
##[codeblock]
## var rng := Xoshiro256PP.from_seed_int(12345)
## var value := rng.next_u64()
## rng.jump()
## var value_from_next_stream := rng.next_u64()
##[/codeblock]
##
## [b]This generator is not cryptographically secure.[/b] Do not use it for
## passwords, tokens, encryption keys, or other security-sensitive values.
class_name Xoshiro256PP
extends RefCounted

const U64Math := preload("res://addons/GodotXoshiro256PP/u64_math.gd")

const JUMP: Array[int] = [
	1733541517147835066, # 0x180ec6d33cfd0aba
	-3051731464161248980, # 0xd5a61266f0c9392c
	-6244198995065845334, # 0xa9582618e03fc9aa
	4155657270789760540, # 0x39abdc4529b1661c
]

const LONG_JUMP: Array[int] = [
	8566230491382795199, # 0x76e15d3efefdcbbf
	-4251311993797857357, # 0xc5004e441c522fb3
	8606660816089834049, # 0x77710069854ee241
	4111957640723818037, # 0x39109bb02acbe635
]


var s0: int
var s1: int
var s2: int
var s3: int
	

## Creates a generator initialized from a byte array containing a 32-byte seed.[br]
## Example:
##[codeblock]
## var rng := Xoshiro256PP.from_seed(PackedByteArray([
##     1, 0, 0, 0, 0, 0, 0, 0,
##     2, 0, 0, 0, 0, 0, 0, 0,
##     3, 0, 0, 0, 0, 0, 0, 0,
##     4, 0, 0, 0, 0, 0, 0, 0,
## ]))
##[/codeblock]
##
## [param u8_array] must contain exactly 32 bytes and must not be all zero.
## An invalid seed is replaced with the state produced from integer seed 0.
static func from_seed(u8_array: PackedByteArray) -> Xoshiro256PP:
	var rng := Xoshiro256PP.new()
	rng.set_seed(u8_array)
	return rng


## Creates a generator initialized deterministically from an integer seed.[br]
## Example:
##[codeblock]
## var rng := Xoshiro256PP.from_seed_int(12345)
##[/codeblock]
##
## The integer is expanded into the four-word state using the SplitMix64
## generator.
static func from_seed_int(seed: int) -> Xoshiro256PP:
	var rng := Xoshiro256PP.new()
	rng.seed_from_int(seed)
	return rng


## Performs a 64-bit logical right shift on a signed GDScript integer.[br]
## Example:
##[codeblock]
## var value := Xoshiro256PP.logical_shr(-1, 1)
##[/codeblock]
## [param shift] must be between 0 and 63.
static func logical_shr(x: int, shift: int) -> int:
	if shift == 0:
		return x
		
	return (x >> shift) & ((1 << (64 - shift)) - 1)


## Rotates a 64-bit value left by [param k] bits.[br]
## Example:
##[codeblock]
## var rotated := Xoshiro256PP.rotl(value, 23)
##[/codeblock]
## [param k] must be between 1 and 63.
static func rotl(x: int, k: int) -> int:
	return (x << k) | logical_shr(x, 64 - k)


## Advances the generator and returns the next pseudo-random 64-bit value.[br]
## Example:
##[codeblock]
## var value := rng.next_u64()
##[/codeblock]
##
## The value is represented by a signed GDScript integer.
func next_u64() -> int:
	var result := rotl(s0 + s3, 23) + s0

	var t := s1 << 17

	s2 ^= s0
	s3 ^= s1
	s1 ^= s2
	s0 ^= s3

	s2 ^= t
	s3 = rotl(s3, 45)

	return result

## Replaces the generator state with a deterministic integer-seeded state using
## the SplitMix64 generator.[br]
## Example:
##[codeblock]
## rng.seed_from_int(9876)
##[/codeblock]
func seed_from_int(seed: int) -> void:
	var sm := SplitMix64.new(seed)

	s0 = sm.next_u64()
	s1 = sm.next_u64()
	s2 = sm.next_u64()
	s3 = sm.next_u64()

## Replaces the generator state from exactly 32 bytes.[br]
## Example:
##[codeblock]
## rng.set_seed(PackedByteArray([
##     1, 0, 0, 0, 0, 0, 0, 0,
##     2, 0, 0, 0, 0, 0, 0, 0,
##     3, 0, 0, 0, 0, 0, 0, 0,
##     4, 0, 0, 0, 0, 0, 0, 0,
## ]))
##[/codeblock]
##
## Invalid or all-zero seeds cause an error and replace the state with the
## state produced from integer seed 0.
func set_seed(u8_array: PackedByteArray) -> void:
	if u8_array.size() != 32:
		push_error(
			"Xoshiro256PP: u8_array must be exactly 32 bytes long, but got %d bytes"
			% u8_array.size()
		)
		seed_from_int(0)
		return
		
	var state: PackedInt64Array = u8_array.to_int64_array()
	
	s0 = state[0]
	s1 = state[1]
	s2 = state[2]
	s3 = state[3]

	if s0 == 0 and s1 == 0 and s2 == 0 and s3 == 0:
		push_error(
			"Xoshiro256PP: u8_array must not be all zeros, using different state instead"
		)
		seed_from_int(0)

## Returns the current generator state encoded as 32 bytes in the same format
## accepted by [method set_seed].[br]
## Example:
##[codeblock]
## var saved_state := rng.get_seed()
##[/codeblock]
func get_seed() -> PackedByteArray:
	var state := PackedInt64Array([s0, s1, s2, s3])
	
	return state.to_byte_array()


## Advances the state by 2^128 steps.[br]
## Example:
##[codeblock]
## rng.jump()
##[/codeblock]
##
## This is useful for creating a non-overlapping subsequence of the stream.
func jump() -> void:
	_jump_poly(JUMP)


## Advances the state by 2^192 steps.[br]
## Example:
##[codeblock]
## rng.long_jump()
##[/codeblock]
##
## This can be used to separate very distant generator streams.
func long_jump() -> void:
	_jump_poly(LONG_JUMP)
	
	
## Applies a jump polynomial to the current four-word state.
##
## This internal implementation is shared by [method jump] and
## [method long_jump].
func _jump_poly(poly: Array[int]) -> void:
	var t0: int = 0
	var t1: int = 0
	var t2: int = 0
	var t3: int = 0

	for j in poly:
		for b in 64:
			if ((j >> b) & 1) != 0:
				t0 ^= s0
				t1 ^= s1
				t2 ^= s2
				t3 ^= s3

			next_u64()

	s0 = t0
	s1 = t1
	s2 = t2
	s3 = t3
