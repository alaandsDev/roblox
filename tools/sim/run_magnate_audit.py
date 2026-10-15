#!/usr/bin/env python3
"""Auditoria 200 h: Player Auras (proposta R, Absoluta candidata 10T) + Ranking Magnata.

    python3 tools/sim/run_magnate_audit.py [--players 48] [--side 24] [--hours 200] [--jobs N]
                                          [--json resumo.json] [--from-json resumo.json]

Roda tools/sim/analyze_magnate.luau (EconomyModel oficial + protótipo MoneyLedger) com as MESMAS
sementes em todos os cenários e reescreve as partes geradas de:
    PLAYER_AURA_ECONOMY_AUDIT.md   (<!-- GERADO200:INICIO --> ... <!-- GERADO200:FIM -->)
    MAGNATE_RANKING_AUDIT.md       (<!-- GERADO:INICIO --> ... <!-- GERADO:FIM -->)
Hipótese de estudo: nada disso existe no jogo. Determinístico.
"""
import argparse
import concurrent.futures
import glob
import json
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LUNE = sorted(glob.glob(os.path.join(ROOT, "tools", "bin", "lune-*", "lune*")))
SCRIPT = os.path.join("tools", "sim", "analyze_magnate.luau")
AURA_DOC = os.path.join(ROOT, "PLAYER_AURA_ECONOMY_AUDIT.md")
MAGNATE_DOC = os.path.join(ROOT, "MAGNATE_RANKING_AUDIT.md")
PROFILES = ["Casual", "Ativo", "Otimizador", "Pago"]
CHECKS = [10, 20, 40, 80, 120, 200]
STRATEGY_PROFILE = "Ativo"
STRATEGIES = ["A", "B", "C", "D"]
STRATEGY_NAMES = {
    "base": "sem Player Aura (jogo atual)",
    "A": "A · compra assim que consegue",
    "B": "B · prioriza Rebirth",
    "C": "C · acumula dinheiro",
    "D": "D · otimizada",
    "R10": "padrão do perfil (proposta)",
}


def money(v):
    if v is None:
        return "—"
    for unit, size in (("Qa", 1e15), ("T", 1e12), ("B", 1e9), ("M", 1e6), ("K", 1e3)):
        if abs(v) >= size:
            return f"${v / size:.2f}{unit}"
    return f"${v:.0f}"


def hours(sec):
    return "—" if sec is None else f"{sec / 3600:.1f} h"


def count(v):
    return "—" if v is None else f"{v:.0f}"


def pct(values, q):
    values = sorted(v for v in values if v is not None)
    if not values:
        return None
    k = (len(values) - 1) * q
    lo = int(k)
    hi = min(lo + 1, len(values) - 1)
    return values[lo] + (values[hi] - values[lo]) * (k - lo)


def at(lst, i):
    if isinstance(lst, list):
        return lst[i] if i < len(lst) else None
    if isinstance(lst, dict):
        return lst.get(str(i + 1))
    return None


def run_shard(task):
    scenario, profile, seed0, n, hrs, out = task
    subprocess.check_call([LUNE[-1], "run", SCRIPT, scenario, profile, str(seed0), str(n), str(hrs), out], cwd=ROOT)
    with open(out, encoding="utf-8") as f:
        return json.load(f)


