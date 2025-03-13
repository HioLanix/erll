-module(h_test).
-export([run_test/0, send_post_request/0, send_get_request/0, send_delete_request/0]). %% h_test:send_delete_request().


run_test() ->
        inets:start(),
    serv:start(8080), 
    io:format("Server started and listening on port 8080~n"), 
   timer:sleep(2000),
    test_requests(),
    ok.



 test_requests()-> 
    send_post_request(),
        timer:sleep(100),
    send_get_request(),
        timer:sleep(100),
    send_delete_request().

send_post_request() ->
    URL = "http://localhost:8080/POST",
    Headers = [{"Content-Type", "application/json"}],
    Body = "{\"key\": \"value\"}", 
    Request = {URL, Headers, "application/json", Body},
    
    %% Send the POST request
    case httpc:request(post, Request, [], []) of
        {ok, {{_, StatusCode, _}, _, ResponseBody}} ->
            io:format("Response Status Code: ~p~n", [StatusCode]),
            io:format("Response Body: ~s~n", [ResponseBody]);
        {error, Reason} ->
            io:format("Error: ~p~n", [Reason])
    end.

send_get_request() ->
    URL = "http://localhost:8080/GET",
    Request = {URL, []}, % No headers or body for GET
    case httpc:request(get, Request, [], []) of
        {ok, {{_, StatusCode, _}, _, ResponseBody}} ->
            io:format("GET Response Status Code: ~p~n", [StatusCode]),
            io:format("GET Response Body: ~s~n", [ResponseBody]);
        {error, Reason} ->
            io:format("GET Error: ~p~n", [Reason])
    end.

send_delete_request() ->
    {ok, Socket} = gen_tcp:connect("localhost", 8080, [binary, {active, false}]),
    Request = "DELETE /DELETE HTTP/1.1\r\nHost: localhost:8080\r\n\r\n",
    gen_tcp:send(Socket, Request),
    case gen_tcp:recv(Socket, 0) of
        {ok, Response} ->
            io:format("Received response: ~s~n", [Response]);
        {error, Reason} ->
            io:format("Error: ~p~n", [Reason])
    end,
    gen_tcp:close(Socket).
