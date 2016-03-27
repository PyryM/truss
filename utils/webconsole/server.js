var port = 8087;
var WebSocketServer = require('ws').Server
  , wss = new WebSocketServer({ port: port });

var trussConnection = null;
var clientConnections = {};

function sendToTruss(msg){
  if(trussConnection && 
      trussConnection.readyState == trussConnection.OPEN){
      trussConnection.send(msg);
  }
}

function sendToClients(msg) {
  for(var cname in clientConnections) {
    var currconn = clientConnections[cname];
    if(currconn.readyState == currconn.OPEN) {
      currconn.send(msg);
    } else {
      console.log("Puring connection " + cname);
      delete clientConnections[cname];
    }
  }
}

wss.on('connection', function connection(ws) {
  var cname = ws._socket.remoteAddress + ":" +
              ws._socket.remotePort;

  ws.on('message', function incoming(message) {
    var jdata = JSON.parse(message);
    if(jdata.source == "truss") {
      trussConnection = ws;
      sendToClients(message);
    } else if(jdata.source == "client") {
      clientConnections[cname] = ws;
      sendToTruss(message);
    }

    console.log('received: %s', message);
  });
});

console.log("Serving on port " + port);