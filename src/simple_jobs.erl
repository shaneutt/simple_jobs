%% @doc simple_queue - A small job runner for one-offs
%%
%% Provides a simple queuing mechanism and thin wrapper so that you
%% can spawn a lot of erlang processes quickly, but still get some
%% information back on whether they failed.
%%
%% @end
-module(simple_jobs).

%% API exports
-export([run/2, run/3]).

%%====================================================================
%% API functions
%%====================================================================

%% @doc
%%
%% Start up a number of jobs equal to total given with a default timeout of 10000ms
%%
%% @end

-spec run(Job :: fun(), Total :: pos_integer()) -> ok.

run(Job, Total) -> run(Job, Total, 0, 10000).

%% @doc
%%
%% Start up a number of jobs equal to total given, with a custom timeout.
%%
%% @end

-spec run(Job :: fun(), Total :: pos_integer(), Timeout :: pos_integer()) -> ok.

run(Job, Total, Timeout) -> run(Job, Total, 0, Timeout).

%%====================================================================
%% Private functions
%%====================================================================

%% @private
%%
%% Start up a number of jobs equal to the total given and wait for them to
%% finish via wait_for_jobs/3.
%%

-spec run(
  Job     :: fun(),
  Total   :: pos_integer(),
  Queued  :: integer(),
  Timeout :: pos_integer()
) ->
  Results :: ok | {error, Messages :: list({Reason :: atom(), Count :: pos_integer()})}.

run(_Job, Total, Total, Timeout) -> wait_for_jobs(Total, [], Timeout);
run(Job, Total, Queued, Timeout) ->
  spawn_monitor(Job),
  run(Job, Total, Queued + 1, Timeout).

%% @private
%%
%% Waits for each job (monitor processes) in the queue given the original total
%% and reports back a count of any encountered monitor down reasons on failure.
%%
%% @end

wait_for_jobs(0, [], _Timeout)          -> ok;
wait_for_jobs(0, Messages, _Timeout)    -> {error, Messages};
wait_for_jobs(Total, Messages, Timeout) ->
  receive
    {'DOWN', _MonitorRef, process, _Pid, normal} ->
      wait_for_jobs(Total - 1, Messages, Timeout);
    {'DOWN', _MonitorRef, process, _Pid, Reason} ->
      NewCount = case lists:keyfind(Reason, 1, Messages) of
        false           -> 1;
        {Reason, Count} -> Count + 1
      end,
      NewMessages = lists:keystore(Reason, 1, Messages, {Reason, NewCount}),
      wait_for_jobs(Total - 1, NewMessages, Timeout);
    _Other -> wait_for_jobs(Total, Messages, Timeout)
  after
    Timeout ->
      {error, timeout}
  end.

%%====================================================================
%% Unit tests
%%====================================================================

-ifdef(TEST).
-include_lib("eunit/include/eunit.hrl").

%% helper
no_messages_remain() ->
  receive
    _Message -> false
  after
    0 -> true
  end.

flush() ->
  receive
    _Message -> flush()
  after
    0 -> ok
  end.

%% tests

run_test_() ->
  %% basic tests of job runs
  Result = run(fun() -> ok end, 10),
  BasicTestResults = lists:flatten([
    ?_assert(no_messages_remain()),
    ?_assertEqual(ok, Result)
  ]),

  %% test jobs that time out
  TimeoutJob = fun() -> timer:sleep(10) end,
  TimeoutRes = run(TimeoutJob, 10, 5),
  TimeoutTestResults = lists:flatten([
    ?_assertEqual({error, timeout}, TimeoutRes)
  ]),
  timer:sleep(10),
  flush(),

  %% test that errors are recorded as counts
  ErrorJob = fun() ->
    RandomNum = crypto:rand_uniform(0, 3),
    if
      RandomNum =:= 0 -> exit(batman);
      RandomNum =:= 1 -> exit(joker);
      RandomNum =:= 2 -> exit(robin)
    end
  end,
  ErrorRes = run(ErrorJob, 1000),
  ErrorTestResults = lists:flatten([
    ?_assertMatch({error, [_, _, _]}, ErrorRes)
  ]),

  %% all done, report!
  lists:flatten([
    BasicTestResults,
    TimeoutTestResults,
    ErrorTestResults
  ]).

-endif.
