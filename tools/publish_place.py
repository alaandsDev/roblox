"""Publica build/SimuladorEscudo.rbxlx no Roblox usando a Open Cloud API.

Uso:  python tools\\publish_place.py

Configuração (uma vez): crie publish.local.json na raiz do projeto (ele NÃO vai pro Git):
    {
      "api_key": "SUA_CHAVE",
      "universe_id": 1234567890,
      "place_id": 9876543210
    }
Ou use as variáveis de ambiente ROBLOX_API_KEY, ROBLOX_UNIVERSE_ID e ROBLOX_PLACE_ID.

A chave é criada em https://create.roblox.com/dashboard/credentials com a permissão
"universe-places" > "write", liberada para a experiência do jogo.
"""

import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
ARQUIVO = RAIZ / "build" / "SimuladorEscudo.rbxlx"
CONFIG = RAIZ / "publish.local.json"


def carregar_config() -> dict:
    config = {}
    if CONFIG.exists():
        config = json.loads(CONFIG.read_text(encoding="utf-8"))
    config["api_key"] = os.environ.get("ROBLOX_API_KEY", config.get("api_key"))
    config["universe_id"] = os.environ.get("ROBLOX_UNIVERSE_ID", config.get("universe_id"))
    config["place_id"] = os.environ.get("ROBLOX_PLACE_ID", config.get("place_id"))
    faltando = [k for k in ("api_key", "universe_id", "place_id") if not config.get(k)]
    if faltando:
        sys.exit(f"Faltando {', '.join(faltando)}. Veja as instruções no topo de tools/publish_place.py.")
    return config


def main() -> None:
    if not ARQUIVO.exists():
        sys.exit("Arquivo não encontrado. Rode antes: python tools\\build_place.py")
    config = carregar_config()

    url = (
        f"https://apis.roblox.com/universes/v1/{config['universe_id']}"
        f"/places/{config['place_id']}/versions?versionType=Published"
    )
    requisicao = urllib.request.Request(
        url,
        data=ARQUIVO.read_bytes(),
        method="POST",
        headers={"x-api-key": config["api_key"], "Content-Type": "application/xml"},
    )
    try:
        with urllib.request.urlopen(requisicao) as resposta:
            versao = json.loads(resposta.read()).get("versionNumber")
            print(f"Publicado! Versão {versao}.")
    except urllib.error.HTTPError as erro:
        sys.exit(f"Erro {erro.code}: {erro.read().decode(errors='replace')}")


if __name__ == "__main__":
    main()
