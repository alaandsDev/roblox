# DICE BALANCE ANALYSIS — Roll Legends (FINAL, aplicado)

Gerado por `lune run tools/sim/analyze_dice_balance.luau` com o **mesmo `DiceCore` do servidor**.
**Pesos FINAIS de produção** (`DiceConfig.RarityWeights`, explícitos): proposta de e4b73ac aprovada
com a **Variante B** (Shinobi antes do Flame, Colossus antes do Awakened) e o **Divino reduzido**
(Celestial 0,5% / Forbidden 0,75%). Pity: Lendário 50 (mantido) · Mítico **250**. Luck: inalterada.
Preço e rolls de desbloqueio seguem a POSIÇÃO; o LuckMultiplier é de cada Dice. "Antes" = normalização
da tabela global (commit 4a69c25).

- Pools (personagens por Dice) **não mudam**; só os `RarityWeights`.
- Cadência: Normal = 1 s/roll (1 roll/s) · Roll Rápido = 0.5 s/roll (2 rolls/s). Tempos = expectativa matemática, não garantia.
- **Expected Rarity Value (ERV)** = Σ P(raridade) × Score — ferramenta de análise, não é gameplay. Score: Comum 1 · Incomum 3 · Raro 10 · Épico 30 · Lendário 100 · Mítico 400 · Divino 2000 · Secreto 15000.
- Luck nos cenários: 1,0x · Luck do próprio Dice (LuckMultiplier, sem upgrades) · máximo F2P (upgrades/renascimentos/perks no máximo + boost diário 2x) · máximo com monetização (+ VIP + Sorte x2). Fórmula atual: retornos decrescentes (LuckSoftCap 10) e `LuckExponent` por raridade.

## 1. Tabela final dos 16 Dice (ordem oficial)

| # | Dice | Unlock (rolls · Dice anterior) | Preço | Pool | Pesos finais (Luck 1) | Luck do Dice | ERV antes | ERV final |
|---:|---|---|---:|---|---|---:|---:|---:|
| 1 | **Starter** | 0 · — | 0 | C4 U2 R1 E1 | C 62.00% · U 26.00% · R 9.00% · E 3.00% | 1.00x | 4.1 | **3.2** |
| 2 | **Lucky** | 50 · Starter | 2.5k | C2 U2 R2 E1 | C 55.00% · U 28.00% · R 12.00% · E 5.00% | 1.25x | 4.1 | **4.1** |
| 3 | **Rampart** | 125 · Lucky | 10k | C1 U2 R2 E2 | C 45.00% · U 32.00% · R 16.00% · E 7.00% | 1.40x | 4.1 | **5.1** |
| 4 | **Shinobi** | 300 · Rampart | 40k | C2 U2 R2 E2 | C 35.00% · U 33.00% · R 22.00% · E 10.00% | 1.70x | 4.1 | **6.5** |
| 5 | **Flame** | 425 · Shinobi | 75k | U2 R2 E1 L1 | U 60.00% · R 28.00% · E 11.00% · L 1.00% | 1.60x | 12.4 | **8.9** |
| 6 | **Blade** | 550 · Flame | 125k | U2 R3 E2 L1 | U 50.00% · R 32.00% · E 16.00% · L 2.00% | 1.80x | 12.4 | **11.5** |
| 7 | **Fighter** | 775 · Blade | 225k | U3 R2 E1 L1 | U 45.00% · R 33.00% · E 19.00% · L 3.00% | 1.90x | 12.4 | **13.3** |
| 8 | **Storm** | 1000 · Fighter | 400k | R3 E2 L2 | R 60.00% · E 32.00% · L 8.00% | 2.00x | 24.7 | **23.6** |
| 9 | **Spirit** | 1500 · Storm | 750k | R1 E3 L2 M1 | R 50.00% · E 36.00% · L 13.00% · M 1.00% | 2.20x | 39.0 | **32.8** |
| 10 | **Arcane** | 2000 · Spirit | 1.4M | R3 E3 L1 M1 | R 45.00% · E 37.00% · L 16.00% · M 2.00% | 2.35x | 39.0 | **39.6** |
| 11 | **Shadow** | 2500 · Arcane | 2.6M | E3 L2 M2 | E 65.00% · L 30.00% · M 5.00% | 2.55x | 83.9 | **69.5** |
| 12 | **Void** | 3000 · Shadow | 5M | E2 L2 M1 D1 | E 55.00% · L 36.00% · M 8.70% · D 0.3000% | 2.75x | 132.1 | **93.3** |
| 13 | **Colossus** | 4500 · Void | 12.5M | E2 L2 M2 | E 40.00% · L 45.00% · M 15.00% | 3.50x | 83.9 | **117.0** |
| 14 | **Awakened** | 6000 · Colossus | 30M | L3 M3 | L 85.00% · M 15.00% | 3.10x | 181.8 | **145.0** |
| 15 | **Celestial** | 8000 · Awakened | 75M | L2 M2 D3 | L 64.00% · M 35.50% · D 0.5000% | 4.00x | 305.1 | **216.0** |
| 16 | **Forbidden** | 12000 · Celestial | 750M | M1 D3 S3 | M 99.25% · D 0.7500% · S 0.00450% | 4.00x | 1450.0 | **412.7** |

