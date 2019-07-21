defmodule PrologTest do
  use ExUnit.Case
  doctest Prolog

  test "greets the world" do
    assert Prolog.hello() == :world
  end
end
