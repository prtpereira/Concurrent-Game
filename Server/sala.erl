-module(sala).
-export([init/0]).
-import( login, [initAccounts/0,login/2,makeLogin/1,getInfo/1,close_account/1]).
-import( motor, [action/1,makeMoviment/2, estado2String/1,addMonster/1,time/2,applyNewDirection/1]).


%--------- Processos do jogo -----------------
init() ->
  Port = 12345,
  initAccounts(),

  Room = spawn(fun()-> room([],[],[]) end),
  register(room, Room),

  Pids = spawn( fun()-> allPids( #{} ) end),
  register(pids, Pids),

  {ok, LSock} = gen_tcp:listen(Port, [binary, {packet, line}, {reuseaddr, true}]),
  acceptor(LSock).

acceptor(LSock) ->
  {ok, Sock} = gen_tcp:accept(LSock),
  spawn(fun() -> acceptor(LSock) end),
  makeLogin(Sock),
  user(Sock, room).

room(Jogos, UsersOff, UsersOn) ->
  pids ! {getList, self()}, receive {number,XXX} -> true end,
  io:format("------------~nEm pausa:~w~nEm espera:~w~nJogos a decorrer:~w~nPids Registados:~w ~n------------~n",
            [length(UsersOff), length(UsersOn), length(Jogos), XXX]),
  receive
    {line, User, Msg} ->
      case string2Atom(Msg) of
        info ->
          Info = getInfo( getUsername(User)),
          User ! {line, info2String( Info )},
          room(Jogos, UsersOff, UsersOn);
        logout ->
          pids ! {close, User},
          User ! {makeLogin},
          room(Jogos, UsersOff -- [User], UsersOn);
        close_account ->
          Username = getUsername(User),
          pids ! {close, User},
          close_account(Username),
          User ! {makeLogin},
          room(Jogos, UsersOff -- [User], UsersOn);
        play ->
          {UserNivel, _,_,_} = getInfo( getUsername(User)),
          case procuraUser( UsersOn, UserNivel) of
            none ->
              room( Jogos, lists:delete(User,UsersOff) , [User|UsersOn]);
            User2 ->
              io:format("$ Jogo iniciado~n", []),
              Jogo = novoJogo(User, User2),
              User  ! {setUp, Jogo},
              User  ! {line, "inicioDeJogo\n"},
              User2 ! {setUp, Jogo},
              User2 ! {line, "inicioDeJogo\n"},
              room( [Jogo|Jogos], lists:delete(User,UsersOff),lists:delete(User2,UsersOn))
          end;
        none ->
          io:format("$ Tag nao reconhecia pela sala ~p~n", [Msg]),
          room(Jogos, UsersOff, UsersOn)
      end;
    {enter, User} ->
      io:format("$ Utilizador entrou na sala~n", []),
      User ! {setUp, self()},
      room(Jogos, [User|UsersOff], UsersOn);
    {leave, Pid} ->
      io:format("$ Utilizador saiu ~n", []),
      room(Jogos, UsersOff -- [Pid], UsersOn -- [Pid]);
    {finnishGame, Game, Time, Winner} ->
      io:format("Terminou partida: Ganhou ~p em ~.2f segundos!! ~n", [Winner,Time/1000]),
      Username = getUsername(Winner),
      accounts ! {registeVictory, Username, Time},
      room( Jogos -- [Game], UsersOff, UsersOn)
  end.

partida(Estado, Pid1, Pid2, Time) ->
  receive
    {line, Pid1, Data} ->
      {Jog1, Jog2, B, Ms} = Estado,
      NewEstado = { makeMoviment(Jog1, Data), Jog2, B, Ms},
      partida(NewEstado, Pid1,Pid2, Time);
    {line, Pid2, Data} ->
      {Jog1, Jog2, B, Ms } = Estado,
      NewEstado = {Jog1, makeMoviment(Jog2, Data), B, Ms},
      partida(NewEstado, Pid1, Pid2,Time);
    {leave, Pid1} ->
      room ! {enter, Pid2},
      Pid2 ! {line, "fim winner\n"},
      Time ! {finnishGame},
      receive {time, Res} -> true end,
      room ! {finnishGame, self(), Res, Pid2 };
    {leave, Pid2} ->
      room ! {enter, Pid1},
      Pid1 ! {line, "fim winner\n"},
      Time ! {finnishGame},
      receive {time, Res} -> true end,
      room ! {finnishGame, self(), Res, Pid1 };
    {createMonster} ->
      partida( addMonster( Estado), Pid1, Pid2, Time);
    {changeDirectionEnergy} ->
      {Jog1, Jog2, B, Ms } = Estado,
      Bnew = applyNewDirection(B),
      partida( {Jog1, Jog2, Bnew, Ms }, Pid1, Pid2, Time)
  after 15 ->
      {NewEstado, Coll1, Coll2 } = action( Estado),
      Pid1 ! {line, estado2String(NewEstado)},
      Pid2 ! {line, estado2String(NewEstado)},
      case Coll1  or Coll2 of
        true ->
          room ! {enter, Pid1},
          room ! {enter, Pid2},
          Time ! {finnishGame},
          receive {time, Res} -> true end,
          case Coll1 of
            true ->
              room ! {finnishGame, self(), Res, Pid2},
              Pid1 ! {line, "fim loser\n"},
              Pid2 ! {line, "fim winner\n"};
            false->
              room ! {finnishGame, self(), Res, Pid1},
              Pid1 ! {line, "fim winner\n"},
              Pid2 ! {line, "fim loser\n"}
          end;
        false ->
          partida(NewEstado, Pid1,Pid2, Time)
      end
  end.

% um processo por cliente
user(Sock, Father) ->
  receive
    {setUp, NewFather}->
      user(Sock, NewFather);
    {line, Data} ->
      gen_tcp:send(Sock, Data),
      user(Sock, Father);
    {makeLogin} ->
      makeLogin(Sock),
      user(Sock, Father);

    {tcp, _, Data} ->
      Father ! {line, self(), Data},
      user(Sock, Father);
    {tcp_closed, _} ->
      Father ! {leave, self()},
      pids   ! {close, self()};
    {tcp_error, _, _} ->
      Father ! {leave, self()},
      pids   ! {close, self()}
  end.

allPids(Map) ->
  receive
    {create, Pid, Username} ->
      allPids( maps:put(Pid, Username, Map));
    {close, Pid} ->
      allPids( maps:remove(Pid, Map));
    {getList, Pid} ->
      Pid ! {number, maps:size(Map)},
      allPids(Map);
    {getUsername, User, Pid} ->
      Pid ! {user, maps:get(User, Map)},
      allPids(Map)
    end.


%------- Funcoes auxiliares -------------
%recebe Lista de Pids!!!
procuraUser( [] , _) -> none;
procuraUser( [H|T], UserNivel) ->
  {Nivel,_,_,_} = getInfo(getUsername(H)),
  case (Nivel == UserNivel)  or (Nivel + 1 == UserNivel) or (Nivel == UserNivel +1) of
    true -> H;
    false -> procuraUser(T, UserNivel)
  end.


novoJogo(User1, User2) ->
  Time = spawn( fun() -> time(1,0) end),
  Estado = { {100,{0,0,0},{100,100,1,1}},  {100,{0,0,0},{800,800,-1,-1}}, {450,450, 1, 1}, []},
  Jogo = spawn( fun() -> partida( Estado, User1, User2, Time) end),
  Time ! {setUp, Jogo},
  Jogo.

getUsername(Pid) ->
  pids ! {getUsername, Pid, self()},
  receive {user, UserName} -> UserName end.

info2String({Nivel, Vit, Pontos, TopPoints}) ->
  String1 = lists:flatten(io_lib:format("~p ~p", [Nivel, Vit])),
  [P1,P2,P3,P4,P5] = Pontos,
  String2 = lists:flatten(io_lib:format("~p ~p ~p ~p ~p", [P1,P2,P3,P4,P5])),
  String1 ++ " " ++ String2 ++ " " ++  top2String(TopPoints) ++ "\n".

top2String([]) -> "";
top2String( [{X,Y}|L] ) ->
  lists:flatten(io_lib:format("~s ~p ", [X,Y])) ++ top2String(L).

string2Atom(String) ->
  Data = string:trim(String),
  case string:equal(Data,"logout") of
    true -> logout;
    false ->
      case string:equal(Data,"info") of
        true -> info;
        false ->
          case string:equal(Data,"close_account") of
            true -> close_account;
            false ->
              case string:equal(Data,"play") of
                true -> play;
                false -> none
              end
          end
      end
  end.
