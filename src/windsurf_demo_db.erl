-module(windsurf_demo_db).

-export([init/0, connect/0, store_message/2, get_recent_messages/1]).

-define(MAX_RECENT_MESSAGES, 50).

init() ->
    {ok, Conn} = connect(),
    CreateTable = "CREATE TABLE IF NOT EXISTS messages (
        id SERIAL PRIMARY KEY,
        username VARCHAR(255) NOT NULL,
        message TEXT NOT NULL,
        timestamp TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
    )",
    CreateIndex = "CREATE INDEX IF NOT EXISTS messages_timestamp_idx ON messages (timestamp DESC)",
    {ok, [], []} = epgsql:squery(Conn, CreateTable),
    {ok, [], []} = epgsql:squery(Conn, CreateIndex),
    ok = epgsql:close(Conn).

connect() ->
    Host = application:get_env(windsurf_demo, db_host, "localhost"),
    Port = application:get_env(windsurf_demo, db_port, 5432),
    DB = application:get_env(windsurf_demo, db_name, "windsurf_chat"),
    User = application:get_env(windsurf_demo, db_user, "windsurf"),
    Password = application:get_env(windsurf_demo, db_password, "windsurf"),
    epgsql:connect(#{
        host => Host,
        port => Port,
        database => DB,
        username => User,
        password => Password
    }).

store_message(Username, Message) ->
    {ok, Conn} = connect(),
    Query = "INSERT INTO messages (username, message) VALUES ($1, $2)",
    {ok, 1} = epgsql:equery(Conn, Query, [Username, Message]),
    ok = epgsql:close(Conn).

get_recent_messages(Limit) when is_integer(Limit), Limit > 0 ->
    {ok, Conn} = connect(),
    Query = "SELECT username, message, timestamp FROM messages 
             ORDER BY timestamp DESC 
             LIMIT $1",
    {ok, _Columns, Rows} = epgsql:equery(Conn, Query, [min(Limit, ?MAX_RECENT_MESSAGES)]),
    ok = epgsql:close(Conn),
    lists:reverse([{Username, Message, Timestamp} || {Username, Message, Timestamp} <- Rows]).
