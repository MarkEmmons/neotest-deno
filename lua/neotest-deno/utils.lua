local async = require("neotest.async")

local M = {}

M.get_args = function()
	return {}
end

M.get_allow = function()
	return nil
end

M.get_additional_root_files = function()
	return {}
end

M.get_additional_filter_dirs = function()
	return {}
end

M.get_dap_adapter = function()
	return 'deno'
end

M.is_callable = function(obj)
	return type(obj) == "function" or (type(obj) == "table" and obj.__call)
end

-- Hacky workaround to get the name of the output file
M.get_results_file = function()
	local tmp_dir, idx = string.match(async.fn.tempname(), "(.*)(%d+)$")
	return tmp_dir .. (tonumber(idx) + 1)
end

-- Extract test name from output line. Add quotes if necessary
M.get_test_name = function(output_line)
	local test_name = string.match(output_line, '^(.*) %.%.%. .*$')
	if string.match(test_name, ' ') then
		test_name = '"' .. test_name .. '"'
	end
	return test_name
end

return M
