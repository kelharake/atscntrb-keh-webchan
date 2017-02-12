
//#define ATS_MAINATSFLAG 1
//#define ATS_DYNLOADNAME "my_dynload"

#include "share/atspre_define.hats"
#include "{$LIBATSCC2JS}/staloadall.hats"

#include "webchan_js.dats"


typedef protocol = snd(int)::snd(int)::rcv(int)::nil

fun worker(ch: !channel(protocol) >> channel(nil)): void = let
  val a  = prompt_int("Enter a number:", 0)
  val () = channel_send(ch, a)
  val () = galert("message sent!")

  val b  = prompt_int("Enter another number:", 0)
  val () = channel_send(ch, b)
  val () = galert("message sent!")

  val _  = channel_receive_cb(ch, lam n => galert(n))
in end

extern fun init(): void = "init"

implement init() = let
  val () = webchanjs_create("ws://localhost:5000/", worker)
in end





%{^

init();

%}


