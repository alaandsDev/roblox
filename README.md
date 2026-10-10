# Simulador de Escudo

Simulator para Roblox no estilo "toque para ficar mais forte", versionado com [Rojo](https://rojo.space).

## O jogo

- **TOQUE!**: cada toque dá 🛡️ Armadura (o valor depende do escudo equipado, do nível e dos rebirths) e XP.
- **Nível**: o XP sobe o nível, e cada nível dá +6% de armadura.
- **Pista de paredes**: corra pela pista. Se sua armadura for maior que a vida da parede, você atravessa e ganha 🏆 Vitórias.
- **Escudos**: comprados com vitórias. Cada um dá mais armadura por toque.
- **Rebirth**: a partir do nível 10, zera armadura, vitórias e nível em troca de +50% permanente (você mantém os escudos).
- **Tutorial** em 6 passos, com recompensa em vitórias.
- **Clique automático** grátis, e o **Autoclic OP** (gamepass), que clica mais rápido.
- **Gamepasses**: x2 Armadura, x2 Vitórias, +15 Velocidade e Autoclic OP.
- **Ganho offline**: quem volta ao jogo ganha armadura pelo tempo que ficou fora (até 8 h).
- O progresso é salvo com DataStore.

Toda a economia (preços, escudos, paredes, bônus e tutorial) fica em `src/shared/Config.luau`.

## Estrutura

| Arquivo                          | O que faz                                                 |
|----------------------------------|-----------------------------------------------------------|
| `src/shared/Config.luau`         | Balanceamento e listas (escudos, paredes, tutorial, passes) |
| `src/server/main.server.luau`    | Dados do jogador, salvamento, cliques, compras, rebirth    |
| `src/server/Pista.luau`          | Gera a pista quadriculada e as paredes                     |
| `src/server/Visual.server.luau`  | Iluminação colorida (saturação, bloom)                     |
| `src/client/main.client.luau`    | Toda a interface                                           |
| `src/client/Paredes.client.luau` | Libera a passagem nas paredes que você já consegue quebrar  |

## Como rodar

1. Instale o [Aftman](https://github.com/LPGhatguy/aftman) e rode `aftman install`.
2. No Roblox Studio, instale o plugin **Rojo**.
3. Rode `rojo serve` e clique em **Connect** no plugin.
4. Aperte **Play**. A pista aparece na frente do spawn.

### Configurações no Studio

- **Salvamento**: publique o jogo e ative *Game Settings > Security > Enable Studio Access to API Services*.
- **Gamepasses**: crie os passes no Creator Hub e coloque os IDs em `Config.Gamepasses`.
- **Iluminação**: em *Lighting*, coloque `Technology = Future`, porque essa opção não pode ser mudada por script.

## Visual "cubinhos" (studs)

O chão quadriculado usa o estilo **Studs** nativo do Roblox. Para fazer o mesmo nas suas peças:
selecione a Part, coloque `Material = Plastic` e, em *Surface*, mude `TopSurface` para `Studs`.
Para ter o quadriculado, alterne duas cores parecidas entre peças vizinhas.
As cores vivas vêm do `ColorCorrectionEffect` com saturação alta (`Visual.server.luau`).

> ⚠️ Antes de usar scripts de modelos gratuitos da Toolbox, procure por `require(<número>)`,
> `getfenv` e `loadstring`, que são sinais comuns de backdoor.
