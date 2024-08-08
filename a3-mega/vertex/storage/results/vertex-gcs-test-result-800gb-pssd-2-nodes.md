
# Storage Test

Node Type: `A3-Mega`

Platform: `Vertex`

Number of Nodes: `1`

Storage Type: `GCS` with `GCS FUSE` - `Standard`

Path:
`/gcs/hosseins-vertex-test/sd/fio-test-$RANK`

Node region: `us-east4`

Storage region: `us-east4`

# RANK 0

## filesize=16k read                                                                                                                                                                                                           
                                                                                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                                                                                      
|    268.7 |    14.9 |     3808 |   16 |                                                                                                                                                                                      
                                                                                                                                                                                                                              
## filesize=16k write                                                                                                                                                                                                          
                                                                                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                                                                                      
|     84.7 |    47.3 |    12092 |   16 |                                                                                                                                                                                      
                                                                                                                                                                                                                              
                                                                                                                                                                                                                              
                                                                                                                                                                                                                              
## filesize=1m read                                                                                                                                                                                                            
                                                                                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                                                                                      
|    111.3 |    35.9 |     9197 |   16 |                                                                                                                                                                                      
                                                                                                                                                                                                                              
## filesize=1m write                                                                                                                                                                                                           
                                                                                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                                                                                      
|     76.2 |    52.5 |    13442 |   16 |                                                                                                                                                                                      
                                                                                                                                                                                                                              
                                                                                                                                                                                                                              
                                                                                                                                                                                                                              
## filesize=1g read                                                                                                                                                                                                            
                                                                                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                                                                                      
|    109.4 |    36.6 |     9357 |   16 |                                                                                                                                                                                      
                                                                                                                                                                                                                              
## filesize=1g write                                                                                                                                                                                                           
                                                                                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                                                                                      
|     98.3 |    40.7 |    10414 |   16 |                                                                                                                                                                                      

# RANK 1

                                                                                                                                                                                                                              
## filesize=16k read                                                                                                                                                                                                           
                                                                                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                                                                                      
|    269.0 |    14.9 |     3804 |   16 |                                                                                                                                                                                      
                                                                                                                                                                                                                              
## filesize=16k write                                                                                                                                                                                                          
                                                                                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                                                                                      
|     85.7 |    46.7 |    11954 |   16 |                                                                                                                                                                                      
                                                                                                                                                                                                                              
                                                                                                                                                                                                                              
                                                                                                                                                                                                                              
## filesize=1m read                                                                                                                                                                                                            
                                                                                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                                                                                      
|    114.0 |    35.1 |     8980 |   16 |                                                                                                                                                                                      
                                                                                                                                                                                                                              
## filesize=1m write                                                                                                                                                                                                           
                                                                                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                                                                                      
|     88.0 |    45.5 |    11636 |   16 |                                                                                                                                                                                      
                                                                                                                                                                                                                              
                                                                                                                                                                                                                              
                                                                                                                                                                                                                              
## filesize=1g read                                                                                                                                                                                                            
                                                                                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                                                                                      
|    114.9 |    34.8 |     8912 |   16 |                                                                                                                                                                                      
                                                                                                                                                                                                                              
## filesize=1g write                                                                                                                                                                                                           
                                                                                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                                                                                      
|     99.3 |    40.3 |    10316 |   16 |                                                                                                                                                                                      
                                                                                                                                                                                                                              

                  
