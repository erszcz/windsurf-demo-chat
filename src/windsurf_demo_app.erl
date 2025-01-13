-module(windsurf_demo_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    % Start worker pool first
    {ok, _} = wpool:start_pool(windsurf_db_pool, [
        {workers, 10},
        {worker, {windsurf_demo_db_worker, []}}
    ]),

    % Initialize database
    ok = windsurf_demo_db:init(),

    % Start Cowboy routes
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/", windsurf_demo_handler, []},
            {"/websocket", windsurf_demo_ws_handler, []}
        ]}
    ]),
    {ok, _} = cowboy:start_clear(http, [{port, 8080}], #{
        env => #{dispatch => Dispatch}
    }),
    windsurf_demo_sup:start_link().

stop(_State) ->
    ok = cowboy:stop_listener(http),
    ok = wpool:stop_pool(windsurf_db_pool),
    ok.
