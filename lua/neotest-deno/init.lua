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
;; Deno.test
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

;; BDD describe - nested
(call_expression
	function: (identifier) @func_name (#match? @func_name "^describe$")
	arguments: [
		(arguments ((string) @namespace.name . (arrow_function)))
		(arguments ((string) @namespace.name . (function)))
	]
) @namespace.definition

;; BDD describe - flat
(variable_declarator
	name: (identifier) @namespace.id
	value: (call_expression
		function: (identifier) @func_name (#match? @func_name "^describe")
		arguments: [
			(arguments ((string) @namespace.name))
			(arguments (object (pair
				key: (property_identifier) @key (#match? @key "^name$")
				value: (string) @namespace.name
			)))
		]
	)
) @namespace.definition

;; BDD it
(call_expression
	function: (identifier) @func_name (#match? @func_name "^it$")
	arguments: [
		(arguments ((string) @test.name . (arrow_function)))
		(arguments ((string) @test.name . (function)))
	]
) @test.definition
	]]

	local position_tree = lib.treesitter.parse_positions(
		file_path,
		query,
		{ nested_namespaces = true }
	)

	return position_tree
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
	local strategy = {}

	local cwd = DenoNeotestAdapter.root(position.path) or ""
	-- TODO: this needs to work with windows paths too
	local filename, _ = string.gsub(position.path, cwd .. '/', "")

	-- TODO: Support additional arguments
    local command_args = vim.tbl_flatten({
		'test',
		filename,
		--vim.list_extend(args.extra_args or {}),
		'--allow-all',
    })

	-- TODO: User-defined allows
	-- if args.allow add allow args
	-- else --allow-all

	if position.type == "test" then
		local test_name = position.name:gsub('^"', ''):gsub('"$', '')
        vim.list_extend(command_args, { "--filter", test_name })
	end

	-- BUG: Cannot jump to frame at the end of the test
	if args.strategy == "dap" then

		vim.list_extend(command_args, { "--inspect-brk" })

		strategy = {
			name = 'Deno',
			type = 'node2',
			request = 'launch',
			cwd = '${workspaceFolder}',
			runtimeExecutable = 'deno',
			runtimeArgs = command_args,
			port = 9229,
			protocol = 'inspector',
			console = 'integratedTerminal',
		}
	end

	return {
		command = 'deno ' .. table.concat(command_args, " "),
		context = {
			results_path = results_path,
			position = position,
		},
		cwd = DenoNeotestAdapter.root(position.path),
		strategy = strategy,
	}
end

---@async
---@param spec neotest.RunSpec
---@param result neotest.StrategyResult
---@param tree neotest.Tree
---@return table<string, neotest.Result>
function DenoNeotestAdapter.results(spec, result, tree)

    local results = {}

	local test_suite = ''

	local handle = assert(io.open(spec.context.results_path))

	local line = handle:read("l")
	while line do

		if string.find(line, 'running %d+ test') then

			local testfile = string.match(line, 'running %d+ tests? from %.(.+%w+[sx]).-$')
			test_suite = spec.cwd .. testfile .. "::"

		elseif string.find(line, '%.%.%. .*ok') then

			local test_name = string.match(line, '^(.*) %.%.%. .*$')
            results[test_suite .. test_name] = { status = "passed" }
            results[test_suite .. '"' .. test_name .. '"'] = { status = "passed" }

		elseif string.find(line, '%.%.%. .*FAILED') then

			local test_name = string.match(line, '^(.*) %.%.%. .*$')
            results[test_suite .. test_name] = { status = "failed", } --short = testcase.failure[1],
            results[test_suite .. '"' .. test_name .. '"'] = { status = "failed", }
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
