-module(dz5).
  %%         C:/Users/Hio/Desktop/erll/дз 5/

-export([greaterfilter/2,
          showatom/1]).

-spec greaterfilter(list(),number())-> list().
greaterfilter(List, N) -> [X || X <- List, X > N].

-spec showatom(list())-> list().
showatom(List) -> [X || X <- List, is_atom(X)].

  %%         C:/Users/Hio/Desktop/erll/дз 5/