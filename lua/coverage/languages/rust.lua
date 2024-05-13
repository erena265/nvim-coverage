local M = {}

local common = require("coverage.languages.common")
local config = require("coverage.config")
local util = require("coverage.util")

--- Returns a list of signs to be placed.
M.sign_list = common.sign_list

--- Returns a summary report.
M.summary = common.summary

-- From http://lua-users.org/wiki/StringInterpolation.
local interp = function(s, tab)
    return (s:gsub("($%b{})", function(w)
        return tab[w:sub(3, -2)] or w
    end))
end

--- Loads a coverage report from stdout.
-- @param callback called with the results of the coverage report
M.load = function(callback)
    local rust_config = config.opts.lang.rust
    local cwd = vim.fn.getcwd()
    local cmd = rust_config.coverage_command
    cmd = interp(cmd, { cwd = cwd })
    local stdout = ""
    local stderr = ""
    vim.fn.jobstart(cmd, {
        on_stdout = vim.schedule_wrap(function(_, data, _)
            for _, line in ipairs(data) do
                stdout = stdout .. line
            end
        end),
        on_stderr = vim.schedule_wrap(function(_, data, _)
            for _, line in ipairs(data) do
                stderr = stderr .. line
            end
        end),
        on_exit = vim.schedule_wrap(function()
            if #stderr > 0 then
                vim.notify(stderr, vim.log.levels.ERROR)
                return
            end
            callback(util.lcov_to_table(stdout))
        end),
    })
end

return M
