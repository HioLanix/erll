-module(client_app).
-behaviour(application).
%% /mnt/c/Users/Hio/Desktop/newclient/    client_app:auth_user(testuser,testpass).  client_app:message_to(testuser,meow). client_app:send(meow).client_app:auth_user(poll,qqwq).
-export([start/2,
        stop/1,
        connect/2,
        register_user/2,
        auth_user/2,
        send/1,
        message_to/2,
        add_friend/1]).

start(_Type, _Args) ->
    io:format("Starting Hio's client application...~n"),
    application:ensure_all_started(gun),
    application:ensure_all_started(cowlib),
    client_manager:start(),
    client_ws_manager:start_link(), 
    case client_manager:check_autologin() of 
        [{settings, 1, Username, Password, true}] ->
            client_app:auth_user(Username, Password);
        _ ->
            io:format("Authenticate yourself~n")
    end,
    client_sup:start_link().
   %% sip:start().
   
message_to(Name, Message) ->
    % Convert Name and Message to binaries
    NameBinary = 
        if
            is_binary(Name) -> Name;
            is_list(Name) -> list_to_binary(Name);
            is_atom(Name) -> atom_to_binary(Name, utf8);
            true -> erlang:error({badarg, Name})
        end,
    MessageBinary = 
        if
            is_binary(Message) -> Message;
            is_list(Message) -> list_to_binary(Message);
            is_atom(Message) -> atom_to_binary(Message, utf8);
            true -> erlang:error({badarg, Message})
        end,
    % Construct the message list with binaries
    send([<<"send_to ">>, NameBinary,<<" message:">>, MessageBinary]).

add_friend(Name) ->
 atom_to_binary(Name, utf8),
 send([<<"add_friend ">>, atom_to_binary(Name, utf8)]).

send(Message0) ->
    Message0Binary =
        if
            is_binary(Message0) -> Message0;
            is_list(Message0) -> list_to_binary(Message0);
            is_atom(Message0) -> atom_to_binary(Message0, utf8);
            true -> erlang:error({badarg, Message0})
        end,
    case unicode:characters_to_binary(Message0Binary, utf8, utf8) of
        {error, _Invalid, _Rest} ->
            io:format("Error: Invalid UTF-8 data in message~n"),
            {error, invalid_utf8};
        {incomplete, _Invalid, _Rest} ->
            io:format("Error: Incomplete UTF-8 data in message~n"),
            {error, incomplete_utf8};
        ValidMessage0 ->
            Message1 = <<ValidMessage0/binary>>,
            case client_ws_manager:get_connection() of
                #{ws_ref := Wsref, conn_pid := ConnPid} ->
                    gun:ws_send(ConnPid, Wsref, {text, Message1}),
                    ok;
                _ ->
                    io:format("Error: WebSocket connection not found~n"),
                    {error, ws_connection_not_found}
            end
    end.

register_user(Username, Password) ->
    inets:start(),

    % Define the URL and headers
    URL = "http://localhost:8080/register",
    Headers = [{"Content-Type", "application/json"}],

    % Create the JSON body
    Body = jsx:encode([{username, Username}, {password, Password}]),

    % Send the POST request
    case httpc:request(post, {URL, Headers, "application/json", Body}, [], []) of
        {ok, {{_, StatusCode, _}, _, ResponseBody}} ->
            io:format("Registration Response (~p): ~s~n", [StatusCode, ResponseBody]);
        {error, Reason} ->
            io:format("Error: ~p~n", [Reason])
    end.

auth_user(Username, Password) ->
    inets:start(),
    URL = "http://localhost:8080/auth",
    Headers = [{"Content-Type", "application/json"}],
    Body = jsx:encode([{username, Username}, {password, Password}]),
    io:format("DEBUG: Sending request to ~p with body: ~p~n", [URL, Body]),   
    case httpc:request(post, {URL, Headers, "application/json", Body}, [], []) of
        {ok, {{_, StatusCode, _}, _, ResponseBody}} ->
            io:format("auth Response (~p): ~s~n", [StatusCode, ResponseBody]),
            put(user_name, Username),
            put(pass_word, Password),
            connect(Username, ResponseBody);
        {error, Reason} ->
            io:format("Error: ~p~n", [Reason])
    end.

connect(Username, Token) ->
    {ok, ConnPid} = gun:open("localhost", 8080),
    Wsref = gun:ws_upgrade(ConnPid, "/ws?token=" ++ Token),
    io:format("DEBUG: WebSocket upgrade result: ~p~n", [Wsref]),   
    client_ws_manager:set_connection(Wsref, ConnPid),
    io:format("Successfully authorized~n"),
    spawn(fun() -> keepalive(Wsref, ConnPid) end),
    spawn(fun() -> loop(ConnPid) end).

    

loop(ConnPid) ->
    io:format("DEBUG: loop/1 is running for ConnPid: ~p~n", [ConnPid]),   
    receive
        {gun_ws, ConnPid, {text, Message}} ->
            io:format("DEBUG: Received WebSocket message: ~p~n", [Message]),   
            loop(ConnPid);
        {gun_ws, ConnPid, close} ->
            io:format("WebSocket connection closed~n"),
            gun:close(ConnPid);
        {gun_ws, ConnPid, {error, Reason}} ->
            io:format("WebSocket error: ~p~n", [Reason]),
            gun:close(ConnPid)
    end.
keepalive(Wsref, ConnPid) ->
    timer:sleep(3000),
    %%io:format("Wsref: ~p~n", [Wsref]),
    %%io:format("ConnPid: ~p~n", [ConnPid]),
    gun:ws_send(ConnPid, Wsref, {text,atom_to_binary(keepalive, utf8)}),
    timer:sleep(15000),
    keepalive(Wsref, ConnPid).
stop(_State) ->
    ok.
%% client_app:auth_user(testuser,testpass).
