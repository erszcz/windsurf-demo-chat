-module(windsurf_demo_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    % Initialize database and worker pool
    ok = windsurf_demo_db:init(),

    % Start Cowboy
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/", windsurf_demo_handler, []},
            {"/websocket", windsurf_demo_ws_handler, []}
        ]}
    ]),
    {ok, _} = cowboy:start_clear(http,
        [{port, 8080}],
        #{env => #{dispatch => Dispatch}}
    ),
    windsurf_demo_sup:start_link().

stop(_State) ->
    ok = wpool:stop_pool(windsurf_db_pool),
    ok.
