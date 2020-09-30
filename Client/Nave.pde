class Nave {
  PVector posicao;
  PVector direcao;
  int energia;
  PImage inave;
  int r = 40;
  int _r = 255, _g = 255, _b = 255;
    
  Nave(String skin){
    posicao = new PVector(0.0,0.0);
    direcao = new PVector(0.0,0.0);
    energia = 0;
    inave=loadImage(skin);
  }
  
  public void desenha() {
    pushMatrix();
    translate(posicao.x, posicao.y);
    rotate( direcao.heading() );
    fill(_r, _g, _b);
    image(inave,-25,-25);
    //ellipse(0,0, r, r);
    //triangle(r,0,0,-10, 0,10);
    popMatrix();
  }
  
  public void setPosicao(float x, float y) {
    posicao.x = x;
    posicao.y = y;
  }
  public void setDirecao(float x, float y) {
    direcao.x = x;
    direcao.y = y;
  }
  public void setEnergia(int e){
    energia = e;
  }
  
}

class Monster{
  PVector posicao;
  int type;
  PImage imonster;
  
  int r = 40;
  
  Monster(int t, float x, float y){ 
    posicao = new PVector(x,y);
    type = t;
  }
  
  void setPosicao(float x, float y){
    posicao.x = x;
    posicao.y = y;
  }
  
  void desenha(){
    pushMatrix();
    translate(posicao.x, posicao.y);
    if( type==0 ) fill( 255, 0, 0);
    else fill(0,255,0);
    ellipse(0,0, r, r); 
    fill(255,255,255);
    popMatrix();
  } 
}
