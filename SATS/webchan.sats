

abstype rcv(vt@ype)
abstype snd(vt@ype)
abstype seq(type,type)
abstype nil
abstype loop(type)
abstype choose(type,type,bool)

absviewtype channel(type) = ptr

stadef :: = seq

fun
  {a:t@ype}
  channel_receive
  {b:type}
  (ch: !channel(rcv(a)::b) >> channel(b)):
  a 

fun
  {a:t@ype}
  channel_send
  {b:type}
  (ch: !channel(snd(a)::b) >> channel(b), a):
  void

fun
  {}
  channel_receive_int
  {a:int}
  {b:type}
  (ch: !channel(rcv(int a)::b) >> channel(b)):
  int a

fun
  {}
  channel_send_int
  {a:int}
  {b:type}
  (ch: !channel(snd(int a)::b) >> channel(b), int a):
  void


typedef webchan_callback(a:type) = (!channel(a) >> channel(nil)) -> ()

typedef webchan_callback0 = {a:type} (!channel(a) >> channel(nil)) -> ()

viewtypedef channel0 = [a:type] channel(a)


fun
  {}
  webchan_create
  (port: int):
//webchan_callback(a)):
  void


fun
  {}
  webchan_create$public
  ():
  string



fun
  {}
  webchan_create$session_handler
  ():
  ptr



