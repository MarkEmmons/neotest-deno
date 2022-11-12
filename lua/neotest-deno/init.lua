local async = require("neotest.async")
local lib = require("neotest.lib")

---@class neotest.Adapter
---@field name string
local DenoNeotestAdapter = { name = "neotest-deno" }

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
function DenoNeotestAdapter.root(dir)

	-- TODO: Extend functionality to not require a deno.json file
	local result = lib.files.match_root_pattern("deno.json")(dir)
	return result
end

---Filter directories when searching for test files
---@async
---@param name string Name of directory
---@param rel_path string Path to directory, relative to root
---@param root string Root directory of project
function DenoNeotestAdapter.filter_dir(name, rel_path, root)
	return name ~= "node_modules"
end

---@async
---@param file_path string
---@return boolean
function DenoNeotestAdapter.is_test_file(file_path)

	-- See https://deno.land/manual@v1.27.2/basics/testing#running-tests
	local valid_exts = {
		js = true,
		ts = true,
		tsx = true,
		mts = true,
		mjs = true,
		jsx = true,
		cjs = true,
		cts = true,
	}

	-- Get filename
	local file_name = string.match(file_path, ".-([^\\/]-%.?[^%.\\/]*)$")

	-- filename match _ . or test.
	local ext = string.match(file_name, "[_%.]test%.(%w+)$") or	-- Filename ends in _test.<ext> or .test.<ext>
		string.match(file_name, "^test%.(%w+)$") or				-- Filename is test.<ext>
		nil

	if ext and valid_exts[ext] then
		return true
	end

	return false
end

---Given a file path, parse all the tests within it.
---@async
---@param file_path string Absolute file path
---@return neotest.Tree | nil
function DenoNeotestAdapter.discover_positions(file_path)

	local query = [[

		(call_expression
			function: (member_expression) @func_name (#match? @func_name "^Deno.test$")
			arguments: [
				(arguments ((string) @test.name . (arrow_function)))
				(arguments . (function name: (identifier) @test.name))
				(arguments . (object(pair
					key: (property_identifier) @key (#match? @key "^name$")
					value: (string) @test.name
				)))
				(arguments ((string) @test.name . (object) . (arrow_function)))
				(arguments (object) . (function name: (identifier) @test.name))
			]
		) @test.definition
	]]

	return lib.treesitter.parse_positions(file_path, query, { nested_namespaces = true })
end

local function get_results_file()

	local tmp_dir, idx = string.match(async.fn.tempname(), "(.*)(%d+)$")

	return tmp_dir .. (tonumber(idx) + 1)
end

---@param args neotest.RunArgs
---@return nil | neotest.RunSpec | neotest.RunSpec[]
function DenoNeotestAdapter.build_spec(args)

	local results_path = get_results_file()
    local position = args.tree:data()

	return {
		command = "deno test -A",
		context = {
			results_path = results_path,
			file = position.path,
		},
	}
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function DenoNeotestAdapter.results(spec, result, tree)

    local results = {}

	local handle = assert(io.open(spec.context.results_path))

	local line = handle:read("l")
	while line do

		if string.find(line, '%.%.%. .*ok') then

			local test_name = string.match(line, '^(.*) %.%.%. .*$')
			print(test_name .. " PASS")
            results[test_name] = {
                status = "passed",
            }

		elseif string.find(line, '%.%.%. .*FAILED') then

			local test_name = string.match(line, '^(.*) %.%.%. .*$')
            results[test_name] = {
                status = "failed",
                --short = testcase.failure[1],
            }
		end

		line = handle:read("l")
	end

	if handle then
		handle:close()
	end

    return results
end

setmetatable(DenoNeotestAdapter, {
	__call = function()
		return DenoNeotestAdapter
	end,
})

return DenoNeotestAdapter
