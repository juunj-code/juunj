"""
바람의 탑 (Wind Tower) — 전투 공식(#6) 페이싱/밸런스 검증용 로직 시뮬레이션.

Godot이 이 환경에 설치되어 있지 않아(godot/godot4 바이너리 없음) 실제 엔진 빌드에서
playtest할 수 없었다. 대신 #6 전투-공식.md에 명시된 공식을 그대로 이식해
"입력 체감/느낌"이 아니라 "수치 페이싱(턴 수, 스킬 사용 동기)"만 검증하는
언어-불문 시뮬레이션으로 대체했다. 이 대체가 답할 수 없는 것: 실제 터치 입력감,
애니메이션 타이밍, UI 반응성. 답할 수 있는 것: 전투가 몇 턴에 끝나는지,
스킬 vs 기본 공격이 실제로 트레이드오프인지, 확정적 데미지 공식이 즉사/질질 끌기를
만들지 않는지. 결과와 판정은 README.md 참조.

throwaway — 메인 게임 코드에 임포트되지 않음.
"""
from __future__ import annotations

import math
import random

SP_MAX = 5
SP_GAIN_PER_TURN = 1


def floori_eps(x: float) -> int:
    return math.floor(x + 0.0001)


def skill_damage(atk: int, multiplier: float, defense: int) -> int:
    return max(1, floori_eps(atk * multiplier) - defense)


class Unit:
    def __init__(
        self,
        name: str,
        hp: int,
        atk: int,
        defense: int,
        spd: int,
        is_companion: bool,
        skill_mult: float,
        skill_cost: int,
        party_index: int = 0,
    ) -> None:
        self.name = name
        self.hp = hp
        self.atk = atk
        self.defense = defense
        self.spd = spd
        self.sp = 0
        self.is_companion = is_companion
        self.skill_mult = skill_mult
        self.skill_cost = skill_cost
        self.party_index = party_index
        self.skill_uses = 0
        self.basic_uses = 0

    @property
    def alive(self) -> bool:
        return self.hp > 0


def turn_order(units: list[Unit]) -> list[Unit]:
    # #6 공식: base_spd desc, 동률이면 동료 우선(party_index asc) — 안정 정렬 대신 명시적 2차 키
    return sorted(units, key=lambda u: (-u.spd, 0 if u.is_companion else 1, u.party_index))


def pick_target(attacker_is_companion: bool, companions: list[Unit], enemies: list[Unit]) -> Unit | None:
    pool = enemies if attacker_is_companion else companions
    alive = [u for u in pool if u.alive]
    if not alive:
        return None
    return min(alive, key=lambda u: u.hp)  # 포커스 파이어: 최저 HP 우선


def take_turn(unit: Unit, companions: list[Unit], enemies: list[Unit]) -> None:
    target = pick_target(unit.is_companion, companions, enemies)
    if target is None:
        return
    use_skill = unit.sp >= unit.skill_cost  # "SP 되면 항상 스킬" 휴리스틱 (#7 적 AI 규칙과 동일하게 양측에 적용)
    if use_skill:
        dmg = skill_damage(unit.atk, unit.skill_mult, target.defense)
        unit.sp -= unit.skill_cost
        unit.skill_uses += 1
    else:
        dmg = skill_damage(unit.atk, 1.0, target.defense)  # 기본 공격 = multiplier 1.0
        unit.basic_uses += 1
    target.hp = max(0, target.hp - dmg)


def sp_recover(units: list[Unit]) -> None:
    for u in units:
        if u.alive:
            u.sp = min(SP_MAX, u.sp + SP_GAIN_PER_TURN)


def run_battle(companions: list[Unit], enemies: list[Unit], max_turns: int = 30) -> tuple[bool, int]:
    turn_count = 0
    while any(c.alive for c in companions) and any(e.alive for e in enemies) and turn_count < max_turns:
        turn_count += 1
        sp_recover(companions + enemies)
        for unit in turn_order([u for u in (companions + enemies) if u.alive]):
            if not unit.alive:
                continue
            if not (any(c.alive for c in companions) and any(e.alive for e in enemies)):
                break
            take_turn(unit, companions, enemies)
    victory = any(c.alive for c in companions) and not any(e.alive for e in enemies)
    return victory, turn_count


def make_companion(name: str, hp: int, atk: int, defense: int, spd: int, idx: int) -> Unit:
    return Unit(name, hp, atk, defense, spd, True, skill_mult=1.5, skill_cost=2, party_index=idx)


def make_enemy(name: str, hp: int, atk: int, defense: int, spd: int) -> Unit:
    return Unit(name, hp, atk, defense, spd, False, skill_mult=1.3, skill_cost=2)


SCENARIOS = {
    "1층 (적 1마리, 딜러+탱커 파티)": lambda: (
        [make_companion("전사", 100, 18, 15, 5, 0), make_companion("궁수", 70, 26, 8, 7, 1)],
        [make_enemy("고블린", 45, 13, 7, 5)],
    ),
    "2층 (적 2마리)": lambda: (
        [make_companion("전사", 100, 18, 15, 5, 0), make_companion("궁수", 70, 26, 8, 7, 1)],
        [make_enemy("고블린A", 45, 13, 7, 5), make_enemy("고블린B", 45, 13, 7, 5)],
    ),
    "3층 (적 3마리, 동일 speed 타이브레이크 스트레스)": lambda: (
        [make_companion("전사", 100, 18, 15, 5, 0), make_companion("궁수", 70, 26, 8, 7, 1)],
        [make_enemy("적A", 45, 13, 7, 5), make_enemy("적B", 45, 13, 7, 5), make_enemy("적C", 45, 13, 7, 5)],
    ),
    "보스방 (1:1 솔로도 최강 검증)": lambda: (
        [make_companion("전사", 100, 18, 15, 5, 0)],
        [make_enemy("보스", 220, 20, 16, 6)],
    ),
}

if __name__ == "__main__":
    random.seed(42)
    print(f"{'시나리오':35s} {'승률':>6s} {'평균턴':>7s} {'스킬사용%':>8s}")
    for name, factory in SCENARIOS.items():
        n = 500
        wins = 0
        total_turns = 0
        total_skill = 0
        total_actions = 0
        for _ in range(n):
            companions, enemies = factory()
            victory, turns = run_battle(companions, enemies)
            wins += victory
            total_turns += turns
            for u in companions + enemies:
                total_skill += u.skill_uses
                total_actions += u.skill_uses + u.basic_uses
        win_rate = wins / n * 100
        avg_turns = total_turns / n
        skill_pct = (total_skill / total_actions * 100) if total_actions else 0
        print(f"{name:35s} {win_rate:5.1f}% {avg_turns:6.2f}턴 {skill_pct:7.1f}%")
