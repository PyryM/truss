$(function(){
    initCodeMirror();
    connectToServer();
});

var repl = null;
var connection = null;

function remoteEval(code) {
    if(connection != null) {
        var msg = {
            source: "console",
            mtype: "eval",
            code: code
        }
        connection.send(JSON.stringify(msg));
    } else {
        repl.print("[NO CONNECTION]");
    }
}

function replLog(message, topic) {
    $('<div class="log-' + topic + '">[' + topic + '] ' +
        message +
        '</div>').appendTo("#log-column");
}

function connectToServer() {
    connection = new WebSocket("ws://localhost:8087");

    connection.onopen = function (event) {
        var msg = {
            source: "console",
            mtype: "ping"
        } 
        connection.send(JSON.stringify(msg));
        repl.print("[server connection opened]");
    }

    connection.onmessage = function (event) {
        console.log(event.data);
        var jdata = JSON.parse(event.data);
        if(jdata.mtype == "print") {
            repl.print(jdata.message);
        } else if(jdata.mtype == "log") {
            replLog(jdata.message, jdata.topic);
        }
    }

    connection.onclose = function (event) {
        repl.print("[server connection closed: " + event.reason + "]");
        connection = null;
    }
}

function bracketsBalanced(code) {
    var length = code.length;
    var delimiter = '';
    var brackets = [];
    var matching = {
        ')': '(',
        ']': '[',
        '}': '{'
    };

    for (var i = 0; i < length; i++) {
        var char = code.charAt(i);

        switch (delimiter) {
        case "'":
        case '"':
        default:
            switch (char) {
            case "'":
            case '"':
                delimiter = char;
                break;
            case "(":
            case "[":
            case "{":
                brackets.push(char);
                break;
            case ")":
            case "]":
            case "}":
                if (!brackets.length || matching[char] !== brackets.pop()) {
                    repl.print(new SyntaxError("Unexpected closing bracket: '" + char + "'"), "error");
                    return null;
                }
            }
        }
    }

    return brackets.length ? false : true;
}

function doEndBalanced(code) {
    var startTokens = new Set(["function", "do"]);
    var endTokens = new Set(["end"]);

    codeTokens = code.split(/\s+/);
    var nestLevel = 0;
    var curtoken;

    for(var i = 0; i < codeTokens.length; ++i) {
        curtoken = codeTokens[i];
        if(startTokens.has(curtoken)) {
            nestLevel += 1;
        } else if(endTokens.has(curtoken)) {
            nestLevel -= 1;
        }

        // allow !! to break out of a multiline entry
        if(curtoken == "!!") {
            return null;
        }

        // unrecoverable situation like "do [...] end end"
        if(nestLevel < 0) {
            return null;
        }
    }

    return (nestLevel == 0);
}

function initCodeMirror() {
    var geval = eval;

    repl = new CodeMirrorREPL("repl", {
        mode: "lua",
        theme: "dracula"
    });

    window.print = function (message, mclass) {
        repl.print(message, mclass || "message");
    };

    repl.isBalanced = function (code) {
        var b0 = bracketsBalanced(code);
        var b1 = doEndBalanced(code);
        if(b0 == null || b1 == null) {
            return null;
        } else {
            return b0 && b1;
        }
    };

    repl.eval = function (code) {
        remoteEval(code);
    };

    function isExpression(code) {
        if (/^\s*function\s/.test(code)) return false;

        try {
            Function("return " + code);
            return true;
        } catch (error) {
            return false;
        }
    }

    function express(value) {
        if (value === null) var type = "Null";
        else if (typeof value === "Undefined") var type = "Undefined";
        else var type = Object.prototype.toString.call(value).slice(8, -1);

        switch (type) {
        case "String":
            value = '"' + value.replace('\\', '\\\\').replace('\0', '\\0').replace('\n', '\\n').replace('\r', '\\r').replace('\t', '\\t').replace('\v', '\\v').replace('"', '\\"') + '"';
        case "Number":
        case "Boolean":
        case "Function":
        case "Undefined":
        case "Null":
            repl.print(value);
            break;
        case "Object":
        case "Array":
            repl.print(JSON.stringify(value, 4));
            break;
        default:
            repl.print(value, "error");
        }
    }
}
