"""Catálogo PROPOSTO dos 152 modelos do Anime Pack (planejamento — nada é integrado ao jogo).

    python tools/packaudit/catalog.py

Lê third_party/AnimePack_summary.json (dados medidos pela auditoria) + a curadoria abaixo e gera:
    FULL_CHARACTER_CATALOG.md · DICE_PROGRESSION_PROPOSAL.md · FUTURE_CONTENT_RESERVE.md
    PREMIUM_DICE_PROPOSAL.md · REJECTED_CHARACTERS.md · third_party/catalog_proposal.json

Regras:
- SourceModelName = nome do modelo no pack (só desenvolvimento, nunca mostrado ao jogador).
- CharacterId = chave de save: minúsculas/dígitos/_ , única, estável, NÃO derivada do DisplayName.
- DisplayName = nome alterado (pode mudar no futuro sem afetar saves).
- Status: APPROVED · NEEDS_OPTIMIZATION (> 40 peças ou > 20 efeitos próprios) · DUPLICATE ·
  BROKEN · STAND_ONLY · REJECTED.
"""
from __future__ import annotations

import json
import re
import sys
from collections import Counter, defaultdict
from pathlib import Path

RAIZ = Path(__file__).resolve().parents[2]
SUMMARY = RAIZ / "third_party" / "AnimePack_summary.json"

RARITIES = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Divine", "Secret"]
PT = {"Common": "Comum", "Uncommon": "Incomum", "Rare": "Raro", "Epic": "Épico", "Legendary": "Lendário",
      "Mythic": "Mítico", "Divine": "Divino", "Secret": "Secreto"}
MAX_PARTS = 40
MAX_OWN_VFX = 20
# Kit de combate do jogo original (não é visual do personagem)
COMBAT_KIT = ("MoveT", "Smoke", "Break", "Bubbles", "Slider", "Hit1", "Hit2", "Block", "SoruP", "LevelParticle",
              "SenzuEat", "SweatParticle")

# ---------------------------------------------------------------------------------
# Dice F2P propostos (ordem de desbloqueio). anchor = Dice que já existe hoje no jogo.
DICE = [
    {"id": "starter", "name": "Starter Dice", "anchor": "Normal", "theme": "Recrutas e civis: primeiros personagens, silhuetas simples e limpas."},
    {"id": "lucky", "name": "Lucky Dice", "anchor": "Lucky", "theme": "Aventureiros e apostadores: sorte, viagem, cartas."},
    {"id": "rampart", "name": "Rampart Dice", "anchor": None, "theme": "Soldados das muralhas e os primeiros titãs: uniforme militar, capas, escala."},
    {"id": "flame", "name": "Flame Dice", "anchor": "Flame", "theme": "Fogo, explosão e magma."},
    {"id": "shinobi", "name": "Shinobi Dice", "anchor": None, "theme": "Ninjas: bandanas, máscaras, areia e espadas de ninja."},
    {"id": "blade", "name": "Blade Dice", "anchor": None, "theme": "Espadachins: katanas, lâminas duplas e trilhas de corte."},
    {"id": "fighter", "name": "Fighter Dice", "anchor": None, "theme": "Lutadores de punho e heróis de força."},
    {"id": "storm", "name": "Storm Dice", "anchor": "Storm", "theme": "Raio, velocidade e energia elétrica."},
    {"id": "spirit", "name": "Spirit Dice", "anchor": None, "theme": "Guerreiros espirituais: energia espiritual, gelo, flores, capas de capitão."},
    {"id": "arcane", "name": "Arcane Dice", "anchor": None, "theme": "Magia e heróis lendários: arcos, lanças, espadas mágicas."},
    {"id": "shadow", "name": "Shadow Dice", "anchor": None, "theme": "Formas sombrias, máscaras e vilões frios."},
    {"id": "void", "name": "Void Dice", "anchor": "Void", "theme": "Vazio e transformações sinistras."},
    {"id": "awakened", "name": "Awakened Dice", "anchor": None, "theme": "Formas DESPERTAS: o mesmo herói, agora com aura."},
    {"id": "colossus", "name": "Colossus Dice", "anchor": None, "theme": "Força bruta e gigantes: portões, berserkers, monstros."},
    {"id": "celestial", "name": "Celestial Dice", "anchor": "Celestial", "theme": "Lendas em forma máxima: Divinos da progressão principal."},
    {"id": "forbidden", "name": "Forbidden Dice", "anchor": None, "theme": "Endgame: Secretos e as formas finais mais raras."},
]
DICE_BY_ID = {d["id"]: d for d in DICE}
RESERVE = {
    "event": "Event Dice",
    "limited": "Limited Dice",
    "banner": "Special Banner",
    "future": "Future Update",
}

