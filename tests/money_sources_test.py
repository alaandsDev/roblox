#!/usr/bin/env python3
"""Ranking Magnata: TODA entrada de dinheiro do servidor tem origem classificada.

Lê src/server: cada EconomyService.AddMoney(..., "Origem") precisa estar em
src/shared/Config/MoneySourceConfig.luau (fonte ÚNICA usada pelo jogo para o
LifetimeMoneyGenerated) com uma classe válida, e o saldo (Money) só pode subir por
EconomyService.AddMoney (nada de PlayerDataService.Increment(..., "Money") espalhado). O
protótipo da auditoria (tools/sim/MoneyLedger.luau) precisa concordar com a config.
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SERVER = os.path.join(ROOT, "src", "server")
LEDGER = os.path.join(ROOT, "tools", "sim", "MoneyLedger.luau")
CONFIG = os.path.join(ROOT, "src", "shared", "Config", "MoneySourceConfig.luau")
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
prototype = dict(re.findall(r'^\s*([A-Za-z]+)\s*=\s*"([A-Z]+)"', block, re.M))
with open(CONFIG, encoding="utf-8") as f:
    config = f.read()
cblock = config[config.index("Sources = {"): config.index("}", config.index("Sources = {"))]
sources = dict(re.findall(r'^\s*([A-Za-z]+)\s*=\s*"([A-Z]+)"', cblock, re.M))
check(all(prototype.get(k) == v for k, v in sources.items()), "MoneySourceConfig (jogo) == protótipo da auditoria em todas as origens")
check(sources.get("Collector") == "GENERATED" and sources.get("Offline") == "GENERATED" and sources.get("Product") == "OTHER" and sources.get("Dev") == "OTHER" and sources.get("AutoSell") == "RECYCLED", "Collector/Offline contam; Product/Dev/AutoSell não")
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
