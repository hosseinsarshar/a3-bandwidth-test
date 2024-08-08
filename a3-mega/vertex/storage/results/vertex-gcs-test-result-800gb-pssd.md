
# Storage Test

Node Type: `A3-Mega`

Platform: `Vertex`

Number of Nodes: `1`

Storage Type: `GCS` with `GCS FUSE` - `Standard`

Path:
`/gcs/hosseins-vertex-test/sd/fio-test-$RANK`

Node region: `us-east4`

Storage region: `us-east4`

## filesize=16k read                                                                                                                                           
                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                      
|    305.0 |    13.1 |     3354 |   16 |                                                                                                                      
                                                                                                                                                              
## filesize=16k write                                                                                                                                          
                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                      
|     89.3 |    44.8 |    11468 |   16 |                                                                                                                      
                                                                                                                                                              
                                                                                                                                                              
                                                                                                                                                              
## filesize=1m read                                                                                                                                            
                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                      
|    117.0 |    34.2 |     8752 |   16 |                                                                                                                      
                                                                                                                                                              
## filesize=1m write                                                                                                                                           
                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                      
|     87.9 |    45.5 |    11642 |   16 |                                                                                                                      
                                                                                                                                                              
                                                                                                                                                              
                                                                                                                                                              
## filesize=1g read                                                                                                                                            
                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                      
|    113.5 |    35.3 |     9018 |   16 |                                                                                                                      
                                                                                                                                                              
## filesize=1g write                                                                                                                                           
                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                      
|    100.8 |    39.7 |    10159 |   16 |                                                                                                                      
                                                                                                                                                              
                  