Pool: quantidade de personagens por raridade (C/U/R/E/L/M/D/S). ERV com Luck 1.

## 2. Comparação antes × final (Luck 1)

| Dice | Antes (normalização da tabela global) | Final |
|---|---|---|
| Starter | C 56.70% · U 25.77% · R 12.37% · E 5.15% | C 62.00% · U 26.00% · R 9.00% · E 3.00% |
| Lucky | C 56.70% · U 25.77% · R 12.37% · E 5.15% | C 55.00% · U 28.00% · R 12.00% · E 5.00% |
| Rampart | C 56.70% · U 25.77% · R 12.37% · E 5.15% | C 45.00% · U 32.00% · R 16.00% · E 7.00% |
| Shinobi | C 56.70% · U 25.77% · R 12.37% · E 5.15% | C 35.00% · U 33.00% · R 22.00% · E 10.00% |
| Flame | U 56.82% · R 27.27% · E 11.36% · L 4.55% | U 60.00% · R 28.00% · E 11.00% · L 1.00% |
| Blade | U 56.82% · R 27.27% · E 11.36% · L 4.55% | U 50.00% · R 32.00% · E 16.00% · L 2.00% |
| Fighter | U 56.82% · R 27.27% · E 11.36% · L 4.55% | U 45.00% · R 33.00% · E 19.00% · L 3.00% |
| Storm | R 63.16% · E 26.32% · L 10.53% | R 60.00% · E 32.00% · L 8.00% |
| Spirit | R 60.76% · E 25.32% · L 10.13% · M 3.80% | R 50.00% · E 36.00% · L 13.00% · M 1.00% |
| Arcane | R 60.76% · E 25.32% · L 10.13% · M 3.80% | R 45.00% · E 37.00% · L 16.00% · M 2.00% |
| Shadow | E 64.52% · L 25.81% · M 9.68% | E 65.00% · L 30.00% · M 5.00% |
| Void | E 62.89% · L 25.16% · M 9.43% · D 2.52% | E 55.00% · L 36.00% · M 8.70% · D 0.3000% |
| Colossus | E 64.52% · L 25.81% · M 9.68% | E 40.00% · L 45.00% · M 15.00% |
| Awakened | L 72.73% · M 27.27% | L 85.00% · M 15.00% |
| Celestial | L 67.80% · M 25.42% · D 6.78% | L 64.00% · M 35.50% · D 0.5000% |
| Forbidden | M 75.00% · D 20.00% · S 5.00% | M 99.25% · D 0.7500% · S 0.00450% |

## 3. Regressões

**Antes (normalização, ordem atual):**

