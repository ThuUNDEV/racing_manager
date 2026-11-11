extends SceneTree

const BigNumber = preload("res://core/math/big_number.gd")
var fails := 0

func check(ok: bool, label: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + label)
	if not ok:
		fails += 1

func n(value: String) -> BigNumber:
	return BigNumber.parse_decimal(value)

func _initialize() -> void:
	check(n("0.000").to_save() == {"significand": "0", "exponent": 0}, "canonical zero")
	check(n("9007199254740993").add(n("1")).equals("9007199254740994"), "integers beyond float precision")
	check(n("99999999999999999999999").add(n("1")).equals("1e23"), "carry into new exponent")
	check(n("1e23").subtract_checked(n("1")).equals("99999999999999999999999"), "borrow across digits")
	check(n("1").subtract_checked(n("2")) == null, "reject negative wallet")
	check(n("1e300").multiply(n("1e300")).equals("1e600"), "large product without float overflow")
	check(n("1e300").divide(n("1e299")).equals(10), "division exponent")
	check(n("1").divide(n("3")).to_save()["significand"] == "333333333333333333333333", "division precision")
	check(n("5").multiply_ratio(3, 2).equals("7.5"), "exact rational multiply")
	check(n("8").multiply_ratio(1000000, 1000000).equals(8), "microsecond scaling")
	check(n("1.45").pow_nonnegative_int(2).equals("2.1025"), "decimal power")
	check(n("2.001").ceil_number().equals(3) and n("2.999").floor_number().equals(2), "floor and ceil")
	check(n("45.75").format_decimal() == "45,75" and n("0.125").format_decimal() == "0,125", "decimal display preserves decimal point position")
	check(n("1.234567890123456789012345").to_save()["significand"] == "123456789012345678901234", "ties round to even down")
	check(n("1.234567890123456789012355").to_save()["significand"] == "123456789012345678901236", "ties round to even up")
	check(n("1.23456789012345678901234501").to_save()["significand"] == "123456789012345678901235", "sticky digit above tie")
	check(n("1e30").add(n("1")).equals("1e30"), "documented finite precision")
	for exponent_ in [0, 15, 18, 90, 93, 168, 1965, 2040, 2043, 300]:
		var value := n("1e" + str(exponent_))
		check(BigNumber.from_save(value.to_save()).equals(value), "save round trip e%d" % exponent_)
	var cases := {"999": "999", "1000": "1K", "1234567": "1,23M", "1e9": "1B", "1e12": "1T", "1e15": "1AA", "1e18": "1AB", "1e90": "1AZ", "1e93": "1BA", "1e2040": "1ZZ", "1e2043": "1e2043", "999999": "999K"}
	for value in cases:
		check(n(value).format_compact() == cases[value], "format " + value)
	for invalid in ["-1", "NaN", "Infinity", "1e1000001", "1e-1000001", "1e999999999", "", "1.2.3"]:
		check(n(invalid) == null, "reject " + invalid)
	check(n("1").divide(n("0")) == null, "reject division by zero")
	check(BigNumber.from_save({"significand": "10", "exponent": 1}) == null, "reject noncanonical save")
	var oracle: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/golden/big_number_decimal.json"))
	var oracle_ok := true
	for row: Dictionary in oracle:
		var a := n(row["a"])
		var b := n(row["b"])
		var result: BigNumber
		match row["op"]:
			"add": result = a.add(b)
			"subtract": result = a.subtract_checked(b)
			"multiply": result = a.multiply(b)
			"divide": result = a.divide(b)
		if result == null or not result.equals(row["expected"]):
			oracle_ok = false
			print("oracle mismatch: ", row)
	check(oracle_ok, "240 deterministic cases against Python Decimal (24 digits, half-even)")
	quit(1 if fails else 0)
