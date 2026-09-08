extends GutTest

const PianoInputScript := preload("res://scripts/PianoInput.gd")

func test_white_keys_are_not_black():
	for i in [0, 2, 4, 5, 7, 9, 11]:
		assert_false(PianoInputScript.is_black_key(i), "index %d deveria ser tecla branca" % i)

func test_black_keys_identified():
	for i in [1, 3, 6, 8, 10]:
		assert_true(PianoInputScript.is_black_key(i), "index %d deveria ser tecla preta" % i)

func test_white_key_x_positions():
	# 7 brancas de 96px = 672px, cabe nos 720px de largura do retrato com folga
	var expected = {0: 0.0, 2: 96.0, 4: 192.0, 5: 288.0, 7: 384.0, 9: 480.0, 11: 576.0}
	for chromatic_index in expected:
		assert_eq(PianoInputScript.key_x_position(chromatic_index), expected[chromatic_index])

func test_black_key_x_positions():
	# (branca_à_esquerda + 1) * 96 - 60/2
	var expected = {1: 66.0, 3: 162.0, 6: 354.0, 8: 450.0, 10: 546.0}
	for chromatic_index in expected:
		assert_eq(PianoInputScript.key_x_position(chromatic_index), expected[chromatic_index])
