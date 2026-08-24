# GodotXoshiro256PP

[![Godot 4.0+](assets/Godot-4.svg)](https://godotengine.org/)

An efficient and fully reproducible pseudo-random number generator for Godot 4.0+.
The plugin implements **Xoshiro256++** and uses **SplitMix64** to initialize its
state. It is written entirely in GDScript and requires no native libraries or
external dependencies.

The primary API is the `Xoshiro256PP` class. It provides direct control over the
generator state, output sequence, and independent streams. The
`Xoshiro256PPRandom` class, described below, is an optional helper for common
gameplay ranges.

## Features

- 256-bit state;
- deterministic output for the same seed;
- seeding from a single 64-bit integer or 32 bytes of state;
- saving, restoring, and copying generator state;
- `jump()` and `long_jump()` for splitting the sequence into independent
  streams;
- full compatibility with Godot's 64-bit `int` values;
- pure GDScript and cross-platform support.

## Xoshiro256PP

### Creating a generator

For most use cases, an integer seed is sufficient. The same seed always
produces the same sequence:

```gdscript
var rng := Xoshiro256PP.from_seed_int(12345)

var first_value: int = rng.next_u64()
var second_value: int = rng.next_u64()
```

`from_seed_int()` expands one 64-bit integer into four 64-bit state words using
SplitMix64. The default seed is `0`.

If the state is already known, it can be provided as a `PackedByteArray`
containing exactly 32 bytes:

```gdscript
var rng := Xoshiro256PP.from_seed(PackedByteArray([
		1, 0, 0, 0, 0, 0, 0, 0,
		2, 0, 0, 0, 0, 0, 0, 0,
		3, 0, 0, 0, 0, 0, 0, 0,
		4, 0, 0, 0, 0, 0, 0, 0,
]))
```

The array contains four consecutive 64-bit words, `s0`, `s1`, `s2`, and `s3`,
in the same format returned by `get_seed()`. The state must not be all zero. If
the seed has an invalid length or is all zero, the generator reports an error
and uses the state produced from seed `0`.

### Generating values

The low-level `next_u64()` method advances the state and returns the next
64-bit value:

```gdscript
var value: int = rng.next_u64()
```

The value is represented as a signed GDScript `int`. To display or compare it
as an unsigned 64-bit number, use `String.num_uint64(value)`.

### Saving and restoring state

The state can be saved to a game save, serialized, or passed to another
generator. A saved state represents the current position in the stream:

```gdscript
var saved_state: PackedByteArray = rng.get_seed()

var restored := Xoshiro256PP.from_seed(saved_state)
assert(restored.next_u64() == rng.next_u64())

# The same state can be restored in an existing instance.
rng.set_seed(saved_state)
```

### Independent streams

`jump()` advances the generator by $2^{128}$ steps, while `long_jump()` advances
it by $2^{192}$ steps. This is useful when multiple systems need separate,
reproducible sequences:

```gdscript
var world_rng := Xoshiro256PP.from_seed_int(42)
var loot_rng := Xoshiro256PP.from_seed_int(42)

loot_rng.jump()
# world_rng and loot_rng use distant sections of the same stream.
```

Calling either jump method changes the state and does not return a value.

### Limitations

`Xoshiro256PP` is a high-quality generator for simulations and games, but it is
**not cryptographically secure**. Do not use it for passwords, tokens,
encryption keys, or other security-sensitive values.

## Xoshiro256PPRandom

`Xoshiro256PPRandom` wraps an `Xoshiro256PP` instance and provides familiar
methods for gameplay logic:

```gdscript
var random := Xoshiro256PPRandom.new(123456789)

var random_int: int = random.randi()
var random_float: float = random.randf() # [0.0, 1.0)
var random_range: float = random.randf_range(-10.0, 10.0)
var random_integer_range: int = random.randi_range(1, 10)
```

Integer and `PackedByteArray` seeds are supported, as well as an existing
`Xoshiro256PP` instance. `randi_range()` includes both bounds and supports the
full signed 64-bit integer range. Both range methods automatically swap the
bounds when they are provided in reverse order.

The helper state can be saved and restored with the same methods:

```gdscript
var saved_state := random.get_seed()
random.set_seed(saved_state)
```

## Installation

1. Copy the `addons/GodotXoshiro256PP` folder into your project's `res://addons/` directory.
2. Use the `Xoshiro256PP` and `Xoshiro256PPRandom` classes in GDScript.

The plugin does not use the editor API, so it does not need to be enabled in
the Plugins settings.
