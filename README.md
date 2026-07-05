# toolranks

Tools gain levels for digging nodes. Higher level tools dig faster and take longer to wear out.

But remember to repair your tools before they wear out! Here are a few mods that can repair tools:

* xdecor (node: Workbench)
* [anvil](https://github.com/minetest-mods/anvil)
* [technic](https://github.com/minetest-mods/technic) / [technic_plus](https://github.com/mt-mods/technic) (node: MV Tool Workshop)
* Crafting: 2x damaged tool -> 1x repaired tool


## Licence
Code: LGPLv2.1+

Tool level sound: [CC BY 3.0](https://freesound.org/people/MakoFox/sounds/126422/)

## Mod compatibility

Included support for:

* `default` (Minetest Game)
* `mcl_tools` (VoxeLands/Mineclonia)

Some mods that support `toolranks`:

* `ethereal`
* `nether`


### Are you a mod developer?

Does one of your mods add new tools?
If so, to support this mod, add this code to your mod, after your tool's code:

```lua
core.register_tool("mymod:mytool", {
	description = "My Tool Description",
	tool_capabilities = { ... },
}

-- toolranks support
toolranks.add_tool("mymod:mytool")
```

**Note:** `toolranks` overwrites the following item definition fields:

* `after_use` (function)
* `description` (string)

If you would like to use these fields, consider the following:

```lua
core.register_tool("mymod:mytool", {
	description = toolranks.create_description("My Tool Description", 0) ..
		"\nTool with cool SFX!",
	...
	after_use = function(itemstack, user, node, digparams)
		itemstack = toolranks.new_afteruse(itemstack, user, node, digparams) or itemstack
		if have_some_condition then
			...
		end
		return itemstack
	end,
	...
})
```
