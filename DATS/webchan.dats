
#include "share/atspre_staload.hats"
#include "share/HATS/atspre_staload_libats_ML.hats"

staload UN = "prelude/SATS/unsafe.sats"

staload "libats/ML/SATS/string.sats"
staload _ = "libats/ML/DATS/string.dats"

staload "libats/libc/SATS/stdlib.sats"
staload _ = "libats/libc/DATS/stdlib.dats"


#include "./../mydepies.hats"


//#include "./../mydepies.hats"
//staload "./../SATS/webchan.sats"
//#include "./../mydepies.hats"

staload "./../SATS/webchan.sats"




dataviewtype channel_vt =
  | dil_channel of (channel_id)
  | lws_channel of (lws_ptr, channel_id) 



%{#

#ifndef ATSCNTRB_KEH_WEBCHAN_WEBCHAN_SATS
#define ATSCNTRB_KEH_WEBCHAN_WEBCHAN_SATS

#include <stdio.h>
#include <string.h>

char* buffer_to_strptr_copy(char *buffer, size_t length) {
  char *strptr = ATS_MALLOC(length+1); 
  memcpy(strptr, buffer, length);
  strptr[length] = '\0';
  return strptr;
}

#endif

%}

extern fun buffer_to_strptr_copy(ptr, size_t): Strptr1 = "mac#buffer_to_strptr_copy"


extern castfn
f_strptr2string(x: !Strptr1):<> string





extern castfn 
channel2ptr(x: channel_vt):<> ptr





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

extern fun{}
  channel_free
  (ch: channel(nil)):
  void


implement channel_free<>(ch) = 
  case+ $UN.castvwtp0{channel_vt}(ch) of
  | ~dil_channel(_) => ()
  | ~lws_channel(_, _) => ()



extern castfn 
channel_get_channel_vt{t:type}(x: !channel(t)):<> channel_vt


extern fun{} 
  channel_vt_putf
  (ch: channel_vt):
  void




implement channel_vt_putf<>(ch) = () where {
  val _ = $UN.castvwtp0{ptr}(ch)
}


typedef user_session = @{status=bool,ch=channel_id, cr=coroutine_id}


 
  
implement webchan_create<>(port) = let
  var protocols = @[lws_protocols][2](lws_protocols_null())
  var info      = lws_context_creation_info_null()
  val () = lws_set_log_level(LLL_ERR, the_null_ptr)
  val () = protocols.[0].name                     := "session-protocol"
  //val () = protocols.[0].callback                 := $UN.cast{lws_callback_function}(wrapper_callback(public, func))
  val () = protocols.[0].callback                 := $UN.cast{lws_callback_function}(
    lam (wsi: lws_ptr, reason: lws_callback_reasons, user: &user_session, inp: string, len: size_t): int =>
      case reason of
      | x when x = LWS_CALLBACK_ESTABLISHED => 0 where {
        val i  = println!("session established.")
        val () = user.status := true 
        val () = user.ch := chmake(sizeof<ptr>)
        val chh = lws_channel(wsi, user.ch)
        val chp = channel2ptr(chh)
        val () = user.cr := make_coroutine_ptr(lam (x) => () where {
          val ch = $UN.castvwtp1{channel0}(x)
          val f  = $UN.cast{webchan_callback0}(webchan_create$session_handler())
          val _  = f(ch)
          val () = channel_free(ch)
        }, chp)
      }
      | x when x = LWS_CALLBACK_RECEIVE => 0 where {
        val () = println!("receiving message.")
        val st = buffer_to_strptr_copy($UN.cast{ptr}(inp), len)
        val rc = chsends_strptr(user.ch, st)
        val _  = yield()
      }
      | x when x = LWS_CALLBACK_SERVER_WRITEABLE => 0 where {
        val () = println!("sending message.")
        val (rc,sp) = chrecvs_strptr(user.ch)
        val () = assertloc(ptr_isnot_null(ptrcast(sp)))
        val n  = lws_write_text(wsi, $UN.strptr2string(sp))
        val () = strptr_free(sp)
        val _  = yield()
        val _  = yield()
      }
      | x when x = LWS_CALLBACK_CLOSED => if user.status then 0 where {
        val i  = println!("session closed.")
        val () = user.status := false
        val _  = yield()
        val _  = chdone(user.ch)
        val _  = hclose(user.cr)
      } else 0
      | x when x = LWS_CALLBACK_HTTP => ~1 where {
        val i    = inp
        val path = string_append(webchan_create$public(), string_append("/", i))
        val (fpf | ext) = filename_get_ext(i)
        val mime = extension_to_mime(if strptr_isnot_null(ext) then $UN.strptr2string(ext) else "")
        prval () = fpf(ext)        
        val n =
          if test_file_exists(path) && test_file_isdir(path) = 0 then
            lws_serve_http_file_plain(wsi, path, mime)
          else
            lws_return_http_status(wsi, HTTP_STATUS_NOT_FOUND, "File not found!") }
      | _ => 0
  )
  val () = protocols.[0].per_session_data_size    := sizeof<user_session>
  val () = info.protocols                         := addr@protocols
  val () = info.port                              := port
  val cx = lws_create_context(info)
  val () = for (;;) { val _ = lws_service(cx, 50) }
  val () = lws_context_destroy(cx)
