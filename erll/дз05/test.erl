-module(test).

-export([run/0]).

run() ->
    case h_test:run_test() of
        ok -> {passed};
        error -> {error}
end.