-module(dz5).
  %%         C:/Users/Hio/Desktop/erll/дз 5/

-export([greaterfilter/2,
          showatom/1]).


greaterfilter(List, N) -> [X || X <- List, X > N].


showatom(List) -> [X || X <- List, is_atom(X)].

  %%         C:/Users/Hio/Desktop/erll/дз 5/