- Lucky (#2): ERV 4.1 ≤ anterior 4.1
- Rampart (#3): ERV 4.1 ≤ anterior 4.1
- Shinobi (#4): ERV 4.1 ≤ anterior 4.1
- Blade (#6): ERV 12.4 ≤ anterior 12.4
- Fighter (#7): ERV 12.4 ≤ anterior 12.4
- Arcane (#10): ERV 39.0 ≤ anterior 39.0
- Colossus (#13): ERV 83.9 ≤ anterior 132.1

**Final:** nenhuma — ERV estritamente crescente do #1 ao #16.

**Ordem (Variante B aplicada):** Shinobi (#4, sem Lendário) agora vem ANTES do Flame (#5, primeiro
Lendário) e Colossus (#13, E/L/M) antes do Awakened (#14, L/M): o jogador nunca "perde" uma raridade
ao avançar. Pools inalterados. O LuckMultiplier é do Dice, então Shinobi (1,7x) > Flame (1,6x) e
Colossus (3,5x) > Awakened (3,1x) — veja a coluna ERV com Luck do Dice abaixo.

| # | Dice | ERV Luck 1 | ERV Luck do Dice |
|---:|---|---:|---:|
| 1 | Starter | 3.2 | 3.2 |
| 2 | Lucky | 4.1 | 4.4 |
| 3 | Rampart | 5.1 | 5.6 |
| 4 | Shinobi | 6.5 | 7.5 |
| 5 | Flame | 8.9 | 9.7 |
| 6 | Blade | 11.5 | 12.9 |
| 7 | Fighter | 13.3 | 15.1 |
| 8 | Storm | 23.6 | 25.2 |
| 9 | Spirit | 32.8 | 35.7 |
| 10 | Arcane | 39.6 | 43.5 |
| 11 | Shadow | 69.5 | 72.1 |
| 12 | Void | 93.3 | 99.0 |
| 13 | Colossus | 117.0 | 123.8 |
| 14 | Awakened | 145.0 | 149.0 |
| 15 | Celestial | 216.0 | 226.9 |
| 16 | Forbidden | 412.7 | 415.5 |

Limitação do pool (sinalizada): o Forbidden tem 1 único Mítico, que sai em ~99% dos rolls do
Forbidden (é o "comum" do endgame); o valor do Dice são os 3 Divinos e os 3 Secretos.

## 4. Impacto da Luck (final)

Chance da raridade MAIS ALTA de cada Dice nos 4 cenários de Luck (e 1 em X).

| Dice | Raridade topo | Luck 1,0x | Luck do Dice | Máx. F2P | Máx. monetização |
|---|---|---|---|---|---|
| Starter | Épico | 3.00% (1 em 33) @1.00x | 3.00% (1 em 33) @1.00x | 7.99% (1 em 13) @10.40x | 9.29% (1 em 11) @22.88x |
| Lucky | Épico | 5.00% (1 em 20) @1.00x | 5.64% (1 em 18) @1.25x | 13.00% (1 em 8) @13.00x | 14.61% (1 em 7) @28.60x |
| Rampart | Épico | 7.00% (1 em 14) @1.00x | 8.26% (1 em 12) @1.40x | 17.05% (1 em 6) @14.56x | 18.77% (1 em 5) @32.03x |
| Shinobi | Épico | 10.00% (1 em 10) @1.00x | 12.55% (1 em 8) @1.70x | 22.52% (1 em 4) @17.68x | 24.18% (1 em 4) @38.90x |
| Flame | Lendário | 1.00% (1 em 100) @1.00x | 1.20% (1 em 83) @1.60x | 2.13% (1 em 47) @16.64x | 2.29% (1 em 44) @36.61x |
| Blade | Lendário | 2.00% (1 em 50) @1.00x | 2.45% (1 em 41) @1.80x | 3.95% (1 em 25) @18.72x | 4.18% (1 em 24) @41.18x |
| Fighter | Lendário | 3.00% (1 em 33) @1.00x | 3.69% (1 em 27) @1.90x | 5.66% (1 em 18) @19.76x | 5.95% (1 em 17) @43.47x |
| Storm | Lendário | 8.00% (1 em 13) @1.00x | 9.05% (1 em 11) @2.00x | 11.51% (1 em 9) @20.80x | 11.85% (1 em 8) @45.76x |
| Spirit | Mítico | 1.00% (1 em 100) @1.00x | 1.21% (1 em 83) @2.20x | 1.67% (1 em 60) @22.88x | 1.73% (1 em 58) @50.34x |
| Arcane | Mítico | 2.00% (1 em 50) @1.00x | 2.42% (1 em 41) @2.35x | 3.24% (1 em 31) @24.44x | 3.36% (1 em 30) @53.77x |
| Shadow | Mítico | 5.00% (1 em 20) @1.00x | 5.57% (1 em 18) @2.55x | 6.52% (1 em 15) @26.52x | 6.64% (1 em 15) @58.34x |
| Void | Divino | 0.3000% (1 em 333) @1.00x | 0.3827% (1 em 261) @2.75x | 0.5271% (1 em 190) @28.60x | 0.5471% (1 em 183) @62.92x |
| Colossus | Mítico | 15.00% (1 em 7) @1.00x | 16.81% (1 em 6) @3.50x | 18.73% (1 em 5) @36.40x | 18.95% (1 em 5) @80.08x |
| Awakened | Mítico | 15.00% (1 em 7) @1.00x | 16.33% (1 em 6) @3.10x | 17.95% (1 em 6) @32.24x | 18.14% (1 em 6) @70.93x |
| Celestial | Divino | 0.5000% (1 em 200) @1.00x | 0.6441% (1 em 155) @4.00x | 0.7943% (1 em 126) @41.60x | 0.8115% (1 em 123) @91.52x |
| Forbidden | Secreto | 0.00450% (1 em 22.222) @1.00x | 0.00770% (1 em 12.991) @4.00x | 0.0121% (1 em 8.283) @41.60x | 0.0126% (1 em 7.908) @91.52x |

Leitura: a Luck atual tem retornos decrescentes (Luck efetiva nunca passa de ~11) e, nos Dice
endgame, o denominador é dominado por Lendário/Mítico (que também sobem com a Luck). Por isso a
Luck máxima multiplica o Secreto do Forbidden por ~2,8x (não por 20–90x). **Não é preciso mudar
a estrutura da Luck** com os pesos finais; ver §6 e §11 para o efeito por hora e por prêmio.

## 5. Detalhe por Dice (final)

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

### 4. Shinobi — unlock 300 rolls + Rampart · preço 40k · Luck do Dice 1.70x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Comum | 2 | 35.00% | 1 em 3 | 3s | 1s | 30.89% | 1 em 3 | 3s |
| Incomum | 2 | 33.00% | 1 em 3 | 3s | 2s | 32.21% | 1 em 3 | 3s |
| Raro | 2 | 22.00% | 1 em 5 | 5s | 2s | 24.35% | 1 em 4 | 4s |
| Épico | 2 | 10.00% | 1 em 10 | 10s | 5s | 12.55% | 1 em 8 | 8s |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Narotu (`char_narotu_base`) | Épico | 5.00% | 1 em 20 | 20s | 10s |
| Kakaxi (`char_kakaxi_base`) | Épico | 5.00% | 1 em 20 | 20s | 10s |
| Gaaro (`char_gaaro_base`) | Raro | 11.00% | 1 em 9 | 9s | 5s |
| Zabuzo (`char_zabuzo_base`) | Raro | 11.00% | 1 em 9 | 9s | 5s |
| Roque Li (`char_roqueli_base`) | Incomum | 16.50% | 1 em 6 | 6s | 3s |
| Nejo (`char_nejo_base`) | Incomum | 16.50% | 1 em 6 | 6s | 3s |
| Sasuko (Jovem) (`char_sasuko_young`) | Comum | 17.50% | 1 em 6 | 6s | 3s |
| Narotu (Jovem) (`char_narotu_young`) | Comum | 17.50% | 1 em 6 | 6s | 3s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~28 rolls (Normal 28s · Rápido 14s).

### 5. Flame — unlock 425 rolls + Shinobi · preço 75k · Luck do Dice 1.60x

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

### 6. Blade — unlock 550 rolls + Flame · preço 125k · Luck do Dice 1.80x

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

### 13. Colossus — unlock 4500 rolls + Void · preço 12.5M · Luck do Dice 3.50x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Épico | 2 | 40.00% | 1 em 3 | 3s | 1s | 38.01% | 1 em 3 | 3s |
| Lendário | 2 | 45.00% | 1 em 2 | 2s | 1s | 45.18% | 1 em 2 | 2s |
| Mítico | 2 | 15.00% | 1 em 7 | 7s | 3s | 16.81% | 1 em 6 | 6s |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Mighto 5º Portão (`char_mighto_gate5`) | Mítico | 7.50% | 1 em 13 | 13s | 7s |
| Lufy Serpente (`char_lufy_snake`) | Mítico | 7.50% | 1 em 13 | 13s | 7s |
| Gohin (`char_gohin_base`) | Épico | 20.00% | 1 em 5 | 5s | 3s |
| Mighto (`char_mighto_base`) | Épico | 20.00% | 1 em 5 | 5s | 3s |
| Sasuko (`char_sasuko_base`) | Lendário | 22.50% | 1 em 4 | 4s | 2s |
| Brolli (`char_brolli_base`) | Lendário | 22.50% | 1 em 4 | 4s | 2s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~20 rolls (Normal 20s · Rápido 10s).

### 14. Awakened — unlock 6000 rolls + Colossus · preço 30M · Luck do Dice 3.10x

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

### 15. Celestial — unlock 8000 rolls + Awakened · preço 75M · Luck do Dice 4.00x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Lendário | 2 | 64.00% | 1 em 2 | 2s | 1s | 61.14% | 1 em 2 | 2s |
| Mítico | 2 | 35.50% | 1 em 3 | 3s | 1s | 38.22% | 1 em 3 | 3s |
| Divino | 3 | 0.5000% | 1 em 200 | 3m20s | 1m40s | 0.6441% | 1 em 155 | 2m35s |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Vegitto (`char_vegitto_base`) | Divino | 0.1667% | 1 em 600 | 10m00s | 5m00s |
| Deko 100% (`char_deko_full`) | Divino | 0.1667% | 1 em 600 | 10m00s | 5m00s |
| Goju (`char_goju_base`) | Divino | 0.1667% | 1 em 600 | 10m00s | 5m00s |
| Ol Maito Poder Total (`char_olmaito_mode`) | Mítico | 17.75% | 1 em 6 | 6s | 3s |
| Narotu Sábio (`char_narotu_sage`) | Mítico | 17.75% | 1 em 6 | 6s | 3s |
| Yujo (`char_yujo_base`) | Lendário | 32.00% | 1 em 3 | 3s | 2s |
| Sanjo (`char_sanjo_base`) | Lendário | 32.00% | 1 em 3 | 3s | 2s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~854 rolls (Normal 14m14s · Rápido 7m07s).

### 16. Forbidden — unlock 12000 rolls + Celestial · preço 750M · Luck do Dice 4.00x

| Raridade | Pers. | P (Luck 1) | Rolls esperados | Normal | Rápido | P (Luck do Dice) | Rolls | Normal |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Mítico | 1 | 99.25% | 1 em 1 | 1s | 1s | 99.10% | 1 em 1 | 1s |
| Divino | 3 | 0.7500% | 1 em 133 | 2m13s | 1m07s | 0.8961% | 1 em 112 | 1m52s |
| Secreto | 3 | 0.00450% | 1 em 22.222 | 6h10m | 3h05m | 0.00770% | 1 em 12.991 | 3h36m |

| Personagem | Raridade | P (Luck 1) | Rolls esperados | Normal | Rápido |
|---|---|---:|---:|---:|---:|
| Vegitto Azul (`char_vegitto_blue`) | Secreto | 0.00150% | 1 em 66.667 | 18h31m | 9h15m |
| Ichiro Mugetsu (`char_ichiro_mugetsu`) | Secreto | 0.00150% | 1 em 66.667 | 18h31m | 9h15m |
| Mighto 8º Portão (`char_mighto_gate8`) | Secreto | 0.00150% | 1 em 66.667 | 18h31m | 9h15m |
| Madaro (`char_madaro_base`) | Divino | 0.2500% | 1 em 400 | 6m40s | 3m20s |
| Aizo (`char_aizo_base`) | Divino | 0.2500% | 1 em 400 | 6m40s | 3m20s |
| Brolli Lendário (`char_brolli_legend`) | Divino | 0.2500% | 1 em 400 | 6m40s | 3m20s |
| Barbalva (`char_barbalva_base`) | Mítico | 99.25% | 1 em 1 | 1s | 1s |

Completar o pool (todos ao menos 1x, Luck do Dice): ~71.453 rolls (Normal 19h50m · Rápido 9h55m).

## 6. Celestial e Forbidden (endgame) — análise detalhada

### Celestial

| Cenário | Lendário | Mítico | Divino | ERV |
|---|---|---|---|---:|
| Luck 1,0x | 64.00% (1 em 2) | 35.50% (1 em 3) | 0.5000% (1 em 200) | 216.0 |
| Luck do Dice (4.00x) | 61.14% (1 em 2) | 38.22% (1 em 3) | 0.6441% (1 em 155) | 226.9 |
| Máx. F2P (41.6x) | 58.66% (1 em 2) | 40.54% (1 em 2) | 0.7943% (1 em 126) | 236.7 |
| Máx. com monetização (91.5x) | 58.40% (1 em 2) | 40.79% (1 em 2) | 0.8115% (1 em 123) | 237.8 |

Por hora (expectativa), raridades top:

| Cenário | Cadência | Mítico/h | Divino/h | 1 Divino a cada |
|---|---|---:|---:|---:|
| Luck 1,0x | Normal | 1278.0 | 18.00 | 3m20s |
| Luck 1,0x | Rápido | 2556.0 | 36.00 | 1m40s |
| Luck do Dice (4.00x) | Normal | 1375.9 | 23.19 | 2m35s |
| Luck do Dice (4.00x) | Rápido | 2751.9 | 46.38 | 1m18s |
| Máx. F2P (41.6x) | Normal | 1459.6 | 28.59 | 2m06s |
| Máx. F2P (41.6x) | Rápido | 2919.2 | 57.19 | 1m03s |
| Máx. com monetização (91.5x) | Normal | 1468.3 | 29.21 | 2m03s |
| Máx. com monetização (91.5x) | Rápido | 2936.6 | 58.43 | 1m02s |

### Forbidden

| Cenário | Mítico | Divino | Secreto | ERV |
|---|---|---|---|---:|
| Luck 1,0x | 99.25% (1 em 1) | 0.7500% (1 em 133) | 0.00450% (1 em 22.222) | 412.7 |
| Luck do Dice (4.00x) | 99.10% (1 em 1) | 0.8961% (1 em 112) | 0.00770% (1 em 12.991) | 415.5 |
| Máx. F2P (41.6x) | 98.95% (1 em 1) | 1.04% (1 em 96) | 0.0121% (1 em 8.283) | 418.4 |
| Máx. com monetização (91.5x) | 98.93% (1 em 1) | 1.06% (1 em 95) | 0.0126% (1 em 7.908) | 418.7 |

Por hora (expectativa), raridades top:

| Cenário | Cadência | Divino/h | Secreto/h | 1 Secreto a cada |
|---|---|---:|---:|---:|
| Luck 1,0x | Normal | 27.0 | 0.16 | 6h10m |
| Luck 1,0x | Rápido | 54.0 | 0.32 | 3h05m |
| Luck do Dice (4.00x) | Normal | 32.3 | 0.28 | 3h36m |
| Luck do Dice (4.00x) | Rápido | 64.5 | 0.55 | 1h48m |
| Máx. F2P (41.6x) | Normal | 37.4 | 0.43 | 2h18m |
| Máx. F2P (41.6x) | Rápido | 74.9 | 0.87 | 1h09m |
| Máx. com monetização (91.5x) | Normal | 38.0 | 0.46 | 2h11m |
| Máx. com monetização (91.5x) | Rápido | 76.0 | 0.91 | 1h05m |

**Forbidden (final):** Mítico 99,2455% · Divino 0,75% · Secreto 0,0045%. Secreto 1 em ~22.200 com
Luck 1 (cada um dos 3: 1 em ~66.700), **abaixo de 1 por hora mesmo no máximo absoluto** (Luck máxima com
monetização + Roll Rápido) — meta da auditoria de RNG. Antes (75/20/5) era 1 Secreto a cada 20 rolls.

**Celestial (final):** Lendário 64% · Mítico 35,5% · Divino 0,5% (cada um dos 3 Divinos: 1 em 600).

## 7. Pity com os pesos finais

Final: Lendário 50 (mantido) · Mítico 250 (era 800). Um pity só vale em Dice que tem a raridade do piso.
Tempo para 50 rolls: Normal 50s · Rápido 25s. Para 250 rolls: Normal 4m10s · Rápido 2m05s.

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
| Colossus | 60.00% | 1 em 2 | 0.00000% | 1.7 | 0.00000% | 1.7 | 0.00000% | 1.7 | 0.00000% | 1.7 |
| Awakened | 100.00% | 1 em 1 | 0.00000% | 1.0 | 0.00000% | 1.0 | 0.00000% | 1.0 | 0.00000% | 1.0 |
| Celestial | 100.00% | 1 em 1 | 0.00000% | 1.0 | 0.00000% | 1.0 | 0.00000% | 1.0 | 0.00000% | 1.0 |

Dice SEM a raridade (pity congelado): Starter, Lucky, Rampart, Shinobi, Forbidden.

### Pity Mythic (piso: Mítico ou melhor)

| Dice | P natural (Luck 1) | 1 em | chega ao pity 250 | rolls efetivos 250 | chega ao pity 400 | rolls efetivos 400 | chega ao pity 800 | rolls efetivos 800 |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Spirit | 1.00% | 1 em 100 | 8.19% | 91.9 | 1.81% | 98.2 | 0.0325% | 100.0 |
| Arcane | 2.00% | 1 em 50 | 0.6536% | 49.7 | 0.0316% | 50.0 | 0.00001% | 50.0 |
| Shadow | 5.00% | 1 em 20 | 0.00028% | 20.0 | 0.00000% | 20.0 | 0.00000% | 20.0 |
| Void | 9.00% | 1 em 11 | 0.00000% | 11.1 | 0.00000% | 11.1 | 0.00000% | 11.1 |
| Colossus | 15.00% | 1 em 7 | 0.00000% | 6.7 | 0.00000% | 6.7 | 0.00000% | 6.7 |
| Awakened | 15.00% | 1 em 7 | 0.00000% | 6.7 | 0.00000% | 6.7 | 0.00000% | 6.7 |
| Celestial | 36.00% | 1 em 3 | 0.00000% | 2.8 | 0.00000% | 2.8 | 0.00000% | 2.8 |
| Forbidden | 100.00% | 1 em 1 | 0.00000% | 1.0 | 0.00000% | 1.0 | 0.00000% | 1.0 |

Dice SEM a raridade (pity congelado): Starter, Lucky, Rampart, Shinobi, Flame, Blade, Fighter, Storm.

"Chega ao pity" = fração dos ciclos que só terminam pelo pity ((1−p)^(N−1)); "rolls efetivos" =
rolls médios entre acertos COM pity ((1−(1−p)^N)/p). Sem pity seria 1/p.

**Lendário 50 (mantido por decisão de design):** no Flame (Lendário 1%) ~61% dos Lendários vêm do
pity (1 Lendário a cada ~40 rolls em vez de 100), no Blade ~37%, no Fighter ~22%; do Storm em diante o
pity quase não age. Intencional: início/meio de jogo mais generoso, com momentos fortes para iniciantes.

**Mítico 250 (aplicado):** só onde o Mítico é raro — Spirit ~8% dos Míticos pelo pity (~92 rolls entre
Míticos em vez de 100), Arcane ~0,6%, Shadow em diante ~0. Com 800 era decorativo (~0,03% no Spirit).

## 8. Preços e unlocks (por posição; economia ainda pendente)

| # | Dice | Preço | × anterior | Rolls p/ desbloquear | Δ rolls | ~tempo de roll (Normal) | Completar pool anterior (Luck do Dice) |
|---:|---|---:|---:|---:|---:|---:|---:|
| 1 | Starter | 0 | — | 0 | — | 0s | — |
| 2 | Lucky | 2.5k | — | 50 | 50 | 50s | 39 rolls |
| 3 | Rampart | 10k | 4.0x | 125 | 75 | 2m05s | 31 rolls |
| 4 | Shinobi | 40k | 4.0x | 300 | 175 | 5m00s | 40 rolls |
| 5 | Flame | 75k | 1.9x | 425 | 125 | 7m05s | 28 rolls |
| 6 | Blade | 125k | 1.7x | 550 | 125 | 9m10s | 84 rolls |
| 7 | Fighter | 225k | 1.8x | 775 | 225 | 12m55s | 47 rolls |
| 8 | Storm | 400k | 1.8x | 1000 | 225 | 16m40s | 32 rolls |
| 9 | Spirit | 750k | 1.9x | 1500 | 500 | 25m00s | 35 rolls |
| 10 | Arcane | 1.4M | 1.9x | 2000 | 500 | 33m20s | 87 rolls |
| 11 | Shadow | 2.6M | 1.9x | 2500 | 500 | 41m40s | 46 rolls |
| 12 | Void | 5M | 1.9x | 3000 | 500 | 50m00s | 55 rolls |
| 13 | Colossus | 12.5M | 2.5x | 4500 | 1500 | 1h15m | 262 rolls |
| 14 | Awakened | 30M | 2.4x | 6000 | 1500 | 1h40m | 20 rolls |
| 15 | Celestial | 75M | 2.5x | 8000 | 2000 | 2h13m | 34 rolls |
| 16 | Forbidden | 750M | 10.0x | 12000 | 4000 | 3h20m | 854 rolls |

Preço e rolls pertencem à POSIÇÃO (#4 = 40k / 300 rolls, #5 = 75k / 425, #13 = 12,5M / 4.500,
#14 = 30M / 6.000): com a Variante B, Shinobi e Colossus ficaram mais baratos e Flame e Awakened mais caros.
Completar cada pool custa dezenas de rolls (Void/Celestial: centenas; Forbidden: dezenas de milhares por
causa dos Secretos): o freio da progressão é o PREÇO. Validar com a renda real na fase de economia.

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
| Shinobi | Comum | 35.00% | 34.92% | -1.66 | 2.28 |
|  | Incomum | 33.00% | 33.04% | +0.89 |  |
|  | Raro | 22.00% | 22.04% | +1.05 |  |
|  | Épico | 10.00% | 9.99% | -0.21 |  |
| Flame | Incomum | 60.00% | 60.04% | +0.72 | 1.60 |
|  | Raro | 28.00% | 27.95% | -1.03 |  |
|  | Épico | 11.00% | 11.01% | +0.41 |  |
|  | Lendário | 1.00% | 0.9986% | -0.14 |  |
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
| Colossus | Épico | 40.00% | 40.09% | +1.80 | 1.68 |
|  | Lendário | 45.00% | 44.94% | -1.16 |  |
|  | Mítico | 15.00% | 14.97% | -0.85 |  |
| Awakened | Lendário | 85.00% | 85.05% | +1.36 | 2.70 |
|  | Mítico | 15.00% | 14.95% | -1.36 |  |
| Celestial | Lendário | 64.00% | 64.01% | +0.16 | 1.77 |
|  | Mítico | 35.50% | 35.49% | -0.11 |  |
|  | Divino | 0.5000% | 0.4977% | -0.33 |  |
| Forbidden | Mítico | 99.25% | 99.25% | +0.96 | 1.32 |
|  | Divino | 0.7500% | 0.7422% | -0.90 |  |
|  | Secreto | 0.00450% | 0.00400% | -0.75 |  |

Maior desvio entre TODOS os personagens dos 16 Dice: |z| = 2.70 (esperado < ~4 com 112 comparações).

## 10. Sessões endgame (Luck do Dice, pity 50/250, sementes fixas)

| Dice | Sessão | Sessões simuladas | Míticos (média) | Divinos (média) | Secretos (média) | P(≥1 Divino) | P(≥1 Secreto) |
|---|---:|---:|---:|---:|---:|---:|---:|
| Awakened | 100 rolls | 5000 | 16.33 | 0.000 | 0.0000 | 0.0% | 0.00% |
|  | 1000 rolls | 1000 | 163.44 | 0.000 | 0.0000 | 0.0% | 0.00% |
|  | 10000 rolls | 200 | 1636.94 | 0.000 | 0.0000 | 0.0% | 0.00% |
| Colossus | 100 rolls | 5000 | 16.87 | 0.000 | 0.0000 | 0.0% | 0.00% |
|  | 1000 rolls | 1000 | 167.97 | 0.000 | 0.0000 | 0.0% | 0.00% |
|  | 10000 rolls | 200 | 1680.54 | 0.000 | 0.0000 | 0.0% | 0.00% |
| Celestial | 100 rolls | 5000 | 38.29 | 0.640 | 0.0000 | 47.5% | 0.00% |
|  | 1000 rolls | 1000 | 382.12 | 6.442 | 0.0000 | 100.0% | 0.00% |
|  | 10000 rolls | 200 | 3822.86 | 64.695 | 0.0000 | 100.0% | 0.00% |
| Forbidden | 100 rolls | 5000 | 99.10 | 0.889 | 0.0078 | 59.3% | 0.78% |
|  | 1000 rolls | 1000 | 991.02 | 8.901 | 0.0830 | 100.0% | 8.10% |
|  | 10000 rolls | 200 | 9909.83 | 89.435 | 0.7300 | 100.0% | 50.00% |

Sessão de 100 rolls ≈ 1m40s (Normal); 1.000 ≈ 16m40s; 10.000 ≈ 2h47m.

## 11. Endgame: rolls e tempo esperados (final)

| Prêmio | Cenário | Chance | Rolls esperados | Normal (1/s) | Roll Rápido (2/s) |
|---|---|---:|---:|---:|---:|
| Divino (Celestial) | Luck 1,0x | 0.5000% | 1 em 200 | 3m20s | 1m40s |
| Divino (Celestial) | Luck do Dice (4.00x) | 0.6441% | 1 em 155 | 2m35s | 1m18s |
| Divino (Celestial) | Máx. F2P (41.6x) | 0.7943% | 1 em 126 | 2m06s | 1m03s |
| Divino (Celestial) | Máx. com monetização (91.5x) | 0.8115% | 1 em 123 | 2m03s | 1m02s |
| Divino (Forbidden) | Luck 1,0x | 0.7500% | 1 em 133 | 2m13s | 1m07s |
| Divino (Forbidden) | Luck do Dice (4.00x) | 0.8961% | 1 em 112 | 1m52s | 56s |
| Divino (Forbidden) | Máx. F2P (41.6x) | 1.04% | 1 em 96 | 1m36s | 48s |
| Divino (Forbidden) | Máx. com monetização (91.5x) | 1.06% | 1 em 95 | 1m35s | 47s |
| Secreto (Forbidden, qualquer) | Luck 1,0x | 0.00450% | 1 em 22.222 | 6h10m | 3h05m |
| Secreto (Forbidden, qualquer) | Luck do Dice (4.00x) | 0.00770% | 1 em 12.991 | 3h36m | 1h48m |
| Secreto (Forbidden, qualquer) | Máx. F2P (41.6x) | 0.0121% | 1 em 8.283 | 2h18m | 1h09m |
| Secreto (Forbidden, qualquer) | Máx. com monetização (91.5x) | 0.0126% | 1 em 7.908 | 2h11m | 1h05m |
| Secreto Ichiro Mugetsu (`char_ichiro_mugetsu`) | Luck 1,0x | 0.00150% | 1 em 66.667 | 18h31m | 9h15m |
| Secreto Ichiro Mugetsu (`char_ichiro_mugetsu`) | Luck do Dice (4.00x) | 0.00257% | 1 em 38.974 | 10h49m | 5h24m |
| Secreto Ichiro Mugetsu (`char_ichiro_mugetsu`) | Máx. F2P (41.6x) | 0.00402% | 1 em 24.848 | 6h54m | 3h27m |
| Secreto Ichiro Mugetsu (`char_ichiro_mugetsu`) | Máx. com monetização (91.5x) | 0.00422% | 1 em 23.724 | 6h35m | 3h17m |
| Secreto Mighto 8º Portão (`char_mighto_gate8`) | Luck 1,0x | 0.00150% | 1 em 66.667 | 18h31m | 9h15m |
| Secreto Mighto 8º Portão (`char_mighto_gate8`) | Luck do Dice (4.00x) | 0.00257% | 1 em 38.974 | 10h49m | 5h24m |
| Secreto Mighto 8º Portão (`char_mighto_gate8`) | Máx. F2P (41.6x) | 0.00402% | 1 em 24.848 | 6h54m | 3h27m |
| Secreto Mighto 8º Portão (`char_mighto_gate8`) | Máx. com monetização (91.5x) | 0.00422% | 1 em 23.724 | 6h35m | 3h17m |
| Secreto Vegitto Azul (`char_vegitto_blue`) | Luck 1,0x | 0.00150% | 1 em 66.667 | 18h31m | 9h15m |
| Secreto Vegitto Azul (`char_vegitto_blue`) | Luck do Dice (4.00x) | 0.00257% | 1 em 38.974 | 10h49m | 5h24m |
| Secreto Vegitto Azul (`char_vegitto_blue`) | Máx. F2P (41.6x) | 0.00402% | 1 em 24.848 | 6h54m | 3h27m |
| Secreto Vegitto Azul (`char_vegitto_blue`) | Máx. com monetização (91.5x) | 0.00422% | 1 em 23.724 | 6h35m | 3h17m |

## 12. Prisma da Coleção (implementado)

Prism (Dia 7 do Diário) = **Prisma da Coleção**: cada uso sorteia no Dice SELECIONADO, mas só entre os
personagens ainda NÃO descobertos, com as probabilidades relativas do Dice (P(c)/Σ elegíveis). Não muda
pesos, Luck, pity (`PrismConfig.AffectsPity = false`) nem a contagem de rolls; Dice completo = recusado
sem gastar o uso; não é vendido. Usos: `PrismConfig.UsesPerReward` por entrega do Diário (teto
`MaxCharges`), intervalo mínimo `CooldownSeconds`.

Exemplo (Forbidden, só faltando os 3 Secretos): o prisma entrega um Secreto com 100% de chance — é o
efeito desejado de "completar a coleção", limitado pelos usos que só o Diário dá.

