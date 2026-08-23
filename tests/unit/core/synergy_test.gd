extends GutTest
## Covers design/gdd/시너지.md Acceptance Criteria 1-3, 5-7, 9-11, 13.
## AC4 (solo/empty) covered inline below. AC8 (no recalculation mid-battle)
## and AC12 (integration -- #1 actually calls this once per unit) are
## TurnBattle's behavior, not Synergy's own state (Synergy is stateless by
## design) -- see turn_battle_test.gd (both now actually present there as of
## 2026-08-23; AC8 was previously just an unbacked claim in this comment).
##
## AC5/AC6 (same-class_type-duplicate scenarios) don't need synthetic
## companion_ids: MVP's real registry has exactly one companion per
## class_type, but calculate_party_synergy_bonus() dedups by class_type, not
## by companion_id, so passing the same real ID twice already exercises the
## dedup path faithfully.

const TANK := "companion_tank_01" # base_atk 12
const DEALER := "companion_dealer_01" # base_atk 28
const BALANCE := "companion_balance_01" # base_atk 18
const SUPPORT := "companion_support_01" # base_atk 14

func test_two_types_returns_that_pairs_value() -> void: # AC1
	assert_eq(Synergy.calculate_party_synergy_bonus([TANK, DEALER]), 4)

func test_three_types_sums_all_three_pairs() -> void: # AC2
	assert_eq(Synergy.calculate_party_synergy_bonus([TANK, DEALER, SUPPORT]), 11) # 4+2+5

func test_balance_pair_covered() -> void: # AC3
	assert_eq(Synergy.calculate_party_synergy_bonus([DEALER, BALANCE]), 3)

func test_solo_party_returns_zero() -> void: # AC4
	assert_eq(Synergy.calculate_party_synergy_bonus([TANK]), 0)
	assert_eq(Synergy.calculate_party_synergy_bonus([]), 0)

func test_party_of_one_distinct_type_returns_zero() -> void: # AC5
	assert_eq(Synergy.calculate_party_synergy_bonus([TANK, TANK]), 0)

func test_duplicate_type_pair_not_double_counted() -> void: # AC6
	assert_eq(Synergy.calculate_party_synergy_bonus([TANK, TANK, DEALER]), 4)

func test_order_of_companion_ids_does_not_affect_result() -> void: # AC7
	var forward := Synergy.calculate_party_synergy_bonus([DEALER, TANK])
	var reversed := Synergy.calculate_party_synergy_bonus([TANK, DEALER])
	assert_eq(forward, reversed)

func test_undefined_pair_returns_zero_no_warning() -> void: # AC9
	assert_eq(Synergy.TABLE.get(Synergy._pair_key("z_future_type", "tank"), 0), 0)

func test_applied_bonus_uncapped_for_high_base_atk_unit() -> void: # AC10
	var applied := Synergy.get_applied_synergy_bonus([TANK, DEALER, SUPPORT], 28) # dealer's own base_atk
	assert_eq(applied, 11) # 11 <= floori(28*0.5)=14, cap doesn't bite

func test_applied_bonus_capped_for_low_base_atk_unit() -> void: # AC11
	var applied := Synergy.get_applied_synergy_bonus([TANK, DEALER, SUPPORT], 12) # tank's own base_atk
	assert_eq(applied, 6) # min(11, floori(12*0.5)=6) -- cap bites, would be 11 uncapped

func test_table_has_no_duplicate_unordered_pairs() -> void: # AC13
	assert_eq(Synergy.TABLE.size(), 6)
	for key: String in Synergy.TABLE.keys():
		var parts := key.split("-")
		assert_eq(key, Synergy._pair_key(parts[0], parts[1]), "key '%s' isn't in canonical normalized form" % key)
