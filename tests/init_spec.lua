local async = require("plenary.async.tests")
local neotest_deno = require("neotest-deno")

local it = async.it
local describe = async.describe

describe("DenoNeotestAdapter.init", function()

	it("has the correct name", function()

		assert.equals(neotest_deno.name, "neotest-deno")
	end)
end)

describe("DenoNeotestAdapter.is_test_file", function()

	local nix_src_dir = "/home/user/deno/app"
	local win_src_dir = "C:\\Users\\user\\Documents\\deno\\app"

	local valid_exts = {
		'js',
		'ts',
		'tsx',
		'mts',
		'mjs',
		'jsx',
		'cjs',
		'cts',
	}

	describe("Validates unix-style paths", function()

		it("recognizes files named test.<ext>", function()

			for _, ext in pairs(valid_exts) do
				local fn = nix_src_dir .. '/test.' .. ext
				assert.True(neotest_deno.is_test_file(fn))
			end
		end)

		it("recognizes files named *.test.<ext>", function()

			for _, ext in pairs(valid_exts) do
				local fn = nix_src_dir .. '/app.test.' .. ext
				assert.True(neotest_deno.is_test_file(fn))
			end
		end)

		it("recognizes files named *_test.<ext>", function()

			for _, ext in pairs(valid_exts) do
				local fn = nix_src_dir .. '/app_test.' .. ext
				assert.True(neotest_deno.is_test_file(fn))
			end
		end)

		it("rejects files with invalid names", function()

			assert.False(neotest_deno.is_test_file(nix_src_dir .. '/apptest.ts'))
			assert.False(neotest_deno.is_test_file(nix_src_dir .. '/Test.js'))
			assert.False(neotest_deno.is_test_file(nix_src_dir .. '/app.test.unit.tsx'))
			assert.False(neotest_deno.is_test_file(nix_src_dir .. '/main.jsx'))
			assert.False(neotest_deno.is_test_file(nix_src_dir .. '/app_Test.mts'))
		end)

		it("rejects files with invalid extensions", function()

			assert.False(neotest_deno.is_test_file(nix_src_dir .. '/test.json'))
			assert.False(neotest_deno.is_test_file(nix_src_dir .. '/app.test.rs'))
			assert.False(neotest_deno.is_test_file(nix_src_dir .. '/app_test.md'))
		end)
	end)

	describe("Validates Windows-style paths", function()

		it("recognizes files named test.<ext>", function()

			for _, ext in pairs(valid_exts) do
				local fn = win_src_dir .. '\\test.' .. ext
				assert.True(neotest_deno.is_test_file(fn))
			end
		end)

		it("recognizes files named *.test.<ext>", function()

			for _, ext in pairs(valid_exts) do
				local fn = win_src_dir .. '\\app.test.' .. ext
				assert.True(neotest_deno.is_test_file(fn))
			end
		end)

		it("recognizes files named *_test.<ext>", function()

			for _, ext in pairs(valid_exts) do
				local fn = win_src_dir .. '\\app_test.' .. ext
				assert.True(neotest_deno.is_test_file(fn))
			end
		end)

		it("rejects files with invalid names", function()

			assert.False(neotest_deno.is_test_file(win_src_dir .. '\\apptest.ts'))
			assert.False(neotest_deno.is_test_file(win_src_dir .. '\\Test.js'))
			assert.False(neotest_deno.is_test_file(win_src_dir .. '\\app.test.unit.tsx'))
			assert.False(neotest_deno.is_test_file(win_src_dir .. '\\main.jsx'))
			assert.False(neotest_deno.is_test_file(win_src_dir .. '\\app_Test.mts'))
		end)

		it("rejects files with invalid extensions", function()

			assert.False(neotest_deno.is_test_file(win_src_dir .. '\\test.json'))
			assert.False(neotest_deno.is_test_file(win_src_dir .. '\\app.test.rs'))
			assert.False(neotest_deno.is_test_file(win_src_dir .. '\\app_test.md'))
		end)
	end)


end)

-- TODO: More tests!
--describe("DenoNeotestAdapter.root", function()
--end)
--
--describe("DenoNeotestAdapter.filter_dir", function()
--end)

--describe("DenoNeotestAdapter.discover_positions", function()
--end)
--
--describe("DenoNeotestAdapter.build_spec", function()
--end)
--
--describe("DenoNeotestAdapter.results", function()
--end)
