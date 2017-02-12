
#include "share/atspre_staload.hats"
#include "share/atspre_define.hats"
#include "./../mydepies.hats"

staload UN = "prelude/SATS/unsafe.sats"

staload "../SATS/webchan.sats"
staload _ = "../DATS/webchan.dats"


typedef protocol(a:int,b:int) = rcv(int a)::rcv(int b)::snd(int(a+b))::nil

fun worker{a,b:int}(ch: !channel(protocol(a,b)) >> channel(nil)): void = let
  val a  = channel_receive_int(ch)
  val () = println!("0# worker recv: ", a)

  val b  = channel_receive_int(ch)
  val () = println!("1# worker recv: ", b)

  val n  = a + b
  val () = channel_send_int(ch, n)
  val () = println!("2# worker send: ", n)
in end



implement main0() = let
  val port = 5000
  implement webchan_create$public<>() = "./www"
  implement webchan_create$session_handler<>() = $UN.cast{ptr}(worker)
  val () = webchan_create(port)
in end