# ---------------------------------------------------------------------------------
# Curadoria: (SourceModelPath, DisplayName, CharacterId, Family, FormTier, Rarity, Destino, Status forçado, Nota)
# Destino: id de Dice F2P · "premium" · event/limited/banner/future · None (fora do jogo)
C = [
    # AOT — simples (8–9 peças), sem scripts/VFX: ótimos para o começo
    ("AOT.Sasha", "Sacha", "sacha", "sacha", 1, "Common", "starter", None, "Uniforme; base perfeita para Comum."),
    ("AOT.Sasha (Suit)", "Sacha (Terno)", "sacha_suit", "sacha", 1, "Common", "starter", None, "Roupa alternativa (mesma forma)."),
    ("AOT.Annie (Junior High)", "Anny (Colegial)", "anny_school", "anny", 1, "Common", "starter", None, "Roupa alternativa."),
    ("AOT.Mikasa (Formal)", "Mikaza (Formal)", "mikaza_formal", "mikaza", 1, "Common", "starter", None, "Roupa alternativa."),
    ("AOT.Erwin (Alt)", "Erwyn (Gala)", "erwyn_gala", "erwyn", 1, "Uncommon", "starter", None, "Roupa alternativa."),
    ("AOT.Eren", "Erem", "erem", "erem", 1, "Common", "rampart", None, None),
    ("AOT.Mikasa", "Mikaza", "mikaza", "mikaza", 1, "Uncommon", "rampart", None, None),
    ("AOT.Annie", "Anny", "anny", "anny", 1, "Uncommon", "rampart", None, None),
    ("AOT.Erwin", "Erwyn", "erwyn", "erwyn", 1, "Rare", "rampart", None, "Mesma camisa do uniforme da Sacha (normal: mesma tropa)."),
    ("AOT.Eren Post-time skip", "Erem (Veterano)", "erem_veteran", "erem", 2, "Rare", "rampart", None, None),
    ("AOT.Female Titan", "Titã Feminina", "anny_titan", "anny", 2, "Epic", "rampart", None, "Forma titã da Anny."),
    ("AOT.Attack Titan", "Titã de Ataque", "erem_titan", "erem", 3, "Epic", "rampart", None, "Forma titã do Erem."),
    # BLEACH
    ("Bleach Pack.Ichigo", "Ichiro", "ichiro", "ichiro", 1, "Uncommon", "blade", None, "Mesma roupa e contagens da Rukya: confirmar cabelo no Studio."),
    ("Bleach Pack.Hollow Ichigo.Hollow Ichigo", "Ichiro Mascarado", "ichiro_hollow", "ichiro", 2, "Mythic", "shadow", None, None),
    ("Bleach Pack.Hollow Ichigo.Vasto", "Ichiro Vasto", "ichiro_vasto", "ichiro", 3, "Divine", "void", None, None),
    ("Bleach Pack.Hollow Ichigo.Mugetsu", "Ichiro Mugetsu", "ichiro_mugetsu", "ichiro", 4, "Secret", "forbidden", None, "Chama negra própria; forma final."),
    ("Bleach Pack.Rukia", "Rukya", "rukya", "rukya", 1, "Rare", "lucky", None, "Mesma roupa e contagens do Ichiro: confirmar cabelo no Studio."),
    ("Bleach Pack.Kisuke", "Kisuko", "kisuko", "kisuko", 1, "Rare", "blade", None, None),
    ("Bleach Pack.Gin", "Ginn", "ginn", "ginn", 1, "Rare", "blade", None, "Lâmina extensível."),
    ("Bleach Pack.Shinji", "Shinjo", "shinjo", "shinjo", 1, "Epic", "shadow", None, None),
    ("Bleach Pack.Toshiro.Toshiro", "Toshiru", "toshiru", "toshiru", 1, "Rare", "spirit", None, None),
    ("Bleach Pack.Toshiro.Bankai Toshiro", "Toshiru Bankai", "toshiru_bankai", "toshiru", 2, "Secret", "premium", None, "Maior nota do pack (asas de gelo)."),
    ("Bleach Pack.Byakuya", "Byakuto", "byakuto", "byakuto", 1, "Epic", "spirit", None, None),
    ("Bleach Pack.Shunsui", "Shunzo", "shunzo", "shunzo", 1, "Epic", "spirit", None, "Duas lâminas."),
    ("Bleach Pack.Starrk", "Starko", "starko", "starko", 1, "Epic", "spirit", None, "Espadas de energia."),
    ("Bleach Pack.Yoruichi.Yoruichi", "Yoruka", "yoruka", "yoruka", 1, "Legendary", "spirit", None, None),
    ("Bleach Pack.Yoruichi.Shunko Yoruichi", "Yoruka Shunko", "yoruka_shunko", "yoruka", 2, "Mythic", "premium", None, None),
    ("Bleach Pack.Yoruichi.Neko Yoru", "Yoruka Felina", "yoruka_neko", "yoruka", 3, "Mythic", "limited", None, "Forma felina com raios."),
    ("Bleach Pack.Grimmjow", "Grimjau", "grimjau", "grimjau", 1, "Epic", "shadow", None, None),
    ("Bleach Pack.Ulquiorra.Ulq", "Ulkiorra", "ulkiorra", "ulkiorra", 1, "Epic", "shadow", None, None),
    ("Bleach Pack.Ulquiorra.R1", "Ulkiorra Liberado", "ulkiorra_release", "ulkiorra", 2, "Mythic", "void", None, None),
    ("Bleach Pack.Ulquiorra.R2", "Ulkiorra Segunda Forma", "ulkiorra_second", "ulkiorra", 3, "Divine", "event", None, None),
    ("Bleach Pack.Aizen.Aizen", "Aizo", "aizo", "aizo", 1, "Divine", "forbidden", None, None),
    ("Bleach Pack.Aizen.Final Aizen", "Aizo Transcendido", "aizo_final", "aizo", 2, "Secret", "event", None, None),
    ("Bleach Pack.Yamamoto", "Yamamotu", "yamamotu", "yamamotu", 1, "Epic", "flame", None, "Fogo próprio."),
    # DBZ
    ("DBZ.Krillin", "Kurilo", "kurilo", "kurilo", 1, "Rare", "starter", None, "Mesma roupa do Goko."),
    ("DBZ.Goku", "Goko", "goko", "goko", 1, "Uncommon", "fighter", None, None),
    ("DBZ.Buu Saga Goku", "Goko (Saga Majin)", "goko_majin_saga", "goko", 2, "Epic", "storm", None, "Aura e raios."),
    ("DBZ.Gohan", "Gohin", "gohin", "gohin", 1, "Epic", "colossus", None, None),
    ("DBZ.Piccolo", "Pikkolo", "pikkolo", "pikkolo", 1, "Epic", "fighter", None, None),
    ("DBZ.Trunks", "Trunkz", "trunkz", "trunkz", 1, "Rare", "blade", None, "Espada nas costas."),
    ("DBZ.Caulifa", "Kaulifa", "kaulifa", "kaulifa", 1, "Epic", "storm", None, "Aura e raios."),
    ("DBZ.Vegeta", "Vejita", "vejita", "vejita", 1, "Epic", "void", None, None),
    ("DBZ.Majin Vegeta", "Vejita Majin", "vejita_majin", "vejita", 2, "Legendary", "void", None, None),
    ("DBZ.Vegito.VEGITO", "Vegitto", "vegitto", "vegitto", 1, "Divine", "celestial", None, None),
    ("DBZ.Vegito.VEGITO BLUE", "Vegitto Azul", "vegitto_blue", "vegitto", 2, "Secret", "forbidden", None, None),
    ("DBZ.Broly.Broly", "Brolli", "brolli", "brolli", 1, "Legendary", "colossus", None, None),
    ("DBZ.Broly.LSSJ BROLY", "Brolli Lendário", "brolli_legend", "brolli", 2, "Divine", "forbidden", None, None),
    ("DBZ.Goku Black.Goku Black [NEW]", "Goko Sombrio", "goko_dark", "goko_dark", 1, "Mythic", "shadow", None, None),
    ("DBZ.Goku Black.SSJR", "Goko Sombrio Rosé", "goko_dark_rose", "goko_dark", 2, "Mythic", "premium", None, "Aura rosé."),
    # FATE
    ("FATE.Fate Pack.Shirou", "Shiro", "shiro", "shiro", 1, "Rare", "arcane", None, "Lâminas duplas."),
    ("FATE.Archer (EMIYA)", "Emyia Arqueiro", "shiro_archer", "shiro", 2, "Mythic", "arcane", None, "Mesmas lâminas e malhas do Shiro (forma futura)."),
    ("FATE.Fate Pack.Saber", "Seiba", "seiba", "seiba", 1, "Rare", "arcane", None, None),
    ("FATE.SALTER", "Seiba Sombria", "seiba_alter", "seiba", 2, "Divine", "premium", None, None),
    ("FATE.Fate Pack.Gilgamesh", "Gilgamex", "gilgamex", "gilgamex", 1, "Legendary", "arcane", None, None),
    ("FATE.Iskandar", "Iskander", "iskander", "iskander", 1, "Epic", "premium", None, None),
    ("FATE.Kiritsugu", "Kiritsugo", "kiritsugo", "kiritsugo", 1, "Rare", "arcane", None, None),
    ("FATE.Rin", "Rinn", "rinn", "rinn", 1, "Uncommon", "lucky", None, "Arco."),
    ("FATE.Lancer", "Lanseiro", "lanseiro", "lanseiro", 1, "Rare", "storm", None, "Lança."),
    ("FATE.Lancer Mode", "Lanseiro Ardente", "lanseiro_mode", "lanseiro", 2, "Legendary", "premium", None, None),
    # FAIRY TAIL
    ("Fairy Tail.Natsu", "Natzu", "natzu", "natzu", 1, "Uncommon", "flame", None, None),
    ("Fairy Tail.Natsu Awakened", "Natzu Desperto", "natzu_awakened", "natzu", 2, "Mythic", "awakened", None, "Fogo próprio."),
    ("Fairy Tail.Gray", "Grei", "grei", "grei", 1, "Rare", "lucky", None, None),
    ("Fairy Tail.Grey Awakening", "Grei Desperto", "grei_awakened", "grei", 2, "Legendary", "awakened", None, None),
    # HXH
    ("HXH.Gon", "Gom", "gom", "gom", 1, "Common", "lucky", None, None),
    ("HXH.Adult Gon", "Gom Adulto", "gom_adult", "gom", 2, "Mythic", "awakened", None, None),
    ("HXH.Killua", "Killuo", "killuo", "killuo", 1, "Rare", "storm", None, None),
    ("HXH.Killua Godspeed", "Killuo Relâmpago", "killuo_godspeed", "killuo", 2, "Legendary", "storm", None, "Raios próprios."),
    ("HXH.Illumi", "Ilumi", "ilumi", "ilumi", 1, "Epic", "void", None, None),
    ("HXH.Illumi Awakened", "Ilumi Desperto", "ilumi_awakened", "ilumi", 2, "Legendary", "void", None, None),
    ("HXH.Hisoka#2", "Hizoka", "hizoka", "hizoka", 1, "Epic", "lucky", None, "Versão com aura (rosto diferente)."),
    ("HXH.Hisoka#1", "Hizoka", None, "hizoka", 1, None, None, "DUPLICATE", "Mesma roupa e malhas da outra Hizoka; muda só o rosto e não tem aura."),
    # JJK
    ("JJK.Gojo Satoru", "Goju", "goju", "goju", 1, "Divine", "celestial", None, None),
    ("JJK.Gojo Satoru (Blindfold Off)", "Goju (Sem Venda)", None, "goju", 2, None, None, "DUPLICATE", "Idêntico ao Goju em roupa, peças, malhas e texturas medidas. Se os olhos forem diferentes no Studio, vira forma 2."),
    ("JJK.Yuji", "Yujo", "yujo", "yujo", 1, "Legendary", "celestial", None, None),
    ("JJK.Sukuna", "Sukano", "sukano", "sukano", 1, "Divine", "banner", None, None),
    # JOJO — personagens (reservados para o update "Mundo dos Stands") + Stands
    ("JOJO.Jonathan", "Jonatan", "jonatan", "jonatan", 1, "Epic", "future", None, "Hamon."),
    ("JOJO.Young Joseph", "Josef", "josef", "josef", 1, "Rare", "future", None, None),
    ("JOJO.Old Joseph", "Josef Veterano", "josef_old", "josef", 2, "Legendary", "future", None, "Hamon e vinhas."),
    ("JOJO.Jotaro.Model.Jotaro", "Jotaru", "jotaru", "jotaru", 1, "Mythic", "banner", None, None),
    ("JOJO.Josuke.Josuke", "Jozuke", "jozuke", "jozuke", 1, "Legendary", "future", None, None),
    ("JOJO.DIO.DIO", "Dyo", "dyo", "dyo", 1, "Mythic", "future", None, None),
    ("JOJO.DIO.DIO AWAKENED", "Dyo Desperto", "dyo_awakened", "dyo", 2, "Divine", "event", None, None),
    ("JOJO.Kira Yoshikage.Kira Yoshikage", "Kiro Yoshi", "kiro_yoshi", "kiro_yoshi", 1, "Mythic", "future", None, None),
    ("JOJO.Giorno.Giorno", "Jorno", "jorno", "jorno", 1, "Mythic", "banner", None, None),
    ("JOJO.Giorno (BUT BOSS).Giorno", "Jorno Chefe", "jorno_boss", "jorno", 2, "Divine", "limited", None, "Mesmas malhas do Jorno com terno diferente."),
    ("JOJO.Doppio/Diavolo.Doppio", "Dopio", "dopio", "dopio", 1, "Legendary", "future", None, None),
    ("JOJO.Enrico", "Enriko", "enriko", "enriko", 1, "Divine", "limited", None, "Sem scripts; único SurfaceAppearance do pack."),
    ("JOJO.Jolyne.Jolyne.Jolyne", "Jolene", "jolene", "jolene", 1, "Legendary", "future", None, None),
    ("JOJO.Jolyne.Awakened Jolyne", "Jolene Desperta", "jolene_awakened", "jolene", 2, "Mythic", "future", None, None),
    ("JOJO.DIO.TW.Morph", "Stand: Mundo", None, "dyo", 0, None, "future", "STAND_ONLY", "4 peças, sem membros R6 nem roupa."),
    ("JOJO.DIO.TW AURA.Morph", "Stand: Mundo (Aura)", None, "dyo", 0, None, "future", "STAND_ONLY", "Igual ao anterior + aura."),
    ("JOJO.Doppio/Diavolo.KC AURA", "Stand: Rei Carmesim", None, "dopio", 0, None, "future", "STAND_ONLY", "57 peças e sem Humanoid."),
    ("JOJO.Giorno (BUT BOSS).GER", "Stand: Réquiem Dourado", None, "jorno", 0, None, "future", "STAND_ONLY", "85 peças."),
    ("JOJO.Jolyne.STONE FREE", "Stand: Pedra Livre", None, "jolene", 0, None, "future", "STAND_ONLY", None),
    ("JOJO.Jolyne.STONE FREE AURA", "Stand: Pedra Livre (Aura)", None, "jolene", 0, None, "future", "STAND_ONLY", None),
    ("JOJO.Kira Yoshikage.Killer Queen", "Stand: Rainha Assassina", None, "kiro_yoshi", 0, None, "future", "STAND_ONLY", None),
    # MHA
    ("My Hero Academia Pack.Deku", "Deko", "deko", "deko", 1, "Uncommon", "fighter", None, None),
    ("My Hero Academia Pack.Deku Awakened", "Deko Desperto", "deko_awakened", "deko", 2, "Legendary", "storm", None, None),
    ("My Hero Academia Pack.100% Deku", "Deko 100%", "deko_full", "deko", 3, "Divine", "celestial", None, None),
    ("My Hero Academia Pack.Bakugo", "Bakugu", "bakugu", "bakugu", 1, "Rare", "flame", None, None),
    ("My Hero Academia Pack.Awakened Bakugo", "Bakugu Desperto", "bakugu_awakened", "bakugu", 2, "Legendary", "awakened", None, None),
    ("My Hero Academia Pack.Todoroki", "Todoruki", "todoruki", "todoruki", 1, "Uncommon", "flame", None, None),
    ("My Hero Academia Pack.All Might", "Ol Maito", "olmaito", "olmaito", 1, "Legendary", "fighter", None, None),
    ("My Hero Academia Pack.All Might (MODE)", "Ol Maito Poder Total", "olmaito_mode", "olmaito", 2, "Mythic", "celestial", None, None),
    ("My Hero Academia Pack.Lemillion", "Lemilio", "lemilio", "lemilio", 1, "Rare", "fighter", None, None),
    ("My Hero Academia Pack.Hellflame", "Infernus", "infernus", "infernus", 1, "Epic", "premium", None, "Chamas próprias."),
    ("My Hero Academia Pack.Speed Guy", "Velocista", "velocista", "velocista", 1, "Legendary", "future", None, "220 peças (178 SpecialMesh): otimizar antes."),
    # NARUTO
    ("NARUTO.ptsNaruto", "Narotu (Jovem)", "narotu_young", "narotu", 1, "Common", "shinobi", None, None),
    ("NARUTO.tsNaruto", "Narotu", "narotu", "narotu", 2, "Epic", "shinobi", None, None),
    ("NARUTO.Sage Mode", "Narotu Sábio", "narotu_sage", "narotu", 3, "Mythic", "celestial", None, None),
    ("NARUTO.ptsSasuke", "Sasuko (Jovem)", "sasuko_young", "sasuko", 1, "Common", "shinobi", None, None),
    ("NARUTO.tsSasuke", "Sasuko", "sasuko", "sasuko", 2, "Legendary", "colossus", None, "Duas lâminas."),
    ("NARUTO.Neji", "Nejo", "nejo", "nejo", 1, "Uncommon", "shinobi", None, None),
    ("NARUTO.Rock Lee.Rock Lee", "Roque Li", "roqueli", "roqueli", 1, "Uncommon", "shinobi", None, None),
    ("NARUTO.Rock Lee.ROCK LEE GATES", "Roque Li dos Portões", "roqueli_gates", "roqueli", 2, "Mythic", "awakened", None, None),
    ("NARUTO.Gaara", "Gaaro", "gaaro", "gaaro", 1, "Rare", "shinobi", None, "Areia."),
    ("NARUTO.Zabuza", "Zabuzo", "zabuzo", "zabuzo", 1, "Rare", "shinobi", None, "Espadão."),
    ("NARUTO.Kakashi", "Kakaxi", "kakaxi", "kakaxi", 1, "Epic", "shinobi", None, None),
    ("NARUTO.Itachi", "Itaxi", "itaxi", "itaxi", 1, "Legendary", "shadow", None, None),
    ("NARUTO.Pain", "Peinn", "peinn", "peinn", 1, "Legendary", "shadow", None, None),
    ("NARUTO.Madara", "Madaro", "madaro", "madaro", 1, "Divine", "forbidden", None, None),
    ("NARUTO.Minato.Minato", "Minatu", "minatu", "minatu", 1, "Rare", "storm", None, None),
    ("NARUTO.Minato.KCM MINATO", "Minatu Manto de Chakra", "minatu_cloak", "minatu", 2, "Divine", "future", None, "145 peças: otimizar antes."),
    ("NARUTO.Might Guy.Might Guy", "Mighto", "mighto", "mighto", 1, "Epic", "colossus", None, None),
    ("NARUTO.Might Guy.5TH GATE", "Mighto 5º Portão", "mighto_gate5", "mighto", 2, "Mythic", "colossus", None, None),
    ("NARUTO.Might Guy.8TH GATE", "Mighto 8º Portão", "mighto_gate8", "mighto", 3, "Secret", "forbidden", None, None),
    # OTHER
    ("OTHER.MISC.Chika", "Chiko", "chiko", "chiko", 1, "Uncommon", "starter", None, "Arco."),
    ("OTHER.MISC.Saitama", "Saitano", "saitano", "saitano", 1, "Epic", "starter", None, "Piada interna: herói 'comum' que é Épico."),
    ("OTHER.Kazuma", "Kazumo", "kazumo", "kazumo", 1, "Uncommon", "lucky", None, "Aventureiro sortudo."),
    ("OTHER.MISC.Tanjiro", "Tanjiru", "tanjiru", "tanjiru", 1, "Epic", "blade", None, "Trilhas de água e fogo."),
    ("OTHER.MISC.Afro Samurai", "Samurai Afro", "samurai_afro", "samurai_afro", 1, "Legendary", "premium", None, "3ª maior nota do pack."),
    ("OTHER.Accel", "Akcel", "akcel", "akcel", 1, "Epic", "arcane", None, None),
    ("OTHER.Rikka", "Rika", "rika", "rika", 1, "Epic", "arcane", None, "Arco."),
    ("OTHER.Rikka Awakened", "Rika Desperta", "rika_awakened", "rika", 2, "Legendary", "awakened", None, None),
    # ONE PIECE
    ("One Piece Pack.ptsLuffy", "Lufy (Jovem)", None, "lufy", 1, None, None, "BROKEN", "Sem Shirt (só Pants). Se o peito nu for intencional no Studio, vira APPROVED."),
    ("One Piece Pack.TS Luffy.tsLuffy", "Lufy", "lufy", "lufy", 2, "Rare", "fighter", None, None),
    ("One Piece Pack.TS Luffy.Snakeman", "Lufy Serpente", "lufy_snake", "lufy", 3, "Mythic", "colossus", None, None),
    ("One Piece Pack.ptsSanji", "Sanjo (Jovem)", "sanjo_young", "sanjo", 1, "Common", "lucky", None, None),
    ("One Piece Pack.TS SANJI", "Sanjo", "sanjo", "sanjo", 2, "Legendary", "celestial", None, None),
    ("One Piece Pack.ptsZoro", "Zoru (Jovem)", "zoru_young", "zoru", 1, "Uncommon", "blade", None, None),
    ("One Piece Pack.tsZoro", "Zoru", "zoru", "zoru", 2, "Epic", "blade", None, "Roupa e rosto diferentes do Zoru Jovem (não é duplicata)."),
    ("One Piece Pack.ptsLaw", "Lau", "lau", "lau", 1, "Epic", "arcane", None, None),
    ("One Piece Pack.Ace", "Ase", "ase", "ase", 1, "Rare", "flame", None, "Pistola."),
    ("One Piece Pack.Shanks", "Shankz", "shankz", "shankz", 1, "Legendary", "blade", None, "Três lâminas."),
    ("One Piece Pack.Akainu", "Akaino", "akaino", "akaino", 1, "Legendary", "flame", None, "Magma."),
    ("One Piece Pack.Kizaru", "Kizaro", "kizaro", "kizaro", 1, "Legendary", "premium", None, None),
    ("One Piece Pack.Whitebeard", "Barbalva", "barbalva", "barbalva", 1, "Mythic", "forbidden", None, None),
    # YYH
    ("YYH.Yusuke", "Yuzuke", "yuzuke", "yuzuke", 1, "Uncommon", "fighter", None, None),
    ("YYH.Yusuke Mode", "Yuzuke Demônio", "yuzuke_demon", "yuzuke", 2, "Mythic", "spirit", None, None),
    ("YYH.Hiei", "Hiey", "hiey", "hiey", 1, "Legendary", "spirit", None, "Duas lâminas."),
    ("YYH.Hiei (Jagan Eye)", "Hiey (Terceiro Olho)", None, "hiey", 2, None, None, "DUPLICATE", "Idêntico ao Hiey em roupa, peças, malhas, texturas e armas medidas. Se o olho for visível no Studio, vira forma 2."),
]

