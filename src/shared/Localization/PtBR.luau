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
}
