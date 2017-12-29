-- io/zmq.t
--
-- zeromq bindings

local modutils = require("core/module.t")
local class = require("class")
local m = {}

-- header is cropped from the libzmq header "zmq.h"
-- lgpl license
-- available: https://github.com/zeromq/libzmq
local header = [[
  #include <stddef.h>

  int zmq_errno (void);
  const char *zmq_strerror (int errnum);
  void zmq_version (int *major, int *minor, int *patch);

  #define ZMQ_IO_THREADS  1
  #define ZMQ_MAX_SOCKETS 2
  #define ZMQ_SOCKET_LIMIT 3
  #define ZMQ_THREAD_PRIORITY 3
  #define ZMQ_THREAD_SCHED_POLICY 4
  #define ZMQ_MAX_MSGSZ 5
  #define ZMQ_IO_THREADS_DFLT  1
  #define ZMQ_MAX_SOCKETS_DFLT 1023
  #define ZMQ_THREAD_PRIORITY_DFLT -1
  #define ZMQ_THREAD_SCHED_POLICY_DFLT -1

  void *zmq_ctx_new (void);
  int zmq_ctx_term (void *context);
  int zmq_ctx_shutdown (void *context);
  int zmq_ctx_set (void *context, int option, int optval);
  int zmq_ctx_get (void *context, int option);

  typedef struct zmq_msg_t {
      unsigned char _ [64];
  } zmq_msg_t;

  typedef void (zmq_free_fn) (void *data, void *hint);

  int zmq_msg_init (zmq_msg_t *msg);
  int zmq_msg_init_size (zmq_msg_t *msg, size_t size);
  int zmq_msg_init_data (zmq_msg_t *msg, void *data,
      size_t size, zmq_free_fn *ffn, void *hint);
  int zmq_msg_send (zmq_msg_t *msg, void *s, int flags);
  int zmq_msg_recv (zmq_msg_t *msg, void *s, int flags);
  int zmq_msg_close (zmq_msg_t *msg);
  int zmq_msg_move (zmq_msg_t *dest, zmq_msg_t *src);
  int zmq_msg_copy (zmq_msg_t *dest, zmq_msg_t *src);
  void *zmq_msg_data (zmq_msg_t *msg);
  size_t zmq_msg_size (const zmq_msg_t *msg);
  int zmq_msg_more (const zmq_msg_t *msg);
  int zmq_msg_get (const zmq_msg_t *msg, int property);
  int zmq_msg_set (zmq_msg_t *msg, int property, int optval);
  const char *zmq_msg_gets (const zmq_msg_t *msg, const char *property);

  #define ZMQ_PAIR 0
  #define ZMQ_PUB 1
  #define ZMQ_SUB 2
  #define ZMQ_REQ 3
  #define ZMQ_REP 4
  #define ZMQ_DEALER 5
  #define ZMQ_ROUTER 6
  #define ZMQ_PULL 7
  #define ZMQ_PUSH 8
  #define ZMQ_XPUB 9
  #define ZMQ_XSUB 10
  #define ZMQ_STREAM 11

  #define ZMQ_AFFINITY 4
  #define ZMQ_ROUTING_ID 5
  #define ZMQ_SUBSCRIBE 6
  #define ZMQ_UNSUBSCRIBE 7
  #define ZMQ_RATE 8
  #define ZMQ_RECOVERY_IVL 9
  #define ZMQ_SNDBUF 11
  #define ZMQ_RCVBUF 12
  #define ZMQ_RCVMORE 13
  #define ZMQ_FD 14
  #define ZMQ_EVENTS 15
  #define ZMQ_TYPE 16
  #define ZMQ_LINGER 17
  #define ZMQ_RECONNECT_IVL 18
  #define ZMQ_BACKLOG 19
  #define ZMQ_RECONNECT_IVL_MAX 21
  #define ZMQ_MAXMSGSIZE 22
  #define ZMQ_SNDHWM 23
  #define ZMQ_RCVHWM 24
  #define ZMQ_MULTICAST_HOPS 25
  #define ZMQ_RCVTIMEO 27
  #define ZMQ_SNDTIMEO 28
  #define ZMQ_LAST_ENDPOINT 32
  #define ZMQ_ROUTER_MANDATORY 33
  #define ZMQ_TCP_KEEPALIVE 34
  #define ZMQ_TCP_KEEPALIVE_CNT 35
  #define ZMQ_TCP_KEEPALIVE_IDLE 36
  #define ZMQ_TCP_KEEPALIVE_INTVL 37
  #define ZMQ_IMMEDIATE 39
  #define ZMQ_XPUB_VERBOSE 40
  #define ZMQ_ROUTER_RAW 41
  #define ZMQ_IPV6 42
  #define ZMQ_MECHANISM 43
  #define ZMQ_PLAIN_SERVER 44
  #define ZMQ_PLAIN_USERNAME 45
  #define ZMQ_PLAIN_PASSWORD 46
  #define ZMQ_CURVE_SERVER 47
  #define ZMQ_CURVE_PUBLICKEY 48
  #define ZMQ_CURVE_SECRETKEY 49
  #define ZMQ_CURVE_SERVERKEY 50
  #define ZMQ_PROBE_ROUTER 51
  #define ZMQ_REQ_CORRELATE 52
  #define ZMQ_REQ_RELAXED 53
  #define ZMQ_CONFLATE 54
  #define ZMQ_ZAP_DOMAIN 55
  #define ZMQ_ROUTER_HANDOVER 56
  #define ZMQ_TOS 57
  #define ZMQ_CONNECT_ROUTING_ID 61
  #define ZMQ_GSSAPI_SERVER 62
  #define ZMQ_GSSAPI_PRINCIPAL 63
  #define ZMQ_GSSAPI_SERVICE_PRINCIPAL 64
  #define ZMQ_GSSAPI_PLAINTEXT 65
  #define ZMQ_HANDSHAKE_IVL 66
  #define ZMQ_SOCKS_PROXY 68
  #define ZMQ_XPUB_NODROP 69
  #define ZMQ_BLOCKY 70
  #define ZMQ_XPUB_MANUAL 71
  #define ZMQ_XPUB_WELCOME_MSG 72
  #define ZMQ_STREAM_NOTIFY 73
  #define ZMQ_INVERT_MATCHING 74
  #define ZMQ_HEARTBEAT_IVL 75
  #define ZMQ_HEARTBEAT_TTL 76
  #define ZMQ_HEARTBEAT_TIMEOUT 77
  #define ZMQ_XPUB_VERBOSER 78
  #define ZMQ_CONNECT_TIMEOUT 79
  #define ZMQ_TCP_MAXRT 80
  #define ZMQ_THREAD_SAFE 81
  #define ZMQ_MULTICAST_MAXTPDU 84
  #define ZMQ_VMCI_BUFFER_SIZE 85
  #define ZMQ_VMCI_BUFFER_MIN_SIZE 86
  #define ZMQ_VMCI_BUFFER_MAX_SIZE 87
  #define ZMQ_VMCI_CONNECT_TIMEOUT 88
  #define ZMQ_USE_FD 89

  #define ZMQ_MORE 1
  #define ZMQ_SHARED 3

  #define ZMQ_DONTWAIT 1
  #define ZMQ_SNDMORE 2

  #define ZMQ_NULL 0
  #define ZMQ_PLAIN 1
  #define ZMQ_CURVE 2
  #define ZMQ_GSSAPI 3

  #define ZMQ_GROUP_MAX_LENGTH        15

  #define ZMQ_EVENT_CONNECTED         0x0001
  #define ZMQ_EVENT_CONNECT_DELAYED   0x0002
  #define ZMQ_EVENT_CONNECT_RETRIED   0x0004
  #define ZMQ_EVENT_LISTENING         0x0008
  #define ZMQ_EVENT_BIND_FAILED       0x0010
  #define ZMQ_EVENT_ACCEPTED          0x0020
  #define ZMQ_EVENT_ACCEPT_FAILED     0x0040
  #define ZMQ_EVENT_CLOSED            0x0080
  #define ZMQ_EVENT_CLOSE_FAILED      0x0100
  #define ZMQ_EVENT_DISCONNECTED      0x0200
  #define ZMQ_EVENT_MONITOR_STOPPED   0x0400
  #define ZMQ_EVENT_ALL               0xFFFF

  void *zmq_socket (void *, int type);
  int zmq_close (void *s);
  int zmq_setsockopt (void *s, int option, const void *optval,
      size_t optvallen);
  int zmq_getsockopt (void *s, int option, void *optval,
      size_t *optvallen);
  int zmq_bind (void *s, const char *addr);
  int zmq_connect (void *s, const char *addr);
  int zmq_unbind (void *s, const char *addr);
  int zmq_disconnect (void *s, const char *addr);
  int zmq_send (void *s, const void *buf, size_t len, int flags);
  int zmq_send_const (void *s, const void *buf, size_t len, int flags);
  int zmq_recv (void *s, void *buf, size_t len, int flags);
  int zmq_socket_monitor (void *s, const char *addr, int events);
]]

