# DICE BALANCE ANALYSIS — Roll Legends (PROPOSTA, não aplicada)

Gerado por `lune run tools/sim/analyze_dice_balance.luau` com o **mesmo `DiceCore` do servidor**.
Pesos propostos em `tools/sim/DiceBalanceProposal.luau`. **Produção inalterada**: `DiceConfig`,
Luck, pity, preços e unlocks continuam como no commit 4a69c25 até a aprovação.

- Pools (personagens por Dice) **não mudam**; só os `RarityWeights`.
- Cadência: Normal = 1 s/roll (1 roll/s) · Roll Rápido = 0.5 s/roll (2 rolls/s). Tempos = expectativa matemática, não garantia.
- **Expected Rarity Value (ERV)** = Σ P(raridade) × Score — ferramenta de análise, não é gameplay. Score: Comum 1 · Incomum 3 · Raro 10 · Épico 30 · Lendário 100 · Mítico 400 · Divino 2000 · Secreto 15000.
- Luck nos cenários: 1,0x · Luck do próprio Dice (LuckMultiplier, sem upgrades) · máximo F2P (upgrades/renascimentos/perks no máximo + boost diário 2x) · máximo com monetização (+ VIP + Sorte x2). Fórmula atual: retornos decrescentes (LuckSoftCap 10) e `LuckExponent` por raridade.

## 1. Tabela proposta dos 16 Dice

| # | Dice | Unlock (rolls · Dice anterior) | Preço | Pool | Pesos propostos (Luck 1) | Luck do Dice | ERV atual | ERV proposto |
|---:|---|---|---:|---|---|---:|---:|---:|
| 1 | **Starter** | 0 · — | 0 | C4 U2 R1 E1 | C 62.00% · U 26.00% · R 9.00% · E 3.00% | 1.00x | 4.1 | **3.2** |
| 2 | **Lucky** | 50 · Starter | 2.5k | C2 U2 R2 E1 | C 55.00% · U 28.00% · R 12.00% · E 5.00% | 1.25x | 4.1 | **4.1** |
| 3 | **Rampart** | 125 · Lucky | 10k | C1 U2 R2 E2 | C 45.00% · U 32.00% · R 16.00% · E 7.00% | 1.40x | 4.1 | **5.1** |
| 4 | **Flame** | 300 · Rampart | 40k | U2 R2 E1 L1 | U 60.00% · R 28.00% · E 11.00% · L 1.00% | 1.60x | 12.4 | **8.9** |
| 5 | **Shinobi** | 425 · Flame | 75k | C2 U2 R2 E2 | C 20.00% · U 32.00% · R 30.00% · E 18.00% | 1.70x | 4.1 | **9.6** |
| 6 | **Blade** | 550 · Shinobi | 125k | U2 R3 E2 L1 | U 50.00% · R 32.00% · E 16.00% · L 2.00% | 1.80x | 12.4 | **11.5** |
| 7 | **Fighter** | 775 · Blade | 225k | U3 R2 E1 L1 | U 45.00% · R 33.00% · E 19.00% · L 3.00% | 1.90x | 12.4 | **13.3** |
| 8 | **Storm** | 1000 · Fighter | 400k | R3 E2 L2 | R 60.00% · E 32.00% · L 8.00% | 2.00x | 24.7 | **23.6** |
| 9 | **Spirit** | 1500 · Storm | 750k | R1 E3 L2 M1 | R 50.00% · E 36.00% · L 13.00% · M 1.00% | 2.20x | 39.0 | **32.8** |
| 10 | **Arcane** | 2000 · Spirit | 1.4M | R3 E3 L1 M1 | R 45.00% · E 37.00% · L 16.00% · M 2.00% | 2.35x | 39.0 | **39.6** |
| 11 | **Shadow** | 2500 · Arcane | 2.6M | E3 L2 M2 | E 65.00% · L 30.00% · M 5.00% | 2.55x | 83.9 | **69.5** |
| 12 | **Void** | 3000 · Shadow | 5M | E2 L2 M1 D1 | E 55.00% · L 36.00% · M 8.70% · D 0.3000% | 2.75x | 132.1 | **93.3** |
| 13 | **Awakened** | 4500 · Void | 12.5M | L3 M3 | L 85.00% · M 15.00% | 3.10x | 181.8 | **145.0** |
| 14 | **Colossus** | 6000 · Awakened | 30M | E2 L2 M2 | E 25.00% · L 48.00% · M 27.00% | 3.50x | 83.9 | **163.5** |
| 15 | **Celestial** | 8000 · Colossus | 75M | L2 M2 D3 | L 63.50% · M 35.50% · D 1.00% | 4.00x | 305.1 | **225.5** |
| 16 | **Forbidden** | 12000 · Celestial | 750M | M1 D3 S3 | M 98.50% · D 1.50% · S 0.00450% | 4.00x | 1450.0 | **424.7** |

Pool: quantidade de personagens por raridade (C/U/R/E/L/M/D/S). ERV com Luck 1.

## 2. Comparação atual × proposta (Luck 1)

| Dice | Atual (normalização da tabela global) | Proposta |
|---|---|---|
| Starter | C 56.70% · U 25.77% · R 12.37% · E 5.15% | C 62.00% · U 26.00% · R 9.00% · E 3.00% |
| Lucky | C 56.70% · U 25.77% · R 12.37% · E 5.15% | C 55.00% · U 28.00% · R 12.00% · E 5.00% |
| Rampart | C 56.70% · U 25.77% · R 12.37% · E 5.15% | C 45.00% · U 32.00% · R 16.00% · E 7.00% |
| Flame | U 56.82% · R 27.27% · E 11.36% · L 4.55% | U 60.00% · R 28.00% · E 11.00% · L 1.00% |
| Shinobi | C 56.70% · U 25.77% · R 12.37% · E 5.15% | C 20.00% · U 32.00% · R 30.00% · E 18.00% |
| Blade | U 56.82% · R 27.27% · E 11.36% · L 4.55% | U 50.00% · R 32.00% · E 16.00% · L 2.00% |
| Fighter | U 56.82% · R 27.27% · E 11.36% · L 4.55% | U 45.00% · R 33.00% · E 19.00% · L 3.00% |
| Storm | R 63.16% · E 26.32% · L 10.53% | R 60.00% · E 32.00% · L 8.00% |
| Spirit | R 60.76% · E 25.32% · L 10.13% · M 3.80% | R 50.00% · E 36.00% · L 13.00% · M 1.00% |
| Arcane | R 60.76% · E 25.32% · L 10.13% · M 3.80% | R 45.00% · E 37.00% · L 16.00% · M 2.00% |
| Shadow | E 64.52% · L 25.81% · M 9.68% | E 65.00% · L 30.00% · M 5.00% |
| Void | E 62.89% · L 25.16% · M 9.43% · D 2.52% | E 55.00% · L 36.00% · M 8.70% · D 0.3000% |
| Awakened | L 72.73% · M 27.27% | L 85.00% · M 15.00% |
| Colossus | E 64.52% · L 25.81% · M 9.68% | E 25.00% · L 48.00% · M 27.00% |
| Celestial | L 67.80% · M 25.42% · D 6.78% | L 63.50% · M 35.50% · D 1.00% |
| Forbidden | M 75.00% · D 20.00% · S 5.00% | M 98.50% · D 1.50% · S 0.00450% |

## 3. Regressões

**Atual (produção):**

