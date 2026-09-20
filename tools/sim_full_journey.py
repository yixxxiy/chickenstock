"""1000-player funnel: tutorial -> 8-day campaign -> challenge day 20.

Mirrors Game.gd numbers. Players keep the same farm after day 8
(the finale "continue" path), then challenge rules and hard gates apply.
"""
from __future__ import annotations

import random
import sys
from collections import Counter
from dataclasses import dataclass, field
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from sim_challenge_casual import (  # noqa: E402
    CAKE,
    DAY_S,
    GATES,
    MIX_BANDS,
    OVEN_COST,
    PROFILES,
    State,
    oven_cap_cakes,
    play_day,
    wave,
)

CAMPAIGN_DAY_S = 20.0
CAMPAIGN_CHICK = 50
CAMPAIGN_OVEN_MAX = 4
CAMPAIGN_WEALTH = 3000
CAMPAIGN_FLOCK = 15

TUTORIAL_STEPS = [
    ("t0_goal", "读目标 / 点开始"),
    ("t1_eggs", "点收 3 个蛋气泡"),
    ("t2_hatch", "点孵化"),
    ("t3_cake", "等烤完并点卖蛋糕"),
    ("t4_hen", "花 50 买鸡"),
    ("t5_buy", "买 1 股"),
    ("t6_sell", "卖出股票"),
    ("t7_done", "点进入正式游戏"),
]

# Base pass chance at skill 0. Then rises toward 1 as skill -> 1.
TUTORIAL_BASE = {
    "t0_goal": 0.93,
    "t1_eggs": 0.78,
    "t2_hatch": 0.86,
    "t3_cake": 0.74,
    "t4_hen": 0.88,
    "t5_buy": 0.84,
    "t6_sell": 0.80,
    "t7_done": 0.90,
}

SKILL_BANDS = [
    (0.00, 0.22, "slack"),
    (0.22, 0.48, "casual_30plus"),
    (0.48, 0.70, "young_first"),
    (0.70, 0.88, "young_male"),
    (0.88, 1.01, "tryhard"),
]


def clamp(v: float, lo: float, hi: float) -> float:
    return max(lo, min(hi, v))


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def _pick_band(rng: random.Random) -> str:
    roll = rng.random()
    acc = 0.0
    for name, w in MIX_BANDS:
        acc += w
        if roll < acc:
            return name
    return MIX_BANDS[-1][0]


def roll_skill(rng: random.Random) -> tuple[float, str]:
    """Realistic traffic mix, then jitter so each player is unique."""
    name = _pick_band(rng)
    for lo, hi, key in SKILL_BANDS:
        if key == name:
            skill = rng.uniform(lo, min(1.0, hi - 0.001))
            return skill, name
    return rng.random(), name


def lerp_profile(skill: float) -> dict:
    """Blend slack -> tryhard by skill. Wave tuples stay 3-long."""
    slack = PROFILES["slack"]
    tryhard = PROFILES["tryhard"]
    t = clamp(skill, 0.0, 1.0)
    out = {
        "label": f"skill {skill:.2f}",
        "oven_chance": lerp(float(slack["oven_chance"]), float(tryhard["oven_chance"]), t),
        "oven_guard": lerp(float(slack["oven_guard"]), float(tryhard["oven_guard"]), t),
        "chick_pad": int(round(lerp(float(slack["chick_pad"]), float(tryhard["chick_pad"]), t))),
        "stock_buy": lerp(float(slack["stock_buy"]), float(tryhard["stock_buy"]), t),
        "stock_sell": lerp(float(slack["stock_sell"]), float(tryhard["stock_sell"]), t),
        "hatch_p": lerp(0.55, 0.99, t),
        "chick_collect": lerp(0.70, 0.99, t),
        "learn": lerp(0.78, 1.0, t),
    }
    out["focus"] = tuple(lerp(a, b, t) for a, b in zip(slack["focus"], tryhard["focus"]))
    out["collect"] = tuple(
        (lerp(a[0], b[0], t), lerp(a[1], b[1], t))
        for a, b in zip(slack["collect"], tryhard["collect"])
    )
    lo_b = slack["chick_buys"][0] + (tryhard["chick_buys"][0] - slack["chick_buys"][0]) * t
    hi_b = slack["chick_buys"][1] + (tryhard["chick_buys"][1] - slack["chick_buys"][1]) * t
    out["chick_buys"] = (int(round(lo_b)), max(int(round(lo_b)), int(round(hi_b))))
    return out


