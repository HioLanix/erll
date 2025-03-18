-module(registration_ws_app).
-behaviour(application).
% /mnt/c/Users/Hio/Desktop/jwtserv/
-export([start/2]).
-export([stop/1]).

start(_Type, _Args) ->
    io:format("Starting HIO'S Server...~n"),
    application:ensure_all_started(cowboy),
    application:ensure_all_started(sasl),
    user_storage:init(),
    %sip:start(),
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/register", registration_handler, []},
            {"/auth", auth_handler, []},
            {"/ws", ws_handler, []}
        ]}
    ]),
    io:format("Dispatch table created. ...~n"),
    {ok, _} = cowboy:start_clear(http, [{port, 8080}], #{
        env => #{dispatch => Dispatch}
    }),
    io:format("server started on port 8080.~n"),
    {ok, self()},
    registration_ws_sup:start_link().

stop(_State) ->
    ok.
