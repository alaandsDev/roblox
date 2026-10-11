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
}
