-module(client_app).
-behaviour(application).
% /mnt/c/Users/Hio/Desktop/genservclient/    client_app:auth_user(testuser,testpass).  client_app:message_to(poll,meow). client_app:send(meow).client_app:auth_user(poll,qqwq).
-export([start/2,stop/1]).
% start client
start(_Type, _Args) ->
    io:format("Starting Hio's client application...~n"),
    application:ensure_all_started(gun),
    application:ensure_all_started(cowlib),
    client_manager:start(),
    ws_client:start_link(), 
    case client_manager:check_autologin() of 
        [{settings, 1, Username, Password, true}] ->
            ws_client:auth_user(Username,Password);
        _ ->
            io:format("Authenticate yourself~n")
    end,
    client_sup:start_link().
   % sip:start().
   
stop(_State) ->
    ok.
   