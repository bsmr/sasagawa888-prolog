defmodule Prolog do
  def repl() do
    IO.puts("Prolog in Elixir")
    repl1([])
  end

  defp repl1(def) do
    try do
      IO.write("?- ")
      {s,_} = Read.parse([])
      s1 = add_ask(s)
      {s2,_,def1} = Prove.prove_all(s1,[],def,1)
      Print.print(s2)
      repl1(def1)
    catch
      x -> IO.puts(x)
      if x != "goodbye" do
        repl1(def)
      else
        true
      end
    end
  end

  def find_var([],res) do Enum.reverse(res) end
  def find_var([x|xs],res) when is_list(x) do
    res1 = find_var(x,res)
    find_var(xs,res1++res)
  end
  def find_var([x|xs],res) do
    if is_var(x) && !Enum.member?(res,x) do
      find_var(xs,[x|res])
    else
      find_var(xs,res)
    end
  end

  def add_ask(x) do
    ask = [:builtin,[:ask|find_var(x,[])]]
    if is_assert(x) do
      [x]
    else if is_pred(x) || is_builtin(x) do
      [x] ++ [ask]
    else
      # conjunction
      x ++ [ask]
    end
    end
  end

  #-------------data type------------
  def is_pred([:pred,_]) do true end
  def is_pred(_) do false end

  def is_clause([:clause,_,_]) do true end
  def is_clause(_) do false end

  def is_builtin([:builtin,_]) do true end
  def is_builtin(_) do false end

  def  is_var(x) do
    if is_atomvar(x) || is_variant(x) do
      true
    else
      false
    end
  end
  # atom vairable
  def is_atomvar(x) when is_atom(x) do
    x1 = x |> Atom.to_charlist |> Enum.at(0)
    cond do
      x1 == 95 -> true  #under bar
      x1 >= 65 && x1 <= 90 -> true #uppercase
      true -> false
    end
  end
  def is_atomvar(_) do false end

  # variant variable
  def is_variant([x,y]) when is_integer(y) do
    if is_atomvar(x) do
      true
    else
      false
    end
  end
  def is_variant(_) do false end

  # assert builtin
  def is_assert([:builtin,[:assert|_]]) do true end
  def is_assert(_) do false end

end

defmodule Read do
  def parse(buf) do
    {s1,buf1} = read(buf)
    {s2,buf2} = read(buf1)
    if s2 == :. do {s1,[]}
    else if s2 == :":-" do
      {s3,buf3} = parse1(buf2,[])
      {[:clause,s1,s3],buf3}
    else if s2 == :',' do
      {s3,buf3} = parse1(buf2,[s1])
      {s3,buf3}
    else
      throw "error parse1"
    end
    end
    end
  end

  def parse1(buf,res) do
    {s1,buf1} = read(buf)
    {s2,buf2} = read(buf1)
    cond do
      s2 == :. -> {res++[s1],buf2}
      s2 == :")" -> {res++[s1],buf2}
      s2 == :"," -> parse1(buf2,res++[s1])
      true -> throw "error parse2"
    end
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
  def read([")"|xs]) do
    {:")",xs}
  end
  def read(["["|xs]) do
    read_list(xs,[])
  end
  def read([x,"("|xs]) do
    name = String.to_atom(x)
    {tuple,rest} = read_tuple(xs,[])
    cond do
      is_builtin_atom(name) -> {[:builtin,[name|tuple]],rest}
      is_func_atom(name) -> {[name|tuple],rest}
      true -> {[:pred,[name|tuple]],rest}
    end
  end
  def read([x,"."|_]) do
    name = String.to_atom(x)
    if is_builtin_atom(name) do
      {[:builtin,[name]],["."]}
    else
      {[:pred,[name]],["."]}
    end
  end
  def read([x,","|xs]) do
    name = String.to_atom(x)
    cond do
      is_builtin_atom(name) -> {[:builtin,[name]],[","|xs]}
      is_atom_str(x) -> {[:pred,[name]],[","|xs]}
      true -> {name,[","|xs]}
    end
  end
  def read([x|xs]) do
    cond do
      is_integer_str(x) -> {String.to_integer(x),xs}
      is_float_str(x) -> {String.to_float(x),xs}
      x == "nil" -> {nil,xs}
      true -> {String.to_atom(x),xs}
    end
  end

  # for read_list (read simply)
  def read1(x) do
    cond do
      is_integer_str(x) -> String.to_integer(x)
      is_float_str(x) -> String.to_float(x)
      x == "nil" -> nil
      true -> String.to_atom(x)
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
    s = read1(x)
    read_list(xs,ls++[s])
  end
  defp read_list([x,"]"|xs],ls) do
    s = read1(x)
    {ls++[s],xs}
  end

  defp read_tuple([],ls) do
    buf = IO.gets("") |> comment_line |> drop_eol |> tokenize
    read_tuple(buf,ls)
  end
  defp read_tuple([")"|xs],ls) do
    {ls,xs}
  end
  defp read_tuple(["("|xs],ls) do
    {s,rest} = parse(xs)
    read_tuple(rest,ls++[s])
  end
  defp read_tuple([""|xs],ls) do
    read_tuple(xs,ls)
  end
  defp read_tuple([x,","|xs],ls) do
    {s,_} = read([x])
    read_tuple(xs,ls++[s])
  end
  defp read_tuple([x,")"|xs],ls) do
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

  # lowercase or number char or underbar
  def is_atom_str(x) do
    y = String.to_charlist(x)
    if hd(y) >= 97 && hd(y) <= 122 &&
       Enum.all?(y,fn(z) -> (z >= 97 && z <=122) || (z >= 48  && z <= 57) || z == 95 end) do
         true
    else
        false
    end
  end

  def is_builtin_atom(x) do
    Enum.member?([:assert,:halt,:write,:nl,:is,:listing,:ask,:=,:>,:<,:"=>",:"=<"],x)
  end

  def is_func_atom(x) do
    Enum.member?([:+,:-,:*,:/,:^],x)
  end

