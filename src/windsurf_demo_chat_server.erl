-module(windsurf_demo_chat_server).
-behaviour(gen_server).

%% API
-export([
    start_link/0,
    add_client/2,
    remove_client/1,
    broadcast_message/2,
    get_recent_messages/0
]).

%% gen_server callbacks
-export([
    init/1,
    handle_call/3,
    handle_cast/2,
    handle_info/2,
    terminate/2,
    code_change/3
]).

-define(RECENT_MESSAGES_LIMIT, 50).

-record(state, {
    % Map of Pid -> Username
    clients = #{} :: map()
}).

%% API
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

add_client(Pid, Username) ->
    logger:info("Adding client ~p with username: ~p", [Pid, Username]),
    gen_server:cast(?MODULE, {add_client, Pid, Username}),
    % Send recent messages to the new client
    Recent = get_recent_messages(),
    lists:foreach(
        fun({MsgUsername, Message, _Timestamp}) ->
            Payload = jsone:encode(#{
                username => MsgUsername,
                message => Message
            }),
            Pid ! {chat_message, self(), Payload}
        end,
        Recent
    ).

remove_client(Pid) ->
    logger:info("Removing client ~p", [Pid]),
    gen_server:cast(?MODULE, {remove_client, Pid}).

broadcast_message(FromPid, Message) ->
    gen_server:cast(?MODULE, {broadcast, FromPid, Message}).

get_recent_messages() ->
    windsurf_demo_db:get_recent_messages(?RECENT_MESSAGES_LIMIT).

%% gen_server callbacks
init([]) ->
    {ok, #state{}}.

handle_call(_Request, _From, State) ->
    {reply, ok, State}.

handle_cast({add_client, Pid, Username}, State) ->
    logger:info("Storing client ~p with username: ~p", [Pid, Username]),
    {noreply, State#state{clients = maps:put(Pid, Username, State#state.clients)}};
handle_cast({remove_client, Pid}, State) ->
    {noreply, State#state{clients = maps:remove(Pid, State#state.clients)}};
handle_cast({broadcast, FromPid, Message}, State) ->
    Username = maps:get(FromPid, State#state.clients, <<"Anonymous">>),
    logger:info("Broadcasting message from ~p (~p): ~p", [Username, FromPid, Message]),
    ok = windsurf_demo_db:store_message(Username, Message),
    Payload = jsone:encode(#{
        username => Username,
        message => Message
    }),
    logger:info("Encoded payload: ~p", [Payload]),
    maps:foreach(
        fun(ClientPid, _) ->
            ClientPid ! {chat_message, FromPid, Payload}
        end,
        State#state.clients
    ),
    {noreply, State};
handle_cast(_Msg, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