RESERVE_WHY = {
    "ulkiorra_second": ("event", "Forma 3 muito desejada; base e forma 2 ficam no lançamento → evento 'Noite Eterna' completa a família."),
    "aizo_final": ("event", "Secreto de evento: Aizo base é Divino no Forbidden; a forma final vira o prêmio de um evento."),
    "dyo_awakened": ("event", "Visual de vampiro → evento de Halloween; abre caminho para o update dos Stands."),
    "yoruka_neko": ("limited", "Forma 3 rara com raios e beams: ideal para Limited Dice com tempo contado."),
    "enriko": ("limited", "Um dos modelos mais detalhados (único SurfaceAppearance), sem scripts."),
    "jorno_boss": ("limited", "Variação de terno do Jorno; par perfeito com o Stand Réquiem Dourado no futuro."),
    "sukano": ("banner", "Altamente desejado; banner 'Rei Amaldiçoado' ao lado de Goju/Yujo (lançamento)."),
    "jorno": ("banner", "Alta qualidade (nota 67); banner de estreia do mundo dos Stands."),
    "jotaru": ("banner", "Ícone do grupo JOJO; segura um banner especial."),
    "jonatan": ("future", "Update 'Mundo dos Stands' (família completa + Stands como unidade visual)."),
    "josef": ("future", "Update 'Mundo dos Stands' (forma 1 do Josef)."),
    "josef_old": ("future", "Update 'Mundo dos Stands' (forma 2 do Josef)."),
    "jozuke": ("future", "Update 'Mundo dos Stands'."),
    "dyo": ("future", "Update 'Mundo dos Stands' (com o Stand Mundo)."),
    "kiro_yoshi": ("future", "Update 'Mundo dos Stands' (com Rainha Assassina)."),
    "dopio": ("future", "Update 'Mundo dos Stands' (com Rei Carmesim, que precisa de otimização)."),
    "jolene": ("future", "Update 'Mundo dos Stands' (com Pedra Livre)."),
    "jolene_awakened": ("future", "Update 'Mundo dos Stands' (forma 2)."),
    "minatu_cloak": ("future", "Muito desejado, mas tem 145 peças: entra num update depois de otimizado."),
    "velocista": ("future", "220 peças: entra depois de otimizado."),
}


