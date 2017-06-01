%% -------------------------------------------------------------------
%%
%% Copyright (c) 2017 Carlos Gonzalez Florido.  All Rights Reserved.
%%
%% This file is provided to you under the Apache License,
%% Version 2.0 (the "License"); you may not use this file
%% except in compliance with the License.  You may obtain
%% a copy of the License at
%%
%%   http://www.apache.org/licenses/LICENSE-2.0
%%
%% Unless required by applicable law or agreed to in writing,
%% software distributed under the License is distributed on an
%% "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
%% KIND, either express or implied.  See the License for the
%% specific language governing permissions and limitations
%% under the License.
%%
%% -------------------------------------------------------------------

%% @doc
-module(nkservice_rest_sample).
-author('Carlos Gonzalez <carlosj.gf@gmail.com>').

-define(SRV, rest_test).
-define(WS, "wss://127.0.0.1:9010/ws").
-define(HTTP, "https://127.0.0.1:9010/rpc/api").

-compile(export_all).

-include_lib("nkservice/include/nkservice.hrl").

%% ===================================================================
%% Public
%% ===================================================================


%% @doc Starts the service
start() ->
    Spec = #{
        callback => ?MODULE,
        rest_url => "https://all:9010/test1, wss:all:9010/test1/ws",
        webserver_url => "https://all:9010/webs",
        %debug => [{nkservice_rest, [nkpacket]}, {nkservice_webserver, [nkpacket]}],
        packet_no_dns_cache => false
    },
    nkservice:start(?SRV, Spec).


%% @doc Stops the service
stop() ->
    nkservice:stop(?SRV).

test1() ->
    Url = "https://127.0.0.1:9010/test1/test-a?b=1&c=2",
    {ok, {{_, 200, _}, Hs, B}} = httpc:request(post, {Url, [], "test/test", "body1"}, [], []),
    [1] = nklib_util:get_value("header1", Hs),
    #{
        <<"ct">> := <<"test/test">>,
        <<"qs">> := #{<<"b">>:=<<"1">>, <<"c">>:=<<"2">>},
        <<"body">> := <<"body1">>
    } =
        nklib_json:decode(B).

test2() ->
    Url = "https://127.0.0.1:9010/webs/hi.txt",
    {ok, {{_, 200, _}, _, _B}} = httpc:request(Url).

test3() ->
    Url = "wss://127.0.0.1:9010/test1/ws",
    {ok, #{}, Pid} = nkapi_client:start(?SRV, Url, u1, none, #{}),
    nkapi_client:stop(Pid).





%% ===================================================================
%% API callbacks
%% ===================================================================

plugin_deps() ->
    [nkservice_rest, nkservice_webserver].


nkservice_rest_http(_SrvId, post, [<<"test-a">>], Req, State) ->
    Qs = maps:from_list(nkservice_rest_http:get_qs(Req)),
    CT = nkservice_rest_http:get_ct(Req),
    Body = nkservice_rest_http:get_body(Req, #{parse=>true}),
    Reply = nklib_json:encode(#{qs=>Qs, ct=>CT, body=>Body}),
    {http, 200, [{<<"header1">>, 1}], Reply, State};

nkservice_rest_http(_SrvId, _Method, _Path, _Req, _State) ->
    continue.


nkservice_rest_text(Text, _NkPort, State) ->
    #{
        <<"cmd">> := <<"login">>,
        <<"tid">> := TId
    } = nklib_json:decode(Text),
    Reply = #{
        result => ok,
        tid => TId
    },
    nkservice_rest_protocol:send_async(self(), nklib_json:encode(Reply)),
    {ok, State}.
