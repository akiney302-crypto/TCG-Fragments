extends RefCounted
class_name CardVisualTheme

const TYPE_THEMES: Dictionary = {
	"TROOP": {
		"accent": Color("#43C7D9"),
		"frame": "res://art/ui/card_frames/troop.svg",
		"icon": "res://art/ui/card_types/troop.svg",
		"tier": "SIMPLE",
	},
	"CHAMPION": {
		"accent": Color("#E6B95A"),
		"frame": "res://art/ui/card_frames/champion.svg",
		"icon": "res://art/ui/card_types/champion.svg",
		"tier": "HERO",
	},
	"TRUTH": {
		"accent": Color("#8E63D7"),
		"frame": "res://art/ui/card_frames/truth.svg",
		"icon": "res://art/ui/card_types/truth.svg",
		"tier": "STANDARD",
	},
	"SECRETS": {
		"accent": Color("#4C78E7"),
		"frame": "res://art/ui/card_frames/secrets.svg",
		"icon": "res://art/ui/card_types/secrets.svg",
		"tier": "SIMPLE",
	},
}

static func get_theme(type_name: String) -> Dictionary:
	var key: String = type_name.to_upper()
	if TYPE_THEMES.has(key):
		return TYPE_THEMES[key]
	return TYPE_THEMES["TROOP"]
