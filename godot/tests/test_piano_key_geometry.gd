extends GutTest

const PianoInputScript := preload("res://scripts/PianoInput.gd")

func test_white_keys_are_not_black():
	for i in [0, 2, 4, 5, 7, 9, 11]:
		assert_false(PianoInputScript.is_black_key(i), "index %d deveria ser tecla branca" % i)

func test_black_keys_identified():
	for i in [1, 3, 6, 8, 10]:
		assert_true(PianoInputScript.is_black_key(i), "index %d deveria ser tecla preta" % i)

func test_white_key_x_positions():
	var expected = {0: 0.0, 2: 54.0, 4: 108.0, 5: 162.0, 7: 216.0, 9: 270.0, 11: 324.0}
	for chromatic_index in expected:
		assert_eq(PianoInputScript.key_x_position(chromatic_index), expected[chromatic_index])

func test_black_key_x_positions():
	var expected = {1: 37.0, 3: 91.0, 6: 199.0, 8: 253.0, 10: 307.0}
	for chromatic_index in expected:
		assert_eq(PianoInputScript.key_x_position(chromatic_index), expected[chromatic_index])
