defmodule Constants do
  @moduledoc """
  An alternative to use @constant_name value approach to defined reusable 
  constants in elixir. 

  This module offers an approach to define these in a
  module that can be shared with other modules. They are implemented with 
  macros so they can be used in guards and matches

  ## Examples: 

  Create a module to define your shared constants

      defmodule MyConstants do
        use Constants

        define something,   10
        define another,     20
      end

  Use the constants

      defmodule MyModule do
        require MyConstants
        alias MyConstants, as: Const

        def myfunc(item) when item == Const.something, do: Const.something + 5
        def myfunc(item) when item == Const.another, do: Const.another
      end

  """

  defmacro __using__(_opts) do
    quote do
      import Constants
    end
  end

  @doc "Define a constant"
  defmacro constant(name, value) do
    quote do
      defmacro unquote(name), do: unquote(value)
    end
  end

  @doc "Define a constant. An alias for constant"
  defmacro define(name, value) do
    quote do
      constant(unquote(name), unquote(value))
    end
  end
end

defmodule Common.Constant do
  @moduledoc """
  全局变量

  ## Example

  require Common.Constant
  alias Common.Constant, as: Const

  IO.puts(Const.xxx())

  """

  use Constants
  ######### 订单相关 ##########

  ## 订单状态
  define(order_status_deleted, -1)
  define(order_status_unpaid, 1)
  define(order_status_canceled, 2)
  define(order_status_paid, 3)
  define(order_status_finished, 4)
  define(order_status_refunded, 5)

  ######### 电子眼相关 ########

  define(dzy_err_carno, 1)
  define(dzy_err_vin, 2)
  define(dzy_err_engine, 3)
  define(dzy_err_sys, 4)
end