in end
  



implement channel_receive_int<>{a}(ch) = let
  prval () = $UN.prop_assert{false}()
  //val chh = $UN.castvwtp0{channel_vt}(ch)  
  val chh = channel_get_channel_vt(ch)  
  val x = 
    case+ chh of
    | dil_channel(chan) => 0
    | lws_channel(wsi,chan) => n where {
      val (rc,sp) = chrecvs_strptr(chan)
      val () = assertloc(ptr_isnot_null(ptrcast(sp)))
      val  n = atoi($UN.strptr2string(sp))
      val () = strptr_free(sp)
    }
  val () = channel_vt_putf(chh)
  prval () = channel_recv_pop(ch)
in
  $UN.cast{int a}(x)
end


  


implement channel_receive<int>(ch) = let
  prval () = $UN.prop_assert{false}()
  //val chh = $UN.castvwtp0{channel_vt}(ch)  
  val chh = channel_get_channel_vt(ch)  
  val x = 
    case+ chh of
    | dil_channel(chan) => 0
    | lws_channel(wsi,chan) => n where {
      val (rc,sp) = chrecvs_strptr(chan)
      val () = assertloc(ptr_isnot_null(ptrcast(sp)))
      val  n = atoi($UN.strptr2string(sp))
      val () = strptr_free(sp)
    }
  val () = channel_vt_putf(chh)
  prval () = channel_recv_pop(ch)
in
  x
end




implement channel_send<int>(ch,v) = let
  //prval () = $UN.prop_assert{false}()
  val chh = channel_get_channel_vt(ch)  
  val () =
    case+ chh of
    | dil_channel(chan) => ()
    | lws_channel(wsi,chan) => () where {
      val _  = lws_callback_on_writable(wsi)
      val rc = chsends_strptr<>(chan, tostrptr_int(v))
      val _  = yield()
    }
  val () = channel_vt_putf(chh)
  prval () = channel_send_pop(ch)
in end


implement channel_send_int<>(ch,v) = let
  //prval () = $UN.prop_assert{false}()
  val chh = channel_get_channel_vt(ch)  
  val () =
    case+ chh of
    | dil_channel(chan) => ()
    | lws_channel(wsi,chan) => () where {
      val _  = lws_callback_on_writable(wsi)
      val rc = chsends_strptr(chan, tostrptr_int(v))
      val _  = yield()
    }
  val () = channel_vt_putf(chh)
  prval () = channel_send_pop(ch)
in end


