--!strict
-- Textos em português (idioma padrão). Use {nome} para valores dinâmicos.
-- Nenhum texto de interface deve ficar escrito direto nos Controllers.

return {
	["welcome"] = "Bem-vindo ao {game}!",
	["data.studio_offline"] = "Modo de teste: salvamento desativado (Studio sem acesso à API).",
	["data.load_failed"] = "Não foi possível carregar seus dados. Tente entrar novamente em alguns minutos.",
	["data.session_locked"] = "Seus dados ainda estão abertos em outro servidor. Aguarde alguns segundos e entre novamente.",
	["data.future_version"] = "Este servidor está desatualizado. Entre em outro servidor.",
	["data.lost_lock"] = "Seus dados foram abertos em outro servidor.",

	["error.rate_limited"] = "Calma! Você está fazendo isso rápido demais.",
	["error.invalid_args"] = "Pedido inválido.",
	["error.not_ready"] = "Seus dados ainda estão carregando.",
	["error.not_implemented"] = "Em breve!",
	["error.internal"] = "Algo deu errado. Tente novamente.",

	["settings.saved"] = "Configuração salva.",

	["purchase.not_configured"] = "Este item ainda não está à venda.",
	["purchase.thanks"] = "Obrigado pela compra!",

	-- Navegação (HUD)
	["nav.center"] = "CENTRO",
	["nav.home"] = "CASA",
	["nav.shop"] = "LOJA",
	["nav.no_base"] = "Você ainda não tem uma base neste servidor.",

	-- Mapa
	["map.game_title"] = "ROLL LEGENDS",
	["map.hub_title"] = "ROLL LEGENDS",
	["map.market"] = "MERCADO",
	["map.sell"] = "VENDER",
	["map.dice_shop"] = "LOJA DE DADOS",
	["map.towers"] = "TORRES",
	["map.towers_sub"] = "DESAFIE OS ANDARES",
	["map.fusion"] = "FUSÃO",
	["map.missions"] = "MISSÕES",
	["map.trade"] = "TROCAS",
	["map.rankings"] = "RANKINGS",
	["map.lb_rebirths"] = "MAIS REBIRTHS",
	["map.lb_tower"] = "MAIOR TORRE",
	["map.lb_rolls"] = "MAIS ROLLS",
	["map.coming_soon"] = "{name}: em breve!",
	["prompt.open"] = "Abrir",

	-- Base
	["base.free"] = "BASE LIVRE",
	["base.owner_title"] = "BASE DE",
	["base.slot_locked"] = "REBIRTH NECESSÁRIO",
	["base.slot_requires_rebirth"] = "REBIRTH {rebirth}",
	["base.collector"] = "COLETAR",
	["base.upgrades"] = "MELHORIAS",
	["base.floor_unlocked"] = "Novo andar construído! (Andar {floor})",

	["prompt.collect"] = "Coletar",
	["base.not_yours"] = "Essa não é a sua base.",

	-- Raridades / variantes
	["rarity.Common"] = "COMUM",
	["rarity.Uncommon"] = "INCOMUM",
	["rarity.Rare"] = "RARO",
	["rarity.Epic"] = "ÉPICO",
	["rarity.Legendary"] = "LENDÁRIO",
	["rarity.Mythic"] = "MÍTICO",
	["rarity.Divine"] = "DIVINO",
	["rarity.Secret"] = "SECRETO",
	["variant.Normal"] = "NORMAL",
	["variant.Silver"] = "PRATA",
	["variant.Gold"] = "OURO",
	["variant.Diamond"] = "DIAMANTE",
	["variant.Emerald"] = "ESMERALDA",
	["variant.Void"] = "VAZIO",
	["variant.Celestial"] = "CELESTIAL",

	-- Estações (pedestais)
	["station.upgrade"] = "Melhorar",
	["station.level"] = "Nível {level}",
	["station.level_next"] = "Nível {level} > {next}",
	["station.level_max"] = "NÍVEL MÁX",
	["station.max"] = "MÁX",
	["station.not_enough_money"] = "Dinheiro insuficiente para melhorar.",

	-- Economia
	["economy.nothing_to_collect"] = "Nada para coletar ainda.",
	["economy.collected"] = "+{amount}",

	-- Index
	["index.milestone"] = "Index {percent}% completo! +{amount} gemas",

	-- Anúncios
	["announce.drop"] = "{player} conseguiu {name} [{rarity}]!",
	["announce.Discreet"] = "✨ {player} tirou {name} ({rarity})",
	["announce.Global"] = "🌟 {player} conseguiu {name} [{rarity}]! (1 em {odds}) 🌟",
	["announce.Highlight"] = "🔥 {player} conseguiu {name} [{rarity}]! (1 em {odds}) 🔥",

	-- Erros das ações do jogo
	["error.cooldown"] = "Espere um pouco.",
	["error.inventory_full"] = "SEU INVENTÁRIO ESTÁ CHEIO!",
	["error.not_owned"] = "Você não tem esse item.",
	["error.no_free_slot"] = "Todos os pedestais estão ocupados.",
	["error.slot_locked"] = "Esse pedestal ainda está bloqueado.",
	["error.slot_occupied"] = "Esse pedestal já está ocupado.",
	["error.not_equipped"] = "Coloque o personagem na base para melhorar.",
	["error.invalid_flag"] = "Pedido inválido.",
	["error.max_level"] = "Nível máximo!",
	["error.not_enough_money"] = "Dinheiro insuficiente.",
	["error.locked"] = "Personagem travado.",
	["error.favorite"] = "Personagem favorito.",
	["error.equipped"] = "Personagem está na base.",
	["error.nothing_to_sell"] = "Nada para vender.",
	["error.protected"] = "Protegido.",
	["error.invalid_dice"] = "Dado inválido.",
	["error.exclusive"] = "Dado exclusivo (recompensa).",
	["error.already_owned"] = "Você já tem.",
	["error.requires_previous"] = "Compre o dado anterior primeiro.",
	["error.requires_rolls"] = "Faça mais rolls para liberar.",
	["error.invalid_upgrade"] = "Melhoria inválida.",
	["error.already_claimed"] = "Já resgatado hoje.",
	["error.invalid_time"] = "Tente novamente.",
	["error.nothing_to_claim"] = "Nada para resgatar.",
	["error.not_configured"] = "Este item ainda não está à venda.",
	["error.too_far"] = "Chegue mais perto.",
	["error.no_base"] = "Você não tem base.",
	["error.no_character"] = "Aguarde seu personagem aparecer.",

	-- HUD
	["hud.shop"] = "LOJA",
	["hud.rebirth"] = "RENASCER",
	["hud.rebirth_soon"] = "Renascimento: em breve!",
	["hud.index"] = "ÍNDICE",
	["hud.backpack"] = "MOCHILA",
	["hud.upgrades"] = "MELHORIAS",
	["hud.offline"] = "OFFLINE",
	["hud.daily"] = "DIÁRIO",
	["hud.friend_boost"] = "Impulso de Amigos +{percent}%",
	["hud.boost"] = "🍀 Boost {mult}x · {time}",

	-- Roll
	["roll.button"] = "ROLAR",
	["roll.auto"] = "AUTO",
	["roll.hide"] = "OCULTAR",
	["roll.full_sell"] = "VENDER",
	["roll.full_backpack"] = "MOCHILA",

	-- Reveal / cinemática
	["reveal.new"] = "✨ NOVO! ✨",
	["reveal.odds"] = "1 EM {odds}",
	["reveal.continue"] = "CONTINUAR",
	["reveal.skip"] = "PULAR ▶",
	["reveal.secret_intro"] = "???",
	["reveal.autosold"] = "· VENDIDO",
	["reveal.autosold_for"] = "Vendido automaticamente: +{amount}",

	-- Mochila
	["inv.title"] = "MOCHILA",
	["inv.search"] = "Buscar...",
	["inv.filter.All"] = "TODOS",
	["inv.filter.Rarity"] = "RARIDADE",
	["inv.filter.Power"] = "PODER",
	["inv.filter.Income"] = "RENDA",
	["inv.filter.Recent"] = "RECENTES",
	["inv.equip"] = "EQUIPAR",
	["inv.unequip"] = "DESEQUIPAR",
	["inv.lock"] = "TRAVAR",
	["inv.unlock"] = "DESTRAVAR",
	["inv.favorite"] = "FAVORITAR",
	["inv.unfavorite"] = "DESFAVORITAR",
	["inv.sell"] = "VENDER {amount}",
	["inv.equip_best"] = "EQUIPAR MELHORES",
	["inv.best_done"] = "{count} personagens nos pedestais!",

	-- Venda
	["sell.title"] = "VENDER",
	["sell.selected"] = "Selecionado: {name} ({amount})",
	["sell.none_selected"] = "Selecione um personagem na MOCHILA para vender.",
	["sell.selected_button"] = "VENDER SELECIONADO",
	["sell.duplicates"] = "VENDER DUPLICATAS",
	["sell.commons"] = "VENDER COMUNS",
	["sell.autosell_title"] = "AUTO-SELL",
	["sell.autosell_hint"] = "Vende na hora ao rolar (nunca o primeiro de cada personagem). Secreto é protegido.",
	["sell.confirm"] = "Vender {count} personagens por {amount}?",
	["sell.confirm_one"] = "Vender {name} por {amount}?",
	["sell.yes"] = "VENDER",
	["sell.cancel"] = "CANCELAR",
	["sell.done"] = "{count} vendidos por {amount}!",
	["sell.pick_first"] = "Escolha um personagem na MOCHILA.",
	["sell.secret_protected"] = "Secretos nunca são vendidos automaticamente.",

	-- Dados
	["dice.title"] = "LOJA DE DADOS",
	["dice.Normal"] = "Dado Normal",
	["dice.Lucky"] = "Dado Sortudo",
	["dice.Flame"] = "Dado de Chamas",
	["dice.Storm"] = "Dado da Tempestade",
	["dice.Void"] = "Dado do Vazio",
	["dice.Celestial"] = "Dado Celestial",
	["dice.Prism"] = "Dado Prisma",
	["dice.req_rolls"] = "{rolls} rolls",
	["dice.req_dice"] = "ter {dice}",
	["dice.exclusive"] = "Exclusivo do Diário (Dia 7)",
	["dice.buy"] = "COMPRAR",
	["dice.equip"] = "EQUIPAR",
	["dice.equipped"] = "EQUIPADO",
	["dice.locked"] = "BLOQUEADO",
	["dice.bought"] = "{dice} comprado e equipado!",
	["dice.equipped_now"] = "{dice} equipado!",

	-- Melhorias globais
	["upg.title"] = "MELHORIAS",
	["upg.Luck"] = "Sorte",
	["upg.Income"] = "Renda",
	["upg.RollSpeed"] = "Velocidade de Roll",
	["upg.Inventory"] = "Capacidade da Mochila",
	["upg.level"] = "NÍVEL {level}/{max}",
	["upg.maxed"] = "Nível máximo atingido",
	["upg.benefit.Luck"] = "Sorte +{now}% → +{next}%",
	["upg.benefit.Income"] = "Renda +{now}% → +{next}%",
	["upg.benefit.RollSpeed"] = "Rolls {now}% mais rápidos → {next}%",
	["upg.benefit.Inventory"] = "+{now} espaços → +{next}",

	-- Index
	["index.title"] = "ÍNDICE",
	["index.progress"] = "{found} / {total} DESCOBERTOS ({percent}%)",

	-- Dinheiro offline
	["offline.title"] = "BEM-VINDO DE VOLTA!",
	["offline.subtitle"] = "DINHEIRO OFFLINE",
	["offline.claim"] = "RESGATAR",
	["offline.claimed"] = "Dinheiro offline resgatado: {amount}",

	-- Diário
	["daily.title"] = "RECOMPENSAS DIÁRIAS",
	["daily.day"] = "DIA {day}",
	["daily.claim"] = "RESGATAR!",
	["daily.available"] = "Recompensa disponível!",
	["daily.next"] = "Próxima recompensa em {time}",
	["daily.claimed"] = "Dia {day}: {reward}!",

	-- Configurações
	["settings.title"] = "CONFIGURAÇÕES",
	["settings.HideRollAnimation"] = "Ocultar animação do roll",
	["settings.CameraShake"] = "Tremer a câmera",
	["settings.ReducedEffects"] = "Efeitos reduzidos",
	["settings.on"] = "LIGADO",
	["settings.off"] = "DESLIGADO",

	-- Estações
	["station.level_up"] = "NÍVEL {level}!",
}
