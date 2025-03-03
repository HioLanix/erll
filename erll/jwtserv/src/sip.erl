-module(sip).
-export([start/0, send_message/3, handle_message/2]).

start() ->
    % Start the ersip application
    % Start a TCP transport
    {ok, Transport} = ersip_transport:start_link(tcp, {"0.0.0.0", 5060}),
    ersip_transport:set_callback(Transport, {sip, handle_message}),

    % Store the Transport in the process dictionary
    put(transport, Transport),

    io:format("SIP module started (TCP)~n").

send_message(To, From, Message) ->
    % Retrieve the Transport from the process dictionary
    Transport = get(transport),

    % Create a SIP MESSAGE request
    Request = create_sip_message(<<"MESSAGE">>, <<To/binary>>, <<From/binary>>, Message),

    % Send the SIP MESSAGE over TCP
    ersip_transport:send(Transport, Request).

create_sip_message(Method, To, From, Body) ->
    % Create a simple SIP MESSAGE request
    Request = [
        <<Method/binary, " ", To/binary, " SIP/2.0\r\n">>,
        <<"To: ", To/binary, "\r\n">>,
        <<"From: ", From/binary, "\r\n">>,
        <<"Call-ID: 12345@127.0.0.1\r\n">>,
        <<"CSeq: 1 ", Method/binary, "\r\n">>,
        <<"Content-Type: text/plain\r\n">>,
        <<"Content-Length: ", (integer_to_binary(byte_size(Body)))/binary, "\r\n">>,
        <<"\r\n">>,
        Body
    ],
    list_to_binary(Request).

handle_message(Message, _State) ->
    case ersip_message:get_method(Message) of
        <<"MESSAGE">> ->
            Body = ersip_message:get_body(Message),
            To = ersip_message:get_header(<<"To">>, Message),
            io:format("Received SIP MESSAGE for ~s: ~s~n", [To, Body]),
            % Forward the message to the appropriate WebSocket client
            ws_handler:send_message(To,Body);
        _ ->
            % Ignore other SIP methods
            ok
    end.