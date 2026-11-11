class_name BigNumber
extends RefCounted
## Immutable, nonnegative decimal, 24 significant digits. No whole-money floats.
## Decimal digit arithmetic avoids native integer overflow even at exponent 1e6.

const PRECISION := 24
const MAX_EXPONENT := 1000000
const ALPHABET := "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
static var _parser: RegEx
var _coefficient: String = "0"
var exponent: int = 0


static func zero() -> BigNumber:
	return load("res://core/math/big_number.gd").new()


static func release_parser() -> void:
	_parser = null


static func from_int(value: int) -> BigNumber:
	return parse_decimal(str(value))


static func parse_decimal(value: String) -> BigNumber:
	if _parser == null:
		_parser = RegEx.new()
		_parser.compile("^([0-9]+)(?:\\.([0-9]+))?(?:[eE]([+-]?[0-9]+))?$")
	var match_ := _parser.search(value)
	if match_ == null:
		return null
	var exp_text := match_.get_string(3)
	if exp_text.trim_prefix("+").trim_prefix("-").length() > 7:
		return null
	var fraction := match_.get_string(2)
	var power := (int(exp_text) if exp_text != "" else 0) - fraction.length()
	return _from_raw(match_.get_string(1) + fraction, power)


static func from_save(value: Variant) -> BigNumber:
	if typeof(value) != TYPE_DICTIONARY:
		return null
	var d: Dictionary = value
	if typeof(d.get("significand")) != TYPE_STRING or not d.has("exponent"):
		return null
	var e: Variant = d["exponent"]
	if not (typeof(e) == TYPE_INT or typeof(e) == TYPE_FLOAT) or not is_finite(float(e)) or float(e) != floor(float(e)) or absf(float(e)) > MAX_EXPONENT:
		return null
	var digits := String(d["significand"])
	if digits == "0":
		return zero() if int(e) == 0 else null
	if digits.length() != PRECISION or digits[0] == "0" or not digits.is_valid_int() or digits.contains("-") or digits.contains("+"):
		return null
	for digit in digits:
		if digit < "0" or digit > "9":
			return null
	return _from_raw(digits, int(e) - PRECISION + 1)


static func coerce(value: Variant) -> BigNumber:
	if value is BigNumber:
		return value
	if typeof(value) == TYPE_DICTIONARY:
		return from_save(value)
	if typeof(value) == TYPE_STRING or typeof(value) == TYPE_INT:
		return parse_decimal(str(value))
	return null


func to_save() -> Dictionary:
	return {"significand": _coefficient, "exponent": exponent}


func is_zero() -> bool:
	return _coefficient == "0"


func compare(other: BigNumber) -> int:
	assert(other != null)
	if is_zero() or other.is_zero():
		return 0 if is_zero() and other.is_zero() else (-1 if is_zero() else 1)
	if exponent != other.exponent:
		return -1 if exponent < other.exponent else 1
	return _cmp(_coefficient, other._coefficient)


func equals(other: Variant) -> bool:
	var number := coerce(other)
	return number != null and compare(number) == 0


func add(other: BigNumber) -> BigNumber:
	if is_zero():
		return other
	if other.is_zero():
		return self
	if absi(exponent - other.exponent) > PRECISION + 2:
		return self if exponent > other.exponent else other
	var low := mini(exponent, other.exponent)
	return _from_raw(_add(_coefficient + "0".repeat(exponent - low), other._coefficient + "0".repeat(other.exponent - low)), low - PRECISION + 1)


func subtract_checked(other: BigNumber) -> BigNumber:
	if compare(other) < 0:
		return null
	if other.is_zero():
		return self
	if exponent - other.exponent > PRECISION + 2:
		return self
	var low := mini(exponent, other.exponent)
	return _from_raw(_sub(_coefficient + "0".repeat(exponent - low), other._coefficient + "0".repeat(other.exponent - low)), low - PRECISION + 1)


func multiply(other: BigNumber) -> BigNumber:
	if is_zero() or other.is_zero():
		return zero()
	return _from_raw(_mul(_coefficient, other._coefficient), exponent + other.exponent - 2 * (PRECISION - 1))


func divide(other: BigNumber) -> BigNumber:
	if other.is_zero():
		return null
	if is_zero():
		return zero()
	var qr := _divmod(_coefficient + "0".repeat(PRECISION + 2), other._coefficient)
	# One sticky digit records the nonzero remainder for ties-to-even rounding.
	return _from_raw(qr[0] + ("0" if qr[1] == "0" else "1"), exponent - other.exponent - PRECISION - 3)


func multiply_ratio(numerator: int, denominator: int) -> BigNumber:
	if numerator < 0 or denominator <= 0:
		return null
	# Divide once, avoiding double rounding of a multiply followed by divide.
	var raw := _mul(_coefficient, str(numerator))
	var denominator_text := str(denominator)
	if denominator_text[0] == "1" and denominator_text.substr(1).lstrip("0") == "":
		return _from_raw(raw, exponent - PRECISION + 1 - denominator_text.length() + 1)
	var qr := _divmod(raw + "0".repeat(PRECISION + 2), str(denominator))
	return _from_raw(qr[0] + ("0" if qr[1] == "0" else "1"), exponent - PRECISION + 1 - PRECISION - 3)