# ---------------------------------------------------------------------------------

def load_measured() -> dict:
    data = json.loads(SUMMARY.read_text(encoding="utf-8"))
    seen = Counter()
    out = {}
    for c in data["characters"]:
        key = c["path"].replace("Anime Pack.", "").strip()  # "Lancer " tem espaço no fim
        seen[key] += 1
        if key == "HXH.Hisoka":
            key = f"{key}#{seen[key]}"
        own = [v for v in c.get("vfx", []) if not any(k in v for k in COMBAT_KIT)]
        weapons = sorted({w.replace(" (pelo nome)", "").replace(" (Tool)", "") for w in c.get("weapons", [])})
        out[key] = {
            "parts": c["parts"], "meshParts": c["meshParts"], "specialMeshes": c["specialMeshes"],
            "meshIds": c["meshIds"], "textureIds": c["textureIds"], "score": c["score"],
            "ownVfx": len(own), "ownVfxNames": sorted(set(v.split(" ", 1)[-1] for v in own)),
            "weapons": weapons, "scripts": c.get("scripts", 0), "humanoid": c.get("humanoid"),
            "shirt": c.get("shirt"), "pants": c.get("pants"), "face": c.get("face"), "category": c["category"],
        }
    return out


def build() -> list[dict]:
    measured = load_measured()
    rows = []
    for path, display, cid, family, tier, rarity, dest, forced, note in C:
        m = measured.get(path)
        if m is None:
            sys.exit(f"modelo não encontrado nos dados da auditoria: {path}")
        status = forced or "APPROVED"
        notes = [note] if note else []
        if status == "APPROVED" and (m["parts"] > MAX_PARTS or m["ownVfx"] > MAX_OWN_VFX):
            status = "NEEDS_OPTIMIZATION"
            if m["parts"] > MAX_PARTS:
                notes.append(f"{m['parts']} peças (meta ≤ {MAX_PARTS} depois de limpar)")
            if m["ownVfx"] > MAX_OWN_VFX:
                notes.append(f"{m['ownVfx']} efeitos próprios (LOD/efeitos reduzidos)")
        if m["scripts"]:
            notes.append(f"{m['scripts']} script(s) do jogo original: remover")
        rows.append({
            "source": path.split("#")[0].split(".")[-1], "sourcePath": path.split("#")[0] + (f" ({path.split('#')[1]}ª ocorrência)" if "#" in path else ""),
            "display": display, "id": cid, "family": family, "tier": tier, "rarity": rarity, "dest": dest,
            "status": status, "category": m["category"], "parts": m["parts"], "vfx": m["ownVfx"],
            "vfxNames": m["ownVfxNames"], "weapons": m["weapons"], "score": m["score"], "notes": notes,
        })
    if len(rows) != len(measured):
        faltando = set(measured) - {r for r, *_ in C}
        sys.exit(f"curadoria cobre {len(rows)} de {len(measured)} modelos; faltam: {sorted(faltando)}")
    return rows


