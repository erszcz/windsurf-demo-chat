-module(windsurf_demo_db_worker).
-behaviour(gen_server).

%% API
-export([start_link/1]).
-export([squery/2, equery/3]).

%% gen_server callbacks
-export([init/1,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         terminate/2,
         code_change/3]).

-record(state, {conn}).

%% API
start_link(Args) ->
    gen_server:start_link(?MODULE, Args, []).

squery(Pid, Sql) ->
    gen_server:call(Pid, {squery, Sql}).

equery(Pid, Sql, Params) ->
    gen_server:call(Pid, {equery, Sql, Params}).

%% gen_server callbacks
init(_Args) ->
    process_flag(trap_exit, true),
    Host = application:get_env(windsurf_demo, db_host, "localhost"),
    Port = application:get_env(windsurf_demo, db_port, 5432),
    DB = application:get_env(windsurf_demo, db_name, "windsurf_chat"),
    User = application:get_env(windsurf_demo, db_user, "windsurf"),
    Password = application:get_env(windsurf_demo, db_password, "windsurf"),
    
    case epgsql:connect(#{
        host => Host,
        port => Port,
        database => DB,
        username => User,
        password => Password
    }) of
        {ok, Conn} ->
            {ok, #state{conn = Conn}};
        {error, Reason} ->
            {stop, Reason}
    end.

handle_call({squery, Sql}, _From, #state{conn = Conn} = State) ->
    {reply, epgsql:squery(Conn, Sql), State};
handle_call({equery, Sql, Params}, _From, #state{conn = Conn} = State) ->
    {reply, epgsql:equery(Conn, Sql, Params), State};
handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, #state{conn = Conn}) ->
    ok = epgsql:close(Conn),
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
