# Layers

`Layers` is a module for maintaining a list of layers, which can be flagged as enabled or disabled.
The flag states are maintained in a `t:Layers.Mask/0`.

Layers can be useful for UI systems where it can be useful to show or hide certain groups of graphics together.
Another use case may be to group and enable or disable certain modules depending on if the environment is in production, or test mode.

The scope of this module is limited to registering, enabling, disabling and verifying layers.
Attaching modules or data structures to layers is not within the scope of this module.

If the list of layers is fixed and known at compile time, it is recommended to create a seperate module,
and add `use Layers` at the top. You can then define each layer using the `layer` macro,
or define multiple layers at once using the `layers` macro.
All of the Layers callbacks will then be available in this module,
which allows the user to use all of Layers functions without explicitly providing the collection of layers on every call.

## Examples

```elixir
    iex> defmodule Layers.Game do
    ...>   use Layers
    ...>
    ...>   layers [
    ...>     :player,
    ...>     :enemy,
    ...>     :projectiles
    ...>   ]
    ...>
    ...> end
    ...>
    ...> {:ok, mask} = Layers.Mask.new()
    ...>               |> Layers.Game.enable(:enemy)
    ...>
    ...> Layers.Game.enabled?(mask, :enemy)
    true
    ...> Layers.Game.disabled_layers(mask)
    [:player, :projectiles]
    ...>`{:ok, mask} = Layers.Game.enable(:player)
    ...>
    ...> Layers.Game.map(mask, fn
    ...>   :player -> {:ok, %{class: :mage, hp: 999}}
    ...>   :enemy -> {:ok, %{kind: :goblin, hp: 5}}
    ...>   :projectiles -> {:ok, %{type: :rocket, damage: 4}}
    ...> end)
    [{:ok, %{class: mage, hp: 999}}, {:ok, %{kind: :goblin, hp: 5}}]
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `layers` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:layers, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/layers](https://hexdocs.pm/layers).

