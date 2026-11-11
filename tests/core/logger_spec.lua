local env = require("tests.helpers.env")

describe("core.logger", function()
  local logger

  before_each(function()
    package.loaded["wraithvim.core.logger"] = nil
    logger = require("wraithvim.core.logger")
    os.remove(logger.path())
  end)

  it("writes warnings and errors but not debug messages by default", function()
    logger.debug("hidden %d", 1)
    logger.warn("visible %s", "warn")
    logger.error("visible error")
    local content = env.read(logger.path())
    assert.matches("%[WARN%] visible warn", content)
    assert.matches("%[ERROR%] visible error", content)
    assert.is_nil(content:find("hidden"))
  end)

  it("redacts secret-looking assignments", function()
    logger.error("GITHUB_TOKEN=abc123 password: hunter2")
    local content = env.read(logger.path())
    assert.is_nil(content:find("abc123"))
    assert.is_nil(content:find("hunter2"))
    assert.matches("<redacted>", content)
  end)
end)
