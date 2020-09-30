-module(motor).
-export( [action/1, makeMoviment/2, estado2String/1, time/2,addMonster/1, applyNewDirection/1]).

%--------- Alteracao da posicao --------------
% return {Estado,info}
action( Estado) ->
  NewEstado = movePlayers(Estado),
  NewNewEstado = moveMonsters(NewEstado),
  verifyCollisions(NewNewEstado).

% return newEstado
movePlayers( {Jog1, Jog2, B, Ms} ) ->
  {Ener1, Mov1, Pos1} = Jog1,
  {Ener2, Mov2, Pos2} = Jog2,
  NewPos1 = calcPos(Mov1,Pos1),
  NewPos2 = calcPos(Mov2,Pos2),
  { {Ener1, Mov1, NewPos1}, {Ener2, Mov2, NewPos2}, B, Ms}.

%return Pos
calcPos( Mov, Pos) ->
  {Px, Py, Dx, Dy} = Pos,
  { Rot, Mx, My} = Mov,
  Cos = math:cos(Rot),
  Sin = math:sin(Rot),
  {Px + Mx, Py + My, Cos*Dx - Sin*Dy, Sin*Dx + Cos*Dy }.


%---------- Alteracao do Movimento -----------
% Return new Jog
makeMoviment( Jog, Action ) ->
  { Ener, Mov, Pos} = Jog,
  case Ener > 2 of
    true ->
      NewMov = calcMov( Mov, Pos, Action),
      {Ener -2, NewMov, Pos};
    false ->
      Jog
  end.

%return Mov
calcMov( {Rot ,X, Y}, Pos, Action) ->
  %io:format("Gajo fez: ~s ~n", [Action]),
  case string:equal(Action,"direita\n")  of
    true ->
      { Rot +0.01, X, Y };
    false ->
      case  string:equal(Action,"esquerda\n") of
        true ->
          { Rot - 0.01,X, Y};
        false ->
          case  string:equal(Action,"frente\n") of
            true ->
              { _ , _, Dx, Dy} = Pos,
              {Rot, Dx + X, Dy + Y};
            false ->
              case  string:equal(Action,"hack\n") of
                true ->
                  {0,0,0};
                false ->
                  io:format("Erro: Action nao reconhecida ~n"),
                  {Rot,X,Y}
              end
          end
      end
  end.


%----------- Estado to string -----------------
%return String
estado2String(Estado) ->
  {Jog1, Jog2, {X,Y, _, _}, Ms} = Estado,
  jog2String(Jog1) ++ "   "
                   ++ jog2String(Jog2) ++ "   "
                   ++ lists:flatten(io_lib:format("~p ~p", [X,Y])) ++ "  "
                   ++ monstros2String(Ms) ++ "\n".

%return String
jog2String(Jog)->
  { Ener,  _ , {Px,Py,Dx,Dy} } = Jog,
  lists:flatten(io_lib:format("~p ~p ~p ~p ~p", [Px,Py,Dx,Dy, Ener])).

%return string
monstros2String( [] ) -> "";
monstros2String( [ {X,Y} | Ms ] ) ->
  String = lists:flatten(io_lib:format("~p ~p", [X,Y])),
  String ++ " " ++ monstros2String(Ms).


%------------- Monstros ---------------
%return estado
addMonster( Estado) ->
  {Jog1, Jog2, B, Ms} = Estado,
  M = {rand:uniform(900), rand:uniform(900)},
  {Jog1, Jog2, B,  [M|Ms]}.

%return newEstado
moveMonsters( {Jog1, Jog2, B, [] }  ) ->
  {Jog1, Jog2, moveMonster(B), [] };

moveMonsters( {Jog1, Jog2, B, [M|Ms]} )->
  {_ ,_ , NewB, Res } = moveMonsters( {Jog1, Jog2, B, Ms} ),
  NewM = moveMonster(Jog1, Jog2, M),
  { Jog1, Jog2, NewB, [NewM|Res] }.

%return Monster
moveMonster( {X, Y, Movx, Movy}) ->

    case X+Movx<20 of
      true -> Nmx = 20;
      false ->
        case X+Movx>880 of
          true -> Nmx = 880;
          false -> Nmx = X+Movx
        end
    end,

    case Y+Movy<20 of
      true -> Nmy = 20;
      false ->
        case Y+Movy>880 of
          true -> Nmy = 880;
          false -> Nmy = Y+Movy
        end
    end,

    {Nmx , Nmy, Movx, Movy}.

applyNewDirection(B) ->
  {X, Y, _, _} = B,

  Movx=-1+rand:uniform(20)/10,
  Movy=-1+rand:uniform(20)/10,

  {X, Y, Movx, Movy}.

