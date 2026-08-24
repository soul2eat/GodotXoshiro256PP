extends GutTest


func test_randf_returns_values_in_half_open_interval() -> void:
	var random := Xoshiro256PPRandom.new(12345)

	for i in 10000:
		var value := random.randf()

		assert_true(value >= 0.0)
		assert_true(value < 1.0)
		assert_false(is_nan(value))
		assert_false(is_inf(value))


func test_randf_range_stays_inside_bounds() -> void:
	var random := Xoshiro256PPRandom.new(12345)

	for i in 10000:
		var value := random.randf_range(-10.0, 10.0)

		assert_true(value >= -10.0)
		assert_true(value <= 10.0)
		assert_false(is_nan(value))
		assert_false(is_inf(value))


func test_randf_range_swaps_reversed_bounds() -> void:
	var forward := Xoshiro256PPRandom.new(12345)
	var reversed := Xoshiro256PPRandom.new(12345)

	for i in 1000:
		var expected := forward.randf_range(-5.0, 8.0)
		var actual := reversed.randf_range(8.0, -5.0)

		assert_eq(actual, expected)


func test_randf_range_returns_equal_bounds() -> void:
	var random := Xoshiro256PPRandom.new(12345)

	assert_eq(random.randf_range(42.5, 42.5), 42.5)
	assert_eq(random.randf_range(-42.5, -42.5), -42.5)


func test_randf_range_handles_large_finite_bounds() -> void:
	var random := Xoshiro256PPRandom.new(12345)

	for i in 10000:
		var value := random.randf_range(-1.0e308, 1.0e308)

		assert_false(is_nan(value))
		assert_false(is_inf(value))
		assert_true(value >= -1.0e308)
		assert_true(value <= 1.0e308)


func test_randf_range_is_reproducible() -> void:
	var first := Xoshiro256PPRandom.new(12345)
	var second := Xoshiro256PPRandom.new(12345)

	for i in 10:
		var state_before := first.get_seed()

		assert_eq(state_before, second.get_seed(), "Before")

		var first_value := first.randf_range(-100.0, 100.0)

		var state_after_first := first.get_seed()
		var second_value := second.randf_range(-100.0, 100.0)
		var state_after_second := second.get_seed()

		assert_eq(state_after_first, state_after_second, "After")
		assert_eq(first_value, second_value, "Values")


func test_randf_range_rejects_nan() -> void:
	var random := Xoshiro256PPRandom.new(12345)

	assert_eq(random.randf_range(NAN, 1.0), 0.0)

	if self.has_method("assert_push_error"):
		self.call("assert_push_error", "randf_range: NaN is not allowed")


func test_randf_range_rejects_infinity() -> void:
	var random := Xoshiro256PPRandom.new(12345)

	assert_eq(random.randf_range(0.0, INF), 0.0)

	if self.has_method("assert_push_error"):
		self.call("assert_push_error", "randf_range: infinity is not allowed")
