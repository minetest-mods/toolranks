# toolranks

Tools gain levels for digging nodes. Higher level tools dig faster and take longer to wear out.

But remember to repair your tools before they wear out! Here are a few mods that can repair tools:

* xdecor (node: Workbench)
* [anvil](https://github.com/minetest-mods/anvil)
* [technic](https://github.com/minetest-mods/technic) / [technic_plus](https://github.com/mt-mods/technic) (node: MV Tool Workshop)


## Licence
Code: LGPLv2.1+
Tool level sound: [CC BY 3.0](https://freesound.org/people/MakoFox/sounds/126422/)

## Are you a mod developer?

Does one of your mods add new tools?
If so, to support this mod, add this code to your mod, after your tool's code:

```lua
if core.get_modpath("toolranks") then
    core.override_item("mymod:mytool", {
        original_description = "My Tool",
        description = toolranks.create_description("My Tool"),
        after_use = toolranks.new_afteruse
    })
    end
end
```

Or alternatively, you can use the helper function:

```lua
toolranks.add_tool("mymod:mytool")
```
