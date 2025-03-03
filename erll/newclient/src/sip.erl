-module(sip).
-export([start/0, send_message/3]).
%%             /mnt/c/Users/Hio/Desktop/cringe   
%%      client_app:auth_user(testuser,testpass).
%% sip:send_message(<<"https://localhost:8080/">>, <<"testuser">>, <<"Hello, Alice!">>).
start() ->
    % Start Gun and connect to the SIP server
    {ok, ConnPid} = gun:open("https://localhost:8080/", 5060), 
    io:format("Connected to SIP server~n"),

    % Store the connection PID in the process dictionary
    put(conn_pid, ConnPid),

    % Await the connection to be established
    await_connection(ConnPid).


await_connection(ConnPid) ->
    receive
        {gun_up, ConnPid, _Protocol} ->
            io:format("Connection established~n"),
            ok;
        {gun_down, ConnPid, _Protocol, _Reason, _KilledStreams, _UnprocessedStreams} ->
            io:format("Connection failed: ~p~n", [_Reason]),
            {error, connection_failed}
    after 5000 ->
        io:format("Connection timeout~n"),
        {error, timeout}
    end.

send_message(To, From, Message) ->
    case  get(ws_ref) of Wsref  ->
        
    % Retrieve the connection PID from the process dictionary
    ConnPid = get(conn_pid),

    % Create a SIP MESSAGE request
    Request = create_sip_message(<<"MESSAGE">>, To, From, Message),

    % Send the SIP message over the TCP connection
    gun:ws_send(ConnPid,Wsref, {text, Request});

    % Await the response
    %%await_response(ConnPid, StreamRef);
    _->
        {error,not_logined}
    end.

create_sip_message(Method, To, From, Body) ->
    % Create a SIP MESSAGE request
    Request = [
        <<Method/binary, " sip:", To/binary, " SIP/2.0\r\n">>,
        <<"To: <sip:", To/binary, ">\r\n">>,
        <<"From: <sip:", From/binary, ">\r\n">>,
        <<"Call-ID: ", (generate_call_id())/binary, "\r\n">>,
        <<"CSeq: 1 ", Method/binary, "\r\n">>,
        <<"Content-Type: text/plain\r\n">>,
        <<"Content-Length: ", (integer_to_binary(byte_size(Body)))/binary, "\r\n">>,
        <<"\r\n">>,
        Body
    ],
    list_to_binary(Request).

generate_call_id() ->
    % Generate a random Call-ID
    Rand = crypto:strong_rand_bytes(16),
    base64:encode(Rand).

await_response(ConnPid, StreamRef) ->
    receive
        {gun_data, ConnPid, StreamRef, nofin, Data} ->
            io:format("Received response: ~p~n", [Data]),
            await_response(ConnPid, StreamRef);
        {gun_data, ConnPid, StreamRef, fin, Data} ->
            io:format("Final response: ~p~n", [Data]),
            ok;
        {gun_error, ConnPid, StreamRef, Reason} ->
            io:format("Error: ~p~n", [Reason]),
            {error, Reason};
        {gun_down, ConnPid, _Protocol, Reason, _KilledStreams, _UnprocessedStreams} ->
            io:format("Connection down: ~p~n", [Reason]),
            {error, connection_down}
    after 5000 ->
        io:format("Response timeout~n"),
        {error, timeout}
    end.