def tutorial_step_p(step_id: str, skill: float) -> float:
    base = TUTORIAL_BASE[step_id]
    return clamp(base + (1.0 - base) * (skill**0.65), 0.20, 0.998)


def play_tutorial(skill: float, rng: random.Random) -> dict:
    # Clock is paused and only the gold target works, so a trying player
    # almost always finishes. Failures are quit / give-up, not mis-taps.
    quit_p = clamp(0.28 * ((1.0 - skill) ** 1.6), 0.01, 0.32)
    if rng.random() < quit_p:
        weights = [0.10, 0.28, 0.10, 0.22, 0.08, 0.08, 0.08, 0.06]
        step_id, label = rng.choices(TUTORIAL_STEPS, weights=weights, k=1)[0]
        return {
            "ok": False,
            "step": step_id,
            "label": label,
            "why": f"退出教学（停在「{label}」）",
        }
    for step_id, label in TUTORIAL_STEPS:
        if rng.random() <= tutorial_step_p(step_id, skill):
            continue
        if rng.random() < 0.35 + skill * 0.55:
            continue
        return {
            "ok": False,
            "step": step_id,
            "label": label,
            "why": f"放弃教学（卡在「{label}」）",
        }
    return {"ok": True, "step": "", "label": "", "why": ""}


def next_price_campaign(price: int, rng: random.Random) -> int:
    p = max(50, min(680, price if price else 300))
    roll = rng.random()
    if roll < 0.11 and p >= 110:
        n = "rain"
    elif roll < 0.22 and p <= 520:
        n = "hoard"
    else:
        n = "cake"
    if n == "rain":
        factor = 0.55 + rng.random() * 0.18
    elif n == "hoard":
        factor = 1.22 + rng.random() * 0.28
    else:
        factor = 1.05 + rng.random() * 0.12
    nxt = int(round((p + (300 - p) * 0.18) * factor))
    if n == "rain":
        nxt = min(nxt, p - max(12, int(round(p * 0.1))))
    else:
        bump = 24 if n == "hoard" else 8
        frac = 0.16 if n == "hoard" else 0.05
        nxt = max(nxt, p + max(bump, int(round(p * frac))))
    return max(50, min(680, nxt))


def dawn(s: State, collect_chick: bool) -> None:
    s.hens += s.young
    s.young = 0
    if s.hatching:
        s.hatched += s.hatching
        s.hatching = 0
    if collect_chick and s.hatched:
        s.young += s.hatched
        s.hatched = 0


