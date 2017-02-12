
#include "share/atspre_staload.hats"
#include "share/atspre_define.hats"
#include "./../mydepies.hats"

staload UN = "prelude/SATS/unsafe.sats"

staload "../SATS/webchan.sats"
staload _ = "../DATS/webchan.dats"


typedef protocol = rcv(int)::rcv(int)::snd(int)::nil

fun worker(ch: !channel(protocol) >> channel(nil)): void = let
  val a  = channel_receive(ch)
  val () = println!("0# worker recv: ", a)

  val b  = channel_receive(ch)
  val () = println!("1# worker recv: ", b)

  val n  = a + b
  val () = channel_send(ch, n)
  val () = println!("2# worker send: ", n)
in end



implement main0() = let
  val port = 5000
  implement webchan_create$public<>() = "./www"
  implement webchan_create$session_handler<>() = $UN.cast{ptr}(worker)
  val () = webchan_create(port)
in end



