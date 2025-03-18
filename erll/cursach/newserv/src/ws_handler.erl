-module(ws_handler).
-behaviour(cowboy_websocket).

-export([init/2]).
-export([websocket_init/1]).
-export([websocket_handle/2]).
-export([websocket_info/2]).
-export([terminate/3]).

-record(state, {
    username :: binary() | undefined % Username of the connected client
}).

% Initialize the WebSocket connection
init(Req0, State) ->
    % Parse query string from the request
    Qs = cowboy_req:parse_qs(Req0),
    TokenParam = proplists:get_value(<<"token">>, Qs),

    case TokenParam of
        undefined ->
            % If no token is provided, reject the connection
            Req1 = cowboy_req:reply(401, #{}, <<"Missing or invalid token">>, Req0),
            {shutdown, Req1, State};
        TokenValue ->
            % Verify the token
            case verify_token(binary_to_list(TokenValue)) of
                {ok, Username} ->
                    % If the token is valid, proceed with the WebSocket connection
                    io:format("WebSocket connected for user: ~p~n", [Username]),
                    {cowboy_websocket, Req0, #state{username = Username}};
                {error, Reason} ->
                    % If the token is invalid, reject the connection
                    Msg = io_lib:format("Invalid token: ~p", [Reason]),
                    Req1 = cowboy_req:reply(402, #{}, list_to_binary(Msg), Req0),
                    {shutdown, Req1, State}
            end
    end.

% Handle WebSocket initialization
websocket_init(State = #state{username = Username}) ->
    % Register the client with the broadcast server
    case catch gen_server:call(broadcast_server, {add_client, Username, self()}) of
        {'EXIT', {noproc, _}} ->
            io:format("Broadcast server not running, skipping client registration~n"),
            {ok, State};
        ok ->
            io:format("Client ~p registered with broadcast server~n", [Username]),
            {ok, State}
    end.

% Handle incoming WebSocket messages
websocket_handle({text, Msg}, State = #state{username = SenderUsername}) ->
    % Ensure the message is valid UTF-8
    case unicode:characters_to_binary(Msg, utf8, utf8) of
        {error, _Invalid, _Rest} ->
            % Invalid UTF-8 data: log the error and close the connection
            io:format("Invalid UTF-8 message received: ~p~n", [Msg]),
            {stop, State};
        {incomplete, _Invalid, _Rest} ->
            % Incomplete UTF-8 data: log the error and close the connection
            io:format("Incomplete UTF-8 message received: ~p~n", [Msg]),
            {stop, State};
        ValidMsg ->
           % io:format("Valid message: ~p~n", [ValidMsg]),
            case ValidMsg of
                <<"keepalive">> ->
                    % Respond to keepalive messages
                    {reply, {text, <<"keepalive received">>}, State};
                <<"send_to ", Rest/binary>> ->
                    % Parse the "send_to" message
                    case binary:split(Rest, <<" message:">>) of
                        [RecipientUsernameBinary, MessageBinary] ->
                            % Forward the message to the recipient
                            gen_server:cast(broadcast_server, {send_to, RecipientUsernameBinary, SenderUsername, MessageBinary}),
                            {ok, State};
                        _ ->
                            % Invalid "send_to" format: notify the sender
                            io:format("Invalid send_to format: ~p~n", [Rest]),
                            {reply, {text, <<"Invalid send_to format">>}, State}
                    end;
                _ ->
                    % Broadcast the message to all clients via the broadcast server
                    BroadcastMessage = iolist_to_binary([SenderUsername, <<": ">>, ValidMsg]),
                    gen_server:cast(broadcast_server, {broadcast, BroadcastMessage}),
                    {ok, State}
            end
    end.

% Handle messages from the broadcast server
websocket_info({send_message, Message}, State) ->
    io:format("Sending message to client: ~p~n", [Message]),
    {reply, {text, Message}, State};

% Handle other types of info
websocket_info(_Info, State) ->
    {ok, State}.

% Handle WebSocket termination
terminate(_Reason, _Req, #state{username = Username}) ->
    io:format("WebSocket terminated for user: ~p~n", [Username]),
    io:format("WebSocket terminated by reason: ~p~n", [_Reason]),
    % Unregister the client from the broadcast server
    gen_server:cast(broadcast_server, {remove_client, Username}),
    ok;
terminate(_Reason, _Req, _State) ->
    io:format("Client disconnected~n"),
    ok.

% Function to verify jwt token
verify_token(Token) ->
    try
        % Decode the base64 token
        Decode0 = list_to_binary(Token),
        Userdata = jwt:find_issuer_data(Decode0, <<"secret">>),
        % Split the decoded value into username and password
        [Username, Password] = binary:split(Userdata, <<":">>),
        % Authenticate the user
        case user_storage:authenticate(binary_to_list(Username), binary_to_list(Password)) of
            true ->
                {ok, Username};
            false ->
                {error, invalid_credentials}
        end
    catch
        _:_ ->
            {error, invalid_token}
    end.