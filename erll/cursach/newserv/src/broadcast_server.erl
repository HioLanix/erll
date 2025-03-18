-module(broadcast_server).
-behaviour(gen_server).
%% /mnt/c/Users/Hio/Desktop/cursach/newserv/
-export([start_link/0]).
-export([add_client/2, remove_client/1, broadcast/1, send_to/3]). % Explicitly export API functions
-export([init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).

-record(state, {
    clients = #{} :: #{binary() => pid()} % Map of usernames to their PIDs
}).

% API
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

% Add a client to the broadcast list
add_client(Username, Pid) ->
    gen_server:call(?MODULE, {add_client, Username, Pid}).

% Remove a client from the broadcast list
remove_client(Username) ->
    gen_server:call(?MODULE, {remove_client, Username}).

% Broadcast a message to all clients
broadcast(Message) ->
    gen_server:cast(?MODULE, {broadcast, Message}).

% Send a message to a specific user
send_to(RecipientUsername, SenderUsername, Message) ->
    gen_server:cast(?MODULE, {send_to, RecipientUsername, SenderUsername, Message}).

% Initialize the server
init([]) ->
    io:format("Broadcast server started~n"),
    {ok, #state{}}.

% Handle adding a client
handle_call({add_client, Username, Pid}, _From, State = #state{clients = Clients}) ->
    NewClients = Clients#{Username => Pid},
    {reply, ok, State#state{clients = NewClients}};

% Handle removing a client
handle_call({remove_client, Username}, _From, State = #state{clients = Clients}) ->
    NewClients = maps:remove(Username, Clients),
    {reply, ok, State#state{clients = NewClients}}.

% Handle broadcasting a message
handle_cast({broadcast, Message}, State = #state{clients = Clients}) ->
    io:format("Broadcasting message to all clients: ~p~n", [Message]),
    maps:foreach(fun(_Username, Pid) -> Pid ! {send_message, Message} end, Clients),
    {noreply, State};

% Handle sending a message to a specific user
handle_cast({send_to, RecipientUsername, SenderUsername, Message}, State = #state{clients = Clients}) ->
    case maps:get(RecipientUsername, Clients, undefined) of
        undefined ->
            io:format("Recipient ~p not found~n", [RecipientUsername]),
            {noreply, State};
        RecipientPid ->
            ForwardedMessage = iolist_to_binary([SenderUsername, <<": ">>, Message]),
            RecipientPid ! {send_message, ForwardedMessage},
            {noreply, State}
    end;

% Handle other casts
handle_cast(_Msg, State) ->
    {noreply, State}.

% Handle unused handle_info/2
handle_info(_Info, State) ->
    {noreply, State}.

% Terminate the server
terminate(_Reason, _State) ->
    io:format("Broadcast server stopped~n"),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.