def simulate(players, side, hrs, jobs):
    work = tempfile.mkdtemp(prefix="magnate_")
    plan = []
    for profile in PROFILES:
        plan += [("base", profile, players), ("R10", profile, players), ("R5", profile, side), ("R7", profile, side), ("R20", profile, side)]
    for strategy in STRATEGIES:
        plan.append((strategy, STRATEGY_PROFILE, players))
    tasks = []
    for scenario, profile, total in plan:
        per = max(1, total // 6)
        for start in range(0, total, per):
            n = min(per, total - start)
            tasks.append((scenario, profile, 1 + start, n, hrs, os.path.join(work, f"{scenario}_{profile}_{start}.json")))
    data = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
        for task, result in zip(tasks, pool.map(run_shard, tasks)):
            entry = data.setdefault(f"{task[0]}|{task[1]}", {"tiers": result["tiers"], "runs": []})
            entry["runs"].extend(result["runs"])
    for entry in data.values():
        entry["runs"].sort(key=lambda r: r["seed"])
    return data


def snap(run, h):
    for s in run["snaps"]:
        if abs(s["time"] - h * 3600) < 1:
            return s
    return None


def cycle_of(times, t):
    """(início, fim) do ciclo de Rebirth que contém t; None se t está fora de um ciclo completo."""
    before = [x for x in times if x <= t]
    after = [x for x in times if x > t]
    if not after:
        return None
    return (before[-1] if before else 0), after[0], len(before)


def summarize(data):
    out = {}
    for key, entry in data.items():
        scenario, profile = key.split("|")
        runs = entry["runs"]
        base = {r["seed"]: r for r in data.get(f"base|{profile}", {"runs": []})["runs"]}
        tiers = []
        for i, tier in enumerate(entry["tiers"]):
            bought = [at(r["bought"], i) for r in runs]
            states = [at(r["buyState"], i) for r in runs]
            prev = entry["tiers"][i - 1]["money"] if i > 0 else 1
            gain = tier["money"] / prev - 1
            cycle_delta = []
            for r, b in zip(runs, bought):
                if b is None or r["seed"] not in base:
                    continue
                c = cycle_of(r["rebirthTimes"], b)
                if not c:
                    continue
                start, end, index = c
                bt = base[r["seed"]]["rebirthTimes"]
                if index < len(bt) and index >= 1:
                    base_len = bt[index] - bt[index - 1]
                    cycle_delta.append((end - start) - base_len)
            tiers.append({
                "name": tier["name"], "price": tier["price"], "money": tier["money"], "walk": tier.get("walk"),
                "share": sum(1 for b in bought if b is not None) / len(runs),
                "p10": pct(bought, 0.1), "p50": pct(bought, 0.5), "p90": pct(bought, 0.9),
                "rebirths": pct([s["rebirths"] for s in states if s], 0.5),
                "ips": pct([s["ips"] for s in states if s], 0.5),
                "money_at": pct([s["money"] for s in states if s], 0.5),
                "payback": pct([tier["price"] / (s["ips"] * gain) for s in states if s and s["ips"] > 0], 0.5),
                "cycle_delta": pct(cycle_delta, 0.5),
            })
        checks = {}
        for h in CHECKS:
            snaps = [snap(r, h) for r in runs]
            snaps = [s for s in snaps if s]
            checks[h] = {
                "earned": pct([s["earned"] for s in snaps], 0.5),
                "lifetime": pct([s["lifetime"] for s in snaps], 0.5),
                "lifetime_p10": pct([s["lifetime"] for s in snaps], 0.1),
                "lifetime_p90": pct([s["lifetime"] for s in snaps], 0.9),
                "rebirths": pct([s["rebirths"] for s in snaps], 0.5),
                "ips": pct([s["ips"] for s in snaps], 0.5),
                "share_generated": pct([s["lifetime"] / s["earned"] for s in snaps if s["earned"] > 0], 0.5),
            }
        out[key] = {"tiers": tiers, "checks": checks, "players": len(runs), "seeds": [r["seed"] for r in runs],
                    "lifetimes": {str(h): [(snap(r, h) or {}).get("lifetime") for r in runs] for h in CHECKS}}
    return out


def head(cols):
    return ["| " + " | ".join(cols) + " |", "|" + "---|" * len(cols)]


def aura_tables(s, players, side, hrs):
    L = ["<!-- GERADO200:INICIO -->", "",
         f"_Gerado por `python3 tools/sim/run_magnate_audit.py --players {players} --side {side} --hours {hrs}` — {players} jogadores por perfil (R10 e base), {side} nas variantes da Absoluta; MESMAS sementes; P50 salvo indicação._", ""]
    L += ["### 200 h — compra de cada aura (proposta R10: Absoluta 10T)", ""]
    L += head(["Perfil", "Aura", "Preço", "Money", "WalkSpeed", "Comprou em 200 h", "Compra P10 / P50 / P90", "Rebirths na compra", "Renda/s na compra", "Saldo na compra", "Payback¹", "Ciclo de Rebirth da compra²"])
    for profile in PROFILES:
        for t in s[f"R10|{profile}"]["tiers"]:
            delta = t["cycle_delta"]
            dtext = "—" if delta is None else (f"+{delta / 3600:.1f} h" if delta >= 0 else f"{delta / 3600:.1f} h")
            L.append(f"| {profile} | {t['name']} | {money(t['price'])} | ×{t['money']:g} | {t['walk']} | {t['share'] * 100:.0f}% | {hours(t['p10'])} / {hours(t['p50'])} / {hours(t['p90'])} | {count(t['rebirths'])} | {money(t['ips'])}/s | {money(t['money_at'])} | {hours(t['payback'])} | {dtext} |")
    L += ["", "¹ tempo ATIVO para o ganho extra de renda (× novo ÷ × anterior − 1) pagar o preço, com a renda do momento (limite superior: a renda continua crescendo).",
          "² diferença de duração do ciclo de Rebirth em que a compra caiu, contra o MESMO ciclo (mesmo nº de Rebirth, mesma semente) no jogo atual: + = o Rebirth seguinte atrasou (o jogador juntou para a aura).", ""]
    L += ["### Dinheiro produzido e Rebirths (P50)", ""]
    L += head(["Perfil", "Cenário"] + [f"Produzido {h} h" for h in CHECKS] + ["Rebirths 40/80/120/200 h", "Renda/s 200 h"])
    for profile in PROFILES:
        for scenario in ("base", "R10"):
            c = s[f"{scenario}|{profile}"]["checks"]
            rb = " / ".join(count(c[h]["rebirths"]) for h in (40, 80, 120, 200))
            L.append(f"| {profile} | {'atual (sem auras)' if scenario == 'base' else 'R10'} | " + " | ".join(money(c[h]["earned"]) for h in CHECKS) + f" | {rb} | {money(c[200]['ips'])}/s |")
    L += ["", "\"Produzido\" = todo dinheiro que entrou (todas as fontes, inclusive venda e Jackpot).", ""]
    L += ["### Absoluta: 5T × 7,5T × 10T × 20T (o resto da proposta igual)", ""]
    L += head(["Perfil", "Preço da Absoluta", "Comprou em 200 h", "Compra P10 / P50 / P90", "Rebirths na compra", "Celestial (P50)"])
    for profile in PROFILES:
        for scenario, label in (("R5", "5T"), ("R7", "7,5T"), ("R10", "10T"), ("R20", "20T")):
            tiers = s[f"{scenario}|{profile}"]["tiers"]
            a, c = tiers[4], tiers[3]
            L.append(f"| {profile} | {label} | {a['share'] * 100:.0f}% | {hours(a['p10'])} / {hours(a['p50'])} / {hours(a['p90'])} | {count(a['rebirths'])} | {hours(c['p50'])} |")
    L += ["", "<!-- GERADO200:FIM -->"]
    return "\n".join(L)


def magnate_tables(s, players, hrs):
    L = ["<!-- GERADO:INICIO -->", "",
         f"_Gerado por `python3 tools/sim/run_magnate_audit.py` — {players} jogadores por cenário, {hrs} h ativas, MESMAS sementes; Lifetime = protótipo `tools/sim/MoneyLedger.luau` (só GENERATED)._", ""]
    L += ["### LifetimeMoneyGenerated por perfil (P50) — jogo atual × proposta R10", ""]
    L += head(["Perfil", "Cenário"] + [f"{h} h" for h in (20, 40, 80, 120, 200)] + ["% do produzido que conta (200 h)"])
    for profile in PROFILES:
        for scenario in ("base", "R10"):
            c = s[f"{scenario}|{profile}"]["checks"]
            share = c[200]["share_generated"]
            L.append(f"| {profile} | {'atual' if scenario == 'base' else 'R10'} | " + " | ".join(money(c[h]["lifetime"]) for h in (20, 40, 80, 120, 200)) + f" | {'—' if share is None else f'{share * 100:.1f}%'} |")
    L += ["", f"### Estratégias ({STRATEGY_PROFILE}, mesmas sementes) — Lifetime P50 (P10–P90)", ""]
    L += head(["Estratégia"] + [f"{h} h" for h in (20, 40, 80, 120, 200)] + ["Rebirths 200 h", "Auras em 200 h"])
    order = ["base", "R10"] + STRATEGIES
    for strategy in order:
        e = s[f"{strategy}|{STRATEGY_PROFILE}"]
        c = e["checks"]
        cells = [f"{money(c[h]['lifetime'])} ({money(c[h]['lifetime_p10'])}–{money(c[h]['lifetime_p90'])})" for h in (20, 40, 80, 120, 200)]
        auras = sum(1 for t in e["tiers"] if t["share"] >= 0.5) if strategy != "base" else 0
        L.append(f"| {STRATEGY_NAMES[strategy]} | " + " | ".join(cells) + f" | {count(c[200]['rebirths'])} | {auras} |")
    L += ["", "### Bola de neve? Razão entre estratégias (P50) e quem passa quem (mesma semente)", ""]
    L += head(["Comparação"] + [f"{h} h" for h in (20, 40, 80, 120, 200)])
    def ratio_row(a, b, label):
        ca, cb = s[f"{a}|{STRATEGY_PROFILE}"]["checks"], s[f"{b}|{STRATEGY_PROFILE}"]["checks"]
        cells = []
        for h in (20, 40, 80, 120, 200):
            x, y = ca[h]["lifetime"], cb[h]["lifetime"]
            cells.append("—" if not x or not y else f"×{x / y:.2f}")
        L.append(f"| {label} | " + " | ".join(cells) + " |")
    def wins_row(a, b, label):
        la, lb = s[f"{a}|{STRATEGY_PROFILE}"]["lifetimes"], s[f"{b}|{STRATEGY_PROFILE}"]["lifetimes"]
        cells = []
        for h in (20, 40, 80, 120, 200):
            pairs = [(x, y) for x, y in zip(la[str(h)], lb[str(h)]) if x is not None and y is not None]
            cells.append("—" if not pairs else f"{sum(1 for x, y in pairs if x > y) / len(pairs) * 100:.0f}%")
        L.append(f"| {label} | " + " | ".join(cells) + " |")
    ratio_row("R10", "base", "com aura (padrão) ÷ sem aura")
    for x in ("A", "C", "D"):
        ratio_row(x, "B", f"{x} ÷ B")
    wins_row("A", "B", "A à frente de B (% das sementes)")
    wins_row("D", "B", "D à frente de B (% das sementes)")
    wins_row("C", "B", "C à frente de B (% das sementes)")
    L += ["", "### Entre perfis: a aura alarga a distância? (Lifetime P50)", ""]
    L += head(["Razão", "Cenário"] + [f"{h} h" for h in (20, 40, 80, 120, 200)])
    for a, b in (("Pago", "Casual"), ("Otimizador", "Ativo"), ("Ativo", "Casual")):
        for scenario in ("base", "R10"):
            ca, cb = s[f"{scenario}|{a}"]["checks"], s[f"{scenario}|{b}"]["checks"]
            cells = []
            for h in (20, 40, 80, 120, 200):
                x, y = ca[h]["lifetime"], cb[h]["lifetime"]
                cells.append("—" if not x or not y else f"×{x / y:.2f}")
            L.append(f"| {a} ÷ {b} | {'atual' if scenario == 'base' else 'R10'} | " + " | ".join(cells) + " |")
    L += ["", "<!-- GERADO:FIM -->"]
    return "\n".join(L)


def splice(path, begin, end, generated, title):
    if os.path.exists(path):
        with open(path, encoding="utf-8") as f:
            doc = f.read()
    else:
        doc = f"# {title}\n\n"
    if begin in doc and end in doc:
        doc = doc[: doc.index(begin)] + generated + doc[doc.index(end) + len(end):]
    else:
        doc += "\n" + generated + "\n"
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(doc)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--players", type=int, default=48)
    parser.add_argument("--side", type=int, default=24)
    parser.add_argument("--hours", type=int, default=200)
    parser.add_argument("--jobs", type=int, default=os.cpu_count() or 2)
    parser.add_argument("--json")
    parser.add_argument("--from-json")
    args = parser.parse_args()
    if args.from_json:
        with open(args.from_json, encoding="utf-8") as f:
            summary = json.load(f)
        for entry in summary.values():
            entry["checks"] = {int(k): v for k, v in entry["checks"].items()}
    else:
        if not LUNE:
            print("lune não encontrado em tools/bin/lune-*/", file=sys.stderr)
            return 1
        summary = summarize(simulate(args.players, args.side, args.hours, args.jobs))
    if args.json:
        with open(args.json, "w", encoding="utf-8") as f:
            json.dump(summary, f, indent=1)
    splice(AURA_DOC, "<!-- GERADO200:INICIO -->", "<!-- GERADO200:FIM -->", aura_tables(summary, args.players, args.side, args.hours), "PLAYER AURAS")
    splice(MAGNATE_DOC, "<!-- GERADO:INICIO -->", "<!-- GERADO:FIM -->", magnate_tables(summary, args.players, args.hours), "RANKING MAGNATA — auditoria")
    print("ok:", AURA_DOC, MAGNATE_DOC)
    return 0


if __name__ == "__main__":
    sys.exit(main())
