-module(client_manager). % client_manager:start().          client_manager:check_autologin().   client_manager:set_autologin(true).
-export([start/0, set_autologin/1, check_autologin/0]). 

-record(settings, {id,username, password, keeplogined}).

start() ->
    mnesia:delete_schema([node()]),
    mnesia:create_schema([node()]),
    mnesia:start(),
    mnesia:create_table(settings, [{attributes, record_info(fields, settings)}, {disc_copies, [node()]}]),
    restore().

restore() ->
    try
        mnesia:restore("mnesia_backup.bup", [])
    catch
        exit:{aborted, {no_exists, Table}} ->
            io:format("Warning: Table ~p does not exist in the schema. Skipping restore.~n", [Table]),
            ok
    end.

set_autologin(Setting) ->
    case Setting of
        true ->
            Data = #settings{id=1,username = get(user_name), password = get(pass_word), keeplogined = Setting},
            mnesia:dirty_write(Data),
            mnesia:backup("mnesia_backup.bup");
        false ->
            Data = #settings{id=1,username = get(user_name), password = get(pass_word), keeplogined = Setting},
            mnesia:dirty_write(Data),
            mnesia:backup("mnesia_backup.bup");
        _ ->
            io:format("Wrong setting: ~p~n", [Setting])
    end.

check_autologin() ->
    mnesia:dirty_read(settings, 1).

read_settings(Key) ->
    F = fun() ->
        mnesia:read(settings, Key)
    end,
    mnesia:transaction(F).