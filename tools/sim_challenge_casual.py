"""10-run challenge sim for a 30+ casual player.

Uses the live Game.gd numbers. The player is not idle and not optimal:
they collect most eggs, lose some at dusk, bake with downtime, buy chicks
when cash feels safe, upgrade the oven late, and dabble in stock poorly.
"""
from __future__ import annotations

import random
from dataclasses import dataclass, field

CAKE = 150
STEP = 0.12
MULT = [1.60, 1.05, 0.70, 0.42, 0.30, 0.20]
HOLD = [0.30, 0.30, 0.30, 0.30, 0.20, 0.10]
OVEN_COST = [0, 200, 500, 950, 1600, 2800]
GATES = {12: (7300, 22), 16: (11600, 37), 20: (22500, 58)}
DAY_S = [20.0, 18.0, 16.0]
CHICK = [50, 60, 70]


def wave(day: int) -> int:
    return max(0, min(2, (day - 9) // 4))


def cake_cycle_s(level: int) -> float:
    return 19 * STEP * MULT[level - 1] + HOLD[level - 1]


def oven_cap_cakes(level: int, day_s: float, focus: float) -> int:
    t = day_s * focus - 0.10
    if t <= 0:
        return 0
    return max(0, int(t / cake_cycle_s(level)))


@dataclass
class State:
    day: int = 9
    coins: int = 1800
    hens: int = 12
    young: int = 0
    hatching: int = 0
    hatched: int = 0
    oven: int = 3
    shares: int = 0
    price: int = 220
    log: list[str] = field(default_factory=list)

    def birds(self) -> int:
        return self.hens + self.young + self.hatching + self.hatched

    def wealth(self) -> int:
        return self.coins + self.shares * max(1, self.price)


def next_price(price: int, rng: random.Random) -> tuple[int, str]:
    if rng.random() < 0.45:
        nxt = int(round(price * rng.uniform(0.32, 0.78)))
        return max(50, min(1200, nxt)), "down"
    nxt = int(round(price * rng.uniform(1.12, 1.90))) + rng.randint(0, 40)
    return max(50, min(1200, nxt)), "up"


# casual_30plus: slower hold, more dusk miss, 1–3 chick taps, upgrades oven late.
# young_male: hold-repeat eggs, less bake idle, buys more chicks, skips oven6
# if it would break the next wealth gate.
PROFILES = {
    "casual_30plus": {
        "label": "30+ casual",
        "focus": (0.80, 0.74, 0.68),
        "collect": ((0.66, 0.80), (0.66, 0.80), (0.58, 0.74)),
        "oven_chance": 0.70,
        "oven_guard": 0.0,
        "chick_buys": (1, 3),
        "chick_pad": 3,
        "stock_buy": 0.22,
        "stock_sell": 0.18,
    },
    "young_male": {
        "label": "under-30 male",
        "focus": (0.90, 0.86, 0.82),
        "collect": ((0.84, 0.94), (0.82, 0.92), (0.78, 0.90)),
        "oven_chance": 0.88,
        "oven_guard": 0.95,
        "chick_buys": (3, 6),
        "chick_pad": 6,
        "stock_buy": 0.34,
        "stock_sell": 0.16,
    },
    "young_first": {
        "label": "under-30 first play",
        "focus": (0.88, 0.84, 0.80),
        "collect": ((0.80, 0.92), (0.78, 0.90), (0.74, 0.88)),
        "oven_chance": 0.95,
        "oven_guard": 0.0,
        "chick_buys": (2, 5),
        "chick_pad": 4,
        "stock_buy": 0.40,
        "stock_sell": 0.12,
    },
    "slack": {
        "label": "slack / distracted",
        "focus": (0.58, 0.50, 0.42),
        "collect": ((0.42, 0.58), (0.38, 0.54), (0.32, 0.48)),
        "oven_chance": 0.35,
        "oven_guard": 0.0,
        "chick_buys": (0, 2),
        "chick_pad": 1,
        "stock_buy": 0.12,
        "stock_sell": 0.08,
    },
    "tryhard": {
        "label": "tryhard / near-optimal",
        "focus": (0.97, 0.95, 0.93),
        "collect": ((0.94, 0.99), (0.92, 0.98), (0.90, 0.97)),
        "oven_chance": 0.92,
        "oven_guard": 1.00,
        "chick_buys": (4, 8),
        "chick_pad": 8,
        "stock_buy": 0.10,
        "stock_sell": 0.28,
    },
}

# Random-player mix: a few skill bands, weighted like real traffic.
MIX_BANDS = [
    ("slack", 0.15),
    ("casual_30plus", 0.35),
    ("young_first", 0.30),
    ("young_male", 0.15),
    ("tryhard", 0.05),
]


def play_day(s: State, rng: random.Random, prof: dict) -> None:
    w = wave(s.day)
    day_s = DAY_S[w]
    chick_cost = CHICK[w]
    next_gate_day = 12 if s.day <= 12 else (16 if s.day <= 16 else 20)
    need_w, need_b = GATES[next_gate_day]

    if s.oven < 6:
        cost = OVEN_COST[s.oven]
        oven_cakes = oven_cap_cakes(s.oven, day_s, 0.86)
        guard = prof["oven_guard"]
        safe = guard <= 0 or (s.wealth() - cost) >= int(need_w * guard)
        if s.coins >= cost + chick_cost * 2 and s.hens >= oven_cakes * 2 + 2 and safe:
            if rng.random() < prof["oven_chance"]:
                s.coins -= cost
                s.oven += 1
                s.log.append(f"D{s.day} oven->{s.oven}")

    focus = prof["focus"][w]
    lo, hi = prof["collect"][w]
    collect = rng.uniform(lo, hi)
    laid = s.hens
    boxed = int(round(laid * collect))
    boxed = max(0, min(laid, boxed))
    leftover = laid - boxed

    max_cakes = oven_cap_cakes(s.oven, day_s, focus)
    cakes = min(boxed // 2, max_cakes)
    used_eggs = cakes * 2
    leftover += boxed - used_eggs
    s.coins += cakes * CAKE

    if leftover >= 1 and s.hatching == 0 and s.hatched == 0:
        s.hatching = 1
        leftover -= 1

    spare = s.coins - (OVEN_COST[s.oven] if s.oven < 6 else 0) // 3
    want = max(0, need_b + int(prof["chick_pad"]) - s.birds())
    buys = 0
    cap = rng.randint(*prof["chick_buys"])
    while buys < cap and s.coins >= chick_cost and want > 0:
        if spare < chick_cost * 2 and s.wealth() < int(need_w * 0.85):
            break
        s.coins -= chick_cost
        s.young += 1
        want -= 1
        buys += 1

    roll = rng.random()
    if roll < prof["stock_buy"] and s.coins > s.price + 400 and s.shares < 5:
        s.coins -= s.price
        s.shares += 1
    elif roll < prof["stock_buy"] + prof["stock_sell"] and s.shares > 0:
        s.coins += s.price * s.shares
        s.shares = 0

    s.price, _ = next_price(s.price, rng)

    # Dawn: chicks grow, hatch lands.
    s.hens += s.young
    s.young = 0
    if s.hatching:
        s.hatched += 1
        s.hatching = 0
    if s.hatched:
        s.hens += s.hatched
        s.hatched = 0


def run_one(seed: int, prof: dict, **state_kw) -> dict:
    rng = random.Random(seed)
    s = State(**state_kw)
    failed = None
    snapshots = []
    for day in range(9, 21):
        s.day = day
        play_day(s, rng, prof)
        if day in GATES:
            need_w, need_b = GATES[day]
            snap = {
                "day": day,
                "wealth": s.wealth(),
                "birds": s.birds(),
                "cash": s.coins,
                "oven": s.oven,
                "price": s.price,
                "shares": s.shares,
            }
            snapshots.append(snap)
            if s.wealth() < need_w or s.birds() < need_b:
                failed = snap | {"need_w": need_w, "need_b": need_b}
                break
    return {
        "seed": seed,
        "win": failed is None,
        "fail": failed,
        "snaps": snapshots,
        "end": {"wealth": s.wealth(), "birds": s.birds(), "oven": s.oven},
    }


def _pct(xs: list[int], p: float) -> float:
    if not xs:
        return 0.0
    ys = sorted(xs)
    i = min(len(ys) - 1, max(0, int(round((p / 100.0) * (len(ys) - 1)))))
    return float(ys[i])


def _gate_stats(results: list[dict], day: int) -> None:
    reached = []
    for r in results:
        for snap in r["snaps"]:
            if snap["day"] == day:
                reached.append(snap)
                break
    n = len(reached)
    if n == 0:
        print(f"D{day}: nobody reached")
        return
    ws = [s["wealth"] for s in reached]
    bs = [s["birds"] for s in reached]
    need_w, need_b = GATES[day]
    passed = sum(1 for s in reached if s["wealth"] >= need_w and s["birds"] >= need_b)
    w_fail = sum(1 for s in reached if s["wealth"] < need_w and s["birds"] >= need_b)
    b_fail = sum(1 for s in reached if s["wealth"] >= need_w and s["birds"] < need_b)
    both = sum(1 for s in reached if s["wealth"] < need_w and s["birds"] < need_b)
    oven6 = sum(1 for s in reached if s["oven"] >= 6)
    print(
        f"D{day} reached {n}/{len(results)}  pass {passed}  "
        f"fail money {w_fail}  fail birds {b_fail}  fail both {both}"
    )
    print(
        f"     wealth avg {sum(ws)/n:.0f}  p10 { _pct(ws,10):.0f}  "
        f"p50 { _pct(ws,50):.0f}  p90 { _pct(ws,90):.0f}  need {need_w}"
    )
    print(
        f"     birds  avg {sum(bs)/n:.1f}  p10 { _pct(bs,10):.0f}  "
        f"p50 { _pct(bs,50):.0f}  p90 { _pct(bs,90):.0f}  need {need_b}"
    )
    print(f"     oven6 at this gate: {oven6}")


def main() -> None:
    import sys

    n = 100
    name = sys.argv[1] if len(sys.argv) > 1 else "young_male"
    prof = PROFILES[name]
    results = [run_one(1000 + i * 17, prof) for i in range(n)]
    wins = sum(1 for r in results if r["win"])
    print(f"challenge sim x{n}  |  {prof['label']}  |  start D9 cash1800 hens12 oven3")
    print("gates: D12 7300/22  D16 11600/37  D20 22500/58")
    print()
    print(f"WIN {wins}/{n}  ({wins}%)")
    fail_days = {12: 0, 16: 0, 20: 0}
    for r in results:
        if r["fail"]:
            fail_days[r["fail"]["day"]] += 1
    print(
        f"FAIL D12 {fail_days[12]}  D16 {fail_days[16]}  D20 {fail_days[20]}  "
        f"reach D20 {wins + fail_days[20]}"
    )
    print()
    _gate_stats(results, 12)
    _gate_stats(results, 16)
    _gate_stats(results, 20)
    early6 = 0
    early6_fail16 = 0
    for r in results:
        d16 = next((s for s in r["snaps"] if s["day"] == 16), None)
        if d16 and d16["oven"] >= 6:
            early6 += 1
            if r["fail"] and r["fail"]["day"] == 16:
                early6_fail16 += 1
    print()
    print(f"bought oven6 by D16: {early6}  of those failed D16: {early6_fail16}")


def play_optimal_day(s: State) -> None:
    """Skill cap, still normal play: all eggs, full bake, no stock.

    Upgrade oven when hens outrun it. Buy chicks up to the oven's egg
    appetite plus a small buffer, then bank cash for wealth.
    """
    w = wave(s.day)
    day_s = DAY_S[w]
    chick_cost = CHICK[w]
    cap = oven_cap_cakes(s.oven, day_s, 1.0)
    if s.oven < 6 and s.hens > cap * 2 + 1:
        cost = OVEN_COST[s.oven]
        if s.coins >= cost + chick_cost * 2:
            s.coins -= cost
            s.oven += 1
            cap = oven_cap_cakes(s.oven, day_s, 1.0)
    boxed = s.hens
    cakes = min(boxed // 2, cap)
    leftover = boxed - cakes * 2
    s.coins += cakes * CAKE
    if leftover >= 1 and s.hatching == 0 and s.hatched == 0:
        s.hatching = 1
    target = cap * 2 + 6
    while s.hens + s.young < target and s.coins >= chick_cost:
        s.coins -= chick_cost
        s.young += 1
    s.hens += s.young
    s.young = 0
    if s.hatching:
        s.hatched += 1
        s.hatching = 0
    if s.hatched:
        s.hens += s.hatched
        s.hatched = 0


def play_optimal_gated_day(s: State, need: dict[int, tuple[int, int]]) -> None:
    """Max farm while still clearing the next wealth/bird gate."""
    w = wave(s.day)
    day_s = DAY_S[w]
    chick_cost = CHICK[w]
    gate_day = 12 if s.day <= 12 else (16 if s.day <= 16 else 20)
    need_w, need_b = need[gate_day]
    cap = oven_cap_cakes(s.oven, day_s, 1.0)
    if s.oven < 6 and s.hens > cap * 2 + 1:
        cost = OVEN_COST[s.oven]
        if s.coins >= cost + chick_cost * 2 and s.coins - cost + 8 * CAKE >= need_w:
            s.coins -= cost
            s.oven += 1
            cap = oven_cap_cakes(s.oven, day_s, 1.0)
    boxed = s.hens
    cakes = min(boxed // 2, cap)
    leftover = boxed - cakes * 2
    s.coins += cakes * CAKE
    if leftover >= 1 and s.hatching == 0 and s.hatched == 0:
        s.hatching = 1
    target = max(need_b + 2, cap * 2 + 4)
    while s.hens + s.young < target and s.coins >= chick_cost:
        if s.day <= gate_day and s.coins - chick_cost < need_w:
            break
        s.coins -= chick_cost
        s.young += 1
    s.hens += s.young
    s.young = 0
    if s.hatching:
        s.hatched += 1
        s.hatching = 0
    if s.hatched:
        s.hens += s.hatched
        s.hatched = 0


def run_optimal_gated(need: dict[int, tuple[int, int]]) -> dict:
    s = State()
    snaps = []
    for day in range(9, 21):
        s.day = day
        play_optimal_gated_day(s, need)
        if day in need:
            snaps.append(
                {
                    "day": day,
                    "wealth": s.wealth(),
                    "birds": s.birds(),
                    "cash": s.coins,
                    "oven": s.oven,
                }
            )
    return {"snaps": snaps}


def run_optimal() -> dict:
    s = State()
    snaps = []
    for day in range(9, 21):
        s.day = day
        play_optimal_day(s)
        if day in (12, 16, 20):
            snaps.append(
                {
                    "day": day,
                    "wealth": s.wealth(),
                    "birds": s.birds(),
                    "cash": s.coins,
                    "oven": s.oven,
                }
            )
    return {"snaps": snaps, "end": {"wealth": s.wealth(), "birds": s.birds(), "oven": s.oven}}


def _pass_at(results: list[dict], day: int, need_w: int, need_b: int) -> tuple[int, int]:
    reached = 0
    passed = 0
    for r in results:
        snap = next((x for x in r["snaps"] if x["day"] == day), None)
        if snap is None:
            continue
        reached += 1
        if snap["wealth"] >= need_w and snap["birds"] >= need_b:
            passed += 1
    return reached, passed


def _eval_gates(need: dict[int, tuple[int, int]], n: int = 100) -> None:
    global GATES
    old = GATES
    GATES = need
    pops = [
        ("casual_30plus", 50),
        ("young_first", 35),
        ("young_male", 15),
    ]
    print(f"gates D12 {need[12]}  D16 {need[16]}  D20 {need[20]}")
    mix_pass = {12: 0, 16: 0, 20: 0}
    mix_n = 0
    for name, weight in pops:
        prof = PROFILES[name]
        results = [run_one(2000 + i * 19, prof) for i in range(n)]
        print(f"  {prof['label']} x{n}")
        for day in (12, 16, 20):
            reached, passed = _pass_at(results, day, *need[day])
            starters_pass = passed  # failed earlier => not in reached
            # pass rate of all starters
            rate = 100.0 * passed / n
            print(f"    D{day} pass {passed}/{n} ({rate:.0f}%)  reached {reached}")
            mix_pass[day] += passed * weight
        mix_n += n * weight
    print(
        "  MIX 50% 30+ / 35% young-first / 15% young-skilled  "
        f"D12 {100*mix_pass[12]/mix_n:.0f}%  "
        f"D16 {100*mix_pass[16]/mix_n:.0f}%  "
        f"D20 {100*mix_pass[20]/mix_n:.0f}%"
    )
    GATES = old


def tune() -> None:
    opt = run_optimal()
    print("OPTIMAL unconstrained (may miss wealth gates)")
    for snap in opt["snaps"]:
        print(
            f"  D{snap['day']} wealth {snap['wealth']}  birds {snap['birds']}  "
            f"cash {snap['cash']}  oven {snap['oven']}"
        )
    chosen = {12: (7300, 22), 16: (11600, 37), 20: (22500, 58)}
    gated = run_optimal_gated(chosen)
    print("OPTIMAL gate-aware (still try to clear)")
    for snap in gated["snaps"]:
        print(
            f"  D{snap['day']} wealth {snap['wealth']}  birds {snap['birds']}  "
            f"cash {snap['cash']}  oven {snap['oven']}"
        )
    print()
    # D12 near 30+ median ~7250/24; D16 punish greedy oven; D20 near optimal-but-not
    candidates = [
        {12: (7300, 22), 16: (11600, 37), 20: (22500, 58)},
        {12: (7300, 22), 16: (11600, 37), 20: (23000, 56)},
        {12: (7300, 22), 16: (11600, 37), 20: (24000, 58)},
    ]
    for g in candidates:
        _eval_gates(g, 100)
        print()


def _pick_mix(rng: random.Random) -> str:
    roll = rng.random()
    acc = 0.0
    for name, w in MIX_BANDS:
        acc += w
        if roll < acc:
            return name
    return MIX_BANDS[-1][0]


def _print_gate_pass(results: list[dict], n: int, title: str) -> dict:
    fail_days = {12: 0, 16: 0, 20: 0}
    wins = sum(1 for r in results if r["win"])
    for r in results:
        if r["fail"]:
            fail_days[int(r["fail"]["day"])] += 1
    print(title)
    print(
        f"  D12 通过 {n - fail_days[12]}/{n}  ({100.0 * (n - fail_days[12]) / n:.1f}%)  "
        f"挂 {fail_days[12]}"
    )
    print(
        f"  D16 通过 {n - fail_days[12] - fail_days[16]}/{n}  "
        f"({100.0 * (n - fail_days[12] - fail_days[16]) / n:.1f}%)  "
        f"挂 {fail_days[16]}  （到这关 {n - fail_days[12]}）"
    )
    print(
        f"  D20 通关 {wins}/{n}  ({100.0 * wins / n:.1f}%)  "
        f"挂 {fail_days[20]}  （到这关 {n - fail_days[12] - fail_days[16]}）"
    )
    return {"wins": wins, "fail": fail_days}


def mix1000(n: int = 1000) -> None:
    print("挑战模拟 随机玩家水平 x%d" % n)
    print("开局 D9  cash1800  hens12  oven3  price220")
    print("门槛 D12 7300/22  D16 11600/37  D20 22500/58")
    print()
    print("本轮生成的玩家档（权重 = 随机抽到的概率）")
    for name, w in MIX_BANDS:
        p = PROFILES[name]
        print(f"  {w:.0%}  {p['label']}  ({name})")
    print()

    mix_rng = random.Random(20260906)
    by_name: dict[str, list] = {name: [] for name, _ in MIX_BANDS}
    mixed: list[dict] = []
    for i in range(n):
        name = _pick_mix(mix_rng)
        r = run_one(90000 + i * 31, PROFILES[name])
        r["profile"] = name
        mixed.append(r)
        by_name[name].append(r)

    print("=== 混合随机玩家 %d 局 ===" % n)
    _print_gate_pass(mixed, n, "")
    print()
    _gate_stats(mixed, 12)
    _gate_stats(mixed, 16)
    _gate_stats(mixed, 20)
    print()
    print("=== 各档自己的通过量（同一批局里按抽到的档拆开）===")
    for name, _w in MIX_BANDS:
        chunk = by_name[name]
        cn = len(chunk)
        if cn == 0:
            print(f"{PROFILES[name]['label']}: 0 局")
            continue
        _print_gate_pass(chunk, cn, f"{PROFILES[name]['label']}  n={cn}")
        print()

    win_w = [r["end"]["wealth"] for r in mixed if r["win"]]
    if win_w:
        print(
            "通关局收盘资产  avg %.0f  p10 %.0f  p50 %.0f  p90 %.0f  max %d"
            % (sum(win_w) / len(win_w), _pct(win_w, 10), _pct(win_w, 50), _pct(win_w, 90), max(win_w))
        )
        tiers = [100000, 90000, 80000, 70000, 60000, 50000, 40000, 30000, 20000]
        print("通关局能解锁的财富成就（该档及以下全亮）")
        for t in tiers:
            c = sum(1 for w in win_w if w >= t)
            print(f"  >={t:>6}  {c}/{len(win_w)} 通关局  （占总开局 {100.0 * c / n:.1f}%）")


if __name__ == "__main__":
    import sys

    if len(sys.argv) > 1 and sys.argv[1] == "tune":
        tune()
    elif len(sys.argv) > 1 and sys.argv[1] == "mix1000":
        mix1000(int(sys.argv[2]) if len(sys.argv) > 2 else 1000)
    else:
        main()

