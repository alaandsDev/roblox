# roblox

Simulator para Roblox versionado com [Rojo](https://rojo.space).

## O jogo

- **Clicar** gera ⚡ Energia, até o limite da mochila.
- **Vender** troca a energia por 💰 Moedas.
- **Upgrades** (Força e Mochila) custam moedas e ficam mais caros a cada compra.
- **Rebirth** zera moedas e upgrades em troca de +50% de multiplicador permanente.
- O progresso é salvo com DataStore (a cada 60 s e quando o jogador sai).

Toda a economia (preços, bônus, cooldown) fica em `src/shared/Config.luau`.

> Para o salvamento funcionar no Studio, publique o jogo e ative
> *Game Settings > Security > Enable Studio Access to API Services*.

## Estrutura

| Pasta         | Vai para no Roblox                              | Uso                                 |
|---------------|-------------------------------------------------|-------------------------------------|
| `src/server`  | `ServerScriptService.Server`                    | Scripts do servidor (`.server.luau`) |
| `src/client`  | `StarterPlayer.StarterPlayerScripts.Client`     | Scripts do cliente (`.client.luau`)  |
| `src/shared`  | `ReplicatedStorage.Shared`                      | ModuleScripts usados pelos dois     |

## Como usar

1. Instale o [Aftman](https://github.com/LPGhatguy/aftman) e rode `aftman install` (instala o Rojo na versão do `aftman.toml`).
2. No Roblox Studio, instale o plugin do Rojo (Toolbox > Plugins > "Rojo").
3. Na pasta do projeto, rode:
   ```sh
   rojo serve
   ```
4. No Studio, abra o plugin Rojo e clique em **Connect**. Tudo que você editar em `src/` aparece no Studio na hora.

Para gerar um arquivo do jogo: `rojo build -o jogo.rbxl`.

## Usando um template / jogo pronto

Mapas, modelos e partes visuais ficam melhor no próprio Studio (salvos no Roblox).
Os **scripts** do template podem ser trazidos para cá: copie o código de cada
Script/ModuleScript para um arquivo em `src/` seguindo a tabela acima.

> ⚠️ Antes de usar scripts de modelos gratuitos, procure por `require(<número>)`,
> `getfenv` e `loadstring` — são sinais comuns de backdoor.
