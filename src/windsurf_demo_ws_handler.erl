-module(windsurf_demo_ws_handler).

-export([init/2]).
-export([websocket_init/1]).
-export([websocket_handle/2]).
-export([websocket_info/2]).
-export([terminate/3]).

init(Req, _State) ->
    QS = maps:from_list(cowboy_req:parse_qs(Req)),
    logger:info("Query string: ~p", [QS]),
    Username =
        case QS of
            #{<<"username">> := Name} ->
                logger:info("Using provided username: ~p", [Name]),
                Name;
            _ ->
                Generated = generate_username(),
                logger:info("Using generated username: ~p", [Generated]),
                Generated
        end,
    % Set idle timeout to 1 hour and increase max frame size
    {cowboy_websocket, Req, #{username => Username}, #{
        idle_timeout => 3_600_000,
        max_frame_size => 8_000_000
    }}.

websocket_init(State = #{username := Username}) ->
    logger:info("Initializing websocket with username: ~p", [Username]),
    windsurf_demo_chat_server:add_client(self(), Username),
    {ok, State}.

websocket_handle({text, Msg}, State) ->
    case jsone:decode(Msg) of
        {ok, #{action := "join", channel := Channel}} ->
            windsurf_demo_chat_server:join_channel(Channel, self()),
            {ok, State};
        {ok, #{action := "leave", channel := Channel}} ->
            windsurf_demo_chat_server:leave_channel(self()),
            {ok, State};
        {ok, #{action := "message", content := Content}} ->
            windsurf_demo_chat_server:broadcast_message(self(), Content),
            {ok, State};
        {error, Reason} ->
            logger:error("Failed to decode message: ~p", [Reason]),
            {ok, State};
        _ ->
            logger:error("Invalid message format: ~p", [Msg]),
            {ok, State}
    end;
websocket_handle(_Data, State) ->
    {ok, State}.

websocket_info({chat_message, _FromPid, Msg}, State) ->
    {reply, {text, Msg}, State};
websocket_info(_Info, State) ->
    {ok, State}.

terminate(_Reason, _Req, _State) ->
    windsurf_demo_chat_server:remove_client(self()),
    ok.

generate_username() ->
    List = ["Happy", "Sunny", "Clever", "Swift", "Bright", "Quick", "Smart", "Cool"],
    Animals = ["Dolphin", "Eagle", "Fox", "Owl", "Rabbit", "Tiger", "Wolf", "Bear"],
    Adj = iolist_to_binary(lists:nth(erlang:trunc(rand:uniform(length(List))), List)),
    Animal = iolist_to_binary(lists:nth(erlang:trunc(rand:uniform(length(Animals))), Animals)),
    Number = integer_to_binary(erlang:trunc(rand:uniform(100))),
    <<Adj/binary, Animal/binary, Number/binary>>.
