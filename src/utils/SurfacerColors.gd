class_name SurfacerColors
extends Reference

const PANEL_BACKGROUND := Color8(16, 18, 15)
const HEADER_BACKGROUND := Color8(43, 43, 43)

# Lightness values (from 0 to 100).
const LIGHTNESS_NORMAL := 64
const LIGHTNESS_LIGHT := 80
const LIGHTNESS_DARK := 40
const LIGHTNESS_XDARK := 20

const TRANSPARENT := Color8(0, 0, 0, 0)
const WHITE := Color8(255, 255, 255)
const BLACK := Color8(0, 0, 0)
const GREY := Color8(163, 163, 163)

# Hue: 182 (from 0 to 360)
const TEAL := Color8(71, 249, 255)
#const TEAL_L := Color8(, , )
const TEAL_D := Color8(0, 197, 204)
#const TEAL_XD := Color8(, , )

# Hue: 278 (from 0 to 360)
const PURPLE := Color8(188, 71, 255)
#const PURPLE_L := Color8(, , )
const PURPLE_D := Color8(129, 0, 204)
#const PURPLE_XD := Color8(, , )

# Hue: 64 (from 0 to 360)
const YELLOW := Color8(243, 255, 71)
#const YELLOW_L := Color8(, , )
const YELLOW_D := Color8(190, 204, 0)
#const YELLOW_XD := Color8(, , )

# Hue: 31 (from 0 to 360)
const ORANGE := Color8(255, 166, 71)
#const ORANGE_L := Color8(, , )
const ORANGE_D := Color8(204, 105, 0)
#const ORANGE_XD := Color8(, , )

# Hue: 2 (from 0 to 360)
const RED := Color8(255, 78, 71)
#const RED_L := Color8(, , )
const RED_D := Color8(204, 7, 0)
#const RED_XD := Color8(, , )

# Alpha values (from 0 to 1).
const ALPHA_SOLID := 1.0
const ALPHA_SLIGHTLY_FAINT := 0.7
const ALPHA_FAINT := 0.5
const ALPHA_XFAINT := 0.3
const ALPHA_XXFAINT := 0.1
const ALPHA_XXXFAINT := 0.03

static func opacify(base_color: Color, opacity: float) -> Color:
    base_color.a = opacity
    return base_color
