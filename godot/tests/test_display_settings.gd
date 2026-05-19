extends GutTest

func test_viewport_is_portrait_720x1280():
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_width", 0), 720,
		"viewport_width deve ser 720")
	assert_eq(ProjectSettings.get_setting("display/window/size/viewport_height", 0), 1280,
		"viewport_height deve ser 1280")

func test_stretch_aspect_expand():
	assert_eq(ProjectSettings.get_setting("display/window/stretch/aspect", ""), "expand",
		"stretch/aspect deve ser 'expand'")
