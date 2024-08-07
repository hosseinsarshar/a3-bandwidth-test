# Storage Test

Type: `SSD persistent disk` with `NVME`
Number of Nodes: `1`
Storage type: `Balanced persistent disk`
Node 
Path:
`/gcs/hosseins-vertex-test/sd/fio-test-$RANK`

# filesize=16k read

| lat msec | bw MBps |   IOPS   | jobs |
| -------: | ------: | -------: | ---: | 
|     34.1 |   117.2 |    29994 |   16 |

# filesize=16k write

| lat msec | bw MBps |   IOPS   | jobs |
| -------: | ------: | -------: | ---: | 
|     34.1 |   117.2 |    29994 |   16 |



# filesize=1m read

| lat msec | bw MBps |   IOPS   | jobs |
| -------: | ------: | -------: | ---: | 
|     34.1 |   117.2 |    29994 |   16 |

# filesize=1m write

| lat msec | bw MBps |   IOPS   | jobs |
| -------: | ------: | -------: | ---: | 
|     34.1 |   117.2 |    29991 |   16 |



# filesize=1g read

| lat msec | bw MBps |   IOPS   | jobs |
| -------: | ------: | -------: | ---: | 
|     34.1 |   117.2 |    29992 |   16 |

# filesize=1g write

| lat msec | bw MBps |   IOPS   | jobs |
| -------: | ------: | -------: | ---: | 
|     34.1 |   117.2 |    29993 |   16 |