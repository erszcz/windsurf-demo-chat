-module(windsurf_demo_ws_handler).

-export([init/2]).
-export([websocket_init/1]).
-export([websocket_handle/2]).
-export([websocket_info/2]).
-export([terminate/3]).

init(Req, _State) ->
    QS = maps:from_list(cowboy_req:parse_qs(Req)),
    io:format("Query string: ~p~n", [QS]),
    Username = case QS of
        #{<<"username">> := Name} ->
            io:format("Using provided username: ~p~n", [Name]),
            Name;
        _ ->
            Generated = generate_username(),
            io:format("Using generated username: ~p~n", [Generated]),
            Generated
    end,
    % Set idle timeout to 1 hour and increase max frame size
    {cowboy_websocket, Req, #{username => Username}, #{
        idle_timeout => 3_600_000,
        max_frame_size => 8_000_000
    }}.

websocket_init(State = #{username := Username}) ->
    io:format("Initializing websocket with username: ~p~n", [Username]),
    windsurf_demo_chat_server:add_client(self(), Username),
    {ok, State}.

websocket_handle({text, Msg}, State) ->
    windsurf_demo_chat_server:broadcast_message(self(), Msg),
    {ok, State};
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