local ERRORS = {
  EINTR = 4,
  EIO = 5,
  ENXIO = 6,
  E2BIG = 7,
  ENOEXEC = 8,
  EBADF = 9,
  ECHILD = 10,
  EAGAIN = 11,
  ENOMEM =  12,
  EACCES = 13,
  EFAULT = 14,
  EOSERR = 15,
  EBUSY = 16,
  EEXIST = 17,
  EXDEV = 18,
  ENODEV = 19,
  ENOTDIR = 20,
  EISDIR = 21,
  EINVAL = 22,
  ENFILE = 23
}

-- link the dynamic library (should only happen once ideally)

truss.link_library("libzmq")
local zmq_c = terralib.includecstring(header)
m.C_raw = zmq_c
local C = {}
modutils.reexport_without_prefix(zmq_c, "zmq_", C)
modutils.reexport_without_prefix(zmq_c, "ZMQ_", C)
m.C = C
m.ERRORS = ERRORS

-- check version compatibility
-- (this is 4.2.4)
local major_int = terralib.new(int32[2])
local minor_int = terralib.new(int32[2])
local patch_int = terralib.new(int32[2])

C.version(major_int, minor_int, patch_int)
m.VERSION = major_int[0] .. "." .. minor_int[0] .. "." .. patch_int[0]
log.info("zmq runtime version: " .. m.VERSION)

