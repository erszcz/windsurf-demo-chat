-module(windsurf_demo_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    Dispatch = cowboy_router:compile([
        {'_', [
            {"/", windsurf_demo_handler, []},
            {"/ws", windsurf_demo_ws_handler, []}
        ]}
    ]),
    {ok, _} = cowboy:start_clear(http,
        [{port, 8080}],
        #{env => #{dispatch => Dispatch}}
    ),
    windsurf_demo_sup:start_link().

stop(_State) ->
    ok.
