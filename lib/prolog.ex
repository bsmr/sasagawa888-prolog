defmodule Lisp do
  def repl() do
    IO.puts("Prolog in Elixir")
    repl1([],[],[])
  end

  defp repl1(env,buf,dif) do
    try do
      IO.write("?- ")
      {s,buf1} = Read.read(buf)
      {s1,env1,dif1} = Prove.prove(s,env,buf,dif)
      Print.print(s1)
      repl1(env1,buf1,dif1)
    catch
      x -> IO.puts(x)
      if x != "goodbye" do
        repl1(env,buf,dif)
      else
        true
      end
    end
  end
end

defmodule Read do
  def parse(buf) do
    {s1,buf1} = read(buf)
    {s2,buf2} = read(buf1)
    cond do
      s2 == :. -> s1
      s2 == :":-" -> [s2,s1,parse1(buf2)]
    end
  end

  def parse1(buf) do
    [1,2,3]
  end

  def read([]) do
    buf = IO.gets("") |> comment_line |> drop_eol |> tokenize
    read(buf)
  end
  def read([""|xs]) do
    read(xs)
  end
  def read(["."|xs]) do
    {:.,xs}
  end
  def read(["["|xs]) do
    read_list(xs,[])
  end
  def read([x,"("|xs]) do
    pred = String.to_atom(x)
    {tuple,rest} = read_tuple(xs,[])
    {[:pred,[pred|tuple]],rest}
  end
  def read([x|xs]) do
    cond do
      is_integer_str(x) -> {String.to_integer(x),xs}
      is_float_str(x) -> {String.to_float(x),xs}
      x == "nil" -> {nil,xs}
      true -> {String.to_atom(x),xs}
    end
  end

  defp read_list([],ls) do
    buf = IO.gets("") |> comment_line |> drop_eol |> tokenize
    read_list(buf,ls)
  end
  defp read_list(["]"|xs],ls) do
    {ls,xs}
  end
  defp read_list(["["|xs],ls) do
    {s,rest} = read_list(xs,[])
    read_list(rest,ls++[s])
  end
  defp read_list([""|xs],ls) do
    read_list(xs,ls)
  end
  defp read_list(["|"|xs],ls) do
    {s,rest} = read_list(xs,[])
    if length(s) == 1 do
      read_list(rest,[hd(ls)|hd(s)])
    else
      read_list(rest,ls++s)
    end
  end
  defp read_list([x,","|xs],ls) do
    {s,_} = read([x])
    read_list(xs,ls++[s])
  end
  defp read_list([x,"]"|xs],ls) do
    {s,_} = read([x])
    {ls++[s],xs}
  end
  defp read_list(x,ls) do
    {s,rest} = read(x)
    read_list(rest,ls++[s])
  end

  defp read_tuple([],ls) do
    buf = IO.gets("") |> comment_line |> drop_eol |> tokenize
    read_tuple(buf,ls)
  end
  defp read_tuple([")"|xs],ls) do
    {ls,xs}
  end
  defp read_tuple(["("|xs],ls) do
    {s,rest} = read_tuple(xs,[])
    read_tuple(rest,ls++[s])
  end
  defp read_tuple([""|xs],ls) do
    read_tuple(xs,ls)
  end
  defp read_tuple([x,","|xs],ls) do
    {s,_} = read([x])
    read_tuple(xs,ls++[s])
  end
  defp read_tuple([x,"]"|xs],ls) do
    {s,_} = read([x])
    {ls++[s],xs}
  end
  defp read_tuple(x,ls) do
    {s,rest} = read(x)
    read_tuple(rest,ls++[s])
  end


  defp tokenize(str) do
    str |> String.to_charlist |> tokenize1([],[])
  end

  defp tokenize1([],token,res) do
    token1 = Enum.reverse(token) |> List.to_string
    res1 = [token1|res]
    Enum.reverse(res1)
  end
  #space
  defp tokenize1([32,32|ls],token,res) do
    tokenize1(ls,token,res)
  end
  defp tokenize1([32|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],[token1|res])
  end
  defp tokenize1([40|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],["(",token1|res])
  end
  defp tokenize1([41|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],[")",token1|res])
  end
  defp tokenize1([91|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],["[",token1|res])
  end
  defp tokenize1([93|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],["]",token1|res])
  end
  defp tokenize1([124|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],["|",token1|res])
  end
  defp tokenize1([44|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],[",",token1|res])
  end
  defp tokenize1([46|ls],token,res) do
    token1 = token |> Enum.reverse |> List.to_string
    tokenize1(ls,[],[".",token1|res])
  end
  defp tokenize1([l|ls],token,res) do
    tokenize1(ls,[l|token],res)
  end

  defp comment_line(x) do
    if String.slice(x,0,1) == ";" do
      IO.gets("? ")
    else
      x
    end
  end

  defp drop_eol(x) do
    String.split(x,"\n") |> hd
  end

  defp is_integer_str(x) do
    cond do
      x == "" -> false
      # 123
      Enum.all?(x |> String.to_charlist, fn(y) -> y >= 48 and y <= 57 end) -> true
      # +123
      String.length(x) >= 2 and
      x |> String.to_charlist |> hd == 43 and # +
      Enum.all?(x |> String.to_charlist |> tl, fn(y) -> y >= 48 and y <= 57 end) -> true
      # -123
      String.length(x) >= 2 and
      x |> String.to_charlist |> hd == 45 and # -
      Enum.all?(x |> String.to_charlist |> tl, fn(y) -> y >= 48 and y <= 57 end) -> true
      true -> false
    end
  end

  defp is_float_str(x) do
    y = String.split(x,".")
    z = String.split(x,"e")
    cond do
      length(y) == 1 and length(z) == 1 -> false
      length(y) == 2 and is_integer_str(hd(y)) and is_integer_str(hd(tl(y))) -> true
      length(z) == 2 and is_float_str(hd(z)) and is_integer_str(hd(tl(z))) -> true
      true -> false
    end
  end
end

  #----------------prove-------------
defmodule Prove do
  def prove(x,env,buf,dif) do
    {x,env,buf,dif}
  end
end

#----------------print------------
defmodule Print do
  def print(x) when is_number(x) do
    IO.puts(x)
  end
  def print(x) when is_atom(x) do
    if x != nil do
      IO.puts(x)
    else
      IO.puts("nil")
    end
  end
  def print(x) when is_list(x) do
    print_list(x)
  end

  defp print_list([]) do
    IO.puts("nil")
  end
  defp print_list([x|xs]) do
    IO.write("(")
    print(x)
    if xs != [] do
      IO.write(" ")
    end
    print_list1(xs)
  end

  defp print_list1(x) when is_atom(x)do
    IO.write(".")
    print(x)
    IO.puts(")")
  end
  defp print_list1(x) when is_number(x)do
    IO.write(". ")
    print(x)
    IO.puts(")")
  end
  defp print_list1([]) do
    IO.puts(")")
  end
  defp print_list1([x|xs]) do
    print(x)
    if xs != [] do
      IO.write(" ")
    end
    print_list1(xs)
  end
end