end

  #----------------prove-------------
defmodule Prove do
  def prove([:pred,x],y,env,def,n) do
    [name|_] = x
    def1 = def[name]
    prove_pred([:pred,x],def1,y,env,def,n)
  end
  def prove([:builtin,x],y,env,def,n) do
    {res,env1,def1} = prove_builtin(x,y,env,def,n)
    if res == false do
      {res,env1,def1}
    else
      prove_all(y,env1,def1,n+1)
    end
  end

  def prove_all([],env,def,_) do {true,env,def} end
  def prove_all([x|xs],env,def,n) do
    prove(x,xs,env,def,n)
  end

  def prove_pred(_,nil,_,env,def,_) do {false,env,def} end
  def prove_pred(_,[],_,env,def,_) do {false,env,def} end
  def prove_pred(x,[d|ds],y,env,def,n) do
    d1 = alpha_conv(d,n)
    #IO.inspect(x)
    #IO.inspect(d1)
    #IO.inspect(env)
    #IO.inspect(y)
    #IO.gets("??")
    if Prolog.is_pred(d1) do
      env1 = unify(x,d1,env)
      if env1 != false do
        {res,env2,def} = prove_all(y,env1,def,n+1)
        if res == true do
          {res,env2,def}
        else
          prove_pred(x,ds,y,env,def,n)
        end
      else
        prove_pred(x,ds,y,env,def,n)
      end
    else if Prolog.is_clause(d1) do
      env1 = unify(x,head(d1),env)
      if env1 != false do
        {res,env2,def} = prove_all(body(d1)++y,env1,def,n+1)
        if res == true do
          {res,env2,def}
        else
          prove_pred(x,ds,y,env,def,n)
        end
      else
        prove_pred(x,ds,y,env,def,n)
      end
    end
    end
  end


  def prove_builtin([:halt],_,_,_,_) do
    throw "goodbye"
  end
  def prove_builtin([:write,x],y,env,def,n) do
    x1 = deref(x,env)
    Print.print1(x1)
    prove_all(y,env,def,n+1)
  end
  def prove_builtin([:nl],y,env,def,n) do
    IO.puts("")
    prove_all(y,env,def,n+1)
  end
  def prove_builtin([:assert,x],y,env,def,n) do
    if Prolog.is_pred(x) do
      [_,[name|_]] = x
      def1 = find_def(def,name)
      def2 = [{name,def1++[x]}|def]
      prove_all(y,env,def2,n+1)
    else
      #clause
      [_,[_,[name|_]],_] = x
      def1 = find_def(def,name)
      def2 = [{name,def1++[x]}|def]
      prove_all(y,env,def2,n+1)
    end
  end
  def prove_builtin([:is,a,b],y,env,def,n) do
    b1 = eval(b,env)
    env1 = unify(a,b1,env)
    prove_all(y,env1,def,n+1)
  end
  def prove_builtin([:listing],y,env,def,n) do
    listing(def,[])
    prove_all(y,env,def,n+1)
  end
  def prove_builtin([:=,a,b],y,env,def,n) do
    env1 = unify(a,b,env)
    if env1 == false do
      {false,env,def}
    else
      prove_all(y,env1,def,n+1)
    end
  end
  def prove_builtin([:ask],y,env,def,n) do
    prove_all(y,env,def,n+1)
  end
  def prove_builtin([:ask|vars],y,env,def,n) do
    ask(vars,env)
    ans = IO.gets("")
    cond do
      ans == ".\n" -> prove_all(y,env,def,n+1)
      ans == ";\n" -> {false,env,def}
      true -> prove_all(y,env,def,n+1)
    end
  end
  def prove_builtin(x,_,_,_,_) do
    IO.inspect(x)
    throw "error builtin"
  end

  def eval(x,_) when is_number(x) do x end
  def eval(x,env) when is_atom(x) do
     deref(x,env)
  end
  def eval([:+,x,y],env) do
    eval(x,env) + eval(y,env)
  end
  def eval([:-,x,y],env) do
    eval(x,env) - eval(y,env)
  end
  def eval([:*,x,y],env) do
    eval(x,env) * eval(y,env)
  end
  def eval([:/,x,y],env) do
    eval(x,env) / eval(y,env)
  end
  def eval(x,env) do
    deref(x,env)
  end

  def ask([],_) do true end
  def ask([x|xs],env) do
    IO.write(x)
    IO.write(" = ")
    Print.print1(deref(x,env))
    ask(xs,env)
  end

  def listing([],_) do true end
  def listing([{key,body}|rest],check) do
    if Enum.member?(check,key) do
      listing(rest,check)
    else
      listing1(body)
      listing(rest,[key|check])
    end
  end

  def listing1([]) do true end
  def listing1([x|xs]) do
    Print.print(x)
    listing1(xs)
  end


  def find_def(ls,name) do
    def = ls[name]
    if def == nil do
      []
    else
      def
    end
  end


  #dereference
  def deref(x,env) do
    x1 = deref1(x,env,env)
    if x1 == false do
      x
    else
      x1
    end
  end

  def deref1(_,[],_) do false end
  def deref1(x,[[x,v]|_],env) do
    if !Prolog.is_var(v) do
      v
    else
      deref1(v,env,env)
    end
  end
  def deref1(x,[_|es],env) do
    deref1(x,es,env)
  end

  #clause head
  def head([:clause,h,_]) do h end
  #clause body
  def body([:clause,_,b]) do b end

  #alpha convert :X -> [:X,n]
  def alpha_conv([],_) do [] end
  def alpha_conv([x|y],n) when is_atom(x) do
    if Prolog.is_atomvar(x) do
      [[x,n]|alpha_conv(y,n)]
    else
      [x|alpha_conv(y,n)]
    end
  end
  def alpha_conv([x|y],n) when is_number(x) do
    [x|alpha_conv(y,n)]
  end
  def alpha_conv([x|y],n) when is_list(x) do
    [alpha_conv(x,n)|alpha_conv(y,n)]
  end

  def unify([],[],env) do env end
  def unify([x|xs],[y|ys],env) do
    x1 = deref(x,env)
    y1 = deref(y,env)
    cond do
      Prolog.is_var(x1) && !Prolog.is_var(y1) -> unify(xs,ys,[[x1,y1]|env])
      !Prolog.is_var(x1) && Prolog.is_var(y1) -> unify(xs,ys,[[y1,x1]|env])
      Prolog.is_var(x1) && Prolog.is_var(y1) -> unify(xs,ys,[[x1,y1]|env])
      is_list(x1) && is_list(y1) -> unify1(x1,y1,xs,ys,env)
      x1 == y1 -> unify(xs,ys,env)
      true -> false
    end
  end
  # atom or number
  def unify(x,y,env) do
    unify([x],[y],env)
  end

  def unify1(x,y,xs,ys,env) do
    env1 = unify(x,y,env)
    if env1 != false do
      unify(xs,ys,env1)
    else
      false
    end
  end

