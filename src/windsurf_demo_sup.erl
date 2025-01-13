-module(windsurf_demo_sup).
-behaviour(supervisor).

-export([start_link/0]).
-export([init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    ok = windsurf_demo_db:init(),
    SupFlags = #{strategy => one_for_one,
                 intensity => 5,
                 period => 10},
    ChatServer = #{id => windsurf_demo_chat_server,
                  start => {windsurf_demo_chat_server, start_link, []},
                  restart => permanent,
                  shutdown => 5000,
                  type => worker,
                  modules => [windsurf_demo_chat_server]},
    {ok, {SupFlags, [ChatServer]}}.
