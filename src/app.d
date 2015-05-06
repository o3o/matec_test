import std.getopt;
import std.stream;
import std.stdio;
import std.array;
import std.socket;
import std.socketstream;

/**
  Si collega alla stampate matec con indirizzo ip domain e chiedo lo stato
 */
int main(string[] args) {
   printHelp();

   string domain = "192.168.223.11";
   ushort port = 30000;
   getopt(args
         , "i", &domain
         , "p", &port);

   writefln("Connecting to %s on port %d...", domain, port);

   Socket sock = new TcpSocket(new InternetAddress(domain, port));
   scope(exit) sock.close();

   Stream ss = new SocketStream(sock);

   string cmd;
   while (cmd != "q") {
      write(">");
      readf(" %s\n", &cmd);
      if (cmd == "q") {
         break;
      } else if (cmd == "h") {
         printHelp();
      } else if (cmd == "s") {
         queryStatus(ss);
      } else if (cmd == "p") {
         send(ss);
      } else {
         ss.writeString(cmd ~ "\r\n");
         auto line = ss.readLine();
         writeln(line);
      }
   }
   return 0;
}

void printHelp() {
   writeln("Using:");
   writeln("\t matec_test -i <ip_address> -p <port>");

   writeln();
   writeln("Command");
   writeln("--------");

   writeln("<cmd>: raw send <cmd> to Matec");
   writeln("p: print label `fixed.label`");
   writeln("s: query matec status");
   writeln("q: quit");
   writeln("h: this help");
}

/**
 * Invia l'etichetta fixed.label alla stampante
 */
void send(Stream stream) {
   writeln("send");
   auto f = std.stdio.File("fixed.label");
   stream.writeString("^@\r\n");
   foreach (line; f.byLine()) {
      stream.writeString(line ~ "\r\n");
   }
   writeln("done");
}

private void queryStatus(Stream ss) {
   const string QUERY_STATUS =  "^?\r\n";
   ss.writeString(QUERY_STATUS);
   auto line = ss.readLine();
   writeln(line);
   printStatus(cast(string)line);
   writeln();
   printOK(cast(string)line);
}

private void printStatus(string line) {
   switch (line[1]) {
      case '0':
         writeln("Non in corso");
         break;
      case '1':
         writeln("Marcatura in corso");
         break;
      case '2':
         writeln("Marcatura in corso etich. su tampone");
         break;
      case '3':
         writeln("Elab. in corso");
         break;
      default:
         writeln("??");
         break;
   }
}

private void printOK(string line) {
   switch (line[5]) {
      default:
      case '0':
         writeln("OK");
         break;
      case '1':
         writeln("Anomalia");
         break;
   }
}