moveMonster( Jog1, Jog2, {X, Y}) ->
  {_ , _ , {X1,Y1,_,_}} = Jog1,
  {_ , _ , {X2,Y2,_,_}} = Jog2,
  case dist({X1,Y1}, {X,Y}) > dist({X2,Y2},{X,Y}) of
    true ->
      {Movx,Movy} = normalize({X2 -X, Y2 - Y});
    false ->
      {Movx,Movy} = normalize( {X1-X,Y1-Y})
  end,
  { X + Movx, Y + Movy}.

normalize( { X , Y }) ->
  Len = math:sqrt(X*X + Y*Y),
  { X/Len, Y/Len}.

dist( {A,B}, {C,D} ) ->
  X = A - C,
  Y = B - D,
  math:sqrt(X*X + Y*Y).


%-------------- Tempo --------------
time( Time, Jogo) ->
  case math:fmod(Time, 10000) of
    0.0 -> Jogo ! {createMonster};
    _ -> true
  end,
  case math:fmod(Time, 3000) of
    0.0 -> Jogo ! {changeDirectionEnergy};
    _ -> true
  end,
  receive
    {setUp, NewJogo} ->
      time(0, NewJogo);
    {finnishGame} ->
      Jogo ! {time, Time}
  after 500 ->
    time( Time + 500, Jogo)
  end.

%------------ Collisions ------------


verifyCollisions({Jog1, Jog2, B, Ms}) ->

  {_, _, Pos1} = Jog1,
  {_, _, Pos2} = Jog2,

  {Jog1r, Jog2r} = verifyRepulsion(Jog1,Jog2),

  {Jog1a, Jog2a, Bnew} = collideEnergy(Jog1r, Jog2r, B),

  {C1, C2} = collideMonster(Jog1a, Jog2a, Ms),

  Out1 = isOutsideArena(Pos1),
  Out2 = isOutsideArena(Pos2),


  {{Jog1a, Jog2a, Bnew, Ms}, Out1 or C1 , Out2 or C2}.


verifyRepulsion(Jog1, Jog2) ->

    {Ener1, {Rot1, Mx1, My1}, {Px1, Py1, Dx1, Dy1}} = Jog1,
    {Ener2, {Rot2, Mx2, My2}, {Px2, Py2, Dx2, Dy2}} = Jog2,


    Ddist = dist( {Px1,Py1}, {Px2,Py2} ) < 100,

    case Ddist of
      false -> {Mx2n, My2n} = {Mx2, My2},
              {Mx1n, My1n} = {Mx1, My1};
      true ->  {Mx2n, My2n} = applyRepulsion({Px1,Px2,Py1,Py2},{Dx1, Dy1, Mx1, My1}),
               {Mx1n, My1n} = applyRepulsion({Px2,Px1,Py2,Py1},{Dx2, Dy2, Mx2, My2})
    end,


    {{Ener1, {Rot1, Mx1n, My1n}, {Px1, Py1, Dx1, Dy1}}, {Ener2, {Rot2, Mx2n, My2n}, {Px2, Py2, Dx2, Dy2}}}.



applyRepulsion({Px1,Px2,Py1,Py2},{_, _, _, _}) ->

    Fact=0.8/math:sqrt( ((Px1-Px2)*(Px1-Px2))+((Py1-Py2)*(Py1-Py2)) ),
    {((Px2-Px1) * Fact), ((Py2-Py1) *Fact)}.


isOutsideArena(Pos) ->
  {Px, Py, _, _} = Pos,
  (Px>880) or (Py>880) or (Px<20) or (Py<20).


%retorna {Jog1, Jog2, B}
collideEnergy(Jog1, Jog2, B) ->

  {Jog1a, Bnew} = tryGetEnergy(Jog1, B),
  {Jog2a, Bnewnew} = tryGetEnergy(Jog2, Bnew),
  {Jog1a, Jog2a, Bnewnew}.


tryGetEnergy( {Ener, Mov, {Px, Py, Dx, Dy}}, {Xb, Yb, Movx, Movy} ) ->

  Dist = math:sqrt( ((Px-Xb)*(Px-Xb))+((Py-Yb)*(Py-Yb)) ),

  case (Dist=<40) of
    true -> Ener1=100,
          {Xba, Yba} = {rand:uniform(900),rand:uniform(900)};
     _ -> Ener1=Ener,
          {Xba, Yba} = {Xb,Yb}
  end,

  { {Ener1, Mov, {Px, Py, Dx, Dy} }, {Xba, Yba, Movx, Movy} } .


collideMonster(Jog1, Jog2, Ms) ->

  C1 = verifyCollideMonster(Jog1, Ms),
  C2 = verifyCollideMonster(Jog2, Ms),

  {C1,C2}.


verifyCollideMonster(_, []) ->
  false;

verifyCollideMonster(Jog, [{Xm,Ym}|Ms]) ->

  {_, _, {Px, Py, _, _}} = Jog,
  Dist = math:sqrt( ((Px-Xm)*(Px-Xm))+((Py-Ym)*(Py-Ym)) ),

  case (Dist=<40) of
    true -> true;
     _ -> verifyCollideMonster(Jog, Ms)
  end.
