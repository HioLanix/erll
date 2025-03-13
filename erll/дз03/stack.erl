%%  cd('C:/Users/Hio/Desktop/erll/lp 03').
-module(stack).


-export([
    new/0,
    insert/2,
    pop/1,
    lookup/1
]).

-spec new() -> [].
new() ->
    [].

-spec insert(term(), list()) -> list().
insert(Val, Stack) ->
    [Val | Stack].

-spec pop(list()) -> {term(), list()}.
pop([Val | Tail]) ->
    {Val, Tail}.

-spec lookup(list()) -> list().
lookup(Stack) ->
    Stack.