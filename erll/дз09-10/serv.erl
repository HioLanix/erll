-module(serv).  %%         cd('c:/Users/Hio/Desktop/erll/дз09-10/').   cd('c:/Users/Пользователь/Desktop/lit erl/serv/'). serv:start().  /mnt/c/Users/Hio/Desktop/erll/дз09-10/
-export([start/1, accept_loop/1, writelogin/2 ]). 
-record(logins, {id, time, ip, method}).
-include_lib("stdlib/include/qlc.hrl").
-type port_number() :: 1..65535.
-type socket() :: term().
-type peer_address() :: {inet:ip_address(), inet:port_number()}.
-type method() :: string().

-spec start(port_number()) -> ok.
start(Port) ->
    {ok, ListenSocket} = gen_tcp:listen(Port, [binary, {active, false}]),
    io:format("Listening on port ~p~n", [Port]),
    mnesia:delete_schema([node()]),
    mnesia:create_schema([node()]),
    mnesia:start(),
    mnesia:create_table(logins,   [{attributes, record_info(fields, logins)}]),
    spawn(fun() -> accept_loop(ListenSocket) end).

-spec accept_loop(socket()) -> no_return().
accept_loop(ListenSocket) ->
    io:format("Waiting for incoming connections...~n"), 
    case gen_tcp:accept(ListenSocket) of
        {ok, Socket} ->
            {ok, PeerAddress} = inet:peername(Socket),
            io:format("Accepted connection from ~p~n", [PeerAddress]),
            spawn(fun() -> handle_client(Socket, PeerAddress) end), 
            accept_loop(ListenSocket);
        {error, Reason} ->
            io:format("Connection status: ~p~n", [Reason]), 
            exit(ListenSocket, kill)
    end.

handle_client(Socket,PeerAddress) ->
    case  gen_tcp:recv(Socket, 0) of
    {ok, Request} ->
   
    %%mnesia:info(),
        Response = handle_request(Request,PeerAddress),
        gen_tcp:send(Socket, Response),
        gen_tcp:close(Socket);
    {error, closed} ->
        io:format("Connection closed ~n" )
    end.

handle_request(Request, PeerAddress) ->
    Req = binary_to_list(Request),
    Lines = string:tokens(Req, "\r\n"),
    [FirstLine | _] = Lines, 
    [Method | _] = string:tokens(FirstLine, " "), 

    %% Determine the response based on the HTTP method
    case Method of
        "GET" -> 
            M = "HTTP/1.1 200 OK\r\n";
        "POST" ->
            M = "HTTP/1.1 201 Created\r\n";
        "DELETE" ->
            M = "HTTP/1.1 204 No Content\r\n";
        _ ->
            M = "HTTP/1.1 501 Not Implemented\r\n"
    end,

    CT = "Content-Type: text/html\r\n",
     ResponseBody = case Method of
        "DELETE" -> ""; % No body for DELETE requests
        _ -> "Hio's\n" ++ "Server\n" ++ "<div> <span>method:</span> <span>" ++ Method ++ "</span> </div> \r\n\r\n"
    end,

    %% Log the request
    writelogin(PeerAddress, M),

    %% Build the response
    M ++ CT ++ "Content-Length: " ++ integer_to_list(length(ResponseBody)) ++ "\r\n\r\n" ++ ResponseBody.
        
        

-spec writelogin(peer_address(), method()) -> ok | {error, term()}.
writelogin(PeerAddress,M) ->
   
    UniqueId = erlang:unique_integer([monotonic, positive]),   
         
    Login = #logins{id   = UniqueId , time = calendar:local_time(), ip= PeerAddress,method=M},
    io:format(" ~p ~n", [Login]),
    F = fun() -> 
		mnesia:write(Login)
    %% mnesia:read{logins, UniqueId}.handle http req(Data) ->
	end,    
    mnesia:transaction(F).
  
       %%           cd('c:/Users/Hio/Desktop/serv/').  

          


 %%string:find
 
   



