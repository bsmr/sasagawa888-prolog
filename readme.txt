Pure Prolog intepreter in Elixir

Now this is incomplete.

invoke:
  mix prolog

quit: halt.

builtin:
  write/1
  nl/0
  assert/1
  is/2
  =/2
  </2
  >/2
  =>/2
  =</2
  halt/0
  listing/0

Example:
mix prolog
Compiling 1 file (.ex)
Prolog in Elixir
?- assert(fact(0,1)).
true
?- assert((fact(N,A) :- N1 is N-1,fact(N1,A1),A is N*A1)).
true
?- fact(10,X).
X = 3628800
true
?-

?- assert(likes(kim,robin)).
true
?- assert(likes(sandy,lee)).
true
?- assert(likes(sandy,kim)).
true
?- assert(likes(robin,cats)).
true
?- assert((likes(sandy,X) :- likes(X,cats))).
true
?- assert((likes(kim,X) :- likes(X,lee),likes(X,kim))).
true
?- assert(likes(X,X)).
true
?- listing.
likes(kim,robin)
likes(sandy,lee)
likes(sandy,kim)
likes(robin,cats)
likes(sandy,X) :- likes(X,cats)
likes(kim,X) :- likes(X,lee)likes(X,kim)
likes(X,X)
true
?- likes(sandy,Who).
Who = lee;
Who = kim;
Who = robin;
Who = sandy;
Who = cats;
Who = sandy;
false
?-halt.
goodbye
