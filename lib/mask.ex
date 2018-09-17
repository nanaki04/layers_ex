defmodule Layers.Mask do
  @moduledoc """
  Module for performing operations on a layer mask, such as enabling, disabling or toggling layers.
  The mask is an integer of which every bit represents the enabled state of a layer.
  """

  use Bitwise, only_operators: true

  @typedoc """
  The layer mask.
  """
  @type t :: number

  @typedoc """
  On or more layer indices.
  """
  @type indices :: number | [number]

  @doc """
  Creates a new empty mask, with all layers disabled.

  ## Examples

      iex> Layers.Mask.new()
      ...> |> Layers.Mask.format()
      <<0>>

  """
  @spec new() :: t
  def new(), do: 0

  @doc """
  Switch all layers on the mask to enabled.
  The total number of layers needs to be provided as second argument.

  ## Examples

      iex> Layers.Mask.new()
      ...> |> Layers.Mask.enable_all(5)
      ...> |> Layers.Mask.format()
      <<1, 1, 1, 1, 1>>

  """
  @spec enable_all(t, number) :: t
  def enable_all(_, length) do
    0..(length - 1)
    |> Enum.map(fn _ -> 1 end)
    |> Integer.undigits(2)
  end

  @doc """
  Disables all layers on a mask.

  ## Examples

      iex> Layers.Mask.new()
      ...> |> Layers.Mask.enable_all(5)
      ...> |> Layers.Mask.disable_all()
      ...> |> Layers.Mask.format()
      <<0>>

  """
  @spec disable_all(t) :: t
  def disable_all(_), do: 0

  @doc """
  Enables one or more layers on a mask.

  ## Examples

    iex> Layers.Mask.new()
    ...> |> Layers.Mask.enable(3)
    ...> |> Layers.Mask.format()
    <<1, 0, 0, 0>>

    iex> Layers.Mask.new()
    ...> |> Layers.Mask.enable([1, 4])
    ...> |> Layers.Mask.format()
    <<1, 0, 0, 1, 0>>

  """
  @spec enable(t, indices) :: t
  def enable(mask, indices) when is_list(indices) do
    Enum.reduce(indices, mask, fn index, mask -> enable(mask, index) end)
  end

  def enable(mask, indices) do
    mask ||| 1 <<< indices
  end

  @doc """
  Disable one or more layers on a mask.

  ## Examples

    iex> Layers.Mask.new()
    ...> |> Layers.Mask.enable_all(4)
    ...> |> Layers.Mask.disable(2)
    ...> |> Layers.Mask.format()
    <<1, 0, 1, 1>>

    iex> Layers.Mask.new()
    ...> |> Layers.Mask.enable_all(5)
    ...> |> Layers.Mask.disable([1, 3])
    ...> |> Layers.Mask.format()
    <<1, 0, 1, 0, 1>>

  ## Examples

  """
  @spec disable(t, indices) :: t
  def disable(mask, indices) when is_list(indices) do
    Enum.reduce(indices, mask, fn index, mask -> disable(mask, index) end)
  end

  def disable(mask, indices) do
    size =
      mask
      |> Integer.digits(2)
      |> length()

    mask &&& enable_all(mask, size) ^^^ (1 <<< indices)
  end

  @doc """
  Toggles the enabled state of a layer.

  ## Examples

      iex> mask = Layers.Mask.new()
      ...> |> Layers.Mask.toggle(2)
      ...> Layers.Mask.format(mask)
      <<1, 0, 0>>
      ...> Layers.Mask.toggle(mask, [3, 2])
      ...> |> Layers.Mask.format()
      <<1, 0, 0, 0>>

  """
  @spec toggle(t, indices) :: t
  def toggle(mask, indices) when is_list(indices) do
    Enum.reduce(indices, mask, fn index, mask -> toggle(mask, index) end)
  end

  def toggle(mask, indices), do: mask ^^^ (1 <<< indices)

  @doc """
  Verifies if a layer is enabled.

  ## Examples

      iex> mask = Layers.Mask.new()
      ...> Layers.Mask.enabled?(mask, 0)
      false
      ...> Layers.Mask.enable(mask, 0)
      ...> |> Layers.Mask.enabled?(0)
      true

  """
  @spec enabled?(t, number) :: boolean
  def enabled?(mask, index) do
    (mask &&& enable(new(), index)) > 0
  end

  @doc """
  Verifies if a layer is disabled.

  ## Examples

      iex> mask = Layers.Mask.new()
      ...> Layers.Mask.disabled?(mask, 2)
      true
      ...> Layers.Mask.enable(mask, 2)
      ...> |> Layers.Mask.disabled?(2)
      false

  """
  @spec disabled?(t, number) :: boolean
  def disabled?(mask, index), do: not enabled?(mask, index)

  @doc """
  Prints the mask in readable format.

  ## Examples

      iex> Layers.Mask.new()
      ...> |> Layers.Mask.enable(2)
      ...> |> Layers.Mask.enable(4)
      ...> |> Layers.Mask.format()
      <<1, 0, 1, 0, 0>>

  """
  @spec format(t) :: String.t()
  def format(mask) do
    mask
    |> Integer.digits(2)
    |> Kernel.to_string()
  end
end