def validate(rows: list[dict]):
    ids = [r["id"] for r in rows if r["id"]]
    assert len(ids) == len(set(ids)), "CharacterId repetido"
    for cid in ids:
        assert re.fullmatch(r"[a-z][a-z0-9_]{1,31}", cid), f"CharacterId inválido: {cid}"
    displays = [r["display"] for r in rows if r["id"]]
    assert len(displays) == len(set(displays)), "DisplayName repetido entre personagens jogáveis"
    for r in rows:
        if r["status"] in ("APPROVED", "NEEDS_OPTIMIZATION"):
            assert r["id"] and r["rarity"] in RARITIES and r["dest"], f"incompleto: {r['sourcePath']}"
    for d in DICE:
        n = sum(1 for r in rows if r["dest"] == d["id"])
        assert 5 <= n <= 10, f"{d['name']} tem {n} personagens (meta 5–10)"
    # Não colide com o roster atual (24 placeholders)
    current = set(re.findall(r'c\(\d+, "([a-z_]+)"', (RAIZ / "src/shared/Config/CharacterConfig.luau").read_text(encoding="utf-8")))
    assert not (current & set(ids)), f"CharacterId colide com o roster atual: {current & set(ids)}"


# ---------------------------------------------------------------------------------
# Markdown

def fmt_list(items, empty="—"):
    return ", ".join(items) if items else empty


