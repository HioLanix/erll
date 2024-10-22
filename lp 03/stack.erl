-module(cus_queue).
-export([new_queue/0, enqueue, dequeue/1]).

-type stack() :: empty | [{stack, integer{}}].
-type data() :: stack() | {error,empty} | some_error.
-spec new_stack() ->
    [{stack, Elem}];
push(Elem) 
