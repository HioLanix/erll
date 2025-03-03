-module(ws_handler).
-behaviour(cowboy_websocket).

-export([init/2]).
-export([websocket_init/1]).
-export([websocket_handle/2]).
-export([websocket_info/2]).
-export([terminate/3]).
-export([send_message/2]).

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
                    user_storage:remember_socket(Username, Req0),
                    {cowboy_websocket, Req0, #{username => Username}};
                {error, Reason} ->
                    % If the token is invalid, reject the connection
                    Msg = io_lib:format("Invalid token: ~p", [Reason]),
                    Req1 = cowboy_req:reply(402, #{}, list_to_binary(Msg), Req0),
                    {shutdown, Req1, State}
            end
    end.

websocket_init(State) ->
    % Initialize the WebSocket connection
    {ok, State}.

websocket_handle(_Data, State)->
    io:format("Received data: ~s~n", [_Data]),
    % Forward the message to the SIP client
    case ersip_message:get_method(_Data) of
        <<"MESSAGE">> ->
            Body = ersip_message:get_body(_Data),
            To = ersip_message:get_header(<<"To">>, _Data),
            io:format("Received SIP MESSAGE for ~s: ~s~n", [To, Body]),
            % Forward the message to the appropriate WebSocket client
            ws_handler:send_message(To,Body);
        _ ->
            % Ignore other SIP methods
             {ok, State}
    end.
%%websocket_handle(_Data, State) ->
    % Handle other types of WebSocket data
    %%{ok, State}.

websocket_info({sip_message, Body}, State) ->
    % Forward SIP messages to the WebSocket client
    {reply, {text, Body}, State};
websocket_info(_Info, State) ->
    % Handle other types of info
    {ok, State}.

terminate(_Reason, _Req, #{username := Username}) ->
    io:format("WebSocket terminated for user: ~p~n", [Username]),
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

send_message(Client, Message) ->
    case mnesia:dirty_read(clients,Client) of
        [{Client, Pid}] ->
            Pid ! {sip_message, Message};
        [] ->
            io:format("Client ~p not found~n", [Client])
    end.
