class_name LootItemArt
extends RefCounted

const ATLAS: Texture2D = preload("res://assets/ui/item_atlas.png")

const GEAR_REGIONS: Dictionary = {
	"Scrap Gun": Rect2(0, 0, 16, 16),
	"Cutdown Gun": Rect2(16, 0, 16, 16),
	"Heavy-Frame Gun": Rect2(32, 0, 16, 16),
	"Rapid-Frame Gun": Rect2(48, 0, 16, 16),
	"Scrap Blade": Rect2(64, 0, 16, 16),
	"Long Blade": Rect2(80, 0, 16, 16),
	"Heavy Blade": Rect2(96, 0, 16, 16),
	"Quick Blade": Rect2(112, 0, 16, 16),
	"Padded Rags": Rect2(0, 16, 16, 16),
	"Runner Jacket": Rect2(16, 16, 16, 16),
	"Reinforced Vest": Rect2(32, 16, 16, 16),
	"Scavenger Coat": Rect2(48, 16, 16, 16),
	"Bent Lucky Coin": Rect2(64, 16, 16, 16),
	"Finder's Eye": Rect2(80, 16, 16, 16),
	"Rat Fang": Rect2(96, 16, 16, 16),
	"Runner Token": Rect2(112, 16, 16, 16)
}

const CURRENCY_REGIONS: Dictionary = {
	"mutation": Rect2(0, 32, 16, 16),
	"splice": Rect2(16, 32, 16, 16),
	"scrap": Rect2(32, 32, 16, 16),
	"crown": Rect2(48, 32, 16, 16),
	"hoarder": Rect2(64, 32, 16, 16),
	"chaos": Rect2(80, 32, 16, 16),
	"polish": Rect2(96, 32, 16, 16),
	"mechanist": Rect2(112, 32, 16, 16)
}

const CORE_REGIONS: Dictionary = {
	"repeater": Rect2(0, 48, 16, 16),
	"scatter": Rect2(16, 48, 16, 16),
	"piercer": Rect2(32, 48, 16, 16),
	"sprayer": Rect2(48, 48, 16, 16),
	"cleaver": Rect2(0, 32, 16, 16),
	"duelist": Rect2(64, 48, 16, 16),
	"whirlwind": Rect2(80, 48, 16, 16),
	"throwing": Rect2(96, 48, 16, 16)
}

const MISC_REGIONS: Dictionary = {
	"coin": Rect2(112, 48, 16, 16),
	"seal": Rect2(0, 64, 16, 16)
}

static func _texture(region: Rect2) -> Texture2D:
	var texture := AtlasTexture.new()
	texture.atlas = ATLAS
	texture.region = region
	return texture

static func texture_for_item(item: Dictionary) -> Texture2D:
	var base_name: String = String(item.get("base_name", ""))
	if GEAR_REGIONS.has(base_name):
		return _texture(GEAR_REGIONS[base_name] as Rect2)
	return null

static func texture_for_currency(key: String) -> Texture2D:
	if CURRENCY_REGIONS.has(key):
		return _texture(CURRENCY_REGIONS[key] as Rect2)
	return null

static func texture_for_core(core_id: String) -> Texture2D:
	if CORE_REGIONS.has(core_id):
		return _texture(CORE_REGIONS[core_id] as Rect2)
	return null

static func texture_for_misc(key: String) -> Texture2D:
	if MISC_REGIONS.has(key):
		return _texture(MISC_REGIONS[key] as Rect2)
	return null
