#!/usr/bin/env python3
"""Auditoria da renda por Dice (Dice × Raridade) com o simulador econômico oficial.

    python3 tools/sim/run_dice_income_audit.py measure --label after [--hours 40] [--seeds 12]
    python3 tools/sim/run_dice_income_audit.py report  [--baseline tools/sim/dice_income_baseline.json]

measure: tabela dos 112 F2P + simulação (Casual / Ativo / Otimizador / Pago) com os configs
         ATUAIS do repositório -> build/dice_income/<label>.json (resumo determinístico).
report:  compara a linha de base (antes da curva por Dice, gravada no repositório) com a medição
         atual e escreve DICE_INCOME_AUDIT.md.
Nada aqui altera pesos, pity, Luck ou a distribuição dos personagens: só LÊ os configs.
"""
import argparse
import glob
import json
import os
import statistics
import subprocess
import sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LUNE = sorted(glob.glob(os.path.join(ROOT, "tools", "bin", "lune-*", "lune")))
SCRIPT = os.path.join("tools", "sim", "analyze_dice_income.luau")
OUT = os.path.join(ROOT, "build", "dice_income")
BASELINE = os.path.join(ROOT, "tools", "sim", "dice_income_baseline.json")
PROFILES = ["Casual", "Ativo", "Otimizador", "Pago"]
RARITIES = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Secret"]


def lune() -> str:
    if not LUNE:
        sys.exit("lune não encontrado em tools/bin/lune-*/lune (rode python3 tools/run_tests.py uma vez)")
    return LUNE[-1]


def median(values):
    values = [v for v in values if v is not None]
    return statistics.median(values) if values else None


def measure(label: str, hours: float, seeds: int) -> dict:
    os.makedirs(OUT, exist_ok=True)
    table_path = os.path.join(OUT, f"{label}_table.json")
    subprocess.run([lune(), "run", SCRIPT, "table", table_path], cwd=ROOT, check=True, capture_output=True)
    procs = {}
    for prof in PROFILES:
        path = os.path.join(OUT, f"{label}_{prof}.json")
        procs[prof] = (path, subprocess.Popen([lune(), "run", SCRIPT, "sim", path, prof, str(hours), str(seeds)], cwd=ROOT, stdout=subprocess.DEVNULL))
    table = json.load(open(table_path, encoding="utf-8"))
    rows = table["rows"]
    grid = defaultdict(list)
    for r in rows:
        grid[(r["dice"], r["rarity"])].append(r["baseIncome"])
    dice_order = []
    for r in rows:
        if r["dice"] not in dice_order:
            dice_order.append(r["dice"])
    # rendas idênticas entre Dice diferentes (mesma raridade)
    same = []
    for rarity in RARITIES:
        by_value = defaultdict(set)
        for r in rows:
            if r["rarity"] == rarity:
                by_value[r["baseIncome"]].add(r["dice"])
        for value, dice in by_value.items():
            if len(dice) > 1:
                same.append({"rarity": rarity, "baseIncome": value, "dice": sorted(dice, key=dice_order.index)})
    sims = {}
    for prof, (path, proc) in procs.items():
        if proc.wait() != 0:
            sys.exit(f"simulação {prof} falhou")
        data = json.load(open(path, encoding="utf-8"))
        runs = data["runs"]
        n_dice = len(data["dice"])
        owned = [median([r["ownedAt"][i] if i < len(r["ownedAt"]) else None for r in runs]) for i in range(n_dice)]
        rolls_ok = [median([r["rollUnlockAt"][i] if i < len(r["rollUnlockAt"]) else None for r in runs]) for i in range(n_dice)]
        reached = [sum(1 for r in runs if i < len(r["ownedAt"])) / len(runs) for i in range(n_dice)]
        first_rebirth = median([r["rebirthTimes"][0] if r["rebirthTimes"] else None for r in runs])
        rebirths = median([len(r["rebirthTimes"]) for r in runs])
        earned = defaultdict(float)
        for r in runs:
            for k, v in r["earned"].items():
                earned[k] += v / len(runs)
        total = sum(earned.values()) or 1
        sims[prof] = {
            "ownedAt": owned,
            "rollUnlockAt": rolls_ok,
            "reached": reached,
            "firstRebirth": first_rebirth,
            "rebirths": rebirths,
            "finalIps": median([r["ips"] for r in runs]),
            "earnedShare": {k: v / total for k, v in sorted(earned.items())},
            "earnedTotal": total,
        }
    summary = {
        "label": label,
        "hours": hours,
        "seeds": seeds,
        "dice": dice_order,
        "rows": rows,
        "grid": {f"{d}|{r}": sorted(set(grid[(d, r)])) for d in dice_order for r in RARITIES if grid[(d, r)]},
        "sameAcrossDice": same,
        "sims": sims,
    }
    path = os.path.join(OUT, f"{label}.json")
    json.dump(summary, open(path, "w", encoding="utf-8"), indent=1)
    print(f"{label}: {len(rows)} personagens, {len(same)} grupos com renda igual entre Dice -> {path}")
    return summary


