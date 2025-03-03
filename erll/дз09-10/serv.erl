-module(serv).  %%         cd('c:/Users/Hio/Desktop/serv/').  cd('c:/Users/Пользователь/Desktop/lit erl/serv/'). serv:start().
-export([start/1, accept_loop/1, writelogin/2 ]). 
-record(logins, {id, time, ip, method}).
-include_lib("stdlib/include/qlc.hrl").

start(Port) ->
    {ok, ListenSocket} = gen_tcp:listen(Port, [binary, {active, false}]),
    io:format("Listening on port ~p~n", [Port]),
    mnesia:delete_schema([node()]),
    mnesia:create_schema([node()]),
    mnesia:start(),
    mnesia:create_table(logins,   [{attributes, record_info(fields, logins)}]),
    accept_loop(ListenSocket).

accept_loop(ListenSocket) ->
    {ok, Socket} = gen_tcp:accept(ListenSocket),
    {ok, PeerAddress} = inet:peername(Socket),
    spawn(fun() -> handle_client(Socket,PeerAddress)end),
    accept_loop(ListenSocket).

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

handle_request(Request,PeerAddress) ->
     
    %% io:format(" ~p ~n", [Request]),
   %% io:format(" ~p ~n", [PeerAddress]),
     Req = binary_to_list(Request),
    Lines = string:tokens(Req, "\r\n"),
    [Method | _]= string: tokens (Lines, " "),
    case Method of
        "GET" -> 
            M= "HTTP/1.1 200 OK\r\n";

        "POST"->
            M= "HTTP/1.1 201 Created\r\n";
        "DELETE"->
            M= "HTTP/1.1 204 No content\r\n";
        _->
            M= "HTTP/1.1 204 Not Implemented\r\n"
        end,
     [ContetType | _]= string: tokens (Lines, ""), 
    case ContetType of
        "text/html"->
            CT= "Content-Type: text/html\r\n",
            ResponseBody= "Hio's\n" ++  "Server\n"++"<div> <span>metod:</span> <span> " ++ Method ++ "</span> </div> \r\n\r\n" ;
    "application/json"->
            CT= "Content-Type: application/json\r\n",
            ResponseBody= "Hio's\n" ++  "Server\n"++"{'method':'"++ Method ++ "'}\r\n\r\n";
        _ ->
            CT= "Content-Type: wrong content-type\r\n",
            ResponseBody="Hio's\n" ++  "Server\n"++ "ERRROROROR\r\n\r\n"
        end,
       %% [_, Host] = string:tokens(Lines, ": "),
       %% io:format(" ~p ~n", [Host]),
        writelogin(PeerAddress,M),

        M ++ CT ++"Content-Length"++ [byte_size(term_to_binary(ResponseBody)), "\r\n\r\n"] ++ ResponseBody.
        %%ResponseHeader = M++ [byte_size(term_to_binary(ResponseBody)), "\r\n\r\n"] ++ CT,
        %%ResponseHeader ++ ResponseBody ++ Request.
        
        


writelogin(PeerAddress,M) ->
   
    UniqueId = erlang:unique_integer([monotonic, positive]),   
         
    Login = #logins{id   = UniqueId , time = calendar:local_time(), ip= PeerAddress,method=M},
    io:format(" ~p ~n", [Login]),
    F = fun() -> 
		mnesia:write(Login)
    %% mnesia:read{logins, UniqueId}.handle http req(Data) ->
	end,    
    mnesia:transaction(F).
  
       %%           cd('c:/Users/Hio/Desktop/serv/').  https://dyp2000.gitbooks.io/russian-armstrong-erlang/content/chapter17.html

          




 %%string:find
 
   



