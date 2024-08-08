
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
|    299.3 |    13.4 |     3419 |   16 |                                                                                                                      
                                                                                                                                                              
## filesize=16k write                                                                                                                                          
                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                      
|     89.2 |    44.9 |    11483 |   16 |                                                                                                                      
                                                                                                                                                              
                                                                                                                                                              
                                                                                                                                                              
## filesize=1m read                                                                                                                                            
                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                      
|    117.0 |    34.2 |     8754 |   16 |                                                                                                                      
                                                                                                                                                              
## filesize=1m write                                                                                                                                           
                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                      
|     89.7 |    44.6 |    11414 |   16 |                                                                                                                      
                                                                                                                                                              
                                                                                                                                                              
                                                                                                                                                              
## filesize=1g read                                                                                                                                            
                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                      
|    115.9 |    34.5 |     8837 |   16 |                                                                                                                      
                                                                                                                                                              
## filesize=1g write                                                                                                                                           
                                                                                                                                                              
| lat msec | bw MBps |   IOPS   | jobs |                                                                                                                      
| -------: | ------: | -------: | ---: |                                                                                                                      
|    100.4 |    39.9 |    10198 |   16 |                                                                                                                      
                                                                                                                                                              
