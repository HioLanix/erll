-module(ws_client).
-behaviour(gen_server).
% /mnt/c/Users/Hio/Desktop/genservclient/   ws_client:auth_user(testuser, testpass).  ws_client:auth_user(poll, qqwq).  ws_client:message_to(poll,hi).  ws_client:message_to(hio,hey hio).
% API 
-export([start_link/0, connect/1, send/1, message_to/2, add_friend/1, get_token/2,auth_user/2]).

% gen_server callbacks
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {
    conn_pid :: pid() | undefined, % Gun connection PID
    ws_ref :: reference() | undefined, % WebSocket reference
    username :: binary() | undefined, % Authenticated username
    token :: binary() | undefined % Authentication token
}).

% Start the client
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

% Connect to the WebSocket server with a token
connect(Token) ->
    gen_server:cast(?MODULE, {connect, Token}).

% Send a message over the WebSocket connection
send(Message) ->
    gen_server:cast(?MODULE, {send, Message}).

% Send a message to a specific user
message_to(Name, Message) ->
    gen_server:cast(?MODULE, {message_to, Name, Message}).

% Add a friend
add_friend(Name) ->
    gen_server:cast(?MODULE, {add_friend, Name}).

% Initialize the client
init([]) ->
    {ok, #state{}}.

% Handle the connect request
handle_cast({connect, Token}, State) ->
    {ok, ConnPid} = gun:open("localhost", 8080),
    Wsref = gun:ws_upgrade(ConnPid, "/ws?token=" ++ Token),
    io:format("DEBUG: WebSocket upgrade result: ~p~n", [Wsref]),
    spawn(fun() -> keepalive(Wsref,ConnPid) end),
    {noreply, State#state{conn_pid = ConnPid, ws_ref = Wsref, token = Token}};

% Handle sending a message
handle_cast({send, Message}, State = #state{conn_pid = ConnPid, ws_ref = Wsref}) ->
    case unicode:characters_to_binary(Message, utf8, utf8) of
        {error, _Invalid, _Rest} ->
            io:format("Error: Invalid UTF-8 data in message~n"),
            {noreply, State};
        {incomplete, _Invalid, _Rest} ->
            io:format("Error: Incomplete UTF-8 data in message~n"),
            {noreply, State};
        ValidMessage ->
            gun:ws_send(ConnPid, Wsref, {text, ValidMessage}),
            {noreply, State}
    end;

% Handle sending a message to a specific user
handle_cast({message_to, Name, Message}, State) ->
    NameBinary = ensure_binary(Name),
    MessageBinary = ensure_binary(Message),
    case {NameBinary, MessageBinary} of
        {{error, badarg}, _} ->
            {noreply, State};
        {_, {error, badarg}} ->
            {noreply, State};
        {NameBinary, MessageBinary} ->
            FullMessage = <<"send_to ", NameBinary/binary, " message:", MessageBinary/binary>>,
            gen_server:cast(?MODULE, {send, FullMessage}),
            {noreply, State}
    end;

% Handle adding a friend
handle_cast({add_friend, Name}, State) ->
    NameBinary = ensure_binary(Name),
    case NameBinary of
        {error, _Reason} ->
            {noreply, State};
        _ ->
            FullMessage = <<"add_friend ", NameBinary/binary>>,
            gen_server:cast(?MODULE, {send, FullMessage}),
            {noreply, State}
    end;

% Handle other casts
handle_cast(_Msg, State) ->
    {noreply, State}.

% Handle getting a token from the server
get_token(Username, Password) ->
    gen_server:call(?MODULE, {get_token, Username, Password}).
auth_user(Username, Password) ->
    gen_server:call(?MODULE, {auth_user, Username, Password}).

% Handle getting a token from the server
handle_call({get_token, Username, Password}, _From, State) ->
    inets:start(),
    URL = "http://localhost:8080/auth",
    Headers = [{"Content-Type", "application/json"}],
    % Ensure Username and Password are binaries
    UsernameBinary = ensure_binary(Username),
    PasswordBinary = ensure_binary(Password),
    % Construct the JSON body
    Body = jsx:encode([{username, UsernameBinary}, {password, PasswordBinary}]),
    io:format("DEBUG: Sending request to ~p with body: ~p~n", [URL, Body]),
    case httpc:request(post, {URL, Headers, "application/json", Body}, [], []) of
        {ok, {{_, StatusCode, _}, _, ResponseBody}} ->
            io:format("DEBUG: Received response with status code ~p: ~s~n", [StatusCode, ResponseBody]),
            case jsx:is_json(ResponseBody) of
                true ->
                    try jsx:decode(ResponseBody, [return_maps]) of
                        #{<<"token">> := Token} ->
                            {reply, {ok, Token}, State#state{username = UsernameBinary, token = Token}};
                        #{<<"error">> := Error} ->
                            io:format("Error: Authentication failed: ~p~n", [Error]),
                            {reply, {error, Error}, State};
                        _ ->
                            io:format("Error: Invalid response format~n"),
                            {reply, {error, invalid_response}, State}
                    catch
                        _:_ ->
                            io:format("Error: Failed to decode JSON response~n"),
                            {reply, {error, invalid_json}, State}
                    end;
                false ->
                    io:format("Error: Response is not valid JSON: ~s~n", [ResponseBody]),
                    {reply, {error, invalid_json}, State}
            end;
        {error, Reason} ->
            io:format("Error: ~p~n", [Reason]),
            {reply, {error, Reason}, State}
    end;

handle_call({auth_user, Username, Password}, _From, State) ->
    inets:start(),
    URL = "http://localhost:8080/auth",
    Headers = [{"Content-Type", "application/json"}],
    % Ensure Username and Password are binaries
    UsernameBinary = ensure_binary(Username),
    PasswordBinary = ensure_binary(Password),
    % Construct the JSON body
    Body = jsx:encode([{username, UsernameBinary}, {password, PasswordBinary}]),
    io:format("DEBUG: Sending request to ~p with body: ~p~n", [URL, Body]),
    case httpc:request(post, {URL, Headers, "application/json", Body}, [], []) of
        {ok, {{_, StatusCode, _}, _, ResponseBody}} ->
            io:format("DEBUG: Received response with status code ~p: ~s~n", [StatusCode, ResponseBody]),
                            % Connect to the WebSocket server using the token
                            gen_server:cast(?MODULE, {connect, ResponseBody}),
                            {reply, {ok, connecting}, State#state{username = UsernameBinary, token = ResponseBody}};
        {error, Reason} ->
            io:format("Error: ~p~n", [Reason]),
            {reply, {error, Reason}, State}
    end;

% Handle other calls
handle_call(_Request, _From, State) ->
    {reply, ok, State}.

% Handle Gun connection events
handle_info({gun_up,_, http}, State) ->
   % io:format("Connecting to server~n"),
    {noreply, State};
handle_info({gun_upgrade, ConnPid, Ref, [<<"websocket">>], Headers}, State) ->
    %io:format("WebSocket upgrade confirmed with headers: ~p~n", [Headers]),
    {noreply, State#state{conn_pid = ConnPid, ws_ref = Ref}};

handle_info({gun_down, _,ws, closed, _}, State) ->
    io:format("Disconnected from server: ~n"),
    {noreply, State#state{conn_pid = undefined, ws_ref = undefined}};

handle_info({gun_ws_upgrade, ConnPid, Wsref, ok, _Headers}, State) ->
    io:format("WebSocket upgrade successful~n"),
    {noreply, State#state{conn_pid = ConnPid, ws_ref = Wsref}};

handle_info({gun_ws, _,_, close}, State) ->
    io:format("WebSocket connection closed~n"),
    {noreply, State#state{conn_pid = undefined, ws_ref = undefined}};

handle_info({gun_ws, _,_, {error, Reason}}, State) ->
    io:format("WebSocket error: ~p~n", [Reason]),
    {noreply, State};

handle_info({gun_ws, _, _, {text, <<"Server time: ", Time/binary>>}}, State) ->
    %io:format("Received server time: ~p~n", [Time]),
            {noreply, State};

handle_info({gun_ws, _,_, {text, <<"keepalive recieced">>}}, State) ->
    %io:format("Received keepalive message: ~n"),
    {noreply, State};

handle_info({gun_ws, _,_, {text, Message}}, State) ->
    io:format("Received WebSocket message: ~p~n", [Message]),
    {noreply, State};

% Handle other messages
handle_info(Info, State) ->
    io:format("Unexpected message: ~p~n", [Info]),
    {noreply, State}.

% Terminate the client
terminate(_Reason, _State) ->
    ok.

% Handle code changes
code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

% Helper function to ensure a value is binary
ensure_binary(Value) when is_binary(Value) -> Value;
ensure_binary(Value) when is_list(Value) -> list_to_binary(Value);
ensure_binary(Value) when is_atom(Value) -> atom_to_binary(Value, utf8);
ensure_binary(_) -> {error, badarg}.

% Keepalive loop
keepalive(Wsref, ConnPid) ->
    timer:sleep(3000),
    gun:ws_send(ConnPid, Wsref, {text, <<"keepalive">>}),
    timer:sleep(15000),
    keepalive(Wsref, ConnPid).
