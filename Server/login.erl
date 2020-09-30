-module(login).
-export( [initAccounts/0, create_account/2, close_account/1,login/2,makeLogin/1, getInfo/1]).


initAccounts()->
  Pid2 = spawn( fun() -> accounts( #{}, [{"none", 0}|| _ <- lists:seq(1,5)] ) end),
  register( accounts , Pid2).

%Users = #{ quim => {pass,nivel,vitorias,[Pontos]}, pedro => pass2, ...}
accounts( Map, TopPoints )->
  receive
      {login, Username, Passwd, Pid } ->
        case maps:find( Username, Map) of
          {ok, {Passwd, _,_,_ }} ->
            room ! {enter, Pid},
            pids ! {create, Pid, Username},
            Pid ! ok;
          _ ->
            Pid ! error
          end;
      {create, User, Pass, Pid} ->
        case  maps:is_key(User, Map) of
          true ->
            Pid ! user_exists;
          false ->
            Pid ! ok,
            accounts(maps:put(User,{Pass,1,0,[0,0,0,0,0]}, Map), TopPoints)
        end;
      {close, Username} ->
        accounts(maps:remove(Username, Map),TopPoints);
      {getInfo, Username, Pid} ->
        { _, Nivel, Vit, Pontos} = maps:get(Username,Map),
        Pid ! {info, Nivel, Vit, Pontos, TopPoints};
      {registeVictory, Username, Score} ->
        { Pass, Nivel, Vit, Pontos} = maps:get(Username,Map),
        case Vit + 1 of
          Nivel ->
            NewNivel = Nivel +1,
            NewVit = 0;
           _ ->
            NewNivel = Nivel,
            NewVit = Vit +1
        end,
        NewPontos = addtoList(Pontos, Score),
        NewTopPoints = addtoList(TopPoints, {Username, Score}),
        NewMap  = maps:update(Username, {Pass, NewNivel, NewVit, NewPontos}, Map),
        accounts(NewMap, NewTopPoints)
  end,
      accounts(Map, TopPoints).

%------   funcoes auxiliares    ------
create_account(Username, Passwd) ->
  accounts ! {create, Username, Passwd, self()},
  receive
    V -> V
  end.

close_account(Username) ->
  accounts ! {close, Username}.

login(Username, Passwd) ->
  accounts ! {login, Username, Passwd, self()},
  receive
    V -> V
  end.

addtoList(L, {U,V}) ->
  {X,Min} = min(L),
  case V > Min  of
    true  ->  [ {U,V} | lists:delete({X,Min},L)];
    false ->  L
  end;
addtoList(L, V) ->
  Min = lists:min(L),
  case V > Min  of
    true  ->  [ V |lists:delete(Min,L)];
    false ->  L
  end.

min([X]) -> X;
min([ {X1,Y1}| L]) ->
  {X2,Y2} = min(L),
  case Y2 < Y1 of true -> {X2,Y2}; false -> {X1,Y1} end.

getInfo(Username)->
    accounts ! {getInfo, Username, self()},
    receive
      {info, Nivel, Vit, Pontos, TopPoints} ->
        {Nivel, Vit, Pontos, TopPoints}
    end.


%-------- fazer login -----------
makeLogin(Sock) ->
  receive
    {tcp, _, Msg} ->
      Data = string:trim(Msg),
      [H|T] = string:split(Data, " ", all),
      case string:equal(H,"login") of
        true ->
          [UserName, Passwd] = T,
          case login(UserName, Passwd) of
            ok ->
              gen_tcp:send(Sock, "accept\n");
            error ->
              gen_tcp:send(Sock, "error\n"),
              makeLogin(Sock)
          end;
        false ->
          case string:equal(H,"create") of
            true ->
              [UserName, Passwd] = T,
              case create_account(UserName, Passwd) of
                ok -> gen_tcp:send(Sock,"ok\n");
                user_exists -> gen_tcp:send(Sock,"user_exists\n")
              end,
              makeLogin(Sock);
            false ->
              String = lists:flatten(io_lib:format("Erro : tag \"~s\" nao esperada\n", [Msg])),
              gen_tcp:send(Sock, String ),
              makeLogin(Sock)
          end
      end
  end.
