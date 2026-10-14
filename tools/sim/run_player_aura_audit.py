#!/usr/bin/env python3
"""Auditoria econômica das PLAYER AURAS (hipótese; nada implementado no jogo).

    python3 tools/sim/run_player_aura_audit.py [--players 120] [--hours 40] [--jobs N] [--json out.json]

Roda tools/sim/analyze_player_auras.luau (EconomyModel oficial) para cada cenário × perfil com as
MESMAS sementes, agrega (P50/P10/P90) e escreve a parte gerada de PLAYER_AURA_ECONOMY_AUDIT.md
(entre os marcadores <!-- GERADO:INICIO --> / <!-- GERADO:FIM -->). Determinístico.
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
SCRIPT = os.path.join("tools", "sim", "analyze_player_auras.luau")
DOC = os.path.join(ROOT, "PLAYER_AURA_ECONOMY_AUDIT.md")
PROFILES = ["Casual", "Ativo", "Otimizador", "Pago"]
SCENARIOS = ["baseH", "H", "baseR", "R"]
BEGIN, END = "<!-- GERADO:INICIO -->", "<!-- GERADO:FIM -->"
REBIRTH_BASE, REBIRTH_GROWTH = 15e6, 2.2


def money(v):
    if v is None:
        return "—"
    for unit, size in (("T", 1e12), ("B", 1e9), ("M", 1e6), ("K", 1e3)):
        if abs(v) >= size:
            return f"{v / size:.2f}{unit}"
    return f"{v:.0f}"


def hours(sec):
    if sec is None:
        return "—"
    return f"{sec / 3600:.1f} h"


def pct(values, q):
    values = sorted(values)
    if not values:
        return None
    k = (len(values) - 1) * q
    lo = int(k)
    hi = min(lo + 1, len(values) - 1)
    return values[lo] + (values[hi] - values[lo]) * (k - lo)


def run_shard(task):
    scenario, profile, seed0, n, hrs, out = task
    lune = LUNE[-1]
    subprocess.check_call([lune, "run", SCRIPT, scenario, profile, str(seed0), str(n), str(hrs), out], cwd=ROOT)
    with open(out, encoding="utf-8") as f:
        return json.load(f)


def simulate(players, hrs, jobs, scenarios=SCENARIOS):
    work = tempfile.mkdtemp(prefix="player_auras_")
    per = max(1, players // 4)
    tasks = []
    for scenario in scenarios:
        for profile in PROFILES:
            for start in range(0, players, per):
                count = min(per, players - start)
                tasks.append((scenario, profile, 1 + start, count, hrs, os.path.join(work, f"{scenario}_{profile}_{start}_{hrs}.json")))
    data = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=jobs) as pool:
        for task, result in zip(tasks, pool.map(run_shard, tasks)):
            key = (task[0], task[1])
            entry = data.setdefault(key, {"tiers": result["tiers"], "saveRatio": result["saveRatio"], "runs": []})
            entry["runs"].extend(result["runs"])
    return data


def tier_at(lst, i):
    # serde do Lune: lista Luau vira lista JSON; posições vazias (nil) somem só no fim
    if isinstance(lst, list):
        return lst[i] if i < len(lst) else None
    if isinstance(lst, dict):
        return lst.get(str(i + 1))
    return None


def snap(run, hour):
    for s in run["snaps"]:
        if abs(s["time"] - hour * 3600) < 1:
            return s
    return None


def hrs_of(runs):
    times = [s["time"] for r in runs for s in r["snaps"]]
    return max(times) / 3600 if times else 40


def summarize(data):
    out = {}
    for (scenario, profile), entry in data.items():
        runs = entry["runs"]
        tiers = []
        for i, tier in enumerate(entry["tiers"]):
            afford = [tier_at(r["affordable"], i) for r in runs]
            bought = [tier_at(r["bought"], i) for r in runs]
            states = [tier_at(r["buyState"], i) for r in runs]
            got = [b for b in bought if b is not None]
            ok_afford = [a for a in afford if a is not None]
            ips = [s["ips"] for s in states if s]
            rbs = [s["rebirths"] for s in states if s]
            prev_mult = entry["tiers"][i - 1]["money"] if i > 0 else 1
            gain = tier["money"] / prev_mult - 1
            payback = [tier["price"] / (s["ips"] * gain) for s in states if s and s["ips"] > 0]
            # quanto o próximo Rebirth atrasou: tempo entre a compra e o Rebirth seguinte
            delays = []
            for r, b in zip(runs, bought):
                if b is None:
                    continue
                after = [t for t in r["rebirthTimes"] if t > b]
                before = [t for t in r["rebirthTimes"] if t <= b]
                if after and before:
                    delays.append(after[0] - before[-1])
            tiers.append({
                "name": tier["name"], "price": tier["price"], "money": tier["money"],
                "affordShare": len(ok_afford) / len(runs), "affordP50": pct(ok_afford, 0.5),
                "boughtShare": len(got) / len(runs), "boughtP10": pct(got, 0.1), "boughtP50": pct(got, 0.5), "boughtP90": pct(got, 0.9),
                "ipsP50": pct(ips, 0.5), "rebirthsP50": pct(rbs, 0.5), "paybackP50": pct(payback, 0.5),
                "rebirthGapP50": pct(delays, 0.5),
                "priceInRebirths": tier["price"] / REBIRTH_BASE,
            })
        checkpoints = {}
        for h in sorted({10, 20, 40, int(hrs_of(runs))}):
            snaps = [snap(r, h) for r in runs]
            snaps = [s for s in snaps if s]
            checkpoints[h] = {
                "ips": pct([s["ips"] for s in snaps], 0.5),
                "rebirths": pct([s["rebirths"] for s in snaps], 0.5),
                "earned": pct([s["earned"] for s in snaps], 0.5),
                "auraSpent": pct([s["auraSpent"] for s in snaps], 0.5),
            }
        forbidden = [tier_at(r["diceAt"], 15) for r in runs]
        forbidden = [f for f in forbidden if f is not None]
        out[f"{scenario}|{profile}"] = {
            "tiers": tiers, "checkpoints": checkpoints, "players": len(runs), "saveRatio": entry["saveRatio"],
            "forbiddenP50": pct(forbidden, 0.5), "forbiddenShare": len(forbidden) / len(runs),
        }
    return out


def count(v):
    return "—" if v is None else f"{v:.0f}"


def rb_text(t):
    return count(t["rebirthsP50"])


def rebirth_cost(n):
    return REBIRTH_BASE * REBIRTH_GROWTH ** n


def tables(summary, players, hrs, long_summary=None, long_hours=80, long_players=0):
    lines = [BEGIN, "", f"_Gerado por `python3 tools/sim/run_player_aura_audit.py --players {players} --hours {hrs}` — {players} jogadores por perfil e cenário, MESMAS sementes entre cenários; P50 salvo indicação._", ""]
    for scenario, title in (("H", "Hipótese do pedido (H)"), ("R", "Recomendação (R)")):
        lines += [f"### {title}: compra de cada aura por perfil", ""]
        lines += ["| Perfil | Aura | Preço | Money | Pode pagar¹ (P50) | Comprou em 40 h | Compra P10 / P50 / P90 | Renda/s na compra | Rebirths na compra | Payback² | Ciclo de Rebirth com a compra³ |", "|---|---|---|---|---|---|---|---|---|---|---|"]
        for profile in PROFILES:
            s = summary[f"{scenario}|{profile}"]
            base = summary[f"base{scenario}|{profile}"]
            for t in s["tiers"]:
                afford = hours(base["tiers"][s["tiers"].index(t)]["affordP50"]) if base else "—"
                afford_share = f" ({base['tiers'][s['tiers'].index(t)]['affordShare'] * 100:.0f}%)" if base else ""
                lines.append(
                    f"| {profile} | {t['name']} | {money(t['price'])} | ×{t['money']:g} | {afford}{afford_share} | {t['boughtShare'] * 100:.0f}% | "
                    f"{hours(t['boughtP10'])} / {hours(t['boughtP50'])} / {hours(t['boughtP90'])} | {money(t['ipsP50'])}/s | "
                    f"{rb_text(t)} | "
                    f"{hours(t['paybackP50'])} | {hours(t['rebirthGapP50'])} |"
                )
        lines += [""]
    lines += ["¹ Na linha de base (jogo atual, ninguém compra): 1º momento em que o SALDO ≥ preço, e % dos jogadores que chegam lá em 40 h. Com o Rebirth zerando o saldo, isso só acontece quando o Rebirth seguinte custa ≈ o preço (ou o jogador adia o Rebirth).", "² Tempo ATIVO para o ganho extra de renda (× novo ÷ × anterior − 1) pagar o preço, com a renda do momento da compra (sem contar o crescimento depois — limite superior).", "³ Tempo entre o Rebirth anterior e o seguinte quando a compra cai no meio (inclui o tempo poupando para a aura).", ""]
    lines += ["### Impacto em 10 h / 20 h / 40 h ativas (P50)", "", "| Perfil | Cenário | Renda/s 10 h | Renda/s 20 h | Renda/s 40 h | Rebirths 10/20/40 h | Ganho total 40 h | Gasto em auras 40 h | Forbidden comprado (P50) |", "|---|---|---|---|---|---|---|---|---|"]
    for profile in PROFILES:
        for scenario in ("baseH", "H", "R"):
            s = summary[f"{scenario}|{profile}"]
            c = s["checkpoints"]
            rb = " / ".join(count(c[h]["rebirths"]) for h in (10, 20, 40))
            name = {"baseH": "atual (sem auras)", "H": "H", "R": "R"}[scenario]
            lines.append(
                f"| {profile} | {name} | {money(c[10]['ips'])} | {money(c[20]['ips'])} | {money(c[40]['ips'])} | {rb} | {money(c[40]['earned'])} | {money(c[40]['auraSpent'])} | {hours(s['forbiddenP50'])} |"
            )
    if long_summary:
        lines += ["", f"### Longo prazo: {long_hours} h ativas ({long_players} jogadores por perfil e cenário) — quando chegam as últimas auras", "", "| Perfil | Cenário | Aura | Preço | Comprou em {0} h | Compra P50 | Renda/s na compra | Rebirths na compra | Renda/s {0} h | Rebirths {0} h |".format(long_hours), "|---|---|---|---|---|---|---|---|---|---|"]
        for profile in PROFILES:
            for scenario in ("H", "R"):
                s = long_summary[f"{scenario}|{profile}"]
                c = s["checkpoints"].get(long_hours) or s["checkpoints"][str(long_hours)]
                for t in s["tiers"][2:]:
                    lines.append(f"| {profile} | {scenario} | {t['name']} | {money(t['price'])} | {t['boughtShare'] * 100:.0f}% | {hours(t['boughtP50'])} | {money(t['ipsP50'])}/s | {rb_text(t)} | {money(c['ips'])} | {count(c['rebirths'])} |")
    lines += ["", "Custo do Rebirth n (15M × 2,2ⁿ) para comparar com os preços: " + ", ".join(f"RB{n + 1} {money(rebirth_cost(n))}" for n in range(0, 24, 2)) + ".", "", END]
    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--players", type=int, default=120)
    parser.add_argument("--hours", type=float, default=40)
    parser.add_argument("--jobs", type=int, default=os.cpu_count() or 2)
    parser.add_argument("--long-hours", type=int, default=120, help="horizonte longo (últimas auras)")
    parser.add_argument("--long-players", type=int, default=30)
    parser.add_argument("--json", help="salva o resumo")
    parser.add_argument("--from-json", help="só reescreve o relatório a partir de um resumo salvo")
    args = parser.parse_args()
    if args.from_json:
        with open(args.from_json, encoding="utf-8") as f:
            saved = json.load(f)
        summary, long_summary = saved["main"], saved.get("long")
        for part in (summary, long_summary or {}):
            for entry in part.values():
                entry["checkpoints"] = {int(k): v for k, v in entry["checkpoints"].items()}
    else:
        if not LUNE:
            print("lune não encontrado em tools/bin/lune-*/", file=sys.stderr)
            return 1
        summary = summarize(simulate(args.players, args.hours, args.jobs))
        long_summary = None
        if args.long_players > 0:
            long_summary = summarize(simulate(args.long_players, args.long_hours, args.jobs, ["H", "R"]))
    if args.json:
        with open(args.json, "w", encoding="utf-8") as f:
            json.dump({"main": summary, "long": long_summary}, f, indent=1)
    generated = tables(summary, args.players, int(args.hours), long_summary, args.long_hours, args.long_players)
    if os.path.exists(DOC):
        with open(DOC, encoding="utf-8") as f:
            doc = f.read()
        if BEGIN in doc and END in doc:
            doc = doc[: doc.index(BEGIN)] + generated + doc[doc.index(END) + len(END):]
        else:
            doc += "\n" + generated + "\n"
    else:
        doc = "# PLAYER AURAS — auditoria econômica\n\n" + generated + "\n"
    with open(DOC, "w", encoding="utf-8", newline="\n") as f:
        f.write(doc)
    print("ok:", DOC)
    return 0


if __name__ == "__main__":
    sys.exit(main())
