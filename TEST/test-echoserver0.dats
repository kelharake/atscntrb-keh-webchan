
#include "share/atspre_staload.hats"
#include "share/atspre_define.hats"
#include "./../mydepies.hats"

staload UN = "prelude/SATS/unsafe.sats"

staload "../SATS/webchan.sats"
staload _ = "../DATS/webchan.dats"


staload "$PATSHOMELOCS/atscntrb-keh-direct.c/SATS/basic.sats"


fun client_loop(cch: ch2): void = let
  val msg = ch2recv<Strptr1>(cch)
in
  case+ msg of 
  | ~None_vt() => ch2free(cch)
  | ~Some_vt(str) =>
    case+ ch2send<refcnt(Strptr1)>(cch, refcnt(str)) of
    | ~Some_vt(v) => {
      val () = ch2free(cch) 
      val () = gfree_val(v)
    }
    | ~None_vt() => client_loop(cch)
end

fun main_loop(mch: ch1in): void = let
  val-~Some_vt(cch) = ch1recv<ch2>(mch)
  val ()            = go(client_loop(cch))
  val ()            = main_loop(mch)
in end

implement main0() = let
  val port = 5000
  val $tuple(min,mout) = ch1make()
  val _  = go(main_loop(min))
  implement ws_listen$public<>() = "./www"
  val () = ws_listen(mout, port)
in end



