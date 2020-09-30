import java.io.*;
import java.net.*;
import java.util.Scanner;

class Client {
  private BufferedReader in;
  private PrintWriter  out;

  Client(String host, int port){
    try{
      Socket s = new Socket(host, port);
      in = new BufferedReader(new InputStreamReader( s.getInputStream()));
      out = new PrintWriter(s.getOutputStream());
    }catch( Exception e){ System.out.println("Erro ao ligar ao servidor"); }
  }

  public String getEstado(){
    try{
      String res = in.readLine();
      while( in.ready()){
        res = in.readLine();
      }
      return res;
    }catch( Exception e){ return "Nao consegui receber estado"; }
  }

  boolean haveMessage(){
    try{
      return in.ready();
    }catch( Exception e){ return false; }
  }

  public void sendMessage( String msg){
    out.println(msg);
    out.flush();
  }

}