def dest_name(dest):
    if dest in DICE_BY_ID:
        return DICE_BY_ID[dest]["name"]
    if dest == "premium":
        return "Premium Dice"
    if dest in RESERVE:
        return f"Reserva: {RESERVE[dest]}"
    return "—"


def catalog_md(rows):
    out = ["# FULL_CHARACTER_CATALOG — Anime Pack (152 modelos) — PROPOSTA", "",
           "> Planejamento: **nenhum personagem foi integrado ao jogo.** Gerado por",
           "> `python tools/packaudit/catalog.py` a partir dos dados da auditoria (`3265dc7`).",
           "> SourceModelName / SourceCategory são metadados internos de desenvolvimento: nunca aparecem",
           "> para o jogador. CharacterId é a chave de save (estável); DisplayName pode mudar.",
           "> Peças/efeitos = medidos (efeitos próprios, sem o kit de combate do jogo original).", ""]
    counts = Counter(r["status"] for r in rows)
    out += ["## Resumo", "", "| Status | Qtde |", "|---|---:|"]
    for s in ["APPROVED", "NEEDS_OPTIMIZATION", "DUPLICATE", "BROKEN", "STAND_ONLY", "REJECTED"]:
        out.append(f"| {s} | {counts.get(s, 0)} |")
    out += [f"| **Total** | **{len(rows)}** |", ""]
    out += ["## Catálogo completo", "",
            "| # | SourceModelName | CharacterId | DisplayName | SourceCategory | Status | Raridade | Destino | Família | Forma | Peças | VFX próprios | Arma | Notas técnicas |",
            "|---:|---|---|---|---|---|---|---|---|---:|---:|---|---|---|"]
    for i, r in enumerate(sorted(rows, key=lambda r: (r["category"], r["family"], r["tier"])), 1):
        out.append(f"| {i} | {r['sourcePath']} | `{r['id'] or '—'}` | {r['display']} | {r['category']} | {r['status']} | "
                   f"{r['rarity'] or '—'} | {dest_name(r['dest'])} | {r['family']} | {r['tier']} | {r['parts']} | "
                   f"{fmt_list(r['vfxNames'][:4])} | {fmt_list(r['weapons'][:3])} | {'; '.join(r['notes']) or '—'} |")
    top = [
        ("toshiru_bankai", "thumbnail, Premium"), ("ichiro_mugetsu", "Secreto F2P, marketing"),
        ("mighto_gate8", "Secreto F2P, VFX forte"), ("vegitto_blue", "Secreto F2P, thumbnail"),
        ("enriko", "Limited, modelo mais detalhado"), ("samurai_afro", "Premium"), ("jorno", "Special Banner"),
        ("seiba_alter", "Premium, Divino"), ("goko_dark_rose", "Premium, aura"), ("brolli_legend", "Divino F2P"),
        ("kizaro", "Premium"), ("infernus", "Premium, chamas"), ("killuo_godspeed", "marketing (raios)"),
        ("yoruka_neko", "Limited"), ("aizo_final", "Secreto de evento"),
    ]
    by_id = {r["id"]: r for r in rows if r["id"]}
    out += ["", "## 15 mais valiosos visualmente (marketing · thumbnail · Divino · Secreto · Premium · updates)", "",
            "| # | DisplayName | Raridade | Destino | Nota técnica | VFX próprios | Uso sugerido |", "|---:|---|---|---|---:|---|---|"]
    for i, (cid, use) in enumerate(top, 1):
        r = by_id[cid]
        out.append(f"| {i} | {r['display']} | {r['rarity']} | {dest_name(r['dest'])} | {r['score']} | {fmt_list(r['vfxNames'][:3])} | {use} |")
    out += ["", "## Famílias e formas (CharacterFamily / FormTier)", "",
            "FormTier: 1 = base · 2 = forma avançada · 3 = forma máxima · 4 = forma final · 0 = Stand (não é unidade sozinha).",
            "Roupas alternativas da mesma pessoa ficam no mesmo FormTier.", "",
            "| Família | Formas (FormTier → DisplayName [destino]) |", "|---|---|"]
    fam = defaultdict(list)
    for r in rows:
        fam[r["family"]].append(r)
    for name in sorted(fam):
        members = sorted(fam[name], key=lambda r: r["tier"])
        if len(members) > 1:
            out.append(f"| {name} | " + " → ".join(f"{r['tier']}: {r['display']} [{dest_name(r['dest'])}]" for r in members) + " |")
    out += ["", "## Metadados propostos para o Index futuro", "",
            "```lua", "-- Exemplo (NÃO implementado): entrada futura do CharacterConfig",
            "{ Id = \"ichiro_hollow\", DisplayName = \"Ichiro Mascarado\", Rarity = \"Mythic\",",
            "  Family = \"ichiro\", FormTier = 2, DiceSource = \"shadow\",",
            "  SourceCategory = \"Bleach Pack\", SourceModelName = \"Hollow Ichigo\" } -- os 2 últimos: só dev", "```", "",
            "Variantes (Normal/Silver/Gold/Diamond/Emerald/Void/Celestial) = **um modelo base + VariantVisualModifier**",
            "(brilho/aura/cor). O Index futuro guarda `Discovered` e um mapa `Variants[variante] = true` por",
            "personagem — campo novo e opcional no save, sem migração destrutiva (ausente = só Normal).", ""]
    return "\n".join(out)


