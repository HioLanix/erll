-module(h_test).
-include_lib("eunit/include/eunit.hrl").


run_test() ->
greaterfilter_test(),
showatom_test(),
ok.

greaterfilter_test() ->
    ?assertEqual([4, 5], dz5:greaterfilter([1, 2, 3, 4, 5], 3)),
    ?assertEqual([], dz5:greaterfilter([1, 2, 3], 5)),
    ?assertEqual([11, 17], dz5:greaterfilter([11, 0, 17, -10], 0)).
showatom_test() ->
    ?assertEqual([a, b], dz5:showatom([1, a, 2, b, 3])),
    ?assertEqual([], dz5:showatom([1, 2, 3])),
    ?assertEqual([hello, world], dz5:showatom([hello, 42, world])).