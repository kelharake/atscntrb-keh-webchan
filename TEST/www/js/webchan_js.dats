
staload "$PATSHOMELOCS/atscntrb-keh-webchan/SATS/webchan.sats"

%{^

function channel_send_ws(obj, v) {
  obj.ws.send(v)
}


function console_log(str) {
  console.log(str);
}

function webchanjs_create(addr, fn) {
  var obj = {
    ws: null,
    cbs: [],
    messages: [],
    waiting: null
  };
  var ws = new WebSocket(addr);
  obj.ws = ws;
  ws.onmessage = function(x) {
    if (obj.cbs.length == 0) {
      obj.messages.push(x);
    } else {
      var f = obj.cbs.shift();
      f(x);
    }
  };
  ws.onopen = function() { fn(obj); };
}


function channel_receive_ws_int_cb(obj, f) {
  if (obj.messages.length == 0) {
    obj.cbs.push(function(x) { f(parseInt(x.data)); });
  } else {
    var msg = obj.messages.pop();
    f(parseInt(msg.data));
  }
}

function channel_receive_ws_int(obj) {
  while (obj.messages.length == 0);
  var msg = obj.messages.pop();
  return parseInt(msg.data);
}

function prompt_int(msg, v) {
  return parseInt(prompt(msg, v));
}

%}


extern fun
webchanjs_create{a:vt@ype}(string, a): void = "mac#webchanjs_create"

extern praxi 
  {a:t@ype}
  channel_send_pop
  {b:type}
  (ch: !channel(snd(a)::b) >> channel(b)):
  void
 
extern praxi 
  {a:t@ype}
  channel_recv_pop
  {b:type}
  (ch: !channel(rcv(a)::b) >> channel(b)):
  void

extern fun
prompt_int(string, int): int = "mac#prompt_int"

extern fun
channel_receive_ws_int(!channel0): int = "mac#channel_receive_ws_int"

extern fun
channel_receive_ws_int_cb(!channel0, int -> void): void = "mac#channel_receive_ws_int_cb"

extern fun
channel_send_ws{a:vt@ype}(!channel0, a): void = "mac#channel_send_ws"


extern fun
yield{a:vt@ype}(): a = "mac#yield"


implement channel_receive<int>(ch) = let
  prval () = channel_recv_pop(ch)
  val n = channel_receive_ws_int(ch)
in
  n
end


implement channel_send<int>(ch, v) = let
  prval () = channel_send_pop(ch)
  val () = channel_send_ws{int}(ch, v)
in
  ()
end



extern fun
  {a:t@ype}
  channel_receive_cb
  {b:type}
  (ch: !channel(rcv(a)::b) >> channel(b), f: a -> void): void
  

implement channel_receive_cb<int>(ch, f) = let
  val () = channel_receive_ws_int_cb(ch, f)
  prval () = channel_recv_pop(ch)
in end


extern fun
galert{a:vt@ype}(a): void = "mac#alert"


