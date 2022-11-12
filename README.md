# neotest-deno

A [neotest](https://github.com/rcarriga/neotest) adapter for [deno](https://deno.land/).

WIP

## Installation

Requires [nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter).

Install and configure like any other neotest adapter:

```lua

use "markemmons/neotest-deno"

require("neotest").set({
	adapters = {
		require("neotest-deno"),
		...
	}
})
```

## TODO

* Coverage
* Benchmarks
* Chai, Sinon.JS or fast-check.
* Documentation tests
* DAP support (if possible)
