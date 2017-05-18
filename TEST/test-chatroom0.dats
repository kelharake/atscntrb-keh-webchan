
#include "share/atspre_staload.hats"
#include "share/atspre_define.hats"
#include "./../mydepies.hats"

staload UN = "prelude/SATS/unsafe.sats"

staload "./../SATS/webchan.sats"
staload _ = "./../DATS/webchan.dats"

staload "$PATSHOMELOCS/atscntrb-keh-direct.c/SATS/basic.sats"

dataviewtype COMMAND =
  | PRIVMSG of (Strptr1)
  | JOIN of (ch1out)
  | PART of (ch1out)

fun client_loop(cin: ch1in, cout: ch1out, rout: ch1out): void = let
  val msg = ch1recv<Strptr1>(cin)
in
  case+ msg of 
  | ~None_vt() => () where {
    val-~None_vt() = ch1send<COMMAND>(rout, PART(cout))
    val () = ch1outfree(rout)
    val () = ch1infree(cin)
  }
  | ~Some_vt(str) => client_loop(cin, cout, rout) where {
    val ()         = println!($UN.strptr2string(str))
    val-~None_vt() = ch1send<COMMAND>(rout, PRIVMSG(str))
  }
end

fun broadcast_loop(str: !refcnt(Strptr1), lst: List0_vt(ch1out)): List0_vt(ch1out) =
  case+ lst of
  | ~list_vt_nil() => list_vt_nil()
  | ~list_vt_cons(x,xs) => let
    val strc = refcnt_incref(str)
    val res = ch1send<refcnt(Strptr1)>(x,strc)
  in
    case+ res of
    | ~Some_vt(strc) => broadcast_loop(str, xs) where { 
      val () = gfree_val(strc)
      val () = ch1outfree(x)
    }
    | ~None_vt() => list_vt_cons(x, broadcast_loop(str, xs))
  end

fun room_loop(rch: ch1in, lst: List0_vt(ch1out)): void = let
  val-~Some_vt(com) = ch1recv<COMMAND>(rch)
in
  case+ com of
  | ~JOIN(cout) => let
    val () = println!("client joined.")
    val () = room_loop(rch, list_vt_cons(cout, lst))
  in end
  | ~PART(cout) => let
    val () = println!("client left.")
    val () = ch1outfree(cout)
    val () = room_loop(rch, lst)
  in end
  | ~PRIVMSG(str) => let
    val strc = refcnt(str)
    val lst  = broadcast_loop(strc, lst)
    val ()   = gfree_val(strc) 
    val ()   = room_loop(rch, lst)
  in end
end


fun main_loop(mch: ch1in, rout: ch1out): void = let
  val-~Some_vt(cch)       = ch1recv<ch2>(mch)
  val ~ch2(cin,cout)      = cch
  val coutd               = ch1outdup(cout)
  val routd               = ch1outdup(rout)
  val-~None_vt()          = ch1send<COMMAND>(rout, JOIN(cout))
  val _                   = go(client_loop(cin, coutd, routd))
  val ()                  = main_loop(mch, rout)
in end



implement main0() = let
  val port = 5000
  val $tuple(min,mout) = ch1make()
  val $tuple(rin,rout) = ch1make()
  val _  = go(main_loop(min, rout))
  val _  = go(room_loop(rin, list_vt_nil()))
  implement ws_listen$public<>() = "./www"
  val () = ws_listen(mout, port)
in end



