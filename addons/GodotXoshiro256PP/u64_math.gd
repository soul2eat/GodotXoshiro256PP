extends RefCounted


const U32_MASK: int = 0xFFFFFFFF
const U16_MASK: int = 0xFFFF

const INT64_MIN = -9223372036854775807 - 1
const INT64_MAX: int = 9223372036854775807


## Multiplies two unsigned 64-bit values modulo 2^64 and returns the full
## product as [high, low] 64-bit words.[br]
## Example:
##[codeblock]
## var product := U64Math.mul_u64(0x100000000, 2)
## # product is [0, 0x200000000]
##[/codeblock]
##
## Inputs and outputs are interpreted modulo 2^64. Values are returned as
## signed GDScript integers when their top bit is set.
static func mul_u64(a: int, b: int) -> Array[int]:
	var a0 := a & U32_MASK
	var a1 := (a >> 32) & U32_MASK

	var b0 := b & U32_MASK
	var b1 := (b >> 32) & U32_MASK

	var p0 := _mul_u32(a0, b0)
	var p1 := _mul_u32(a1, b0)
	var p2 := _mul_u32(a0, b1)
	var p3 := _mul_u32(a1, b1)

	var middle := p0[1] + p1[0] + p2[0]

	var lo32 := p0[0]
	var lo_hi32 := middle & U32_MASK
	var carry := middle >> 32

	var hi_middle := p1[1] + p2[1] + p3[0] + carry

	var hi32 := hi_middle & U32_MASK
	var hi_hi32 := (p3[1] + (hi_middle >> 32)) & U32_MASK

	var lo := (lo_hi32 << 32) | lo32
	var hi := (hi_hi32 << 32) | hi32

	return [hi, lo]


## Multiplies two unsigned 32-bit values and returns the 64-bit product as
## [low, high] 32-bit words.
##
## This helper splits each operand into 16-bit parts to avoid intermediate
## overflow while constructing a full 64-bit product.
static func _mul_u32(a: int, b: int) -> Array[int]:
	var a0 := a & U16_MASK
	var a1 := (a >> 16) & U16_MASK

	var b0 := b & U16_MASK
	var b1 := (b >> 16) & U16_MASK

	var p0 := a0 * b0
	var p1 := a0 * b1
	var p2 := a1 * b0
	var p3 := a1 * b1

	var lo := p0
	lo += (p1 & U16_MASK) << 16
	lo += (p2 & U16_MASK) << 16

	var carry := lo >> 32

	var hi := p3
	hi += p1 >> 16
	hi += p2 >> 16
	hi += carry

	return [
		lo & U32_MASK,
		hi & U32_MASK
	]