func pow_nonnegative_int(power: int) -> BigNumber:
	if power < 0:
		return null
	var result := from_int(1)
	var base := self
	var remaining := power
	while remaining > 0:
		if remaining % 2 == 1:
			result = result.multiply(base)
			if result == null:
				return null
		remaining = remaining / 2
		if remaining > 0:
			base = base.multiply(base)
			if base == null:
				return null
	return result


func shifted(power: int) -> BigNumber:
	return _from_raw(_coefficient, exponent - PRECISION + 1 + power) if not is_zero() else zero()


func floor_number() -> BigNumber:
	if is_zero() or exponent < 0:
		return zero()
	if exponent >= PRECISION - 1:
		return self
	return _from_raw(_coefficient.left(exponent + 1), 0)


func ceil_number() -> BigNumber:
	var floored := floor_number()
	return floored if compare(floored) == 0 else floored.add(from_int(1))


func format_scientific() -> String:
	if is_zero():
		return "0"
	var tail := _coefficient.substr(1).rstrip("0")
	return _coefficient[0] + ("," + tail if tail != "" else "") + "e" + str(exponent)


func format_compact() -> String:
	if is_zero() or exponent < 0:
		return "0"
	if exponent < 3:
		return _coefficient.left(exponent + 1)
	var group := exponent / 3
	var suffix: String
	if group <= 4:
		suffix = ["K", "M", "B", "T"][group - 1]
	elif group < 681:
		var index := group - 5
		suffix = ALPHABET[index / 26] + ALPHABET[index % 26]
	else:
		return _short_mantissa(1) + "e" + str(exponent)
	return _short_mantissa(exponent % 3 + 1) + suffix


func format_decimal(max_fraction: int = 3) -> String:
	if is_zero() or exponent < -max_fraction:
		return "0"
	if exponent >= PRECISION:
		return format_scientific()
	var head := _coefficient.left(exponent + 1) if exponent >= 0 else "0"
	var fraction := _coefficient.substr(exponent + 1) if exponent >= 0 else "0".repeat(-exponent - 1) + _coefficient
	fraction = fraction.left(max_fraction).rstrip("0")
	return head + ("," + fraction if fraction != "" else "")


func _short_mantissa(integer_digits: int) -> String:
	var head := _coefficient.left(integer_digits)
	var fraction := _coefficient.substr(integer_digits, maxi(0, 3 - integer_digits)).rstrip("0")
	return head + ("," + fraction if fraction != "" else "")


static func _from_raw(raw: String, power: int) -> BigNumber:
	var digits := _strip(raw)
	if digits == "0":
		return zero()
	var exp_ := power + digits.length() - 1
	if digits.length() > PRECISION:
		var discarded := digits.substr(PRECISION)
		digits = digits.left(PRECISION)
		var sticky := discarded.substr(1).lstrip("0") != ""
		var up := discarded[0] > "5" or (discarded[0] == "5" and (sticky or int(digits[PRECISION - 1]) % 2 == 1))
		if up:
			digits = _add(digits, "1")
			if digits.length() > PRECISION:
				exp_ += 1
				digits = digits.left(PRECISION)
	if absi(exp_) > MAX_EXPONENT:
		return null
	var out: BigNumber = load("res://core/math/big_number.gd").new()
	out._coefficient = digits + "0".repeat(PRECISION - digits.length())
	out.exponent = exp_
	return out


static func _strip(digits: String) -> String:
	var out := digits.lstrip("0")
	return "0" if out == "" else out


static func _cmp(a: String, b: String) -> int:
	if a.length() != b.length():
		return -1 if a.length() < b.length() else 1
	return 0 if a == b else (-1 if a < b else 1)


static func _add(a: String, b: String) -> String:
	var out := ""
	var carry := 0
	for i in maxi(a.length(), b.length()):
		var digit := carry
		if i < a.length():
			digit += int(a[a.length() - i - 1])
		if i < b.length():
			digit += int(b[b.length() - i - 1])
		out = str(digit % 10) + out
		carry = digit / 10
	return (str(carry) if carry else "") + out


static func _sub(a: String, b: String) -> String:
	var out := ""
	var borrow := 0
	for i in a.length():
		var digit := int(a[a.length() - i - 1]) - borrow
		if i < b.length():
			digit -= int(b[b.length() - i - 1])
		borrow = 1 if digit < 0 else 0
		out = str(digit + (10 if borrow else 0)) + out
	return _strip(out)


static func _mul(a: String, b: String) -> String:
	var digits: Array[int] = []
	digits.resize(a.length() + b.length())
	digits.fill(0)
	for i in a.length():
		for j in b.length():
			digits[i + j + 1] += int(a[i]) * int(b[j])
	for i in range(digits.size() - 1, 0, -1):
		digits[i - 1] += digits[i] / 10
		digits[i] %= 10
	var out := ""
	for digit in digits:
		out += str(digit)
	return _strip(out)


static func _divmod(a: String, b: String) -> Array[String]:
	var quotient := ""
	var remainder := "0"
	for digit in a:
		remainder = _strip(remainder + digit)
		var count := 0
		while _cmp(remainder, b) >= 0:
			remainder = _sub(remainder, b)
			count += 1
		quotient += str(count)
	return [_strip(quotient), remainder]
