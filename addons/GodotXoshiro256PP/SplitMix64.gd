## Creates a SplitMix64 generator with the given initial state.[br]
## Example:
##[codeblock]
## var splitter := SplitMix64.new(12345)
##[/codeblock]
##
## [param seed] is used as the initial internal state value.
class_name SplitMix64
extends RefCounted

const GAMMA: int = -7046029254386353131
const MIX1: int = -4658895280553007687
const MIX2: int = -7723592293110705685

var state: int = 0


func _init(seed: int = 0) -> void:
	state = seed


## Performs a 64-bit logical right shift, filling the high bits with zero.[br]
## Example:
##[codeblock]
## var high_bits := SplitMix64.logical_shr(value, 11)
##[/codeblock]
##
## [param shift] must be between 1 and 63. This is needed because GDScript
## integers are signed.
static func logical_shr(x: int, shift: int) -> int:
	return (x >> shift) & ((1 << (64 - shift)) - 1)


## Advances the state and returns the next pseudo-random 64-bit value.[br]
## Example:
##[codeblock]
## var value := splitter.next_u64()
##[/codeblock]
##
## The returned 64-bit word is represented by a signed GDScript integer.
func next_u64() -> int:
	state += GAMMA

	var z: int = state

	z = (z ^ logical_shr(z, 30)) * MIX1
	z = (z ^ logical_shr(z, 27)) * MIX2
	z ^= logical_shr(z, 31)

	return z


## Returns the next pseudo-random float in the half-open interval [0, 1).[br]
## Example:
##[codeblock]
## var unit_value := splitter.next_float()
##[/codeblock]
##
## The value is built from the 53 most significant random bits of the next
## 64-bit output.
func next_float() -> float:
	var z := next_u64()

	# Top 53 bits → [0, 2^53)
	var value := logical_shr(z, 11)

	return float(value) / 9007199254740992.0
