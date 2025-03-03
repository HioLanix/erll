-module(client_manager).
-export([start/0, register_client/2, send_message/2,allow_messages/1]).
%% /mnt/c/Users/Hio/Desktop/cringe
-record(clients, {username, pid}).
-record(allowance, {wsref,allowed}).
start() ->
    mnesia:delete_schema([node()]),
    mnesia:create_schema([node()]),
    mnesia:start(),
    mnesia:create_table(clients,   [{attributes, record_info(fields, clients)}, {[node()]}]),
    %%restore(),                                                                %% {disc_copies, [node()]}]),
    mnesia:create_table(allowance,   [{attributes, record_info(fields, allowance)}, {[node()]}]).
    %%spawn(fun() -> 
   %% backup_loop(60) end).
allow_messages(Wsref)->
Data = #allowance{wsref=Wsref,allowed="Allowed"},
    io:format(" ~p ~n", [Data]),
    F = fun() -> 
		mnesia:write(Data)
	end,    
    mnesia:transaction(F).

backup_loop(Interval) ->
    mnesia:backup("mnesia_backup.bup"),
    timer:sleep(Interval * 1000),
    backup_loop(Interval).
restore() ->
    mnesia:restore("mnesia_backup.bup", []).

register_client(Client, Pid) ->
     User = #clients{username=Client, pid=Pid},
    io:format(" ~p ~n", [User]),
    F = fun() -> 
		mnesia:write(User)
	end,    
    mnesia:transaction(F).

send_message(Client, Message) ->
    case mnesia:dirty_read(clients,Client) of
        [{Client, Pid}] ->
            Pid ! {sip_message, Message};
        [] ->
            io:format("Client ~p not found~n", [Client])
    end.
