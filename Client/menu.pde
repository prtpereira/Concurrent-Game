class Menu{

  public int nivel, vitorias;
  public float pontos[];
  public float topScore[];
  public String topUser[];
  

  void drawMenu(){
    text("1-Search game\n2-Logout\n3-Remove account",133,750);
      // resultados
      int aux = 0;
      int delta = 40;
      int base = 250;
      for(int i = 1; i < nivel; i ++) aux += i;
      aux =+ vitorias;
      text("Nivel: " + nivel, 250,base);
      text("Vitorias: " + aux, 250,base + delta);
      text("My top score: " + pontos[0] + ", " + pontos[1] + ", " +pontos[2] + ", " + pontos[3] + ", " + pontos[4],250, base + 2*delta);
      text("TOP SCORE", 250, base +3*delta);
      for(int i = 0; i < 5; i ++)
        text(topScore[i] + " by " + topUser[i], 250 + 20, base + (4+i)*delta);
    }

  void keyPressedMenu(){
     switch( key){
       case '1':
         estado = 2;
         c.sendMessage("play");
         break;
       case '2':
         c.sendMessage("logout");
         estado = 0;
         break;
       case '3':
         c.sendMessage("close_account");
         estado = 0;
         break;
    }
  }

}

class Login{
  int state = -1;
  String username= "";
  String password = "";
  String res = "";
  boolean isLogin;  // false -> significa que é create
  
  void reset(){
    username = "";
    password = "";
    res = "";
    state = -1;
    
  }

  void drawLogin(int x, int y) {
    switch (state) {
    case -1:
      fill(0);
      text("Press: \n1- Create new account\n2- Login", x, y);
      break;
    case 0:
      fill(0);
      text ("Username:\n"+username +"_", x, y);
      break;
    case 1:
      fill(0);
      text ("Password: \n"+password +"_", x, y);
      break;
    case 2:
      if( isLogin && res.equals("accept") ){
        estado = 1;
        c.sendMessage("info");
        string2estado( c.getEstado());
        reset();
      }
      else{
       fill(255, 2, 2);
       text(res, x, y);
      }
      break;
    }
  }

  void keyPressedLogin() {
    switch( state){
      case -1:
        isLogin =  key == '2';
        state ++;
        break;
      case 0:
        if (key == ENTER) {
          state++;
        } else if( key==BACKSPACE && username.length()>0){
          username = username.substring(0, username.length()-1);
        }else if( key != BACKSPACE)  username = username + key;
        break;
      case 1:
        if (key==ENTER) {
          if( username.length() == 0 || password.length() == 0){
            res = "Username or password invalid";
            state ++;
            break;
          }
          //enviar info para o servidor
          if(isLogin) c.sendMessage("login " + username + " " + password);
          else c.sendMessage("create " + username + " " +  password);
          
          // guarda resposta em "res"
          res = c.getEstado();
          state ++;
        } else if( key==BACKSPACE && password.length()>0){
          password = password.substring(0, password.length()-1);
        }else if( key != BACKSPACE)  password = password + key;
        break;
       case 2:
         state = -1;
         password ="";
         username = "";
         break;
    }
  }
}
