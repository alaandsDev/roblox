#!/usr/bin/env python3
"""Roda a auditoria econômica em paralelo e gera ECONOMY_BALANCE_ANALYSIS.md.

    python3 tools/sim/run_economy_analysis.py [--scale 1] [--jobs N] [--report-only DIR]

Cada worker (Lune) simula uma fatia das tarefas (sementes fixas) e grava um JSON; o passo
"report" junta tudo e escreve o relatório. Determinístico: mesma escala = mesmo relatório.
"""
import argparse
import glob
import os
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
LUNE = sorted(glob.glob(os.path.join(ROOT, "tools", "bin", "lune-*", "lune")))
SCRIPT = os.path.join("tools", "sim", "analyze_economy.luau")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--scale", type=float, default=1.0, help="multiplica o nº de jogadores (0.01 = rápido)")
    parser.add_argument("--jobs", type=int, default=os.cpu_count() or 2)
    parser.add_argument("--report-only", help="pasta com JSONs já gerados")
    args = parser.parse_args()
    if not LUNE:
        print("lune não encontrado em tools/bin/lune-*/lune", file=sys.stderr)
        return 1
    lune = LUNE[-1]
    work = args.report_only or tempfile.mkdtemp(prefix="economy_")
    if not args.report_only:
        procs = []
        for shard in range(args.jobs):
            out = os.path.join(work, f"shard{shard:02d}.json")
            procs.append(subprocess.Popen([lune, "run", SCRIPT, "worker", str(shard), str(args.jobs), out, str(args.scale)], cwd=ROOT))
        failed = [p.wait() for p in procs]
        if any(failed):
            print("worker falhou", failed, file=sys.stderr)
            return 1
    return subprocess.call([lune, "run", SCRIPT, "report", work, str(args.scale)], cwd=ROOT)


if __name__ == "__main__":
    sys.exit(main())
