unused_args = false
allow_defined_top = true
max_line_length = 999

globals = {
    "core",
}

read_globals = {
    string = {fields = {"split"}},
    table = {fields = {"copy", "getn"}},

    -- Builtin
    "vector", "ItemStack",
    "dump",

    -- MTG
    "default"
}
