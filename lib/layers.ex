defmodule Layers do
  @moduledoc """
  Layers is a module for maintaining a list of layers, which can be flagged as enabled or disabled.
  The flag states are maintained in a layer mask.

  Layers can be useful for UI systems where it can be useful to show or hide certain groups of graphics together.
  Another use case may be to group and enable or disable certain modules depending on if the environment is in production, or test mode.

  The scope of this module is limited to registering, enabling, disabling and verifying layers.
  Attaching modules or data structures to layers is not within the scope of this module.

  If the list of layers is fixed and known at compile time, it is recommended to create a seperate module,
  and add `use Layers` at the top. You can then define each layer using the `layer` macro,
  or define multiple layers at once using the `layers` macro.
  All of the Layers callbacks will then be available in this module,
  which allows the user to use all of Layers functions without explicitly providing the collection of layers on every call.
  """

  alias Layers.Mask

  @typedoc """
  An atom representing a layer
  """
  @type layer :: atom

  @typedoc """
  The numeric identifier of a layer
  """
  @type index :: number

  @typedoc """
  A list of layers
  """
  @type layers :: [layer]

  @typedoc """
  A list of layer indices
  """
  @type indices :: [index]

  @typedoc """
  A list of atom based layer identifiers, or a list of the layers numeric identifiers
  """
  @type t :: layers | indices

  @callback layer_to_index(layer | index) :: {:ok, index} | {:error, String.t}
  @callback layer_to_index!(layer | index) :: index
  @callback enable(Mask.t, layer | index) :: {:ok, Mask.t} | {:error, String.t}
  @callback enable!(Mask.t, layer | index) :: Mask.t
  @callback disable(Mask.t, layer | index) :: {:ok, Mask.t} | {:error, String.t}
  @callback disable!(Mask.t, layer | index) :: Mask.t
  @callback enabled?(Mask.t, layer | index) :: boolean
  @callback disabled?(Mask.t, layer | index) :: boolean
  @callback enabled_layers(Mask.t) :: t
  @callback disabled_layers(Mask.t) :: t
  @callback map(Mask.t, (layer -> term)) :: [term]
  @callback map(Mask.t, layer | index, (layer -> term)) :: {:some, term} | :none
  @callback map(Mask.t, layer | index, term, (layer -> term)) :: term

  @doc false
  defmacro __using__(opts) do
    quote bind_quoted: [opts: opts] do
      @behaviour Layers
      import Layers, only: :macros

      Module.register_attribute __MODULE__, :layer_register, accumulate: true
      @before_compile Layers
    end
  end

  @doc """
  Register a layer at compile time.

  ## Examples

      iex> defmodule Layers.Env do
      ...>   use Elixir.Layers
      ...>
      ...>   layer :prod
      ...>   layer :mock
      ...>
      ...> end
      ...>
      ...> Elixir.Layers.Mask.new()
      ...> |> Layers.Env.disabled_layers()
      [:mock, :prod]

  """
  defmacro layer(layer) do
    quote do
      @layer_register unquote(layer)
    end
  end

  @doc """
  Register multiple layers at compile time.

  ## Examples

      iex> defmodule Layers.Game do
      ...>   use Elixir.Layers
      ...>
      ...>   layers [
      ...>     :player,
      ...>     :enemy,
      ...>     :projectiles
      ...>   ]
      ...>
      ...> end
      ...>
      ...> Elixir.Layers.Mask.new()
      ...> |> Layers.Game.disabled_layers()
      [:projectiles, :enemy, :player]

  """
  defmacro layers(layers) do
    quote do
      Enum.each(unquote(layers), fn layer -> @layer_register layer end)
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    layers = Module.get_attribute(env.module, :layer_register)

    quote do
      @impl(Layers)
      def layer_to_index(layer), do: Layers.layer_to_index(unquote(Macro.escape(layers)), layer)
      @impl(Layers)
      def layer_to_index!(layer), do: Layers.layer_to_index!(unquote(Macro.escape(layers)), layer)
      @impl(Layers)
      def enable(mask, layer), do: Layers.enable(unquote(Macro.escape(layers)), mask, layer)
      @impl(Layers)
      def enable!(mask, layer), do: Layers.enable!(unquote(Macro.escape(layers)), mask, layer)
      @impl(Layers)
      def disable(mask, layer), do: Layers.disable(unquote(Macro.escape(layers)), mask, layer)
      @impl(Layers)
      def disable!(mask, layer), do: Layers.disable!(unquote(Macro.escape(layers)), mask, layer)
      @impl(Layers)
      def enabled?(mask, layer), do: Layers.enabled?(unquote(Macro.escape(layers)), mask, layer)
      @impl(Layers)
      def disabled?(mask, layer), do: Layers.disabled?(unquote(Macro.escape(layers)), mask, layer)
      @impl(Layers)
      def enabled_layers(mask), do: Layers.enabled_layers(unquote(Macro.escape(layers)), mask)
      @impl(Layers)
      def disabled_layers(mask), do: Layers.disabled_layers(unquote(Macro.escape(layers)), mask)
      @impl(Layers)
      def map(mask, fun), do: Layers.map(unquote(Macro.escape(layers)), mask, fun)
      @impl(Layers)
      def map(mask, layer, fun), do: Layers.map(unquote(Macro.escape(layers)), mask, layer, fun)
      @impl(Layers)
      def map(mask, layer, default, fun), do: Layers.map(unquote(Macro.escape(layers)), mask, layer, default, fun)
    end
  end

  @doc """
  Obtain the index of a layer.
  If the layer identifier passed as second argument is already a numeric representation,
  no conversion will take place.

  ## Examples

      iex> Layers.layer_to_index([:default, :mock], :mock)
      {:ok, 1}
      ...> Layers.layer_to_index([:default, :mock], 0)
      {:ok, 0}
      ...> Layers.layer_to_index([:default, :mock], :dev)
      {:error, "Layer {dev} not found!"}

  """
  @spec layer_to_index(t, layer | index) :: {:ok, index} | {:error, String.t}
  def layer_to_index(_, layer) when is_number(layer), do: {:ok, layer}

  def layer_to_index(layers, layer) do
    case Enum.find_index(layers, &(layer == &1)) do
      nil -> {:error, "Layer {" <> to_string(layer) <> "} not found!"}
      index -> {:ok, index}
    end
  end

  @doc """
  Obtain the index of a layer.
  This function will throw an error if the layer does not exist.

  ## Examples

      iex> Layers.layer_to_index!([:red, :green, :blue, :alpha], :blue)
      2

  """
  @spec layer_to_index!(t, layer | index) :: number | no_return
  def layer_to_index!(_, layer) when is_number(layer), do: layer

  def layer_to_index!(layers, layer) do
    case Enum.find_index(layers, &(layer == &1)) do
      nil -> throw "Layer {" <> to_string(layer) <> "} not found!"
      index -> index
    end
  end

  @doc """
  Flags a layer as enabled, and returns the updated mask.

  ## Examples

      iex> layers = [:r, :g, :b, :a]
      ...> mask = Layers.Mask.new()
      ...> Layers.enabled?(layers, mask, :b)
      false
      ...> {:ok, mask} = Layers.enable(layers, mask, :b)
      ...> Layers.enabled?(layers, mask, :b)
      true

  """
  @spec enable(t, Mask.t, layer | index) :: {:ok, Mask.t} | {:error, String.t}
  def enable(layers, mask, layer) do
    case layer_to_index(layers, layer) do
      {:ok, index} -> {:ok, Mask.enable(mask, index)}
      error -> error
    end
  end

  @doc """
  Flags a layer as enabled, and returns the updated mask.
  Throws an error if the layer does not exist.

  ## Examples

      iex> layers = [:r, :g, :b, :a]
      ...> mask = Layers.Mask.new()
      ...> Layers.enabled?(layers, mask, :b)
      false
      ...> mask = Layers.enable!(layers, mask, :g)
      ...> Layers.enabled?(layers, mask, :g)
      true

  """
  @spec enable!(t, Mask.t, layer | index) :: Mask.t | no_return
  def enable!(layers, mask, layer) do
    case enable(layers, mask, layer) do
      {:ok, mask} -> mask
      {:error, error} -> throw error
    end
  end

  @doc """
  Flags a layer as disabled, and returns the updated mask.

  ## Examples

      iex> layers = [:r, :g, :b, :a]
      ...> mask = Layers.Mask.new()
      ...> |> Layers.Mask.enable_all(length(layers))
      ...> Layers.enabled?(layers, mask, :b)
      true
      ...> {:ok, mask} = Layers.disable(layers, mask, :b)
      ...> Layers.enabled?(layers, mask, :b)
      false

  """
  @spec disable(t, Mask.t, layer | index) :: {:ok, Mask.t} | {:error, String.t}
  def disable(layers, mask, layer) do
    case layer_to_index(layers, layer) do
      {:ok, index} -> {:ok, Mask.disable(mask, index)}
      error -> error
    end
  end

  @doc """
  Flags a layer as disabled, and returns the updated mask.
  Throws an error if the layer does not exist.

  ## Examples

      iex> layers = [:r, :g, :b, :a]
      ...> mask = Layers.Mask.new()
      ...> |> Layers.Mask.enable_all(length(layers))
      ...> Layers.enabled?(layers, mask, :b)
      true
      ...> mask = Layers.disable!(layers, mask, :b)
      ...> Layers.enabled?(layers, mask, :b)
      false

  """
  @spec disable!(t, Mask.t, layer | index) :: Mask.t | no_return
  def disable!(layers, mask, layer) do
    case disable(layers, mask, layer) do
      {:ok, mask} -> mask
      {:error, error} -> throw error
    end
  end

  @doc """
  Verify if the layer, or one of the layers passed as third argument,
  is enabled on the layer mask passed as second argument.

  If multiple layers are passed, one or more of the layers has to be enabled to pass the verification.

  ## Examples

      iex> layers = [:r, :g, :b, :a]
      ...> mask = Layers.Mask.new()
      ...> {:ok, mask} = Layers.enable(layers, mask, :g)
      ...> {:ok, mask} = Layers.enable(layers, mask, :a)
      ...> Layers.enabled?(layers, mask, :r)
      false
      ...> Layers.enabled?(layers, mask, :g)
      true
      ...> Layers.enabled?(layers, mask, [:r, :b])
      false
      ...> Layers.enabled?(layers, mask, [:r, :a])
      true

  """
  @spec enabled?(t, Mask.t, layer | index | [layer] | [index]) :: boolean
  def enabled?(layers, mask, layer) when is_list(layer) do
    Enum.reduce(layer, false, fn
      _, true -> true
      layer, false -> enabled?(layers, mask, layer)
    end)
  end

  def enabled?(layers, mask, layer) do
    case layer_to_index(layers, layer) do
      {:ok, index} -> Mask.enabled?(mask, index)
      _ -> false
    end
  end

  @doc """
  Verify if the layer, or all of the layers passed as third argument,
  are disabled on the layer mask passed as second argument.

  If multiple layers are passed, all off the layers need to be disabled to verify as disabled.

  ## Examples

      iex> layers = [:r, :g, :b, :a]
      ...> mask = Layers.Mask.new()
      ...> {:ok, mask} = Layers.enable(layers, mask, :g)
      ...> {:ok, mask} = Layers.enable(layers, mask, :a)
      ...> Layers.disabled?(layers, mask, :r)
      true
      ...> Layers.disabled?(layers, mask, :g)
      false
      ...> Layers.disabled?(layers, mask, [:r, :g])
      false
      ...> Layers.disabled?(layers, mask, [:r, :b])
      true

  """
  @spec disabled?(t, Mask.t, layer | index | [layer] | [index]) :: boolean
  def disabled?(layers, mask, layer) do
    !enabled?(layers, mask, layer)
  end

  @doc """
  Filters a collection of layers and returns only those that are enabled on the layer mask.

  ## Examples

      iex> layers = [:r, :g, :b, :a]
      ...> mask = Layers.Mask.new()
      ...> {:ok, mask} = Layers.enable(layers, mask, :g)
      ...> {:ok, mask} = Layers.enable(layers, mask, :a)
      ...> Layers.enabled_layers(layers, mask)
      [:g, :a]

  """
  @spec enabled_layers(t, Mask.t) :: t
  def enabled_layers(layers, mask) do
    layers
    |> Enum.filter(&enabled?(layers, mask, &1))
  end

  @doc """
  Filters a collection of layers and returns only those that are disabled on the layer mask.

  ## Examples

      iex> layers = [:r, :g, :b, :a]
      ...> mask = Layers.Mask.new()
      ...> {:ok, mask} = Layers.enable(layers, mask, :g)
      ...> {:ok, mask} = Layers.enable(layers, mask, :a)
      ...> Layers.disabled_layers(layers, mask)
      [:r, :b]

  """
  @spec disabled_layers(t, Mask.t) :: t
  def disabled_layers(layers, mask) do
    layers
    |> Enum.filter(&disabled?(layers, mask, &1))
  end

  @doc """
  Runs a function agains all enabled layers.

  ## Examples

      iex> layers = [:r, :g, :b, :a]
      ...> mask = Layers.Mask.new()
      ...> {:ok, mask} = Layers.enable(layers, mask, :g)
      ...> {:ok, mask} = Layers.enable(layers, mask, :a)
      ...> Layers.map(layers, mask, &Kernel.to_string/1)
      ["g", "a"]

  """
  @spec map(t, Mask.t, (layer -> term)) :: [term]
  def map(layers, mask, fun) do
    enabled_layers(layers, mask)
    |> Enum.map(fun)
  end

  @doc """
  Runs a function against a layer, only if the layer is enabled.
  Returns the result in option form, returning {:some, return_value} if the function was executed,
  and :none if the layer was disabled and nothing happened.

  ## Examples

      iex> layers = [:prod, :dev, :mock]
      ...> mask = Layers.Mask.new()
      ...> {:ok, mask} = Layers.enable(layers, mask, :prod)
      ...> Layers.map(layers, mask, :prod, &Kernel.to_string/1)
      {:some, "prod"}
      ...> Layers.map(layers, mask, :dev, &Kernel.to_string/1)
      :none

  """
  @spec map(t, Mask.t, layer | index, (layer -> term)) :: {:some, term} | :none
  def map(layers, mask, layer, fun) do
    if enabled?(layers, mask, layer), do: {:some, fun.(layer)}, else: :none
  end

  @doc """
  Runs a function against a layer, only if the layer is enabled.
  Returns a default value in case the layer is disabled.

  ## Examples

      iex> layers = [:prod, :dev, :mock]
      ...> mask = Layers.Mask.new()
      ...> {:ok, mask} = Layers.enable(layers, mask, :prod)
      ...> Layers.map(layers, mask, :prod, "disabled", &Kernel.to_string/1)
      "prod"
      ...> Layers.map(layers, mask, :dev, "disabled", &Kernel.to_string/1)
      "disabled"

  """
  @spec map(t, Mask.t, layer | index, term, (layer -> term)) :: term
  def map(layers, mask, layer, default, fun) do
    if enabled?(layers, mask, layer), do: fun.(layer), else: default
  end

end
