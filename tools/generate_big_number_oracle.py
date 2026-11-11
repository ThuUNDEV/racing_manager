"""Regenerate the deterministic Decimal oracle consumed by big_number_test.gd."""
from decimal import Decimal, localcontext, ROUND_HALF_EVEN
from pathlib import Path
import json
import random

rng = random.Random(91473)
cases = []
for i in range(240):
    a = f"{rng.randrange(1, 10**24)}e{rng.randrange(-60, 301)}"
    b = f"{rng.randrange(1, 10**24)}e{rng.randrange(-60, 301)}"
    op = ["add", "subtract", "multiply", "divide"][i % 4]
    with localcontext() as context:
        context.prec = 24
        context.rounding = ROUND_HALF_EVEN
        x, y = +Decimal(a), +Decimal(b)
        if op == "subtract" and x < y:
            x, y, a, b = y, x, b, a
        result = {
            "add": lambda: x + y,
            "subtract": lambda: x - y,
            "multiply": lambda: x * y,
            "divide": lambda: x / y,
        }[op]()
    cases.append({"a": a, "b": b, "op": op, "expected": str(result)})
dest = Path(__file__).resolve().parents[1] / "tests/golden/big_number_decimal.json"
dest.write_text(json.dumps(cases, indent=2) + "\n", encoding="utf-8")
