
local

#define
LIBWEBSOCKETS_targetloc
"$PATSHOMELOCS/atscntrb-keh-libwebsockets"

#define
LIBDILL_targetloc
"$PATSHOMELOCS/atscntrb-keh-libdill"


#define
DIRECT_targetloc
"$PATSHOMELOCS/atscntrb-keh-direct.c"



in

#include
"{$LIBWEBSOCKETS}/HATS/all.hats"

staload D = "{$LIBDILL}/SATS/libdill.sats"
staload _ = "{$LIBDILL}/DATS/libdill.dats"

staload _ = "libats/ML/DATS/string.dats"

staload "libats/SATS/refcount.sats"
staload _ = "libats/DATS/refcount.dats"

staload B = "{$DIRECT}/SATS/basic.sats"
staload _ = "{$DIRECT}/DATS/basic.dats"

end


