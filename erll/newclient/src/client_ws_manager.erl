-module(client_ws_manager).
-behaviour(gen_server).

-export([start_link/0, set_connection/2, get_connection/0]).
-export([init/1, handle_call/3, handle_cast/2, handle_info/2]).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

set_connection(Wsref, ConnPid) ->
    gen_server:call(?MODULE, {set_connection, Wsref, ConnPid}).

get_connection() ->
    gen_server:call(?MODULE, get_connection).

init([]) ->
    {ok, #{ws_ref => undefined, conn_pid => undefined}}.

handle_call({set_connection, Wsref, ConnPid}, _From, State) ->
    NewState = State#{ws_ref => Wsref, conn_pid => ConnPid},
    {reply, ok, NewState};
handle_call(get_connection, _From, State) ->
    {reply, State, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.