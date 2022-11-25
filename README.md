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

### Test Support

- [x] Deno.test tests
- [x] bdd - nested tests
- [ ] bdd - flat tests
- [ ] Chai
- [ ] Sinon.JS
- [ ] fast-check
- [ ] Documentation tests

### Features

- [ ] Coverage
- [ ] Benchmarks
- [ ] DAP support (if possible)
