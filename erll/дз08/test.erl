-module(test).

-export([run/0]).

run() ->
Status =case i:start() of 
        true ->
    case h_test:run_test() of
        ok -> {passed};
        error -> {failed}
    end;
    _->{error}
end,
io:format("test: ~p~n", [Status]).