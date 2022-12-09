local lib = require("neotest.lib")
local utils = require("neotest-deno.utils")
local config = require("neotest-deno.config")

---@class neotest.Adapter
---@field name string
local DenoNeotestAdapter = { name = "neotest-deno" }

---Find the project root directory given a current directory to work from.
---Should no root be found, the adapter can still be used in a non-project context if a test file matches.
---@async
---@param dir string @Directory to treat as cwd
---@return string | nil @Absolute root dir of test suite
function DenoNeotestAdapter.root(dir)

	local result = nil
	local root_files = vim.list_extend(
		config.get_additional_root_files(),
		{ "deno.json", "deno.jsonc", "import_map.json" }
	)

	for _, root_file in ipairs(root_files) do
		result = lib.files.match_root_pattern(root_file)(dir)
		if result then
			break
		end
	end

	return result
end

---Filter directories when searching for test files
---@async
---@param name string Name of directory
---!param rel_path string Path to directory, relative to root
---!param root string Root directory of project
function DenoNeotestAdapter.filter_dir(name)

	local filter_dirs = vim.list_extend(
		config.get_additional_filter_dirs(),
		{ "node_modules" }
	)

	for _, filter_dir in ipairs(filter_dirs) do
		if name == filter_dir then
			return false
		end
	end

	return true
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

	-- TODO: discover flat tests
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

---@param args neotest.RunArgs
---@return nil | neotest.RunSpec | neotest.RunSpec[]
function DenoNeotestAdapter.build_spec(args)

	local results_path = utils.get_results_file()
    local position = args.tree:data()
	local strategy = {}

	local cwd = assert(
		DenoNeotestAdapter.root(position.path),
		"could not locate root directory of " .. position.path
	)

    local command_args = vim.tbl_flatten({
		"test",
		position.path,
		"--no-prompt",
		vim.list_extend(config.get_args(), args.extra_args or {}),
		config.get_allow() or "--allow-all",
    })

	if position.type == "test" then

		local test_name = position.name
		if args.strategy == "dap" then
			test_name = test_name:gsub('^"', ''):gsub('"$', '')
		end

        vim.list_extend(command_args, { "--filter", test_name })
	end

	-- BUG: Need to capture results after debugging the test
	-- TODO: Adding additional arguments breaks debugging
	-- need to determine if this is normal
	if args.strategy == "dap" then

		-- TODO: Allow users to specify an alternate port =HOST:PORT
		vim.list_extend(command_args, { "--inspect-brk" })

		strategy = {
			name = 'Deno',
			type = config.get_dap_adapter(),
			request = 'launch',
			cwd = '${workspaceFolder}',
			runtimeExecutable = 'deno',
			runtimeArgs = command_args,
			port = 9229,
			protocol = 'inspector',
		}
	end

	return {
		command = 'deno ' .. table.concat(command_args, " "),
		context = {
			results_path = results_path,
			position = position,
		},
		cwd = cwd,
		strategy = strategy,
	}
end

---@async
---@param spec neotest.RunSpec
---!param result neotest.StrategyResult
---!param tree neotest.Tree
---@return table<string, neotest.Result>
function DenoNeotestAdapter.results(spec)

    local results = {}
	local test_suite = ''
	local handle = assert(io.open(spec.context.results_path))
	local line = handle:read("l")

	-- TODO: ouput and short fields for failures
	while line do

		-- Next test suite
		if string.find(line, 'running %d+ test') then
			local testfile = string.match(line, 'running %d+ tests? from %.(.+%w+[sx]).-$')
			test_suite = spec.cwd .. testfile .. "::"

		-- Passed test
		elseif string.find(line, '%.%.%. .*ok') then
            results[test_suite .. utils.get_test_name(line)] = { status = "passed" }

		-- Failed test
		elseif string.find(line, '%.%.%. .*FAILED') then
            results[test_suite .. utils.get_test_name(line)] = { status = "failed", }
		end

		line = handle:read("l")
	end

	if handle then
		handle:close()
	end

    return results
end

setmetatable(DenoNeotestAdapter, {
	__call = function(_, opts)
		if utils.is_callable(opts.args) then
			config.get_args = opts.args
		elseif opts.args then
			config.get_args = function()
				return opts.args
			end
		end
		if utils.is_callable(opts.allow) then
			config.get_allow = opts.allow
		elseif opts.allow then
			config.get_allow = function()
				return opts.allow
			end
		end
		if utils.is_callable(opts.root_files) then
			config.get_additional_root_files = opts.root_files
		elseif opts.root_files then
			config.get_additional_root_files = function()
				return opts.root_files
			end
		end
		if utils.is_callable(opts.filter_dirs) then
			config.get_additional_filter_dirs = opts.filter_dirs
		elseif opts.filter_dirs then
			config.get_additional_filter_dirs = function()
				return opts.filter_dirs
			end
		end
		if utils.is_callable(opts.dap_adapter) then
			config.get_dap_adapter = opts.dap_adapter
		elseif opts.dap_adapter then
			config.get_dap_adapter = function()
				return opts.dap_adapter
			end
		end
		return DenoNeotestAdapter
	end,
})

return DenoNeotestAdapter