end


#----------------print------------
defmodule Print do
  def print(x) do
    print1(x)
    IO.puts("")
  end

  def print1(x) when is_number(x) do
    IO.write(x)
  end
  def print1(x) when is_atom(x) do
    if x != nil do
      IO.write(x)
    else
      IO.write("nil")
    end
  end
  def print1(x) when is_list(x) do
    cond do
      Prolog.is_pred(x) -> print_pred(x)
      Prolog.is_builtin(x) -> print_pred(x)
      Prolog.is_clause(x) -> print_clause(x)
      true -> print_list(x)
    end
  end

  def print_pred([_,[name|args]]) do
    IO.write(name)
    print_tuple(args)
  end

  def print_clause([_,head,body]) do
    print_pred(head)
    IO.write(" :- ")
    print_body(body)
  end

  def print_body([]) do true end
  def print_body([x|xs]) do
    print_pred(x)
    IO.write(",")
    print_body(xs)
  end


  defp print_list([]) do
    IO.puts("[]")
  end
  defp print_list([x|xs]) do
    IO.write("[")
    print1(x)
    if xs != [] do
      IO.write(",")
    end
    print_list1(xs)
  end

  defp print_list1(x) when is_atom(x)do
    IO.write("|")
    print1(x)
    IO.write("]")
  end
  defp print_list1(x) when is_number(x)do
    IO.write("|")
    print1(x)
    IO.write("]")
  end
  defp print_list1([]) do
    IO.write("]")
  end
  defp print_list1([x|xs]) do
    print1(x)
    if xs != [] do
      IO.write(",")
    end
    print_list1(xs)
  end

  defp print_tuple([]) do
    true
  end
  defp print_tuple([x|xs]) do
    IO.write("(")
    print1(x)
    if xs != [] do
      IO.write(",")
    end
    print_tuple1(xs)
  end
  defp print_tuple1([]) do
    IO.write(")")
  end
  defp print_tuple1([x|xs]) do
    print1(x)
    if xs != [] do
      IO.write(",")
    end
    print_tuple1(xs)
  end


end