def dice_md(rows):
    out = ["# DICE_PROGRESSION_PROPOSAL — PROPOSTA (não implementada)", "",
           "> Muitos Dice com pools pequenos (5–10, ideal 7–8). Âncoras = Dice que já existem hoje",
           "> (Normal→Starter, Lucky, Flame, Storm, Void, Celestial). O Prism continua exclusivo do Diário.",
           "> **Chances globais de raridade, Luck, pity e economia NÃO mudam nesta etapa.**", ""]
    out += ["## Ordem de desbloqueio", "", "| # | Dice | Âncora atual | Tema | Qtde | Raridades (C/U/R/E/L/M/D/S) |", "|---:|---|---|---|---:|---|"]
    for i, d in enumerate(DICE, 1):
        pool = [r for r in rows if r["dest"] == d["id"]]
        rc = Counter(r["rarity"] for r in pool)
        bands = "/".join(str(rc.get(x, 0)) for x in RARITIES)
        out.append(f"| {i} | **{d['name']}** | {d['anchor'] or 'novo'} | {d['theme']} | {len(pool)} | {bands} |")
    total = sum(1 for r in rows if r["dest"] in DICE_BY_ID)
    out += ["", f"**Total F2P: {total} personagens em {len(DICE)} Dice.** + Premium Dice (ver PREMIUM_DICE_PROPOSAL.md).", ""]
    out += ["## Progressão das faixas", "",
            "- Iniciais (Starter → Shinobi): Comum, Incomum, Raro e alguns Épicos.",
            "- Intermediários (Blade → Arcane): Raro, Épico, Lendário e os primeiros Míticos.",
            "- Avançados (Shadow → Colossus): Épico, Lendário, Mítico e o primeiro Divino (Void).",
            "- Endgame (Celestial, Forbidden): Lendário, Mítico, Divino e Secreto.", "",
            "**Ponto a decidir na etapa de RNG:** hoje o sorteio escolhe a raridade com as chances globais e",
            "depois um personagem daquela raridade. Com pools por Dice, uma raridade que o Dice não tem",
            "(ex.: Secreto no Starter) precisa de regra (sugestão: cair para a maior raridade do Dice, ou",
            "o pity respeitar a faixa do Dice). Fica para a nova simulação, depois de aprovar os pools.", ""]
    for i, d in enumerate(DICE, 1):
        pool = sorted([r for r in rows if r["dest"] == d["id"]], key=lambda r: RARITIES.index(r["rarity"]))
        out += [f"## {i}. {d['name']}" + (f" (âncora: {d['anchor']})" if d["anchor"] else ""), "", d["theme"], "",
                "| Raridade | DisplayName | CharacterId | SourceModelName | Família | Forma | Nota técnica | VFX próprios | Peças | Status |",
                "|---|---|---|---|---|---:|---:|---|---:|---|"]
        for r in pool:
            out.append(f"| {r['rarity']} | {r['display']} | `{r['id']}` | {r['sourcePath']} | {r['family']} | {r['tier']} | {r['score']} | "
                       f"{fmt_list(r['vfxNames'][:3])} | {r['parts']} | {r['status']} |")
        out.append("")
    out += ["## Personagem → Dice", "", "| DisplayName | CharacterId | Raridade | Dice |", "|---|---|---|---|"]
    for r in sorted([r for r in rows if r["dest"] in DICE_BY_ID or r["dest"] == "premium"], key=lambda r: r["display"]):
        out.append(f"| {r['display']} | `{r['id']}` | {r['rarity']} | {dest_name(r['dest'])} |")
    out += ["", "## Formas espalhadas pela progressão (exemplos)", ""]
    fam = defaultdict(list)
    for r in rows:
        if r["id"]:
            fam[r["family"]].append(r)
    for name, members in sorted(fam.items()):
        if len(members) >= 2:
            members.sort(key=lambda r: r["tier"])
            out.append(f"- **{name}**: " + " → ".join(f"{r['display']} ({PT.get(r['rarity'], '?')}, {dest_name(r['dest'])})" for r in members))
    out.append("")
    return "\n".join(out)


