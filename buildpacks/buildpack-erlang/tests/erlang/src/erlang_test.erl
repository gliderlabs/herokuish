%% @author author <author@example.com>
%% @copyright YYYY author.

%% @doc erlang_test startup code

-module(erlang_test).
-author('author <author@example.com>').
-export([start/0, start_link/0, stop/0]).

%% @spec start_link() -> {ok,Pid::pid()}
%% @doc Starts the app for inclusion in a supervisor tree
start_link() ->
    application:set_env(webmachine, webmachine_logger_module,
                        webmachine_logger),
    application:ensure_all_started(webmachine),
    erlang_test_sup:start_link().

%% @spec start() -> ok
%% @doc Start the erlang_test server.
start() ->
    application:set_env(webmachine, webmachine_logger_module,
                        webmachine_logger),
    application:ensure_all_started(webmachine),
    application:start(erlang_test).

%% @spec stop() -> ok
%% @doc Stop the erlang_test server.
stop() ->
    application:stop(erlang_test).
