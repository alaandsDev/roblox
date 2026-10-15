#!/usr/bin/env python3
"""Ranking Magnata (auditoria): TODA entrada de dinheiro do servidor tem origem classificada.

Lê src/server: cada EconomyService.AddMoney(..., "Origem") precisa estar em
tools/sim/MoneyLedger.luau (MoneyLedger.Sources) com uma classe válida, e o saldo (Money) só
pode subir por EconomyService.AddMoney (nada de PlayerDataService.Increment(..., "Money")
espalhado). Assim nenhuma fonte nova escapa da classificação GENERATED/TRANSFER/REFUND/RECYCLED/
OTHER antes da implementação do LifetimeMoneyGenerated.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SERVER = os.path.join(ROOT, "src", "server")
LEDGER = os.path.join(ROOT, "tools", "sim", "MoneyLedger.luau")
KINDS = {"GENERATED", "TRANSFER", "REFUND", "RECYCLED", "OTHER"}

falhas = 0


def check(ok, msg):
    global falhas
    print(("  ✓ " if ok else "  ✗ ") + msg)
    if not ok:
        falhas += 1


with open(LEDGER, encoding="utf-8") as f:
    ledger = f.read()
block = ledger[ledger.index("MoneyLedger.Sources = {"): ledger.index("\n}\n", ledger.index("MoneyLedger.Sources = {"))]
sources = dict(re.findall(r'^\s*([A-Za-z]+)\s*=\s*"([A-Z]+)"', block, re.M))
check(len(sources) >= 10, f"protótipo tem {len(sources)} origens classificadas")
check(all(kind in KINDS for kind in sources.values()), "toda classe é GENERATED/TRANSFER/REFUND/RECYCLED/OTHER")

origins = {}
increments = []
for folder, _, files in os.walk(SERVER):
    for name in files:
        if not name.endswith(".luau"):
            continue
        path = os.path.join(folder, name)
        with open(path, encoding="utf-8") as f:
            text = f.read()
        rel = os.path.relpath(path, ROOT)
        for m in re.finditer(r'EconomyService\.AddMoney\([^)]*?,\s*"([A-Za-z]+)"\s*\)', text):
            origins.setdefault(m.group(1), []).append(rel)
        for m in re.finditer(r'Increment\([^)]*"Money"', text):
            increments.append(rel)

check(len(origins) >= 8, f"{len(origins)} origens reais encontradas no servidor: {', '.join(sorted(origins))}")
for origin, files in sorted(origins.items()):
    check(origin in sources, f"origem \"{origin}\" ({files[0]}) classificada como {sources.get(origin, '???')}")
check(increments == ["src/server/Services/EconomyService.luau"] or all(p.endswith("EconomyService.luau") for p in increments),
      "Money só sobe por EconomyService.AddMoney (porta única) — " + (", ".join(sorted(set(increments))) or "nenhum Increment"))
check(sources.get("Trade") == "TRANSFER" and sources.get("Sell") == "RECYCLED" and sources.get("Refund") == "REFUND", "troca/venda/reembolso nunca contam como gerado")

print(f"[Magnata: origens de dinheiro classificadas] {'OK' if falhas == 0 else f'{falhas} falha(s)'}")
sys.exit(1 if falhas else 0)
