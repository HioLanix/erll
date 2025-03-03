-module(client_app).
-behaviour(application).
%% /mnt/c/Users/Hio/Desktop/cringe/    client_app:auth_user(testuser,testpass).
-export([start/2,stop/1,connect/2,register_user/2,auth_user/2]).
start(_Type, _Args) ->
    io:format("Starting Hio's client application...~n"),
    application:ensure_all_started(gun),
    application:ensure_all_started(cowlib),
     client_sup:start_link().
   %% sip:start().
   


register_user(Username, Password) ->
    % Start the inets application (if not already started)
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
    % Start the inets application (if not already started)
    inets:start(),

    % Define the URL and headers
    URL = "http://localhost:8080/auth",
    Headers = [{"Content-Type", "application/json"}],

    % Create the JSON body
    Body = jsx:encode([{username, Username}, {password, Password}]),

    % Send the POST request
    case httpc:request(post, {URL, Headers, "application/json", Body}, [], []) of
        {ok, {{_, StatusCode, _}, _, ResponseBody}} ->
            io:format("auth Response (~p): ~s~n", [StatusCode, ResponseBody]),
         connect(Username,ResponseBody);
        {error, Reason} ->
            io:format("Error: ~p~n", [Reason])
    end.
connect(Username,Token) ->
    
    % Connect to the WebSocket server
    {ok, ConnPid} = gun:open("localhost", 8080),
    
   %% client_manager:register_client(Username,ConnPid),
    % Perform the WebSocket handshake
    Wsref=gun:ws_upgrade(ConnPid, "/ws?token=" ++ Token),
   %% client_manager:allow_messages(Wsref),
    put(ws_ref, Wsref),
    % Handle WebSocket messages
spawn(fun() -> 
    loop(ConnPid) end).
    

loop(ConnPid) ->
    receive
        {gun_ws, ConnPid, {text, Message}} ->
            io:format("Received message: ~s~n", [Message]),
           
            loop(ConnPid);
        {gun_ws, ConnPid, close} ->
            io:format("WebSocket connection closed~n"),
            gun:close(ConnPid);
        {gun_ws, ConnPid, {error, Reason}} ->
            io:format("WebSocket error: ~p~n", [Reason]),
            gun:close(ConnPid)
    end.

stop(_State) ->
    ok.