def play_campaign_day(s: State, rng: random.Random, prof: dict) -> dict:
    day_s = CAMPAIGN_DAY_S
    chick_cost = CAMPAIGN_CHICK
    learn = float(prof.get("learn", 1.0))
    if s.day <= 3:
        learn *= 0.90
    focus = clamp(prof["focus"][0] * learn, 0.20, 1.0)
    lo, hi = prof["collect"][0]
    collect = clamp(rng.uniform(lo, hi) * learn, 0.15, 0.99)

    if s.oven < CAMPAIGN_OVEN_MAX and s.day >= 2:
        cost = OVEN_COST[s.oven]
        oven_cakes = oven_cap_cakes(s.oven, day_s, 0.86)
        if s.coins >= cost + chick_cost * 2 and s.hens >= oven_cakes * 2:
            if rng.random() < prof["oven_chance"]:
                s.coins -= cost
                s.oven += 1

    laid = 3 if s.day == 1 else s.hens
    boxed = max(0, min(laid, int(round(laid * collect))))
    leftover = laid - boxed
    max_cakes = oven_cap_cakes(s.oven, day_s, focus)
    cakes = min(boxed // 2, max_cakes)
    leftover += boxed - cakes * 2
    s.coins += cakes * CAKE

    hatched_today = 0
    if leftover >= 1 and s.hatching == 0 and s.hatched == 0:
        if rng.random() < float(prof.get("hatch_p", 0.8)):
            s.hatching = 1
            leftover -= 1
            hatched_today = 1

    want = max(0, CAMPAIGN_FLOCK + int(prof["chick_pad"]) - s.birds())
    buys = 0
    cap = rng.randint(*prof["chick_buys"])
    while buys < cap and s.coins >= chick_cost and want > 0:
        if s.coins < chick_cost * 2 and s.wealth() < int(CAMPAIGN_WEALTH * 0.80):
            break
        s.coins -= chick_cost
        s.young += 1
        want -= 1
        buys += 1

    roll = rng.random()
    if roll < prof["stock_buy"] and s.coins > s.price + 80 and s.shares < 4:
        s.coins -= s.price
        s.shares += 1
    elif roll < prof["stock_buy"] + prof["stock_sell"] and s.shares > 0:
        s.coins += s.price * s.shares
        s.shares = 0

    s.price = next_price_campaign(s.price, rng)
    dawn(s, rng.random() < float(prof.get("chick_collect", 0.9)))
    return {
        "cakes": cakes,
        "dusk_lost": leftover,
        "chick_buys": buys,
        "hatched": hatched_today,
        "collect": collect,
    }


def classify_gate(wealth: int, birds: int, need_w: int, need_b: int, extras: dict) -> tuple[str, str]:
    w_miss = wealth < need_w
    b_miss = birds < need_b
    if w_miss and b_miss:
        primary = "资产和鸡群都不够"
    elif w_miss:
        primary = "资产不够"
    else:
        primary = "鸡群不够"

    tags: list[str] = []
    hens = max(1, int(extras.get("hens", 1)))
    dusk = int(extras.get("dusk_lost", 0))
    eggs_seen = int(extras.get("eggs_seen", 0))
    if eggs_seen > 0 and dusk >= max(3, int(eggs_seen * 0.28)):
        tags.append("黄昏碎蛋多")
    oven = int(extras.get("oven", 1))
    day = int(extras.get("day", 0))
    if day >= 16 and oven <= 3:
        tags.append("烤炉没升上去")
    elif day == 8 and oven <= 2:
        tags.append("八日烤炉仍很低")
    if int(extras.get("stock_loss", 0)) > 400:
        tags.append("股票亏了")
    if b_miss and int(extras.get("chick_buys", 0)) == 0:
        tags.append("当天没买鸡")
    if w_miss and birds > need_b + 4:
        tags.append("扩群过猛，现金被买鸡掏空")
    if int(extras.get("cakes", 0)) < max(1, hens // 3) and w_miss:
        tags.append("蛋糕产出跟不上")
    if extras.get("early") and int(extras.get("early_cakes", 0)) <= 2:
        tags.append("前三天蛋糕太少")
    if not tags:
        tags.append("整体节奏偏慢")
    return primary, "；".join(tags)


def run_one(seed: int, skill: float, band: str) -> dict:
    rng = random.Random(seed)
    prof = lerp_profile(skill)
    tut = play_tutorial(skill, rng)
    out = {
        "seed": seed,
        "skill": skill,
        "band": band,
        "win": False,
        "stage": "",
        "day": 0,
        "why": "",
        "detail": "",
        "wealth": 0,
        "birds": 0,
        "need_w": 0,
        "need_b": 0,
        "day8_quest": False,
        "day8_snap": {},
        "snaps": [],
    }
    if not tut["ok"]:
        out["stage"] = "tutorial"
        out["day"] = 0
        out["why"] = tut["why"]
        out["detail"] = tut["step"]
        return out

    s = State(day=1, coins=120, hens=1, oven=1, price=120, young=0, hatching=0, hatched=0, shares=0)
    dusk_total = 0
    cake_total = 0
    buy_total = 0
    eggs_seen = 0
    early_cakes = 0
    for day in range(1, 9):
        s.day = day
        stats = play_campaign_day(s, rng, prof)
        dusk_total += int(stats["dusk_lost"])
        cake_total += int(stats["cakes"])
        buy_total += int(stats["chick_buys"])
        eggs_seen += 3 if day == 1 else max(1, s.hens)
        if day <= 3:
            early_cakes += int(stats["cakes"])

    out["day8_quest"] = s.wealth() >= CAMPAIGN_WEALTH and s.birds() >= CAMPAIGN_FLOCK
    out["day8_snap"] = {
        "wealth": s.wealth(),
        "birds": s.birds(),
        "oven": s.oven,
        "cash": s.coins,
        "why": "",
        "detail": "",
    }
    if not out["day8_quest"]:
        primary, tags = classify_gate(
            s.wealth(),
            s.birds(),
            CAMPAIGN_WEALTH,
            CAMPAIGN_FLOCK,
            {
                "hens": s.hens,
                "dusk_lost": dusk_total,
                "eggs_seen": eggs_seen,
                "oven": s.oven,
                "day": 8,
                "chick_buys": buy_total,
                "cakes": cake_total,
                "early": True,
                "early_cakes": early_cakes,
            },
        )
        out["day8_snap"]["why"] = f"八日任务未达标：{primary}"
        out["day8_snap"]["detail"] = tags
        out["stage"] = "day8"
        out["day"] = 8
        out["why"] = out["day8_snap"]["why"]
        out["detail"] = tags
        out["wealth"] = s.wealth()
        out["birds"] = s.birds()
        out["need_w"] = CAMPAIGN_WEALTH
        out["need_b"] = CAMPAIGN_FLOCK
        out["snaps"].append(
            {"day": 8, "wealth": s.wealth(), "birds": s.birds(), "oven": s.oven, "cash": s.coins}
        )
        return out
    out["snaps"].append(
        {"day": 8, "wealth": s.wealth(), "birds": s.birds(), "oven": s.oven, "cash": s.coins}
    )

    for day in range(9, 21):
        s.day = day
        before_shares = s.shares
        before_price = s.price
        play_day(s, rng, prof)
        stock_loss = 0
        if before_shares > 0 and s.price < before_price:
            stock_loss = (before_price - s.price) * before_shares
        if day in GATES:
            need_w, need_b = GATES[day]
            snap = {
                "day": day,
                "wealth": s.wealth(),
                "birds": s.birds(),
                "oven": s.oven,
                "cash": s.coins,
            }
            out["snaps"].append(snap)
            if s.wealth() < need_w or s.birds() < need_b:
                primary, tags = classify_gate(
                    s.wealth(),
                    s.birds(),
                    need_w,
                    need_b,
                    {
                        "hens": s.hens,
                        "oven": s.oven,
                        "day": day,
                        "stock_loss": stock_loss,
                        "chick_buys": 1 if s.young else 0,
                        "cakes": oven_cap_cakes(s.oven, DAY_S[wave(day)], prof["focus"][wave(day)]),
                    },
                )
                out["stage"] = f"d{day}"
                out["day"] = day
                out["why"] = f"第{day}天门槛：{primary}"
                out["detail"] = tags
                out["wealth"] = s.wealth()
                out["birds"] = s.birds()
                out["need_w"] = need_w
                out["need_b"] = need_b
                return out

    out["win"] = True
    out["stage"] = "win"
    out["day"] = 20
    out["why"] = "通关"
    out["wealth"] = s.wealth()
    out["birds"] = s.birds()
    return out


def _pct(xs: list[int], p: float) -> float:
    if not xs:
        return 0.0
    ys = sorted(xs)
    i = min(len(ys) - 1, max(0, int(round((p / 100.0) * (len(ys) - 1)))))
    return float(ys[i])


def _print_reason_table(rows: list[dict], indent: str = "    ") -> None:
    why = Counter()
    detail = Counter()
    for r in rows:
        why[r["why"]] += 1
        if r.get("detail"):
            for bit in str(r["detail"]).split("；"):
                if bit:
                    detail[bit] += 1
    for text, n in why.most_common():
        print(f"{indent}{n:4d}  {text}")
    if detail:
        print(f"{indent}细分（可重叠）：")
        for text, n in detail.most_common(8):
            print(f"{indent}  {n:4d}  {text}")


def main(n: int = 1000) -> None:
    print("全流程模拟  教学日 → 八日经营 → 挑战第20天")
    print(f"人数 {n}  水平按现网权重抽档，再在档内抖开")
    print("权重  摸鱼15% / 30+休闲35% / 年轻首玩30% / 年轻熟练15% / 硬核5%")
    print("规则  教学失败或八日任务未达标即停。未达标不能进挑战。")
    print("八日  3000金 + 15鸡    挑战硬门槛  D12 7300/22  D16 11600/37  D20 22500/58")
    print("路径  第八晚达标后继续同一座农场")
    print()

    rng = random.Random(20260906)
    results = []
    for i in range(n):
        skill, band = roll_skill(rng)
        results.append(run_one(70000 + i * 37, skill, band))

    stages = [
        ("tutorial", "教学日", 0, 0),
        ("day8", "第8天（八日任务）", CAMPAIGN_WEALTH, CAMPAIGN_FLOCK),
        ("d12", "第12天", 7300, 22),
        ("d16", "第16天", 11600, 37),
        ("d20", "第20天", 22500, 58),
    ]
    wins = [r for r in results if r["win"]]
    print(f"通关（第20天门槛通过）  {len(wins)}/{n}  ({100.0 * len(wins) / n:.1f}%)")
    print()
    print("=== 卡在哪一关 ===")
    reached = n
    for key, label, need_w, need_b in stages:
        stuck = [r for r in results if r["stage"] == key]
        passed_here = reached - len(stuck)
        extra = f"  门槛 {need_w}/{need_b}" if need_w else ""
        print(
            f"{label:16s}  到达 {reached:4d}  通过 {passed_here:4d}  "
            f"({100.0 * passed_here / n:.1f}%)  卡死 {len(stuck):4d}{extra}"
        )
        reached = passed_here
    print(f"{'通关':16s}  {len(wins):4d}")

    print("\n=== 各关卡住原因 ===")
    for key, label, _w, _b in stages:
        stuck = [r for r in results if r["stage"] == key]
        print(f"\n{label}  n={len(stuck)}")
        if not stuck:
            print("    （无人卡在这）")
            continue
        if key != "tutorial":
            ws = [r["wealth"] for r in stuck]
            bs = [r["birds"] for r in stuck]
            print(
                f"    卡住时资产 avg {sum(ws)/len(ws):.0f}  "
                f"p10 {_pct(ws,10):.0f}  p50 {_pct(ws,50):.0f}  "
                f"鸡 avg {sum(bs)/len(bs):.1f}  需要 {stuck[0]['need_w']}/{stuck[0]['need_b']}"
            )
        _print_reason_table(stuck)

    print("\n=== 各水平档通关 ===")
    by_band: dict[str, list] = {name: [] for name, _ in MIX_BANDS}
    for r in results:
        by_band[r["band"]].append(r)
    for name, _w in MIX_BANDS:
        chunk = by_band[name]
        cn = len(chunk)
        if cn == 0:
            continue
        w = sum(1 for r in chunk if r["win"])
        stops = Counter(r["stage"] for r in chunk)
        q8 = sum(1 for r in chunk if r["stage"] != "tutorial" and r["day8_quest"])
        print(
            f"{PROFILES[name]['label']:20s}  n={cn:3d}  通关 {w:3d} ({100.0 * w / cn:5.1f}%)  "
            f"卡教学 {stops.get('tutorial', 0)}  "
            f"卡八日 {stops.get('day8', 0)}  "
            f"八日达标 {q8}  "
            f"卡12 {stops.get('d12', 0)}  "
            f"卡16 {stops.get('d16', 0)}  "
            f"卡20 {stops.get('d20', 0)}"
        )

    if wins:
        ww = [r["wealth"] for r in wins]
        print()
        print(
            "通关局收盘资产  avg %.0f  p10 %.0f  p50 %.0f  p90 %.0f  max %d"
            % (sum(ww) / len(ww), _pct(ww, 10), _pct(ww, 50), _pct(ww, 90), max(ww))
        )


if __name__ == "__main__":
    count = 1000
    if len(sys.argv) > 1:
        count = int(sys.argv[1])
    main(count)