if major_int[0] ~= 4 or minor_int[0] < 1 then
  truss.error("Version mismatch: expected 4.2.4 got " .. m.VERSION)
  return {}
end

-- create a context for this thing
local context
function m.init()
  if not context then
    log.info("Creating ZMQ context.")
    context = C.ctx_new()
  end
  return m
end

function m.shutdown()
  if context then
    C.ctx_term(context)
    context = nil
  end
end

local function ok(e, verbose)
  if e == 0 then
    return true
  else
    local err_msg = ffi.string(C.strerror(C.errno()))
    if verbose ~= false then
      log.error("ZMQ: " .. err_msg)
    end
    return false, err_msg
  end
end

local Socket = class("Socket")
m.Socket = Socket

function Socket:init(mode)
  if not context then
    truss.error("Cannot create socket without context!"
             .. " (Did you forget zmq.init()?)")
    return
  end
  self._sock = C.socket(context, mode)
  self._msg = terralib.new(C.msg_t)
  C.msg_init(self._msg)
end

function Socket:recv(block)
  if not self._sock then return -1 end
  local flags = (block and 0) or C.DONTWAIT
  local err = C.msg_recv(self._msg, self._sock, flags)
  if err ~= 0 then err = C.errno() end
  if err == 0 then
    local msg_size = C.msg_size(self._msg)
    local msg_data = C.msg_data(self._msg)
    return msg_size, msg_data
  elseif err == ERRORS.EAGAIN then
    return 0
  else -- an actual unexpected error
    local errmsg = ffi.string(C.strerror(err))
    return false, errmsg
  end
end

function Socket:recv_string(block)
  local msg_size, msg_data = self:recv(block)
  if msg_size and msg_data then
    return ffi.string(msg_data, msg_size)
  else
    return nil
  end
end

function Socket:send(data, data_len)
  if not self._sock then return end
  return ok(C.send(self._sock, data, data_len, 0))
end

function Socket:send_string(s)
  return self:send(s, #s)
end

function Socket:bind(url)
  if not self._sock then return end
  return ok(C.bind(self._sock, url))
end

function Socket:connect(url)
  if not self._sock then return end
  return ok(C.connect(self._sock, url))
end

function Socket:unbind(url)
  if not self._sock then return end
  return ok(C.unbind(self._sock, url))
end

function Socket:disconnect(url)
  if not self._sock then return end
  return ok(C.disconnect(self._sock, url))
end

function Socket:close()
  if self._sock then
    C.close(self._sock)
    self._sock = nil
  end
  if self._msg then
    C.msg_close(self._msg)
    self._msg = nil
  end
  return true
end

local ReplySocket = Socket:extend("ReplySocket")
m.ReplySocket = ReplySocket

function ReplySocket:init(url, handler)
  ReplySocket.super.init(self, C.REP)
  self:bind(url)
  self._handler = handler
end

function ReplySocket:update()
  local msg_size, msg_data = self:recv(block)
  if msg_size and msg_size > 0 then
    local datasize, data = self._handler(msg_size, msg_data)
    self:send(data, datasize)
  end
end

return m
