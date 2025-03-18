-module(auth_handler).
-behaviour(cowboy_handler).
%%  c:/Users/Hio/Desktop/jwtserv/src/auth_handler.erl /mnt/c/Users/Hio/Desktop/jwtserv/
-export([init/2]).

init(Req0, State) ->
    {ok, Body, Req1} = cowboy_req:read_body(Req0),
    io:format("DEBUG: Request Headers: ~p~n", [cowboy_req:headers(Req0)]),
    io:format("DEBUG: Request Body: ~p~n", [Body]),
    Params = jsx:decode(Body, [return_maps]),
    Username = maps:get(<<"username">>, Params, undefined),
    Password = maps:get(<<"password">>, Params, undefined),

    case {Username, Password} of
        {undefined, _} -> respond(Req1, 400, <<"Missing username">>);
        {_, undefined} -> respond(Req1, 400, <<"Missing password">>);
        _ ->
            case user_storage:authenticate(binary_to_list(Username), binary_to_list(Password)) of
    		true ->
                T=calendar:local_time(),
                Jwtid=erlang:unique_integer([monotonic, positive]),
		        Token = jwt:encode(hs256,[{exp, 3000000000},{nbf,T},{iat, T},{iss, <<Username/binary,":", Password/binary>>},{aud, <<"hio_jwt_serv">>}, {prn, <<"none">>},{jti, Jwtid}], <<"secret">>),
		        %%respond(Req1, 200, jsx:encode(term_to_binary(Token)));
                respond(Req1, 200, (Token));
		false ->
		        respond(Req1, 401, <<"Invalid credentials">>)
	    end		
    end.


respond(Req, Code, Message) ->
    cowboy_req:reply(Code, #{}, Message, Req).


