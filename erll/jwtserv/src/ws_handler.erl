-module(ws_handler).
-behaviour(cowboy_websocket).

-export([init/2]).
-export([websocket_init/1]).
-export([websocket_handle/2]).
-export([websocket_info/2]).
-export([terminate/3]).

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
                  
                    {cowboy_websocket, Req0, #{username => Username}};
                {error, Reason} ->
                    % If the token is invalid, reject the connection
                    Msg = io_lib:format("Invalid token: ~p", [Reason]),
                    Req1 = cowboy_req:reply(402, #{}, list_to_binary(Msg), Req0),
                    {shutdown, Req1, State}
            end
    end.

websocket_init(State) ->
      user_storage:remember_socket( <<"testuser">>, self()),
    % Initialize the WebSocket connection
    {ok, State}.

websocket_handle({text, Msg}, State = #{username := SenderUsername}) ->
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
             io:format("validsmg: ~p~n", [Msg]),
            case ValidMsg of
                <<"keepalive">> ->
                    {ok, State};
                <<"send_to ", Rest/binary>> ->
                    % Parse the "send_to" message
                    io:format("Parsing send_to message: ~p~n", [Rest]),
                    case binary:split(Rest, <<" message:">>) of
                        [RecipientUsernameBinary, MessageBinary] ->
                            % Look up the recipient's WebSocket connection
                            io:format("Looking up socket for recipient: ~p~n", [RecipientUsernameBinary]),
                            case user_storage:find_socket(RecipientUsernameBinary) of
                                {ok, RecipientPid} ->
                                    % Forward the message to the recipient
                                    ForwardMsg = iolist_to_binary([SenderUsername, <<": ">>, MessageBinary]),
                                    io:format("Forwarding message to recipient ~p: ~p~n", [RecipientPid, ForwardMsg]),
                                    % Send the message to the recipient  <0.367.0> ! {send_message, <<"meow">>}.
                                    RecipientPid ! {send_message, ForwardMsg},
                                    {ok, State};  % Return {ok, State} to continue
                                {error, not_found} ->
                                    % Recipient not found: notify the sender
                                    io:format("Recipient not found: ~p~n", [RecipientUsernameBinary]),
                                    {reply, {text, <<"Recipient not found">>}, State}
                            end;
                        _ ->
                            % Invalid "send_to" format: notify the sender
                            io:format("Invalid send_to format: ~p~n", [Rest]),
                            {reply, {text, <<"Invalid send_to format">>}, State}
                    end;
                _ ->
                    % Log the valid message
                    io:format("Received unknown message: ~s~n", [ValidMsg]),
                    % Echo the message back to the client
                    {reply, {text, <<"Echo: ", ValidMsg/binary>>}, State}
            end
    end.
% websocket_handle({text, Msg}, State) ->
%     io:format("DEBUG: Received message: ~p~n", [Msg]),  
%     {reply, {text, <<"Echo: ", Msg/binary>>}, State}.

websocket_info({send_message, Msg}, State) ->
    % Forward the message to the client
    io:format("Sending message to client: ~p~n", [Msg]),  
    {reply, {text, Msg}, State};
websocket_info(_Info, State) ->
    % Handle other types of info
    {ok, State}.

terminate(_Reason, _Req, #{username := Username}) ->
    io:format("WebSocket terminated for user: ~p~n", [Username]),
    io:format("WebSocket terminated by reason: ~p~n", [_Reason]),
    ok;
terminate(_Reason, _Req, _State) ->
    ok.

% Function to verify the custom token
verify_token(Token) ->
    try
        % Decode the base64 token
        io:write(Token),
        Decode0 = list_to_binary(Token),
        io:format("~p~n", [is_binary(Decode0)]),
        Userdata = jwt:find_issuer_data(Decode0, <<"secret">>),
        io:format("~p~n", [Userdata]),
        % Split the decoded value into username and password
        [Username, Password] = binary:split(Userdata, <<":">>),
        io:format("~p~n", [Username]),
        io:format("~p~n", [Password]),
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