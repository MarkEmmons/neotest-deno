# neotest-deno

A [neotest](https://github.com/rcarriga/neotest) adapter for [deno](https://deno.land/).

WIP

![neotest-deno1](https://user-images.githubusercontent.com/21696951/206565569-3d7b6489-da56-42e3-bf72-9b2599dc3a30.gif)

![neotest-deno2](https://user-images.githubusercontent.com/21696951/206565583-e7c0696d-6183-4652-af18-aa74775ecb97.gif)

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
