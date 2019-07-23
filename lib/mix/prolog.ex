defmodule Mix.Tasks.Prolog do
  use Mix.Task

  def run(_) do
    Prolog.repl()
  end
end
