defmodule PrologTest do
  use ExUnit.Case
  doctest Prolog

  test "deref" do
    env =  [[[:A, 5], 1],[[:A1, 5], 1],[[:N1, 5], 0],[[:A1, 3], [:A, 5]],
            [[:N, 5], 1],[[:N1, 3], 1],[[:A1, 1], [:A, 3]],[[:N, 3], 2],
            [[:N1, 1], 2],[:X, [:A, 1]],[[:N, 1], 3]]
    assert Prove.deref([:A1,3],env) == 1
  end
end
