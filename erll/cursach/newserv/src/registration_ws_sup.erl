%%%-------------------------------------------------------------------
%% @doc registration_ws top level supervisor.
%% @end
%%%-------------------------------------------------------------------

-module(registration_ws_sup).

-behaviour(supervisor).

-export([start_link/0]).

-export([init/1]).

-define(SERVER, ?MODULE).

start_link() ->
    supervisor:start_link({local, ?SERVER}, ?MODULE, []).

%% sup_flags() = #{strategy => strategy(),         % optional
%%                 intensity => non_neg_integer(), % optional
%%                 period => pos_integer()}        % optional
%% child_spec() = #{id => child_id(),       % mandatory
%%                  start => mfargs(),      % mandatory
%%                  restart => restart(),   % optional
%%                  shutdown => shutdown(), % optional
%%                  type => worker(),       % optional
%%                  modules => modules()}   % optional
init([]) ->
    BroadcastServer = #{
        id => broadcast_server,
        start => {broadcast_server, start_link, []},
        restart => permanent,
        shutdown => 5000,
        type => worker,
        modules => [broadcast_server]
    },

    Children = [BroadcastServer],
    {ok, {{one_for_one, 5, 10}, Children}}.
%% internal functions
