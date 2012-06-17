CPU_INFO =
<<eos
processor : 0
vendor_id : AuthenticAMD
cpu family  : 17
model   : 3
model name  : AMD Athlon(tm)X2 DualCore QL-60

processor : 1
eos
      
CPU_USAGE =
<<eos
32.9
 0.2
 0.3
 0.0
 0.0
 0.0
 0.0
 0.0
eos

NET_USAGE =
<<eos
Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
    lo:    1080      16    0    0    0     0          0         0     1080      16    0    0    0     0       0          0
  eth0:972526934 1975755 11375    0    0     0          0         0 39121984  159852    0    0    0     0       0          0
venet0:       0       0    0    0    0     0          0         0        0       0    0    0    0     0       0          0
eos

MEMORY_USAGE = 
<<eos
             total       used       free     shared    buffers     cached
Mem:       3795968    3665112     130856          0      46324     957760
-/+ buffers/cache:    2661028    1134940
Swap:      4100092      42836    4057256
eos