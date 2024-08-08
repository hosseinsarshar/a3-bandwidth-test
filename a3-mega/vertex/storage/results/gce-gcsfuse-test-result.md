# Storage Test

Node Type: `A3-High`

Platform: `GCE`

Number of Nodes: `1`

Storage Type: `GCS` with `GCS FUSE` - `Standard`

Path:
Path: `gs://hosseins-llama3/storage-test`

Node region: `us-central1`

Storage region: `us-central1`


# filesize=16k read

| lat msec | bw MBps |   IOPS   | jobs |
| -------: | ------: | -------: | ---: | 
|    401.0 |    10.0 |     2552 |   16 |

# filesize=16k write

| lat msec | bw MBps |   IOPS   | jobs |
| -------: | ------: | -------: | ---: | 
|     14.0 |   284.8 |    72901 |   16 |



# filesize=1m read

| lat msec | bw MBps |   IOPS   | jobs |
| -------: | ------: | -------: | ---: | 
|     11.4 |   352.0 |    90114 |   16 |

# filesize=1m write

| lat msec | bw MBps |   IOPS   | jobs |
| -------: | ------: | -------: | ---: | 
|     14.1 |   282.9 |    72407 |   16 |



# filesize=1g read

| lat msec | bw MBps |   IOPS   | jobs |
| -------: | ------: | -------: | ---: | 
|      7.9 |   505.8 |   129467 |   16 |

# filesize=1g write

| lat msec | bw MBps |   IOPS   | jobs |
| -------: | ------: | -------: | ---: | 
|     15.3 |   262.1 |    67098 |   16 |