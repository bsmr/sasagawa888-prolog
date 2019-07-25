Pure Prolog intepreter in Elixir

Now this is incomplete.

Example:
mix prolog
Compiling 1 file (.ex)
Prolog in Elixir
?- assert(fact(0,1)).
true
?- assert((fact(N,A) :- is(N1,-(N,1)),fact(N1,A1),is(A,*(N,A1)))).
true
?- fact(10,X).
X = 3628800
true
?-

$ mix prolog
Compiling 1 file (.ex)
Prolog in Elixir
?- assert(fact(0,1)).
true
?- assert((fact(N,A) :- is(N1,-(N,1)),fact(N1,A1),is(A,*(N,A1)))).
true
?- fact(3,X).
true
?- fact(3,X),write(X).
6true
?- fact(10,X),write(X).
3628800true
?- halt.
goodbye
