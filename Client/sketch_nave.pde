import java.util.Scanner;  //<>//
import java.util.ArrayList;

Nave n1, n2;
Client c;
Menu menu;
Login login;
PImage bg;
ArrayList<Monster> monstros;
int estado;
    /* 0 -> fazer login
       1 -> Menu
       2 -> Procurando partida
       3 -> Jogando
   */
String result;

void setup() {
  bg = loadImage("bgGame.jpg");
  size(900, 900);
  textSize(26);
  monstros = new ArrayList<Monster>();
  estado = 0;
  n1 = new Nave("sp2.png"); 
  n2 = new Nave("sp1.png");

  c = new Client("localhost", 12345);

  menu = new Menu();
  login = new Login();

  result = "";
}

void draw() {
  background(255);
  switch( estado ){
    case 0:
      login.drawLogin(300,300);
      break;
    case 1:
      fill(0);
      menu.drawMenu();
      if( result != "") text("-- " + result + " --", 400,50);
      break;
    case 2:
      text("searching....", 20, 40);
      if( c.haveMessage() )  string2estado(c.getEstado());
      break;
    case 3:
     background(0);
      desenhaJogo();
      break;
  }
}

void desenhaJogo(){
  try {
    background(bg);
    
    String estado = c.getEstado();
    string2estado(estado);

    n1.desenha();
    n2.desenha();

    for ( Monster m : monstros) m.desenha();

    String output = String.format("Energia: %d   Energia: %d", n1.energia, n2.energia );
    text(output, 10, 30);
  }catch( Exception e) {
    System.out.println("Erro no render ( func desenhaJogo): " + e);
    System.exit(-1);
  }
}

void keyPressed() {
  if( estado == 0) login.keyPressedLogin();
  if( estado == 1) menu.keyPressedMenu();
  if( estado == 3){
    if (keyCode == UP) {
      c.sendMessage("frente");
    } else if (keyCode == LEFT) {
      c.sendMessage("esquerda");
    } else if (keyCode == RIGHT) {
      c.sendMessage("direita");
    }
  }
}

void string2estado(String e) {
  float x, y;
  
  e = e.replace('.',',');
  
  Scanner scanner = new Scanner(e);
  
  if(scanner.hasNext("fim")){ // menu == 3
      scanner.next();
      result = scanner.next();
      estado = 1;  
      c.sendMessage("info");
      string2estado( c.getEstado());
      scanner.close();
      return ;
  }
  if( scanner.hasNext("inicioDeJogo")){ //menu == 2
    scanner.next();
    estado = 3;
    scanner.close();
    return ;
  }
  if( estado == 1){
    System.out.println(e);
    menu.nivel = scanner.nextInt();
    menu.vitorias = scanner.nextInt();
    menu.pontos = new float[5];
    menu.topUser = new String[5];
    menu.topScore = new float[5];
    for(int i = 0; i < 5; i++){ menu.pontos[i] = scanner.nextFloat(); }
    for(int i = 0; i < 5; i++){ menu.topUser[i] = scanner.next(); menu.topScore[i] = scanner.nextFloat();}
    scanner.close();
    return ;
  }

  // Le jogador 1
  x = scanner.nextFloat();
  y = scanner.nextFloat();
  n1.setPosicao(x, y);

  x = scanner.nextFloat();
  y = scanner.nextFloat();
  n1.setDirecao(x, y);

  int ener = scanner.nextInt();
  n1.setEnergia(ener);


  // Le jogador 2
  x = scanner.nextFloat();
  y = scanner.nextFloat();
  n2.setPosicao(x, y);

  x = scanner.nextFloat();
  y = scanner.nextFloat();
  n2.setDirecao(x, y);

  ener = scanner.nextInt();
  n2.setEnergia(ener);

  //Le Monstros
  monstros.clear();
  float a = scanner.nextFloat();
  float b = scanner.nextFloat();
  monstros.add( new Monster(1,a,b) );

  while ( scanner.hasNextFloat()){
    a = scanner.nextFloat();
    b = scanner.nextFloat();
    monstros.add( new Monster(0,a,b) );
  }
  scanner.close();
}
