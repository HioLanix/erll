-module(user_storage). 
-export([remember_socket/2,find_socket/1,add_user/2, authenticate/2, find_user/1, init/0]).
-record(users, {login, password}).
-record(sockets, {username, socket}).
%-define(USER_DB, user_db).
 % c:/Users/Hio/Desktop/registration_ws/src/user_storage.erl   /mnt/c/Users/Hio/Desktop/jwtserv  user_storage:find_socket(testuser).

remember_socket(Username, SocketPid) ->
    Data = #sockets{username = Username, socket = SocketPid},
    io:format("Storing socket for user ~p: ~p~n", [Username, SocketPid]),  
    F = fun() -> 
        mnesia:write(Data)
    end,
    mnesia:transaction(F).

find_socket(Username) ->
    case mnesia:dirty_read(sockets, Username) of
        [{sockets, Username, SocketPid}] -> {ok, SocketPid};
        [] -> {error, not_found}
    end.

add_user(Username, Password) ->
   % UniqueId = erlang:unique_integer([monotonic, positive]),        
   User = #users{login=Username, password=Password},
    io:format(" ~p ~n", [User]),
    F = fun() -> 
		mnesia:write(User)
	end,    
    mnesia:transaction(F).
 

authenticate(Username, Password) ->
   case mnesia:dirty_read(users,Username) of
        [{users,Username,Password}] -> true;
        _ -> false
    end.
  
find_user(Username) ->
    case  mnesia:dirty_read(users,Username) of
        [{Username,_Password}] -> {ok, Username};
        _ -> not_found
    end.

init() ->
    mnesia:delete_schema([node()]),
    mnesia:create_schema([node()]),
    mnesia:start(),
    mnesia:create_table(users,   [{attributes, record_info(fields, users)}, {disc_copies, [node()]}]),
    mnesia:create_table(sockets, [{attributes, record_info(fields, sockets)}]),
    restore(),
    spawn(fun() -> 
    backup_loop(60) end).

backup_loop(Interval) ->
    mnesia:backup("mnesia_backup.bup"),
    timer:sleep(Interval * 1000),
    backup_loop(Interval).

restore() ->
    mnesia:restore("mnesia_backup.bup", []).

