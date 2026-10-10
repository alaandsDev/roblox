# Simulador de Escudo

Simulator para Roblox no estilo "toque para ficar mais forte", versionado com [Rojo](https://rojo.space).

## O jogo

| Sistema | Como funciona |
|---|---|
| **TOQUE!** | Cada toque dá 🛡️ Armadura e XP. Também há Clique Automático grátis e o Autoclic OP (gamepass). |
| **Nível** | O XP sobe o nível, e cada nível dá +6% de armadura. |
| **Pista de paredes** | Se sua armadura for maior que a vida da parede, você atravessa e ganha 🏆 Vitórias. |
| **Escudos** | 12 escudos comprados com vitórias. Cada um dá mais armadura por toque e aparece no braço. |
| **Pets** | Ovos no hub de cada mundo (ProximityPrompt "Abrir"). Os pets seguem o jogador e dão +% de armadura. |
| **Fusão** | 5 pets iguais viram 1 pet **Dourado** (bônus x3). |
| **Auras** | Compradas com vitórias. Dão +% de vitórias e um efeito de partículas. |
| **Mundos** | Grama → Neve → Lava → Doce. Cada mundo tem paredes e prêmios maiores, além de ovos próprios. |
| **Melhorias** | Upgrades permanentes: +Armadura, +Vitórias, +Velocidade e +espaço de pet. |
| **Rebirth** | Zera armadura, vitórias e nível em troca de +50% de armadura para sempre. Você mantém escudos, pets e auras. |
| **Poções** | Armadura x2, Vitórias x2 e Sorte (mais pets raros), cada uma por 10 min. Vêm dos prêmios. |
| **Prêmios** | Recompensa diária (7 dias seguidos) e presentes por tempo jogado (1 a 60 min). |
| **Vitórias Automáticas** | Gamepass: dá as vitórias da melhor parede a cada 10 s. |
| **Boosts com Robux** | x2, x4 e x8 de armadura por 15 min (Developer Products). |
| **Rankings** | Placares globais de Renascimentos e Vitórias no hub do Mundo 1. |
| **Ganho offline** | Quem volta ao jogo ganha armadura pelo tempo que ficou fora (até 8 h). |
| **Tutorial** | 6 passos com recompensa. |

Toda a economia fica em `src/shared/Config.luau`.

## Estrutura

```
src/
  shared/
    Config.luau          balanceamento e listas (escudos, pets, ovos, mundos, auras...)
    Modelos.luau         usa os modelos da pasta ReplicatedStorage.Modelos
  server/
    main.server.luau     ações dos jogadores, compras, personagem, loop de vitórias automáticas
    Dados.luau           salvar/carregar, multiplicadores, recompensas, sorteio de ovos
    Mundo.luau           gera hub, ovos, pista e paredes de cada mundo
    Ranking.luau         placares globais
    Visual.server.luau   iluminação colorida
  client/
    main.client.luau     HUD: TOQUE!, nível, tutorial, menu, gamepasses
    UI.luau              helpers de interface
    Janelas/             Loja (escudos, auras, melhorias, rebirth), Pets (inventário, fusão, ovo), Mundos, Recompensas
    PetsVisual.client.luau  pets seguindo os jogadores
    Paredes.client.luau     libera a passagem nas paredes que você já consegue quebrar
```

## Como rodar

1. Instale o [Aftman](https://github.com/LPGhatguy/aftman) e rode `aftman install`.
2. No Roblox Studio, instale o plugin **Rojo**.
3. Rode `rojo serve` e clique em **Connect** no plugin.
4. Aperte **Play**.

No Studio, todos os gamepasses ficam liberados para teste (`Config.LiberarPassesNoStudio`).

### Configurações no Studio

- **Salvamento e rankings**: publique o jogo e ative *Game Settings > Security > Enable Studio Access to API Services*.
- **Gamepasses / produtos**: crie no Creator Hub e coloque os IDs em `Config.Gamepasses` e `Config.Produtos`.
- **Iluminação**: em *Lighting*, coloque `Technology = Future`.

## Puxar do Git, gerar e publicar (Windows)

```
cd C:\Users\aland\Desktop\projects\roblox
git switch claude/nice-dirac-ubdorh
git pull origin claude/nice-dirac-ubdorh
git log -5 --oneline
python tools\build_place.py
.\build\SimuladorEscudo.rbxlx
python tools\publish_place.py
```

- `build_place.py` gera `build\SimuladorEscudo.rbxlx` (baixa o Rojo sozinho se precisar).
- Abrir o `.rbxlx` abre o jogo no Studio para testar.
- `publish_place.py` publica no Roblox. Antes da primeira vez, crie `publish.local.json` na raiz
  (instruções no topo do script). Esse arquivo tem sua chave secreta e **não vai para o Git**.

### Não perca o que você fez no Studio

O build é gerado a partir do Git, então o que você montar só no Studio some na próxima publicação.
Salve assim e faça commit:

- **Modelos** (pets, ovos, escudos): clique com o botão direito em `ReplicatedStorage > Modelos` →
  *Save to File...* → salve como `assets\Modelos.rbxm`.
- **Mapa/decoração**: agrupe tudo numa pasta `Mapa` no Workspace → *Save to File...* →
  `assets\Mapa.rbxm`.

O `build_place.py` coloca esses arquivos de volta no jogo automaticamente.

## Usando itens grátis da Store (Toolbox)

O jogo funciona sem nenhum modelo, usando bolinhas e discos coloridos no lugar. Para trocar pelos itens da Store:

**Jeito automático:** abra `tools/BuscarModelos.lua`, copie tudo, cole na **Command Bar** do Studio
(*View > Command Bar*) e aperte Enter. O script pesquisa cada pet, ovo e escudo na Store, coloca na
pasta certa com o nome certo e apaga os scripts dos modelos. Depois, confira e troque o que não gostar.

**Jeito manual:**

1. No Studio, crie em **ReplicatedStorage** uma pasta `Modelos` com três subpastas: `Pets`, `Ovos` e `Escudos`.
2. Na Toolbox (*View > Toolbox > Creator Store*), pegue os modelos grátis. Exemplos de busca: "egg", "pet pack", "shield".
3. Arraste cada modelo para a subpasta certa e **renomeie com o Id do Config**:
   - Pets: `Cachorro`, `Gato`, `Coelho`, `Raposa`, `Panda`, `Unicornio`, `Pinguim`, `Urso`, `Yeti`, `Fenix`, `Salamandra`, `Golem`, `Dragao`, `Ursinho`, `Cupcake`, `Arcoiris`
   - Ovos: `Basico`, `Floresta`, `Neve`, `Lava`, `Doce`
   - Escudos: `Madeira`, `Pedra`, `Ferro`, `Cavaleiro`, `Dragao`, `Ouro`, `Diamante`, `Fogo`, `Cosmico`, `Gelo`, `Magma`, `Galaxia`
4. O tamanho é ajustado sozinho. Os modelos não precisam estar na mesma escala.

> ⚠️ **Segurança:** o código apaga automaticamente qualquer script que venha dentro desses modelos
> (backdoors são comuns em itens grátis). Mesmo assim, não coloque modelos da Toolbox direto no
> Workspace sem checar: procure por `require(<número>)`, `getfenv` e `loadstring`.

Para adicionar um pet, ovo ou escudo novo, inclua uma entrada no `Config.luau` com um Id novo
e coloque um modelo com esse nome na pasta.

## Visual "cubinhos" (studs)

O chão quadriculado usa o estilo **Studs** nativo do Roblox (`Material = Plastic`, `TopSurface = Studs`),
alternando duas cores entre peças vizinhas. As cores de cada mundo ficam em `Config.Mundos[n].Cores`.