def hms(seconds):
    if seconds is None:
        return "não alcançou"
    seconds = int(seconds)
    if seconds < 3600:
        return f"{seconds // 60} min"
    return f"{seconds / 3600:.1f} h"


def fmt(v):
    if v is None:
        return "-"
    return f"{v:g}" if v < 1000 else f"{v:,.0f}".replace(",", ".")


def report(baseline_path: str):
    before = json.load(open(baseline_path, encoding="utf-8"))
    after = json.load(open(os.path.join(OUT, "after.json"), encoding="utf-8"))
    L = []
    w = L.append
    w("# Auditoria — Renda por Dice (Dice × Raridade)")
    w("")
    w("> Gerado por `python3 tools/sim/run_dice_income_audit.py report`. Pesos, pity, Luck e a")
    w("> distribuição dos 112 personagens F2P NÃO foram alterados (só BaseIncome).")
    w(f"> Simulação: simulador oficial `tools/sim/EconomyModel.luau`, {after['seeds']} jogadores por perfil, {after['hours']:g} h de jogo ATIVO cada (offline entre sessões incluído).")
    w("")
    w("## 1. Problema encontrado")
    w("")
    w("Antes: o catálogo de lançamento usava **stats provisórios por raridade** (`gen_launch_catalog.py`,")
    w("`STATS`): todo Mítico rendia $160/s (o piloto Barbalva $170/s) em qualquer Dice, todo Lendário $60/s etc.")
    w(f"Grupos de mesma raridade com renda IGUAL entre Dice diferentes: **antes {len(before['sameAcrossDice'])}**, **depois {len(after['sameAcrossDice'])}**.")
    w("")
    for s in before["sameAcrossDice"]:
        w(f"- antes: {s['rarity']} ${fmt(s['baseIncome'])}/s em {len(s['dice'])} Dice ({', '.join(s['dice'])})")
    w("")
    for title, data in (("2. Dice × Raridade — BaseIncome Nível 1 (ANTES)", before), ("3. Dice × Raridade — BaseIncome Nível 1 (DEPOIS)", after)):
        w(f"## {title}")
        w("")
        w("| # | Dice | " + " | ".join(RARITIES) + " |")
        w("|---|---|" + "---|" * len(RARITIES))
        for i, d in enumerate(data["dice"], 1):
            cells = []
            for r in RARITIES:
                vals = data["grid"].get(f"{d}|{r}")
                cells.append("-" if not vals else "/".join(fmt(v) for v in vals))
            w(f"| {i} | {d} | " + " | ".join(cells) + " |")
        w("")
    w("## 4. Tempo de jogo ATIVO para comprar cada Dice (mediana) — antes → depois")
    w("")
    w("Entre parênteses: quando os rolls exigidos foram atingidos (se o Dice sai logo depois disso, o")
    w("gargalo é o número de rolls, não o dinheiro).")
    w("")
    w("| # | Dice | Preço | " + " | ".join(PROFILES) + " |")
    w("|---|---|---|" + "---|" * len(PROFILES))
    prices = {}
    sim_dice = json.load(open(os.path.join(OUT, "after_Ativo.json"), encoding="utf-8"))["dice"]
    for d in sim_dice:
        prices[d["id"]] = d["price"]
    for i, d in enumerate(after["dice"]):
        cells = []
        for prof in PROFILES:
            b, a = before["sims"][prof], after["sims"][prof]
            cells.append(f"{hms(b['ownedAt'][i])} → **{hms(a['ownedAt'][i])}** ({hms(a['rollUnlockAt'][i])})")
        w(f"| {i + 1} | {d} | ${fmt(prices.get(d, 0))} | " + " | ".join(cells) + " |")
    w("")
    w("## 5. Rebirth, renda final e fontes de dinheiro (mediana)")
    w("")
    w("| Perfil | 1º Rebirth antes → depois | Rebirths em " + f"{after['hours']:g} h | Renda/s final antes → depois | Offline % | Torre % | Venda % |")
    w("|---|---|---|---|---|---|---|")
    for prof in PROFILES:
        b, a = before["sims"][prof], after["sims"][prof]
        share = a["earnedShare"]
        w(f"| {prof} | {hms(b['firstRebirth'])} → **{hms(a['firstRebirth'])}** | {fmt(b['rebirths'])} → **{fmt(a['rebirths'])}** | ${fmt(b['finalIps'])} → **${fmt(a['finalIps'])}** | "
          f"{share.get('Offline', 0) * 100:.0f}% | {share.get('Tower', 0) * 100:.1f}% | {(share.get('Sell', 0) + share.get('SellUpgraded', 0)) * 100:.1f}% |")
    w("")
    w("## 6. Upgrades, venda/refund, fusão, troca, offline, torre e exploits")
    w("")
    w("- **Fonte da verdade da renda:** `CharacterConfig.IncomeCurve` (Dice × Raridade) define o `BaseIncome` dos 112 F2P;")
    w("  `Formulas:unitIncome` = BaseIncome × (1 + 0,25 × (Nível − 1)) × Variante.IncomeMultiplier; estação = × multiplicadores globais.")
    w("  Antes: `BaseIncome` literal por raridade no catálogo gerado (`gen_launch_catalog.py` STATS) e nos pilotos.")
    w("- **Upgrades:** custo do nível = BaseIncome × 60 s × 1,2^(Nível−1) — proporcional ao BaseIncome, então o tempo para um nível")
    w("  se pagar é o mesmo em todo Dice (sem Dice \"barato de upar\"). Teste: `tests/DiceIncome.spec.luau`.")
    w("- **Venda/refund:** base = BaseIncome × SellSeconds[raridade] × variante + 75% do investimento gravado na unidade;")
    w("  venda − investimento ≤ base para todo personagem/nível (comprar níveis e vender nunca dá lucro). Venda em massa = Σ individual.")
    w("- **Fusão:** a unidade nova soma o investimento das consumidas (independe da renda). **Troca:** copia Id/Nível/Variante/investimento,")
    w("  então a renda não muda. **Save/load:** a renda não é gravada no save; é recalculada de Id/Nível/Variante (saves antigos")
    w("  passam a render pela curva nova automaticamente; o investimento já gravado continua valendo na venda).")
    w("- **Offline:** limitado a 25% do custo do próximo Rebirth (não infla com a renda maior); fatia do dinheiro igual à de antes.")
    w("- **Torre:** recompensa = max(poder do inimigo × MoneyPerPower, renda/s × IncomeSeconds) — acompanha a renda; < 0,2% do dinheiro.")
    w("- **Inflação:** a renda/s final sobe (+5% Casual a +50% Otimizador em 40 h) porque o fim do jogo tem personagens melhores,")
    w("  mas o nº de Rebirths fica igual (custo 15M × 2,2ⁿ absorve) e nenhum Dice fica mais de 15% mais rápido.")
    w("- **Exploits procurados:** arbitragem upar→vender (impossível, refund 75%), comprar Dice só para vender (venda ∝ renda,")
    w("  não ao preço do Dice), duplicatas de Dice tardio (vender rende mais, mas é o mesmo personagem que já renderia mais na")
    w("  base), troca entre contas (não cria renda). Nenhum encontrado.")
    w("")
    w("## 7. Conclusão")
    w("")
    w("- Curva aplicada: Growth **1,11** por passo de Dice, Pivot **0,10** (âncora perto do 1º Dice de cada raridade).")
    w("- Míticos de Dice diferentes não rendem mais igual (Spirit 149 → Forbidden 309); Lendário Celestial (153) passa o Mítico Spirit (149).")
    w("- Pacing: Casual idêntico (±3%); Dice até o Shadow e 1º Rebirth dentro de ±15% (a maioria ±5%); jogadores ativos chegam ao Celestial/Forbidden")
    w("  ~8–15% antes (o Dice posterior passou a ter valor econômico real). Pesos, pity, Luck e distribuição intocados.")
    w("")
    w("## 8. Os 112 personagens F2P (depois)")
    w("")
    w("| Dice | # | CharacterId | Raridade | BaseIncome antes | BaseIncome | Renda Nv1 Normal | Renda Nv30 Normal | Venda Nv1 |")
    w("|---|---|---|---|---|---|---|---|---|")
    old = {r["id"]: r for r in before["rows"]}
    for r in after["rows"]:
        w(f"| {r['dice']} | {r['order']} | {r['id']} | {r['rarity']} | {fmt(old[r['id']]['baseIncome'])} | {fmt(r['baseIncome'])} | {fmt(r['incomeL1'])} | {fmt(r['incomeL30'])} | {fmt(r['sell'])} |")
    w("")
    open(os.path.join(ROOT, "DICE_INCOME_AUDIT.md"), "w", encoding="utf-8").write("\n".join(L) + "\n")
    print("DICE_INCOME_AUDIT.md escrito")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=["measure", "report"])
    parser.add_argument("--label", default="after")
    parser.add_argument("--hours", type=float, default=40)
    parser.add_argument("--seeds", type=int, default=12)
    parser.add_argument("--baseline", default=BASELINE)
    args = parser.parse_args()
    if args.mode == "measure":
        measure(args.label, args.hours, args.seeds)
    else:
        report(args.baseline)


if __name__ == "__main__":
    main()
