-module(windsurf_demo_db).

-export([init/0, store_message/2, get_recent_messages/1]).

-define(MAX_RECENT_MESSAGES, 50).
-define(POOL_NAME, windsurf_db_pool).
-define(POOL_SIZE, 5).
-define(POOL_OVERFLOW, 2).

init() ->
    % Start the worker pool
    PoolConfig = [
        {worker, {windsurf_demo_db_worker, [
            {host, application:get_env(windsurf_demo, db_host, "localhost")},
            {port, application:get_env(windsurf_demo, db_port, 5432)},
            {database, application:get_env(windsurf_demo, db_name, "windsurf_chat")},
            {username, application:get_env(windsurf_demo, db_user, "windsurf")},
            {password, application:get_env(windsurf_demo, db_password, "windsurf")}
        ]}},
        {size, ?POOL_SIZE},
        {max_overflow, ?POOL_OVERFLOW},
        {pool_sup_intensity, 5},
        {pool_sup_period, 1},
        {worker_module, windsurf_demo_db_worker}
    ],
    {ok, _} = wpool:start_pool(?POOL_NAME, PoolConfig),

    % Initialize database schema
    CreateTable = "CREATE TABLE IF NOT EXISTS messages (
        id SERIAL PRIMARY KEY,
        username VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )",
    CreateIndex = "CREATE INDEX IF NOT EXISTS messages_timestamp_idx ON messages (timestamp DESC)",

    ok = wpool:call(?POOL_NAME, {squery, CreateTable}, best_worker),
    ok = wpool:call(?POOL_NAME, {squery, CreateIndex}, best_worker),
    ok.

store_message(Username, Message) ->
    Query = "INSERT INTO messages (username, message) VALUES ($1, $2)",
    case wpool:call(?POOL_NAME, {equery, Query, [Username, Message]}, best_worker) of
        {ok, 1} -> ok;
        Error -> Error
    end.

get_recent_messages(Limit) when is_integer(Limit), Limit > 0 ->
    Query = "SELECT username, message, timestamp FROM messages 
             ORDER BY timestamp DESC 
             LIMIT $1",
    case wpool:call(?POOL_NAME, {equery, Query, [min(Limit, ?MAX_RECENT_MESSAGES)]}, best_worker) of
        {ok, _Columns, Rows} ->
            lists:reverse([{Username, Message, Timestamp} || {Username, Message, Timestamp} <- Rows]);
        Error ->
            Error
    end.
