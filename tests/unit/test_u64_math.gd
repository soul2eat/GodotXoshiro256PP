extends GutTest

const U64Math := preload("res://addons/GodotXoshiro256PP/u64_math.gd")


func test_mul_u64():
	# Test vectors generated using Rust's 
	# Used as reference values to validate the Godot implementation.
	var expected := [
		[0, 0, "0", "0"],
		[1, 1, "0", "1"],
		[1, 2, "0", "2"],
		[4294967296, 4294967296, "1", "0"],
		[4294967295, 4294967295, "0", "18446744065119617025"],
		[9223372036854775807, 2, "0", "18446744073709551614"],
		[9223372036854775807, 3, "1", "9223372036854775805"],
		[9223372036854775807, 9223372036854775807, "4611686018427387903", "1"],
		[-1, 1, "0", "18446744073709551615"],
		[-1, 2, "1", "18446744073709551614"],
		[-1, -1, "18446744073709551614", "1"],
		[U64Math.INT64_MIN, 2, "1", "0"],
		[U64Math.INT64_MIN, 3, "1", "9223372036854775808"],
		[305419896, 4294967297, "0", "1311768465173141112"],
	]

	for i in expected.size():
		var test: Array = expected[i]
		var result: Array[int] = U64Math.mul_u64(test[0], test[1])

		var actual_high: String = String.num_uint64(result[0])
		var actual_low: String = String.num_uint64(result[1])

		var expected_high: String = test[2]
		var expected_low: String = test[3]

		assert_eq([actual_high, actual_low], [expected_high, expected_low])
