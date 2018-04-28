%%----------------------------------------------------
%% @doc State(S) x Event(E) -> Actions(A), State(S')
%%      当处在S状态时，如果有事件E发生，就会触发A，并修改状态为S'
%%
%% @author shealee.cc@outlook.com
%% @end
%%----------------------------------------------------
-module(code_lock).
-behaviour(gen_fsm).
-export(
    [
        start_link/1
    ]
).
-export([
        button/1
        ,reset/2
    ]).
-export([
        locked/2
        ,open/2
    ]).
-export([init/1, handle_event/3, handle_sync_event/4, handle_info/3, terminate/3, code_change/4]).

-record(state,{
        status = 0,
        password = 0
    }).

%% 启动gen_fsm并设置密码锁的密码为Code，并调用初始化方法
start_link(Code)->
    io:format("开启服务~n"),
    gen_fsm:start_link({local, code_lock}, code_lock, [Code], []).

%% Digit 为数字，也就是数字锁的密码
button(Digit) ->
    gen_fsm:send_event(code_lock, {button, Digit}).

%% 重置数字锁密码
reset(ODigit, NDigit) ->
    gen_fsm:send_event(code_lock, {reset, ODigit, NDigit}).

%% 初始化操作
init(Code)->
    io:format("初始化密码锁~n"),
    [H | _] = Code,
    State = #state{password = H},
    {ok, locked, State}.

locked({reset, ODigit, NDigit}, State = #state{password = Password}) -> 
    case ODigit of
        Password ->
            io:format("修改密码锁密码!~n"),
            NewState = State#state{password = NDigit},
            {next_state, locked, NewState};
        _ ->
            io:format("密码有误~n"),
            {next_state, locked, State}
    end;
locked({button, Digit}, State = #state{password = Password}) ->
    io:format("判断锁~n"),
    case Digit of
        Password ->
            do_unlock(),
            NewState = State#state{status = 1},
            {next_state, open, NewState, 30000};
        _Wrong ->
            io:format("Digit:~w, Password:~w~n", [Digit, Password]),
            io:format("有误~n"),
            {next_state, locked, State}
    end;
locked(_ , State) ->
    {next_state, locked, State}.

open(timeout, State) ->
    do_lock(),
    NewState = State#state{status = 0},
    {next_state, locked, NewState};
open(_, State) ->
    {next_state, open, State}.

do_unlock() ->
    io:format("门开了").

do_lock() ->
    io:format("门关了").

handle_event(_Event, StateName, State) ->
    {next_state, StateName, State}.

handle_sync_event(_Event, _From, StateName, State) ->
    Reply = ok,
    {reply, Reply, StateName, State}.

handle_info(_Info, StateName, State) ->
    {next_state, StateName, State}.

terminate(_Reason, _StateName, _State) ->
    ok.

code_change(_OldVsn, StateName, State, _Extra) ->
    {ok, StateName, State}.
