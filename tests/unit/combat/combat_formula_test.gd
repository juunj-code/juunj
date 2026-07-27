extends GutTest
## ADR-0008 regression test: floori() + epsilon guard for skill damage.
## Without the guard, 25 * 1.16 evaluates to 28.999999999999996 in float,
## which floori()s to 28 instead of the mathematically-intended 29 —
## a real bug found during #6 전투-공식's design review.

func test_skill_damage_epsilon_guard_prevents_float_underflow() -> void:
	var atk := 25
	var multiplier := 1.16
	var defense := 0
	var damage := floori(atk * multiplier + 0.0001) - defense
	assert_eq(damage, 29, "epsilon guard must prevent 28.999... from flooring to 28")

func test_naive_floori_without_epsilon_guard_documents_the_bug() -> void:
	var atk := 25
	var multiplier := 1.16
	var naive := floori(atk * multiplier)
	assert_eq(naive, 28, "documents exactly the bug ADR-0008's epsilon guard fixes")