- Lucky (#2): ERV 4.1 ≤ anterior 4.1
- Rampart (#3): ERV 4.1 ≤ anterior 4.1
- Shinobi (#5): ERV 4.1 ≤ anterior 12.4
- Fighter (#7): ERV 12.4 ≤ anterior 12.4
- Arcane (#10): ERV 39.0 ≤ anterior 39.0
- Colossus (#14): ERV 83.9 ≤ anterior 181.8

**Proposta:** nenhuma — ERV estritamente crescente do #1 ao #16.

**Limitações estruturais dos pools (sinalizadas, NÃO corrigidas — nenhum personagem foi movido):**

- **Shinobi (#5) não tem Lendário**, e vem depois do Flame (#4), que tem. Pesos não resolvem a
  métrica "chance de Lendário" (0% no Shinobi). A proposta mantém o ERV crescente via Épico 18%,
  mas o jogador perde o Lendário ao avançar. Sugestão (não aplicada): trocar a ordem Shinobi ↔ Flame.
- **Colossus (#14) tem Épico e o Awakened (#13) não.** A proposta compensa com Mítico 27% no
  Colossus (ERV 163,5 > 145). Sugestão (não aplicada): trocar a ordem Colossus ↔ Awakened.
- **Forbidden tem 1 único Mítico**: com Mítico ~98,5%, esse personagem sai em quase todo roll do
  Forbidden (vira o "comum" do endgame). Inevitável com esse pool; o valor do Dice são os 3 Divinos
  e os 3 Secretos.

### Variante B (alternativa recomendada para a fase de unlocks — NÃO aplicada)

Mesmos pools; troca Shinobi ↔ Flame e Colossus ↔ Awakened. Nessa ordem o Shinobi e o Colossus
podem ser mais modestos (Épico 10% e Mítico 15%, em vez de 18% e 27%), e o jogador não "perde" o
Lendário (Shinobi) nem ganha Épico de volta no endgame (Colossus). Os outros 14 Dice iguais à proposta.

| # | Dice | Pesos (Luck 1) | ERV |
|---:|---|---|---:|
| 1 | Starter | C 62.00% · U 26.00% · R 9.00% · E 3.00% | 3.2 |
| 2 | Lucky | C 55.00% · U 28.00% · R 12.00% · E 5.00% | 4.1 |
| 3 | Rampart | C 45.00% · U 32.00% · R 16.00% · E 7.00% | 5.1 |
| 4 | Shinobi | C 35.00% · U 33.00% · R 22.00% · E 10.00% | 6.5 |
| 5 | Flame | U 60.00% · R 28.00% · E 11.00% · L 1.00% | 8.9 |
| 6 | Blade | U 50.00% · R 32.00% · E 16.00% · L 2.00% | 11.5 |
| 7 | Fighter | U 45.00% · R 33.00% · E 19.00% · L 3.00% | 13.3 |
| 8 | Storm | R 60.00% · E 32.00% · L 8.00% | 23.6 |
| 9 | Spirit | R 50.00% · E 36.00% · L 13.00% · M 1.00% | 32.8 |
| 10 | Arcane | R 45.00% · E 37.00% · L 16.00% · M 2.00% | 39.6 |
| 11 | Shadow | E 65.00% · L 30.00% · M 5.00% | 69.5 |
| 12 | Void | E 55.00% · L 36.00% · M 8.70% · D 0.3000% | 93.3 |
| 13 | Colossus | E 40.00% · L 45.00% · M 15.00% | 117.0 |
| 14 | Awakened | L 85.00% · M 15.00% | 145.0 |
| 15 | Celestial | L 63.50% · M 35.50% · D 1.00% | 225.5 |
| 16 | Forbidden | M 98.50% · D 1.50% · S 0.00450% | 424.7 |

Regressões na Variante B: nenhuma (ERV estritamente crescente).
A ordem de desbloqueio (Order/UnlockRequirement/preço por posição) só muda se você aprovar.

## 4. Impacto da Luck (proposta)

Chance da raridade MAIS ALTA de cada Dice nos 4 cenários de Luck (e 1 em X).

| Dice | Raridade topo | Luck 1,0x | Luck do Dice | Máx. F2P | Máx. monetização |
|---|---|---|---|---|---|
| Starter | Épico | 3.00% (1 em 33) @1.00x | 3.00% (1 em 33) @1.00x | 7.99% (1 em 13) @10.40x | 9.29% (1 em 11) @22.88x |
| Lucky | Épico | 5.00% (1 em 20) @1.00x | 5.64% (1 em 18) @1.25x | 13.00% (1 em 8) @13.00x | 14.61% (1 em 7) @28.60x |
| Rampart | Épico | 7.00% (1 em 14) @1.00x | 8.26% (1 em 12) @1.40x | 17.05% (1 em 6) @14.56x | 18.77% (1 em 5) @32.03x |
| Flame | Lendário | 1.00% (1 em 100) @1.00x | 1.20% (1 em 83) @1.60x | 2.13% (1 em 47) @16.64x | 2.29% (1 em 44) @36.61x |
| Shinobi | Épico | 18.00% (1 em 6) @1.00x | 21.58% (1 em 5) @1.70x | 33.86% (1 em 3) @17.68x | 35.71% (1 em 3) @38.90x |
| Blade | Lendário | 2.00% (1 em 50) @1.00x | 2.45% (1 em 41) @1.80x | 3.95% (1 em 25) @18.72x | 4.18% (1 em 24) @41.18x |
| Fighter | Lendário | 3.00% (1 em 33) @1.00x | 3.69% (1 em 27) @1.90x | 5.66% (1 em 18) @19.76x | 5.95% (1 em 17) @43.47x |
| Storm | Lendário | 8.00% (1 em 13) @1.00x | 9.05% (1 em 11) @2.00x | 11.51% (1 em 9) @20.80x | 11.85% (1 em 8) @45.76x |
| Spirit | Mítico | 1.00% (1 em 100) @1.00x | 1.21% (1 em 83) @2.20x | 1.67% (1 em 60) @22.88x | 1.73% (1 em 58) @50.34x |
| Arcane | Mítico | 2.00% (1 em 50) @1.00x | 2.42% (1 em 41) @2.35x | 3.24% (1 em 31) @24.44x | 3.36% (1 em 30) @53.77x |
| Shadow | Mítico | 5.00% (1 em 20) @1.00x | 5.57% (1 em 18) @2.55x | 6.52% (1 em 15) @26.52x | 6.64% (1 em 15) @58.34x |
| Void | Divino | 0.3000% (1 em 333) @1.00x | 0.3827% (1 em 261) @2.75x | 0.5271% (1 em 190) @28.60x | 0.5471% (1 em 183) @62.92x |
| Awakened | Mítico | 15.00% (1 em 7) @1.00x | 16.33% (1 em 6) @3.10x | 17.95% (1 em 6) @32.24x | 18.14% (1 em 6) @70.93x |
| Colossus | Mítico | 27.00% (1 em 4) @1.00x | 29.60% (1 em 3) @3.50x | 32.27% (1 em 3) @36.40x | 32.57% (1 em 3) @80.08x |
| Celestial | Divino | 1.00% (1 em 100) @1.00x | 1.29% (1 em 78) @4.00x | 1.58% (1 em 63) @41.60x | 1.62% (1 em 62) @91.52x |
| Forbidden | Secreto | 0.00450% (1 em 22.222) @1.00x | 0.00769% (1 em 13.010) @4.00x | 0.0120% (1 em 8.307) @41.60x | 0.0126% (1 em 7.932) @91.52x |

Leitura: a Luck atual tem retornos decrescentes (Luck efetiva nunca passa de ~11) e, nos Dice
endgame, o denominador é dominado por Lendário/Mítico (que também sobem com a Luck). Por isso a
Luck máxima multiplica o Secreto do Forbidden por ~2,8x (não por 20–90x). **Não é preciso mudar
a estrutura da Luck** com a proposta; ver §9 para o efeito por hora.

## 5. Detalhe por Dice (proposta)

### 1. Starter — unlock 0 rolls + — · preço 0 · Luck do Dice 1.00x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Comum | 4 | 62.00% | 1 em 2 | 2s | 1s | 62.00% | 1 em 2 | 2s |
| Incomum | 2 | 26.00% | 1 em 4 | 4s | 2s | 26.00% | 1 em 4 | 4s |
| Raro | 1 | 9.00% | 1 em 11 | 11s | 6s | 9.00% | 1 em 11 | 11s |
| Épico | 1 | 3.00% | 1 em 33 | 33s | 17s | 3.00% | 1 em 33 | 33s |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Saitano (`char_saitano_base`) | Épico | 3.00% | 1 em 33 | 33s | 17s |
| Kurilo (`char_kurilo_base`) | Raro | 9.00% | 1 em 11 | 11s | 6s |
| Chiko (`char_chiko_base`) | Incomum | 13.00% | 1 em 8 | 8s | 4s |
| Erwyn (Gala) (`char_erwyn_gala`) | Incomum | 13.00% | 1 em 8 | 8s | 4s |
| Sacha (Terno) (`char_sacha_suit`) | Comum | 15.50% | 1 em 6 | 6s | 3s |
| Mikaza (Formal) (`char_mikaza_formal`) | Comum | 15.50% | 1 em 6 | 6s | 3s |
| Sacha (`char_sacha_base`) | Comum | 15.50% | 1 em 6 | 6s | 3s |
| Anny (Colegial) (`char_anny_school`) | Comum | 15.50% | 1 em 6 | 6s | 3s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~39 rolls (Normal 39s · Rápido 20s).

### 2. Lucky — unlock 50 rolls + Starter · preço 2.5k · Luck do Dice 1.25x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Comum | 2 | 55.00% | 1 em 2 | 2s | 1s | 53.24% | 1 em 2 | 2s |
| Incomum | 2 | 28.00% | 1 em 4 | 4s | 2s | 28.31% | 1 em 4 | 4s |
| Raro | 2 | 12.00% | 1 em 8 | 8s | 4s | 12.81% | 1 em 8 | 8s |
| Épico | 1 | 5.00% | 1 em 20 | 20s | 10s | 5.64% | 1 em 18 | 18s |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Hizoka (`char_hizoka_base`) | Épico | 5.00% | 1 em 20 | 20s | 10s |
| Grei (`char_grei_base`) | Raro | 6.00% | 1 em 17 | 17s | 8s |
| Rukya (`char_rukya_base`) | Raro | 6.00% | 1 em 17 | 17s | 8s |
| Rinn (`char_rinn_base`) | Incomum | 14.00% | 1 em 7 | 7s | 4s |
| Kazumo (`char_kazumo_base`) | Incomum | 14.00% | 1 em 7 | 7s | 4s |
| Sanjo (Jovem) (`char_sanjo_young`) | Comum | 27.50% | 1 em 4 | 4s | 2s |
| Gom (`char_gom_base`) | Comum | 27.50% | 1 em 4 | 4s | 2s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~31 rolls (Normal 31s · Rápido 16s).

### 3. Rampart — unlock 125 rolls + Lucky · preço 10k · Luck do Dice 1.40x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Comum | 1 | 45.00% | 1 em 2 | 2s | 1s | 42.27% | 1 em 2 | 2s |
| Incomum | 2 | 32.00% | 1 em 3 | 3s | 2s | 32.08% | 1 em 3 | 3s |
| Raro | 2 | 16.00% | 1 em 6 | 6s | 3s | 17.40% | 1 em 6 | 6s |
| Épico | 2 | 7.00% | 1 em 14 | 14s | 7s | 8.26% | 1 em 12 | 12s |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Titã de Ataque (`char_erem_titan`) | Épico | 3.50% | 1 em 29 | 29s | 14s |
| Titã Feminina (`char_anny_titan`) | Épico | 3.50% | 1 em 29 | 29s | 14s |
| Erwyn (`char_erwyn_base`) | Raro | 8.00% | 1 em 13 | 13s | 6s |
| Erem (Veterano) (`char_erem_veteran`) | Raro | 8.00% | 1 em 13 | 13s | 6s |
| Anny (`char_anny_base`) | Incomum | 16.00% | 1 em 6 | 6s | 3s |
| Mikaza (`char_mikaza_base`) | Incomum | 16.00% | 1 em 6 | 6s | 3s |
| Erem (`char_erem_base`) | Comum | 45.00% | 1 em 2 | 2s | 1s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~40 rolls (Normal 40s · Rápido 20s).

### 4. Flame — unlock 300 rolls + Rampart · preço 40k · Luck do Dice 1.60x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Incomum | 2 | 60.00% | 1 em 2 | 2s | 1s | 56.41% | 1 em 2 | 2s |
| Raro | 2 | 28.00% | 1 em 4 | 4s | 2s | 29.45% | 1 em 3 | 3s |
| Épico | 1 | 11.00% | 1 em 9 | 9s | 5s | 12.94% | 1 em 8 | 8s |
| Lendário | 1 | 1.00% | 1 em 100 | 1m40s | 50s | 1.20% | 1 em 83 | 1m23s |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Akaino (`char_akaino_base`) | Lendário | 1.00% | 1 em 100 | 1m40s | 50s |
| Yamamotu (`char_yamamotu_base`) | Épico | 11.00% | 1 em 9 | 9s | 5s |
| Bakugu (`char_bakugu_base`) | Raro | 14.00% | 1 em 7 | 7s | 4s |
| Ase (`char_ase_base`) | Raro | 14.00% | 1 em 7 | 7s | 4s |
| Todoruki (`char_todoruki_base`) | Incomum | 30.00% | 1 em 3 | 3s | 2s |
| Natzu (`char_natzu_base`) | Incomum | 30.00% | 1 em 3 | 3s | 2s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~84 rolls (Normal 1m24s · Rápido 42s).

### 5. Shinobi — unlock 425 rolls + Flame · preço 75k · Luck do Dice 1.70x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Comum | 2 | 20.00% | 1 em 5 | 5s | 3s | 16.86% | 1 em 6 | 6s |
| Incomum | 2 | 32.00% | 1 em 3 | 3s | 2s | 29.83% | 1 em 3 | 3s |
| Raro | 2 | 30.00% | 1 em 3 | 3s | 2s | 31.72% | 1 em 3 | 3s |
| Épico | 2 | 18.00% | 1 em 6 | 6s | 3s | 21.58% | 1 em 5 | 5s |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Narotu (`char_narotu_base`) | Épico | 9.00% | 1 em 11 | 11s | 6s |
| Kakaxi (`char_kakaxi_base`) | Épico | 9.00% | 1 em 11 | 11s | 6s |
| Narotu (Jovem) (`char_narotu_young`) | Comum | 10.00% | 1 em 10 | 10s | 5s |
| Sasuko (Jovem) (`char_sasuko_young`) | Comum | 10.00% | 1 em 10 | 10s | 5s |
| Gaaro (`char_gaaro_base`) | Raro | 15.00% | 1 em 7 | 7s | 3s |
| Zabuzo (`char_zabuzo_base`) | Raro | 15.00% | 1 em 7 | 7s | 3s |
| Nejo (`char_nejo_base`) | Incomum | 16.00% | 1 em 6 | 6s | 3s |
| Roque Li (`char_roqueli_base`) | Incomum | 16.00% | 1 em 6 | 6s | 3s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~24 rolls (Normal 24s · Rápido 12s).

### 6. Blade — unlock 550 rolls + Shinobi · preço 125k · Luck do Dice 1.80x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Incomum | 2 | 50.00% | 1 em 2 | 2s | 1s | 45.22% | 1 em 2 | 2s |
| Raro | 3 | 32.00% | 1 em 3 | 3s | 2s | 33.24% | 1 em 3 | 3s |
| Épico | 2 | 16.00% | 1 em 6 | 6s | 3s | 19.09% | 1 em 5 | 5s |
| Lendário | 1 | 2.00% | 1 em 50 | 50s | 25s | 2.45% | 1 em 41 | 41s |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Shankz (`char_shankz_base`) | Lendário | 2.00% | 1 em 50 | 50s | 25s |
| Tanjiru (`char_tanjiru_base`) | Épico | 8.00% | 1 em 13 | 13s | 6s |
| Zoru (`char_zoru_base`) | Épico | 8.00% | 1 em 13 | 13s | 6s |
| Trunkz (`char_trunkz_base`) | Raro | 10.67% | 1 em 9 | 9s | 5s |
| Kisuko (`char_kisuko_base`) | Raro | 10.67% | 1 em 9 | 9s | 5s |
| Ginn (`char_ginn_base`) | Raro | 10.67% | 1 em 9 | 9s | 5s |
| Zoru (Jovem) (`char_zoru_young`) | Incomum | 25.00% | 1 em 4 | 4s | 2s |
| Ichiro (`char_ichiro_base`) | Incomum | 25.00% | 1 em 4 | 4s | 2s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~47 rolls (Normal 47s · Rápido 23s).

### 7. Fighter — unlock 775 rolls + Blade · preço 225k · Luck do Dice 1.90x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Incomum | 3 | 45.00% | 1 em 2 | 2s | 1s | 39.75% | 1 em 3 | 3s |
| Raro | 2 | 33.00% | 1 em 3 | 3s | 2s | 33.88% | 1 em 3 | 3s |
| Épico | 1 | 19.00% | 1 em 5 | 5s | 3s | 22.68% | 1 em 4 | 4s |
| Lendário | 1 | 3.00% | 1 em 33 | 33s | 17s | 3.69% | 1 em 27 | 27s |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Ol Maito (`char_olmaito_base`) | Lendário | 3.00% | 1 em 33 | 33s | 17s |
| Yuzuke (`char_yuzuke_base`) | Incomum | 15.00% | 1 em 7 | 7s | 3s |
| Deko (`char_deko_base`) | Incomum | 15.00% | 1 em 7 | 7s | 3s |
| Goko (`char_goko_base`) | Incomum | 15.00% | 1 em 7 | 7s | 3s |
| Lemilio (`char_lemilio_base`) | Raro | 16.50% | 1 em 6 | 6s | 3s |
| Lufy (`char_lufy_base`) | Raro | 16.50% | 1 em 6 | 6s | 3s |
| Pikkolo (`char_pikkolo_base`) | Épico | 19.00% | 1 em 5 | 5s | 3s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~32 rolls (Normal 32s · Rápido 16s).

### 8. Storm — unlock 1000 rolls + Fighter · preço 400k · Luck do Dice 2.00x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Raro | 3 | 60.00% | 1 em 2 | 2s | 1s | 55.90% | 1 em 2 | 2s |
| Épico | 2 | 32.00% | 1 em 3 | 3s | 2s | 35.05% | 1 em 3 | 3s |
| Lendário | 2 | 8.00% | 1 em 13 | 13s | 6s | 9.05% | 1 em 11 | 11s |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Killuo Relâmpago (`char_killuo_godspeed`) | Lendário | 4.00% | 1 em 25 | 25s | 13s |
| Deko Desperto (`char_deko_awakened`) | Lendário | 4.00% | 1 em 25 | 25s | 13s |
| Kaulifa (`char_kaulifa_base`) | Épico | 16.00% | 1 em 6 | 6s | 3s |
| Goko (Saga Majin) (`char_goko_majin_saga`) | Épico | 16.00% | 1 em 6 | 6s | 3s |
| Lanseiro (`char_lanseiro_base`) | Raro | 20.00% | 1 em 5 | 5s | 3s |
| Minatu (`char_minatu_base`) | Raro | 20.00% | 1 em 5 | 5s | 3s |
| Killuo (`char_killuo_base`) | Raro | 20.00% | 1 em 5 | 5s | 3s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~35 rolls (Normal 35s · Rápido 17s).

### 9. Spirit — unlock 1500 rolls + Storm · preço 750k · Luck do Dice 2.20x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Raro | 1 | 50.00% | 1 em 2 | 2s | 1s | 45.17% | 1 em 2 | 2s |
| Épico | 3 | 36.00% | 1 em 3 | 3s | 1s | 39.01% | 1 em 3 | 3s |
| Lendário | 2 | 13.00% | 1 em 8 | 8s | 4s | 14.61% | 1 em 7 | 7s |
| Mítico | 1 | 1.00% | 1 em 100 | 1m40s | 50s | 1.21% | 1 em 83 | 1m23s |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Yuzuke Demônio (`char_yuzuke_demon`) | Mítico | 1.00% | 1 em 100 | 1m40s | 50s |
| Hiey (`char_hiey_base`) | Lendário | 6.50% | 1 em 15 | 15s | 8s |
| Yoruka (`char_yoruka_base`) | Lendário | 6.50% | 1 em 15 | 15s | 8s |
| Starko (`char_starko_base`) | Épico | 12.00% | 1 em 8 | 8s | 4s |
| Byakuto (`char_byakuto_base`) | Épico | 12.00% | 1 em 8 | 8s | 4s |
| Shunzo (`char_shunzo_base`) | Épico | 12.00% | 1 em 8 | 8s | 4s |
| Toshiru (`char_toshiru_base`) | Raro | 50.00% | 1 em 2 | 2s | 1s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~87 rolls (Normal 1m27s · Rápido 43s).

### 10. Arcane — unlock 2000 rolls + Spirit · preço 1.4M · Luck do Dice 2.35x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Raro | 3 | 45.00% | 1 em 2 | 2s | 1s | 39.83% | 1 em 3 | 3s |
| Épico | 3 | 37.00% | 1 em 3 | 3s | 1s | 39.84% | 1 em 3 | 3s |
| Lendário | 1 | 16.00% | 1 em 6 | 6s | 3s | 17.91% | 1 em 6 | 6s |
| Mítico | 1 | 2.00% | 1 em 50 | 50s | 25s | 2.42% | 1 em 41 | 41s |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Emyia Arqueiro (`char_shiro_archer`) | Mítico | 2.00% | 1 em 50 | 50s | 25s |
| Rika (`char_rika_base`) | Épico | 12.33% | 1 em 8 | 8s | 4s |
| Lau (`char_lau_base`) | Épico | 12.33% | 1 em 8 | 8s | 4s |
| Akcel (`char_akcel_base`) | Épico | 12.33% | 1 em 8 | 8s | 4s |
| Shiro (`char_shiro_base`) | Raro | 15.00% | 1 em 7 | 7s | 3s |
| Seiba (`char_seiba_base`) | Raro | 15.00% | 1 em 7 | 7s | 3s |
| Kiritsugo (`char_kiritsugo_base`) | Raro | 15.00% | 1 em 7 | 7s | 3s |
| Gilgamex (`char_gilgamex_base`) | Lendário | 16.00% | 1 em 6 | 6s | 3s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~46 rolls (Normal 46s · Rápido 23s).

### 11. Shadow — unlock 2500 rolls + Arcane · preço 2.6M · Luck do Dice 2.55x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Épico | 3 | 65.00% | 1 em 2 | 2s | 1s | 63.73% | 1 em 2 | 2s |
| Lendário | 2 | 30.00% | 1 em 3 | 3s | 2s | 30.69% | 1 em 3 | 3s |
| Mítico | 2 | 5.00% | 1 em 20 | 20s | 10s | 5.57% | 1 em 18 | 18s |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Ichiro Mascarado (`char_ichiro_hollow`) | Mítico | 2.50% | 1 em 40 | 40s | 20s |
| Goko Sombrio (`char_goko_dark_base`) | Mítico | 2.50% | 1 em 40 | 40s | 20s |
| Peinn (`char_peinn_base`) | Lendário | 15.00% | 1 em 7 | 7s | 3s |
| Itaxi (`char_itaxi_base`) | Lendário | 15.00% | 1 em 7 | 7s | 3s |
| Shinjo (`char_shinjo_base`) | Épico | 21.67% | 1 em 5 | 5s | 2s |
| Ulkiorra (`char_ulkiorra_base`) | Épico | 21.67% | 1 em 5 | 5s | 2s |
| Grimjau (`char_grimjau_base`) | Épico | 21.67% | 1 em 5 | 5s | 2s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~55 rolls (Normal 55s · Rápido 27s).

### 12. Void — unlock 3000 rolls + Shadow · preço 5M · Luck do Dice 2.75x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Épico | 2 | 55.00% | 1 em 2 | 2s | 1s | 53.37% | 1 em 2 | 2s |
| Lendário | 2 | 36.00% | 1 em 3 | 3s | 1s | 36.56% | 1 em 3 | 3s |
| Mítico | 1 | 8.70% | 1 em 11 | 11s | 6s | 9.68% | 1 em 10 | 10s |
| Divino | 1 | 0.3000% | 1 em 333 | 5m33s | 2m47s | 0.3827% | 1 em 261 | 4m21s |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Ichiro Vasto (`char_ichiro_vasto`) | Divino | 0.3000% | 1 em 333 | 5m33s | 2m47s |
| Ulkiorra Liberado (`char_ulkiorra_release`) | Mítico | 8.70% | 1 em 11 | 11s | 6s |
| Vejita Majin (`char_vejita_majin`) | Lendário | 18.00% | 1 em 6 | 6s | 3s |
| Ilumi Desperto (`char_ilumi_awakened`) | Lendário | 18.00% | 1 em 6 | 6s | 3s |
| Vejita (`char_vejita_base`) | Épico | 27.50% | 1 em 4 | 4s | 2s |
| Ilumi (`char_ilumi_base`) | Épico | 27.50% | 1 em 4 | 4s | 2s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~262 rolls (Normal 4m22s · Rápido 2m11s).

### 13. Awakened — unlock 4500 rolls + Void · preço 12.5M · Luck do Dice 3.10x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Lendário | 3 | 85.00% | 1 em 1 | 1s | 1s | 83.67% | 1 em 1 | 1s |
| Mítico | 3 | 15.00% | 1 em 7 | 7s | 3s | 16.33% | 1 em 6 | 6s |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Roque Li dos Portões (`char_roqueli_gates`) | Mítico | 5.00% | 1 em 20 | 20s | 10s |
| Gom Adulto (`char_gom_adult`) | Mítico | 5.00% | 1 em 20 | 20s | 10s |
| Natzu Desperto (`char_natzu_awakened`) | Mítico | 5.00% | 1 em 20 | 20s | 10s |
| Rika Desperta (`char_rika_awakened`) | Lendário | 28.33% | 1 em 4 | 4s | 2s |
| Grei Desperto (`char_grei_awakened`) | Lendário | 28.33% | 1 em 4 | 4s | 2s |
| Bakugu Desperto (`char_bakugu_awakened`) | Lendário | 28.33% | 1 em 4 | 4s | 2s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~34 rolls (Normal 34s · Rápido 17s).

### 14. Colossus — unlock 6000 rolls + Awakened · preço 30M · Luck do Dice 3.50x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Épico | 2 | 25.00% | 1 em 4 | 4s | 2s | 23.25% | 1 em 4 | 4s |
| Lendário | 2 | 48.00% | 1 em 2 | 2s | 1s | 47.15% | 1 em 2 | 2s |
| Mítico | 2 | 27.00% | 1 em 4 | 4s | 2s | 29.60% | 1 em 3 | 3s |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Gohin (`char_gohin_base`) | Épico | 12.50% | 1 em 8 | 8s | 4s |
| Mighto (`char_mighto_base`) | Épico | 12.50% | 1 em 8 | 8s | 4s |
| Lufy Serpente (`char_lufy_snake`) | Mítico | 13.50% | 1 em 7 | 7s | 4s |
| Mighto 5º Portão (`char_mighto_gate5`) | Mítico | 13.50% | 1 em 7 | 7s | 4s |
| Sasuko (`char_sasuko_base`) | Lendário | 24.00% | 1 em 4 | 4s | 2s |
| Brolli (`char_brolli_base`) | Lendário | 24.00% | 1 em 4 | 4s | 2s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~17 rolls (Normal 17s · Rápido 8s).

### 15. Celestial — unlock 8000 rolls + Colossus · preço 75M · Luck do Dice 4.00x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Lendário | 2 | 63.50% | 1 em 2 | 2s | 1s | 60.56% | 1 em 2 | 2s |
| Mítico | 2 | 35.50% | 1 em 3 | 3s | 1s | 38.16% | 1 em 3 | 3s |
| Divino | 3 | 1.00% | 1 em 100 | 1m40s | 50s | 1.29% | 1 em 78 | 1m18s |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Vegitto (`char_vegitto_base`) | Divino | 0.3333% | 1 em 300 | 5m00s | 2m30s |
| Deko 100% (`char_deko_full`) | Divino | 0.3333% | 1 em 300 | 5m00s | 2m30s |
| Goju (`char_goju_base`) | Divino | 0.3333% | 1 em 300 | 5m00s | 2m30s |
| Ol Maito Poder Total (`char_olmaito_mode`) | Mítico | 17.75% | 1 em 6 | 6s | 3s |
| Narotu Sábio (`char_narotu_sage`) | Mítico | 17.75% | 1 em 6 | 6s | 3s |
| Yujo (`char_yujo_base`) | Lendário | 31.75% | 1 em 3 | 3s | 2s |
| Sanjo (`char_sanjo_base`) | Lendário | 31.75% | 1 em 3 | 3s | 2s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~428 rolls (Normal 7m08s · Rápido 3m34s).

### 16. Forbidden — unlock 12000 rolls + Celestial · preço 750M · Luck do Dice 4.00x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Mítico | 1 | 98.50% | 1 em 1 | 1s | 1s | 98.20% | 1 em 1 | 1s |
| Divino | 3 | 1.50% | 1 em 67 | 1m07s | 33s | 1.79% | 1 em 56 | 56s |
| Secreto | 3 | 0.00450% | 1 em 22.222 | 6h10m | 3h05m | 0.00769% | 1 em 13.010 | 3h36m |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Vegitto Azul (`char_vegitto_blue`) | Secreto | 0.00150% | 1 em 66.667 | 18h31m | 9h15m |
| Ichiro Mugetsu (`char_ichiro_mugetsu`) | Secreto | 0.00150% | 1 em 66.667 | 18h31m | 9h15m |
| Mighto 8º Portão (`char_mighto_gate8`) | Secreto | 0.00150% | 1 em 66.667 | 18h31m | 9h15m |
| Madaro (`char_madaro_base`) | Divino | 0.5000% | 1 em 200 | 3m20s | 1m40s |
| Aizo (`char_aizo_base`) | Divino | 0.5000% | 1 em 200 | 3m20s | 1m40s |
| Brolli Lendário (`char_brolli_legend`) | Divino | 0.5000% | 1 em 200 | 3m20s | 1m40s |
| Barbalva (`char_barbalva_base`) | Mítico | 98.50% | 1 em 1 | 1s | 1s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~71.558 rolls (Normal 19h52m · Rápido 9h56m).

## 6. Celestial e Forbidden (endgame) — análise detalhada

### Celestial

| Cenário | Lendário | Mítico | Divino | ERV |
|---|---|---|---|---:|
| Luck 1,0x | 63.50% (1 em 2) | 35.50% (1 em 3) | 1.00% (1 em 100) | 225.5 |
| Luck do Dice (4.00x) | 60.56% (1 em 2) | 38.16% (1 em 3) | 1.29% (1 em 78) | 238.9 |
| Máx. F2P (41.6x) | 58.01% (1 em 2) | 40.41% (1 em 2) | 1.58% (1 em 63) | 251.3 |
| Máx. com monetização (91.5x) | 57.74% (1 em 2) | 40.64% (1 em 2) | 1.62% (1 em 62) | 252.7 |

Por hora (expectativa), raridades top:

| Cenário | Cadência | Mítico/h | Divino/h | 1 Divino a cada |
|---|---|---:|---:|---:|
| Luck 1,0x | Normal | 1278.0 | 36.00 | 1m40s |
| Luck 1,0x | Rápido | 2556.0 | 72.00 | 50s |
| Luck do Dice (4.00x) | Normal | 1373.6 | 46.30 | 1m18s |
| Luck do Dice (4.00x) | Rápido | 2747.3 | 92.60 | 39s |
| Máx. F2P (41.6x) | Normal | 1454.7 | 57.00 | 1m03s |
| Máx. F2P (41.6x) | Rápido | 2909.5 | 114.00 | 32s |
| Máx. com monetização (91.5x) | Normal | 1463.1 | 58.22 | 1m02s |
| Máx. com monetização (91.5x) | Rápido | 2926.2 | 116.44 | 31s |

### Forbidden

| Cenário | Mítico | Divino | Secreto | ERV |
|---|---|---|---|---:|
| Luck 1,0x | 98.50% (1 em 1) | 1.50% (1 em 67) | 0.00450% (1 em 22.222) | 424.7 |
| Luck do Dice (4.00x) | 98.20% (1 em 1) | 1.79% (1 em 56) | 0.00769% (1 em 13.010) | 429.8 |
| Máx. F2P (41.6x) | 97.91% (1 em 1) | 2.07% (1 em 48) | 0.0120% (1 em 8.307) | 434.9 |
| Máx. com monetização (91.5x) | 97.88% (1 em 1) | 2.11% (1 em 47) | 0.0126% (1 em 7.932) | 435.5 |

Por hora (expectativa), raridades top:

| Cenário | Cadência | Divino/h | Secreto/h | 1 Secreto a cada |
|---|---|---:|---:|---:|
| Luck 1,0x | Normal | 54.0 | 0.16 | 6h10m |
| Luck 1,0x | Rápido | 108.0 | 0.32 | 3h05m |
| Luck do Dice (4.00x) | Normal | 64.4 | 0.28 | 3h36m |
| Luck do Dice (4.00x) | Rápido | 128.8 | 0.55 | 1h48m |
| Máx. F2P (41.6x) | Normal | 74.7 | 0.43 | 2h18m |
| Máx. F2P (41.6x) | Rápido | 149.3 | 0.87 | 1h09m |
| Máx. com monetização (91.5x) | Normal | 75.8 | 0.45 | 2h12m |
| Máx. com monetização (91.5x) | Rápido | 151.6 | 0.91 | 1h06m |

**Forbidden:** com a proposta (Mítico 98,4955% · Divino 1,5% · Secreto 0,0045%), o Secreto é 1 em
~22.200 com Luck 1 (cada um dos 3 Secretos: 1 em ~66.700) e fica **abaixo de 1 por hora mesmo no
máximo absoluto** (Luck máxima com monetização + Roll Rápido) — a mesma meta da auditoria de RNG
anterior (com 0,005% dava 1,01/h). A normalização atual (75/20/5) dava 1 Secreto a cada 20 rolls.

**Tensão a decidir — Divino no endgame:** a meta da auditoria antiga ("Divino < 3/h") era para o
sorteio GLOBAL. Nos Dice endgame, que existem para entregar Divinos, a proposta dá ~36–150
Divinos/h no Celestial/Forbidden (1 Divino a cada 30 s–1m40s), mas cada Divino específico continua
1 em 200–300 rolls. Se você quiser o Divino mais raro mesmo no endgame, a alternativa é metade:
Celestial L 64 / M 35,5 / D 0,5 e Forbidden M 99,2455 / D 0,75 / S 0,0045 (ERV continua crescente: 216,0 e 412,7).

**Celestial:** Divino 1% (cada um dos 3: 1 em 300). Mítico 35,5% continua frequente, mas é o
Dice que antecede o Forbidden e tem 2 Míticos e 2 Lendários: o valor está nos Divinos.

## 7. Pity com os pesos propostos

Atual: Lendário 50 · Mítico 800. Um pity só vale em Dice que tem a raridade do piso.
Tempo para 50 rolls: Normal 50s · Rápido 25s. Para 800 rolls: Normal 13m20s · Rápido 6m40s.

### Pity Legendary (piso: Lendário ou melhor)

| Dice | P natural (Luck 1) | 1 em | chega ao pity 50 | rolls efetivos 50 | chega ao pity 100 | rolls efetivos 100 | chega ao pity 150 | rolls efetivos 150 | chega ao pity 200 | rolls efetivos 200 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| Flame | 1.00% | 1 em 100 | 61.11% | 39.5 | 36.97% | 63.4 | 22.37% | 77.9 | 13.53% | 86.6 |
| Blade | 2.00% | 1 em 50 | 37.16% | 31.8 | 13.53% | 43.4 | 4.93% | 47.6 | 1.79% | 49.1 |
| Fighter | 3.00% | 1 em 33 | 22.48% | 26.1 | 4.90% | 31.7 | 1.07% | 33.0 | 0.2331% | 33.3 |
| Storm | 8.00% | 1 em 13 | 1.68% | 12.3 | 0.0260% | 12.5 | 0.00040% | 12.5 | 0.00001% | 12.5 |
| Spirit | 14.00% | 1 em 7 | 0.0617% | 7.1 | 0.00003% | 7.1 | 0.00000% | 7.1 | 0.00000% | 7.1 |
| Arcane | 18.00% | 1 em 6 | 0.00598% | 5.6 | 0.00000% | 5.6 | 0.00000% | 5.6 | 0.00000% | 5.6 |
| Shadow | 35.00% | 1 em 3 | 0.00000% | 2.9 | 0.00000% | 2.9 | 0.00000% | 2.9 | 0.00000% | 2.9 |
| Void | 45.00% | 1 em 2 | 0.00000% | 2.2 | 0.00000% | 2.2 | 0.00000% | 2.2 | 0.00000% | 2.2 |
| Awakened | 100.00% | 1 em 1 | 0.00000% | 1.0 | 0.00000% | 1.0 | 0.00000% | 1.0 | 0.00000% | 1.0 |
| Colossus | 75.00% | 1 em 1 | 0.00000% | 1.3 | 0.00000% | 1.3 | 0.00000% | 1.3 | 0.00000% | 1.3 |
| Celestial | 100.00% | 1 em 1 | 0.00000% | 1.0 | 0.00000% | 1.0 | 0.00000% | 1.0 | 0.00000% | 1.0 |

Dice SEM a raridade (pity congelado): Starter, Lucky, Rampart, Shinobi, Forbidden.

### Pity Mythic (piso: Mítico ou melhor)

| Dice | P natural (Luck 1) | 1 em | chega ao pity 250 | rolls efetivos 250 | chega ao pity 400 | rolls efetivos 400 | chega ao pity 800 | rolls efetivos 800 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Spirit | 1.00% | 1 em 100 | 8.19% | 91.9 | 1.81% | 98.2 | 0.0325% | 100.0 |
| Arcane | 2.00% | 1 em 50 | 0.6536% | 49.7 | 0.0316% | 50.0 | 0.00001% | 50.0 |
| Shadow | 5.00% | 1 em 20 | 0.00028% | 20.0 | 0.00000% | 20.0 | 0.00000% | 20.0 |
| Void | 9.00% | 1 em 11 | 0.00000% | 11.1 | 0.00000% | 11.1 | 0.00000% | 11.1 |
| Awakened | 15.00% | 1 em 7 | 0.00000% | 6.7 | 0.00000% | 6.7 | 0.00000% | 6.7 |
| Colossus | 27.00% | 1 em 4 | 0.00000% | 3.7 | 0.00000% | 3.7 | 0.00000% | 3.7 |
| Celestial | 36.50% | 1 em 3 | 0.00000% | 2.7 | 0.00000% | 2.7 | 0.00000% | 2.7 |
| Forbidden | 100.00% | 1 em 1 | 0.00000% | 1.0 | 0.00000% | 1.0 | 0.00000% | 1.0 |

Dice SEM a raridade (pity congelado): Starter, Lucky, Rampart, Flame, Shinobi, Blade, Fighter, Storm.

"Chega ao pity" = fração dos ciclos que só terminam pelo pity ((1−p)^(N−1)); "rolls efetivos" =
rolls médios entre acertos COM pity ((1−(1−p)^N)/p). Sem pity seria 1/p.

**Leitura — Lendário 50:** no Flame (Lendário 1%) 61% dos Lendários viriam do pity e o Lendário
sairia a cada ~40 rolls (não 100): o pity, e não o RNG, passa a definir a raridade da primeira
vitrine. No Blade (2%) 37%; no Fighter (3%) 22%; do Storm em diante (≥8%) o pity quase não age.
**Recomendação:** subir para **150** (Flame: 22% pelo pity, Lendário a cada ~78 rolls; ≥ Blade quase
irrelevante) — continua sendo uma rede de segurança, sem esvaziar a raridade. Manter 50 só se a
intenção for um Lendário bem mais frequente no início.

**Leitura — Mítico 800:** o Mítico só existe do Spirit em diante; no Spirit (1%) a chance de
chegar a 800 rolls sem Mítico é ~0,03%, e do Arcane em diante é ~0. **O pity Mítico 800 é
praticamente decorativo.** Com **250**: Spirit ~8% dos Míticos pelo pity (Mítico a cada ~92 rolls
em vez de 100), Arcane ~0,6%, Shadow+ ~0 — uma rede de segurança real só onde o Mítico é raro.
**Recomendação: voltar o Mítico para 250.** (400 fica no meio: Spirit ~1,8%.)

## 8. Preços e unlocks (avaliação; nada alterado)

| # | Dice | Preço | × anterior | Rolls p/ desbloquear | Δ rolls | ~tempo de roll (Normal) | Completar pool anterior (Luck do Dice) |
|---:|---|---:|---:|---:|---:|---:|---:|
| 1 | Starter | 0 | — | 0 | — | 0s | — |
| 2 | Lucky | 2.5k | — | 50 | 50 | 50s | 39 rolls |
| 3 | Rampart | 10k | 4.0x | 125 | 75 | 2m05s | 31 rolls |
| 4 | Flame | 40k | 4.0x | 300 | 175 | 5m00s | 40 rolls |
| 5 | Shinobi | 75k | 1.9x | 425 | 125 | 7m05s | 84 rolls |
| 6 | Blade | 125k | 1.7x | 550 | 125 | 9m10s | 24 rolls |
| 7 | Fighter | 225k | 1.8x | 775 | 225 | 12m55s | 47 rolls |
| 8 | Storm | 400k | 1.8x | 1000 | 225 | 16m40s | 32 rolls |
| 9 | Spirit | 750k | 1.9x | 1500 | 500 | 25m00s | 35 rolls |
| 10 | Arcane | 1.4M | 1.9x | 2000 | 500 | 33m20s | 87 rolls |
| 11 | Shadow | 2.6M | 1.9x | 2500 | 500 | 41m40s | 46 rolls |
| 12 | Void | 5M | 1.9x | 3000 | 500 | 50m00s | 55 rolls |
| 13 | Awakened | 12.5M | 2.5x | 4500 | 1500 | 1h15m | 262 rolls |
| 14 | Colossus | 30M | 2.4x | 6000 | 1500 | 1h40m | 34 rolls |
| 15 | Celestial | 75M | 2.5x | 8000 | 2000 | 2h13m | 17 rolls |
| 16 | Forbidden | 750M | 10.0x | 12000 | 4000 | 3h20m | 428 rolls |

Leitura:

- Preço: ~×2–4 por Dice até o Celestial e **×10 no Forbidden (750M)** — o salto final é o maior
  da curva. Faz sentido como endgame, mas precisa ser validado com a renda real (fase de economia).
- **Completar cada pool é rápido** com os pesos propostos (Luck do próprio Dice): dezenas de rolls
  do Starter ao Shadow, ~260 no Void, ~430 no Celestial; só o **Forbidden é longo (~71.600 rolls,
  ~20 h em Normal / ~10 h com Roll Rápido)** por causa dos 3 Secretos. Os rolls exigidos entre Dice
  (+50 a +4.000) são MAIORES que isso: o requisito de rolls e, principalmente, o **preço** é que
  seguram a progressão, não o RNG. Consequência: o Índice F2P (exceto Forbidden) pode ser completado
  rápido quando o dinheiro chega — a longevidade vem da economia, dos níveis/variantes e do Forbidden.
  Sugestão separada (fase de economia): validar o tempo até cada preço com a renda real e decidir
  se algum pool deve ficar mais longo (ex.: Divino/Mítico um pouco mais raros nos Dice 9–15).

## 9. Simulação: 1.000.000 rolls por Dice (Luck 1, sem pity)

| Dice | Raridade | Teórico | Observado | Desvio (z) | Maior |z| entre personagens |
|---|---|---:|---:|---:|---:|
| Starter | Comum | 62.00% | 62.03% | +0.63 | 1.84 |
|  | Incomum | 26.00% | 25.99% | -0.30 |  |
|  | Raro | 9.00% | 8.98% | -0.79 |  |
|  | Épico | 3.00% | 3.01% | +0.32 |  |
| Lucky | Comum | 55.00% | 55.00% | -0.06 | 0.84 |
|  | Incomum | 28.00% | 28.04% | +0.93 |  |
|  | Raro | 12.00% | 11.98% | -0.67 |  |
|  | Épico | 5.00% | 4.98% | -0.77 |  |
| Rampart | Comum | 45.00% | 45.02% | +0.41 | 1.70 |
|  | Incomum | 32.00% | 32.03% | +0.67 |  |
|  | Raro | 16.00% | 16.00% | -0.08 |  |
|  | Épico | 7.00% | 6.95% | -1.91 |  |
| Flame | Incomum | 60.00% | 59.98% | -0.39 | 1.72 |
|  | Raro | 28.00% | 28.00% | +0.05 |  |
|  | Épico | 11.00% | 11.00% | +0.15 |  |
|  | Lendário | 1.00% | 1.01% | +1.24 |  |
| Shinobi | Comum | 20.00% | 20.06% | +1.58 | 2.28 |
|  | Incomum | 32.00% | 31.95% | -1.10 |  |
|  | Raro | 30.00% | 29.95% | -1.16 |  |
|  | Épico | 18.00% | 18.04% | +1.07 |  |
| Blade | Incomum | 50.00% | 49.99% | -0.15 | 1.56 |
|  | Raro | 32.00% | 31.99% | -0.26 |  |
|  | Épico | 16.00% | 16.03% | +0.70 |  |
|  | Lendário | 2.00% | 1.99% | -0.45 |  |
| Fighter | Incomum | 45.00% | 45.05% | +1.07 | 1.33 |
|  | Raro | 33.00% | 32.94% | -1.27 |  |
|  | Épico | 19.00% | 19.03% | +0.73 |  |
|  | Lendário | 3.00% | 2.98% | -1.27 |  |
| Storm | Raro | 60.00% | 59.99% | -0.23 | 1.02 |
|  | Épico | 32.00% | 32.02% | +0.52 |  |
|  | Lendário | 8.00% | 7.99% | -0.48 |  |
| Spirit | Raro | 50.00% | 50.00% | +0.04 | 1.04 |
|  | Épico | 36.00% | 36.03% | +0.52 |  |
|  | Lendário | 13.00% | 12.98% | -0.62 |  |
|  | Mítico | 1.00% | 0.9939% | -0.61 |  |
| Arcane | Raro | 45.00% | 45.07% | +1.47 | 2.58 |
|  | Épico | 37.00% | 37.02% | +0.33 |  |
|  | Lendário | 16.00% | 15.92% | -2.15 |  |
|  | Mítico | 2.00% | 1.99% | -0.73 |  |
| Shadow | Épico | 65.00% | 65.06% | +1.27 | 1.65 |
|  | Lendário | 30.00% | 29.95% | -1.01 |  |
|  | Mítico | 5.00% | 4.99% | -0.67 |  |
| Void | Épico | 55.00% | 55.07% | +1.41 | 1.67 |
|  | Lendário | 36.00% | 35.92% | -1.65 |  |
|  | Mítico | 8.70% | 8.71% | +0.19 |  |
|  | Divino | 0.3000% | 0.3037% | +0.68 |  |
| Awakened | Lendário | 85.00% | 85.03% | +0.85 | 1.73 |
|  | Mítico | 15.00% | 14.97% | -0.85 |  |
| Colossus | Épico | 25.00% | 25.01% | +0.18 | 2.17 |
|  | Lendário | 48.00% | 48.06% | +1.23 |  |
|  | Mítico | 27.00% | 26.93% | -1.56 |  |
| Celestial | Lendário | 63.50% | 63.50% | +0.04 | 1.69 |
|  | Mítico | 35.50% | 35.49% | -0.13 |  |
|  | Divino | 1.00% | 1.00% | +0.43 |  |
| Forbidden | Mítico | 98.50% | 98.51% | +1.14 | 1.14 |
|  | Divino | 1.50% | 1.49% | -1.10 |  |
|  | Secreto | 0.00450% | 0.00400% | -0.75 |  |

Maior desvio entre TODOS os personagens dos 16 Dice: |z| = 2.58 (esperado < ~4 com 112 comparações).

## 10. Sessões endgame (Luck do Dice, pity atual 50/800, sementes fixas)

| Dice | Sessão | Sessões simuladas | Míticos (média) | Divinos (média) | Secretos (média) | P(≥1 Divino) | P(≥1 Secreto) |
|---|---:|---:|---:|---:|---:|---:|---:|
| Awakened | 100 rolls | 5000 | 16.33 | 0.000 | 0.0000 | 0.0% | 0.00% |
|  | 1000 rolls | 1000 | 163.44 | 0.000 | 0.0000 | 0.0% | 0.00% |
|  | 10000 rolls | 200 | 1636.94 | 0.000 | 0.0000 | 0.0% | 0.00% |
| Colossus | 100 rolls | 5000 | 29.62 | 0.000 | 0.0000 | 0.0% | 0.00% |
|  | 1000 rolls | 1000 | 295.88 | 0.000 | 0.0000 | 0.0% | 0.00% |
|  | 10000 rolls | 200 | 2957.56 | 0.000 | 0.0000 | 0.0% | 0.00% |
| Celestial | 100 rolls | 5000 | 38.23 | 1.260 | 0.0000 | 71.8% | 0.00% |
|  | 1000 rolls | 1000 | 381.47 | 12.931 | 0.0000 | 100.0% | 0.00% |
|  | 10000 rolls | 200 | 3815.93 | 129.885 | 0.0000 | 100.0% | 0.00% |
| Forbidden | 100 rolls | 5000 | 98.22 | 1.767 | 0.0078 | 83.4% | 0.78% |
|  | 1000 rolls | 1000 | 981.95 | 17.966 | 0.0830 | 100.0% | 8.10% |
|  | 10000 rolls | 200 | 9820.91 | 178.365 | 0.7300 | 100.0% | 50.00% |

Sessão de 100 rolls ≈ 1m40s (Normal); 1.000 ≈ 16m40s; 10.000 ≈ 2h47m.

## 11. Prism (Dia 7 do Diário) — 3 propostas (nada implementado)

1. **Prisma da Coleção** (recomendada): 1 "roll de prisma" por dia, gasto na Loja de Dados. Sorteia
   com as chances normais do Dice selecionado, mas **só entre os personagens que o jogador ainda
   NÃO descobriu** naquele Dice (se já descobriu todos, vira um roll normal). Não aumenta raridade,
   não acelera rolls e não se compra: ajuda a completar o Índice e dá um motivo para trocar de Dice.
2. **Prisma de Variante**: os próximos 25 rolls com o Prism equipado (1x por dia) têm chance de
   sair como variante visual (Silver/Gold) — mesmo personagem, mesmo RNG de raridade. Aproveita a
   Fusão/variantes, mas mexe na economia das variantes (renda maior) e exige balanceamento próprio.
3. **Prisma Espelho**: o Prism "copia" o Dice desbloqueado mais alto e dá um bônus de Luck pequeno
   (+10%) por 10 minutos 1x/dia. Simples, mas é mais Luck (pouco interessante e encosta em P2W de tempo).

**Recomendação: Prisma da Coleção** — usa a mecânica de coleção/RNG, é limitado por dia, é F2P
(vem do Diário) e não substitui nenhum dos 16 Dice; a probabilidade exibida continua sendo a do
Dice (filtrada), então a API de probabilidade atual serve com um filtro de "não descobertos".

## 12. Recomendações (para aprovação; nada aplicado)

1. Aplicar os `RarityWeights` propostos (§1) como `RarityWeights` explícitos no `DiceConfig`.
2. Pity Mítico **800 → 250**; pity Lendário **50 → 150** (ou manter 50 se o início deve ser generoso).
3. Luck: **sem mudança estrutural** — com os pesos propostos o Secreto fica < 1/h no máximo absoluto.
4. Ordem dos Dice: preferir a **Variante B** (Shinobi ↔ Flame e Colossus ↔ Awakened, com Épico 10% no
   Shinobi e Mítico 15% no Colossus) — mesmos pools, curva mais natural; exige mudar a ordem de unlock.
5. Preços/unlocks: manter por ora; validar com a renda real na fase de economia (o preço é o freio
   real da progressão; ×10 no Forbidden).
6. Divino no endgame: manter (1% Celestial / 1,5% Forbidden) ou usar a alternativa com metade (§6).
7. Prism: Prisma da Coleção.
