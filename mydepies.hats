
local

#define
LIBWEBSOCKETS_targetloc
"$PATSHOMELOCS/atscntrb-keh-libwebsockets"

#define
LIBDILL_targetloc
"$PATSHOMELOCS/atscntrb-keh-libdill"

in

#include
"{$LIBWEBSOCKETS}/HATS/all.hats"

staload
"{$LIBDILL}/SATS/libdill.sats"

staload _ =
"{$LIBDILL}/DATS/libdill.dats"

staload _ = "libats/ML/DATS/string.dats"

end


