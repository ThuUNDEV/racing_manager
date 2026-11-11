class_name MoneyCodec
extends RefCounted

const BigNumber = preload("res://core/math/big_number.gd")
## JSON boundary: preserve legacy integer tokens before Godot JSON uses doubles.

const MONEY_KEYS := ["coins", "money", "completion_reward", "income_remainder", "saved_online_rate", "rate", "reward", "exposure", "reward_rate"]

static func legacy_number(value: Variant) -> BigNumber:
	if typeof(value) == TYPE_FLOAT:
		if not is_finite(value) or value < 0:
			return null
		return BigNumber.parse_decimal(String.num(value, 14))
	return BigNumber.coerce(value)

static func encode(value: Variant) -> Variant:
	if value is BigNumber:
		return value.to_save()
	if typeof(value) == TYPE_DICTIONARY:
		var out := {}
		for key in value:
			out[key] = encode(value[key])
		return out
	if typeof(value) == TYPE_ARRAY:
		var out := []
		for item in value:
			out.append(encode(item))
		return out
	return value

static func decode(value: Variant, legacy: bool = false, key: String = "") -> Variant:
	if typeof(value) == TYPE_DICTIONARY:
		if value.has("significand"):
			return BigNumber.from_save(value)
		var out := {}
		for k in value:
			out[k] = decode(value[k], legacy, String(k))
		return out
	if typeof(value) == TYPE_ARRAY:
		var out := []
		for item in value:
			out.append(decode(item, legacy))
		return out
	if legacy and key in MONEY_KEYS:
		return legacy_number(value)
	return value

static func parse(text_: String) -> Variant:
	var regex := RegEx.new()
	# Strings are matched first, so digits inside IDs/text are never modified.
	regex.compile('"(?:[^"\\\\]|\\\\.)*"|-?[0-9]+(?:\\.[0-9]+)?(?:[eE][+-]?[0-9]+)?')
	var tokens := regex.search_all(text_)
	var preserved := text_
	for i in range(tokens.size() - 1, -1, -1):
		var token: RegExMatch = tokens[i]
		var raw := token.get_string()
		if not raw.begins_with('"') and raw.is_valid_int() and raw.trim_prefix("-").length() > 15:
			preserved = preserved.left(token.get_start()) + '"' + raw + '"' + preserved.substr(token.get_end())
	var parser := JSON.new()
	return parser.data if parser.parse(preserved) == OK else null

static func valid_tree(value: Variant, key: String = "", legacy: bool = false) -> bool:
	if key in MONEY_KEYS:
		return legacy_number(value) != null if legacy else BigNumber.from_save(value) != null
	if typeof(value) == TYPE_DICTIONARY:
		for k in value:
			if not valid_tree(value[k], String(k), legacy):
				return false
	elif typeof(value) == TYPE_ARRAY:
		for item in value:
			if not valid_tree(item, "", legacy):
				return false
	return true
