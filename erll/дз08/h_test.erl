-module(h_test).
-export([run_test/0]).


run_test() ->
   h8:start(),
   h8:create_table(),
   h8:insert_data(),
   h8:retrieve_data(),
   h8:delete_table(),
   ok.