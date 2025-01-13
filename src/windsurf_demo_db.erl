-module(windsurf_demo_db).

-export([init/0, store_message/2, get_recent_messages/1]).

-define(MAX_RECENT_MESSAGES, 50).
-define(POOL_NAME, windsurf_db_pool).

init() ->
    CreateTable = "CREATE TABLE IF NOT EXISTS messages (
        id SERIAL PRIMARY KEY,
        username VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )",
    CreateIndex = "CREATE INDEX IF NOT EXISTS messages_timestamp_idx ON messages (timestamp DESC)",
    
    Worker = wpool_pool:best_worker(?POOL_NAME),
    windsurf_demo_db_worker:squery(Worker, CreateTable),
    windsurf_demo_db_worker:squery(Worker, CreateIndex),
    ok.

store_message(Username, Message) ->
    wpool:call(?POOL_NAME,
        fun(Worker) ->
            Query = "INSERT INTO messages (username, message) VALUES ($1, $2)",
            case windsurf_demo_db_worker:equery(Worker, Query, [Username, Message]) of
                {ok, 1} -> ok;
                Error -> Error
            end
        end).

get_recent_messages(Limit) when is_integer(Limit), Limit > 0 ->
    wpool:call(?POOL_NAME,
        fun(Worker) ->
            Query = "SELECT username, message, timestamp FROM messages 
                     ORDER BY timestamp DESC 
                     LIMIT $1",
            case windsurf_demo_db_worker:equery(Worker, Query, [min(Limit, ?MAX_RECENT_MESSAGES)]) of
                {ok, _Columns, Rows} ->
                    lists:reverse([{Username, Message, Timestamp} || {Username, Message, Timestamp} <- Rows]);
                Error ->
                    Error
            end
        end).
