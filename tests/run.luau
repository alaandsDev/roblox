-- Roda todos os testes puros: python tools/run_tests.py (ou: luau tests/run.luau)
local T = require("./TestLib")

require("./TableUtil.spec")
require("./NumberFormatter.spec")
require("./RateLimiter.spec")
require("./Validator.spec")
require("./ProfileCore.spec")
require("./ReceiptCore.spec")
require("./Config.spec")
require("./BaseAllocator.spec")
require("./BaseLayout.spec")
require("./BaseProgression.spec")
require("./MapLayout.spec")
require("./MapValidator.spec")
require("./SpawnCoordinator.spec")

if not T.report() then
	error("testes falharam", 0)
end
