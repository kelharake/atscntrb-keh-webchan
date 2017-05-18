
#include "share/atspre_staload.hats"
#include "share/HATS/atspre_staload_libats_ML.hats"

staload UN = "prelude/SATS/unsafe.sats"

staload "libats/ML/SATS/string.sats"
staload _ = "libats/ML/DATS/string.dats"

staload "libats/libc/SATS/stdlib.sats"
staload _ = "libats/libc/DATS/stdlib.dats"

staload "libats/SATS/refcount.sats"
staload _ = "libats/DATS/refcount.dats"

#include "./../mydepies.hats"
staload "./../SATS/webchan.sats"

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


#include <uuid/uuid.h>


char* generate_uuid() {
  uuid_t uuid;
  int result = uuid_generate_time_safe(uuid);
  char *strptr = ATS_MALLOC(37); 
  uuid_unparse_lower(uuid, strptr);
  return strptr;
}


int mainch = -1;

void set_main_channel(int p) {
  mainch = p;
}

int get_main_channel() {
  return mainch;
} 



#endif

%}

extern fun set_main_channel(int): void = "mac#set_main_channel"
extern fun get_main_channel(): int     = "mac#get_main_channel"
extern fun buffer_to_strptr_copy(ptr, size_t): Strptr1 = "mac#buffer_to_strptr_copy"
extern fun generate_uuid(): Strptr1 = "mac#generate_uuid"


typedef user_session = @{readable=bool,writable=bool,server2client=int,client2server=int,wsi=lws_ptr}

/*
dataviewtype wstring =
  | wst of (string)
  | wsp of (Strptr1)
  | wsr of (refcnt(Strptr1))

fun{} client2server_handler(wsi: lws_ptr, c2s: int): void = let
  val m = $D.chrecv_boxed<wstring>(c2s)
in
  case+ m of
  | ~None_vt() => () where {
    val _ = $D.chdone(c2s)
    val _ = $D.hclose(c2s)
  }
  | ~Some_vt(m) =>
    (case+ m of
     | ~wsr(v) => client2server_handler(wsi, c2s) where {
       val (pf, fpf | strp) = refcnt_vtakeout(v)
       val _  = lws_write_text($UN.cast{lws_ptr}(wsi), $UN.strptr2string(!strp))
       prval () = fpf(pf)
       val () = gfree_val(v)
     }
     | ~wst(str) => client2server_handler(wsi, c2s) where {
       val _  = lws_write_text($UN.cast{lws_ptr}(wsi), str)
     }
     | ~wsp(stp) => client2server_handler(wsi, c2s) where {
       val _  = lws_write_text($UN.cast{lws_ptr}(wsi), $UN.strptr2string(stp))
       val () = strptr_free(stp)
     })
end
*/

fun{} client2server_handler(wsi: lws_ptr, c2s: int): void = let
  val m = $D.chrecv_boxed<refcnt(Strptr1)>(c2s)
in
  case+ m of
  | ~None_vt() => () where {
    val _ = $D.chdone(c2s)
    val _ = $D.hclose(c2s)
  }
  | ~Some_vt(v) => client2server_handler(wsi, c2s) where {
    val (pf, fpf | strp) = refcnt_vtakeout(v)
    val _  = lws_write_text($UN.cast{lws_ptr}(wsi), $UN.strptr2string(!strp))
    prval () = fpf(pf)
    val () = gfree_val(v)
  }
end

implement gfree_val<Strptr1>(x) = let
  val () = strptr_free(x)
in end

implement (a) gfree_val<refcnt(a)>(v) = $effmask_all(let
   val r =  refcnt_decref_opt<a>(v)
   val () = case+ r of
   | ~None_vt() => ()
   | ~Some_vt(s) => gfree_val<a>(s)
in end)

implement ws_listen<>(ch, port) = let
  val+~$B.ch1out(mainch) = ch
  var protocols = @[lws_protocols][2](lws_protocols_null())
  var info      = lws_context_creation_info_null()
  val ()        = set_main_channel(mainch)

  val () = lws_set_log_level(LLL_ERR, the_null_ptr)
  val () = protocols.[0].name                     := "session-protocol"
  val () = protocols.[0].callback                 := $UN.cast{lws_callback_function}(
    lam (wsi: lws_ptr, reason: lws_callback_reasons, user: &user_session, inp: string, len: size_t): int =>
      case reason of
      | x when x = LWS_CALLBACK_ESTABLISHED => 0 where {
        val mainch = get_main_channel()

        val server2client0  = $D.chmake_boxed()       // for the client. 
        val server2client1  = $D.hdup(server2client0) // for the server/handler. 
        val client2server0  = $D.chmake_boxed()       // for the client. 
        val client2server1  = $D.hdup(client2server0) // for the server. 
        val client2server2  = $D.hdup(client2server0) // for the write handler. 

        val () = user.writable := true
        val () = user.readable := true
        val () = user.server2client := server2client1
        val () = user.client2server := client2server1
        val _  = $B.go(client2server_handler(wsi, client2server2))

        val n = $B.ch2($B.ch1in(server2client0), $B.ch1out(client2server0))
        val m = $D.chsend_boxed<$B.ch2>(mainch, n)
        val () = case+ m of
        | ~None_vt() => ()
        | ~Some_vt(~$B.ch2(~$B.ch1in(_),~$B.ch1out(_))) => () where {
          val _  = $D.chdone(server2client0)
          val _  = $D.chdone(client2server0)
          val _  = $D.hclose(server2client0)
          val _  = $D.hclose(client2server0)
          val () = user.writable := false
          val () = user.readable := false
          val () = lws_close_reason(wsi, LWS_CLOSE_STATUS_NORMAL, the_null_ptr, i2sz(0))
        }
      }
      | x when x = LWS_CALLBACK_RECEIVE => n where {
        val () = if user.readable then () where {
          val st  = buffer_to_strptr_copy($UN.cast{ptr}(inp), len)
          val s2c = user.server2client
          val m   = $D.chsend_boxed<strptr>(s2c, st)
          val ()  = case+ m of
          | ~None_vt() => () // success. 
          | ~Some_vt(st) => () where { // fail. 
            val () = strptr_free(st)
            val () = user.readable := false
            val _  = $D.chdone(s2c)
            val _  = $D.hclose(s2c)
          }
        }
        val n = if ~user.readable && ~user.writable then ~1 else 0
      }
      | x when x = LWS_CALLBACK_SERVER_WRITEABLE => n where {
        val n = if ~user.readable && ~user.writable then ~1 else 0
      }
      | x when x = LWS_CALLBACK_CLOSED => 0 where {
        val () = if user.writable then () where {
          val ()  = user.writable := false
          val c2s = user.client2server
          val _   = $D.chdone(c2s)
          val _   = $D.hclose(c2s)
        }
        val () = if user.readable then () where {
          val ()  = user.readable := false
          val s2c = user.server2client
          val _   = $D.chdone(s2c)
          val _   = $D.hclose(s2c)
        }
        // =================================================================== 
        // Waiting for the handler to tell the server that it is ok to release 
        // the wsi object.                                                     
        //val _  = chdone(user2handler)
        //val _  = chdone(handler2user)
        //val _  = chdone(handler2server)
        //val _  = chdone(server2handler)
        // =================================================================== 
      }
      | x when x = LWS_CALLBACK_HTTP => ~1 where {
        val i    = inp
        val path = string_append(ws_listen$public(), string_append("/", i))
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
  val () = for (;;) { val _ = lws_service(cx, 50) val _ = $D.yield() }
  val () = lws_context_destroy(cx)
in end

