var port = 8087;
var WebSocketServer = require('ws').Server
  , wss = new WebSocketServer({ port: port });

var trussConnection = null;
var clientConnections = {};

function sendToTruss(msg){
  if(trussConnection && 
      trussConnection.readyState == trussConnection.OPEN){
      trussConnection.send(msg);
  } else {
    var jmsg = {"source": "server",
                "mtype": "print",
                "message": "[no remote connection]"};
    sendToClients(JSON.stringify(jmsg));
  }
}

function sendToClients(msg) {
  for(var cname in clientConnections) {
    var currconn = clientConnections[cname];
    if(currconn.readyState == currconn.OPEN) {
      currconn.send(msg);
    } else {
      console.log("Purging connection " + cname);
      delete clientConnections[cname];
    }
  }
}

wss.on('connection', function connection(ws) {
  var cname = ws._socket.remoteAddress + ":" +
              ws._socket.remotePort;

  ws.on('message', function incoming(message) {
    var jdata = JSON.parse(message);
    if(jdata.source == "host") {
      trussConnection = ws;
      if(jdata.mtype != "ping") {
        sendToClients(message);
      }
    } else if(jdata.source == "console") {
      clientConnections[cname] = ws;
      if(jdata.mtype != "ping") {
        sendToTruss(message);
      }
    }

    console.log('received: %s', message);
  });
});

console.log("Serving on port " + port);