def reserve_md(rows):
    out = ["# FUTURE_CONTENT_RESERVE — PROPOSTA", "",
           "> Conteúdo guardado de propósito para updates/eventos. Não é só o que sobrou: inclui alguns dos",
           "> modelos mais desejados do pack. Nada disso está implementado.", ""]
    for key, title in RESERVE.items():
        pool = [r for r in rows if r["dest"] == key and r["id"]]
        out += [f"## {title} ({len(pool)})", "", "| DisplayName | CharacterId | Raridade | Família/Forma | Peças | Por que está reservado |", "|---|---|---|---|---:|---|"]
        for r in sorted(pool, key=lambda r: RARITIES.index(r["rarity"])):
            why = RESERVE_WHY.get(r["id"], ("", "—"))[1]
            out.append(f"| {r['display']} | `{r['id']}` | {r['rarity']} | {r['family']} / {r['tier']} | {r['parts']} | {why} |")
        out.append("")
    stands = [r for r in rows if r["status"] == "STAND_ONLY"]
    out += [f"## Stands para o update 'Mundo dos Stands' ({len(stands)}, STAND_ONLY)", "",
            "Ideia: cada personagem JOJO vira UMA unidade visual (personagem + Stand flutuando atrás, ancorado",
            "e sem o LocalStand original). Precisa de adaptação → update futuro.", "",
            "| Stand | Dono (família) | Peças | Observação |", "|---|---|---:|---|"]
    for r in stands:
        out.append(f"| {r['display']} ({r['sourcePath']}) | {r['family']} | {r['parts']} | {'; '.join(r['notes'])} |")
    out.append("")
    return "\n".join(out)


def premium_md(rows):
    pool = sorted([r for r in rows if r["dest"] == "premium"], key=lambda r: RARITIES.index(r["rarity"]))
    out = ["# PREMIUM_DICE_PROPOSAL — PROPOSTA (sem Robux, preço ou Developer Product)", "",
           f"> {len(pool)} candidatos. Critério: visual/efeitos/qualidade medida e formas especiais —",
           "> **não** força. A base de cada família continua grátis nos Dice F2P (ex.: Toshiru no Spirit",
           "> Dice; a forma Bankai é a versão Premium). Raridades seguem as mesmas regras do jogo.", "",
           "| Raridade | DisplayName | SourceModelName | Nota técnica | VFX próprios | Arma | Peças | Por que Premium |",
           "|---|---|---|---:|---|---|---:|---|"]
    why = {
        "toshiru_bankai": "Maior nota do pack (80): asas e efeitos de gelo; forma 2 de um personagem F2P.",
        "seiba_alter": "Versão sombria da Seiba (F2P no Arcane); 10 MeshParts.",
        "goko_dark_rose": "Aura rosé própria; forma 2 do Goko Sombrio (F2P no Shadow).",
        "yoruka_shunko": "Efeitos Shunko próprios; forma 2 da Yoruka (F2P no Spirit).",
        "kizaro": "Nota 64, rosto próprio; visual de almirante muito reconhecível.",
        "samurai_afro": "3ª maior nota do pack (73): lâmina e beams.",
        "lanseiro_mode": "Lança + 8 efeitos Reiatsu; forma 2 do Lanseiro (F2P no Storm).",
        "infernus": "13 partículas de chama próprias; silhueta forte para thumbnail.",
        "iskander": "Nota 65: armadura e capa detalhadas.",
    }
    for r in pool:
        out.append(f"| {r['rarity']} | {r['display']} | {r['sourcePath']} | {r['score']} | {fmt_list(r['vfxNames'][:3])} | "
                   f"{fmt_list(r['weapons'][:2])} | {r['parts']} | {why.get(r['id'], '—')} |")
    out += ["", "## Regras sugeridas (anti pay-to-win)", "",
            "- Mesmas chances de raridade e mesmo poder base por raridade que o F2P: a vantagem é exclusividade e visual.",
            "- Pelo menos uma forma de cada família Premium também existe no F2P.",
            "- Fusão/Index: personagens Premium contam no Index como qualquer outro (coleção, não poder).",
            "- Preço/produto definidos só depois da nova simulação.", ""]
    return "\n".join(out)


def rejected_md(rows):
    out = ["# REJECTED_CHARACTERS — DUPLICATE · BROKEN · STAND_ONLY · REJECTED · NEEDS_OPTIMIZATION", "",
           "> NEEDS_OPTIMIZATION **não** é rejeição: o modelo é bom, mas precisa ser aliviado antes de entrar",
           "> (meta ≤ 40 peças depois da limpeza; efeitos com LOD). Duplicatas foram verificadas pelos dados",
           "> medidos (roupa, rosto, peças, malhas, texturas, armas, efeitos); a confirmação visual é no Studio.", ""]
    for status in ["DUPLICATE", "BROKEN", "STAND_ONLY", "REJECTED", "NEEDS_OPTIMIZATION"]:
        pool = [r for r in rows if r["status"] == status]
        out += [f"## {status} ({len(pool)})", ""]
        if not pool:
            out += ["Nenhum.", ""]
            continue
        out += ["| SourceModelName | DisplayName | Peças | VFX próprios | Destino | Justificativa |", "|---|---|---:|---:|---|---|"]
        for r in pool:
            out.append(f"| {r['sourcePath']} | {r['display']} | {r['parts']} | {r['vfx']} | {dest_name(r['dest'])} | {'; '.join(r['notes'])} |")
        out.append("")
    return "\n".join(out)


def main():
    rows = build()
    validate(rows)
    (RAIZ / "FULL_CHARACTER_CATALOG.md").write_text(catalog_md(rows), encoding="utf-8")
    (RAIZ / "DICE_PROGRESSION_PROPOSAL.md").write_text(dice_md(rows), encoding="utf-8")
    (RAIZ / "FUTURE_CONTENT_RESERVE.md").write_text(reserve_md(rows), encoding="utf-8")
    (RAIZ / "PREMIUM_DICE_PROPOSAL.md").write_text(premium_md(rows), encoding="utf-8")
    (RAIZ / "REJECTED_CHARACTERS.md").write_text(rejected_md(rows), encoding="utf-8")
    (RAIZ / "third_party" / "catalog_proposal.json").write_text(json.dumps(rows, ensure_ascii=False, indent=1), encoding="utf-8")
    counts = Counter(r["status"] for r in rows)
    playable = [r for r in rows if r["status"] in ("APPROVED", "NEEDS_OPTIMIZATION")]
    f2p = [r for r in rows if r["dest"] in DICE_BY_ID]
    premium = [r for r in rows if r["dest"] == "premium"]
    reserve = [r for r in rows if r["dest"] in RESERVE and r["id"]]
    print(dict(counts))
    print(f"jogáveis únicos {len(playable)} · F2P {len(f2p)} em {len(DICE)} Dice · Premium {len(premium)} · "
          f"lançamento {len(f2p) + len(premium)} · reserva {len(reserve)} "
          f"({dict(Counter(r['dest'] for r in reserve))}) · stands {counts['STAND_ONLY']}")
    for d in DICE:
        pool = [r for r in rows if r["dest"] == d["id"]]
        print(f"  {d['name']}: {len(pool)}")


if __name__ == "__main__":
    main()
