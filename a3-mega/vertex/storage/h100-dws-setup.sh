PROJECT_ID=google.com:vertex-training-dlexamples
REGION=us-east5 # europe-west4
ZONE=us-east5-a # europe-west4-c

MACHINE_TYPE=a3-megagpu-8g # a3-megagpu-8g # a3-highgpu-8g
ACCELERATOR_TYPE=nvidia-h100-mega-80gb # nvidia-h100-mega-80gb # nvidia-h100-80gb
ACCELERATOR_COUNT=8
BOOT_DISK_SIZE=800GB
BOOT_DISK_TYPE=pd-ssd
IMAGE_FAMILY=tf-2-15-gpu-debian-11 # https://cloud.google.com/deep-learning-containers/docs/choosing-container
IMAGE_PROJECT=ml-images
INITIAL_SIZE=1
RESIZE_NODES=1
INSTANCE_NAME="dws-h100-high-x2-mig-hosseins-1" # "dws-h100-mega-x2-mig-hosseins"
INSTANCE_NAME_WITH_CONTAINER="dws-h100-high-x2-mig-with-container-hosseins" # "dws-h100-mega-x2-mig-hosseins"
INSTANCES_TEMPLATE="dws-h100-high-8gpu-instance-hosseins-1" # "dws-h100-mega-8gpu-instance-hosseins"
INSTANCES_TEMPLATE_WITH_CONTAINER="dws-h100-high-8gpu-instance-with-container-hosseins" # "dws-h100-mega-8gpu-instance-hosseins"

WAIT_DURATION="3h30m" #3 hours, 30 minutes
RUN_DURATION="3d1h30m" #1 hour, 30 minutes
#RESIZE_REQUEST_DURATION="3d1h30s" # 3 day, 1 hour, 30 minutes

# Set the default project and zone for gcloud commands
CONTAINER_IMAGE="classicboyir/nemo:02"

gcloud config set project $PROJECT_ID
gcloud config set compute/zone $ZONE

# Update gcloud to get the latest attributes used by DWS
sudo gcloud components update

gcloud beta compute instance-templates create $INSTANCES_TEMPLATE \
     --machine-type=$MACHINE_TYPE \
     --image-family=$IMAGE_FAMILY \
     --image-project=$IMAGE_PROJECT \
     --boot-disk-size=$BOOT_DISK_SIZE \
     --boot-disk-type=$BOOT_DISK_TYPE \
     --boot-disk-device-name=$INSTANCES_TEMPLATE \
     --accelerator=type=$ACCELERATOR_TYPE,count=$ACCELERATOR_COUNT \
     --max-run-duration=$RUN_DURATION \
     --network-interface=nic-type=GVNIC \
     --instance-termination-action=delete \
     --reservation-affinity=none \
     --maintenance-policy=TERMINATE
     # --on-host-maintenance=terminate \

gcloud beta compute instance-templates create-with-container $INSTANCES_TEMPLATE_WITH_CONTAINER \
     --machine-type=$MACHINE_TYPE \
     --boot-disk-size=$BOOT_DISK_SIZE \
     --boot-disk-type=$BOOT_DISK_TYPE \
     --boot-disk-device-name=$INSTANCES_TEMPLATE_WITH_CONTAINER \
     --accelerator=type=$ACCELERATOR_TYPE,count=$ACCELERATOR_COUNT \
     --network-interface=nic-type=GVNIC \
     --reservation-affinity=none \
     --container-image=$CONTAINER_IMAGE \
     --maintenance-policy=TERMINATE


# more specific settings
"""
gcloud compute instance-templates create $INSTANCES_TEMPLATE \
    --machine-type=$MACHINE_TYPE \
    --image-family=$IMAGE_FAMILY \
    --image-project=$IMAGE_PROJECT \
    --boot-disk-size=$BOOT_DISK_SIZE \
    --boot-disk-type=$BOOT_DISK_TYPE \
    --boot-disk-device-name=$INSTANCES_TEMPLATE \
    --maintenance-policy=TERMINATE \
    --accelerator=type=$ACCELERATOR_TYPE,count=$ACCELERATOR_COUNT \
    --network-interface=nic-type=GVNIC \
    --instance-template-region=$REGION \
    --instance-termination-action=delete \
    --reservation-affinity=none
"""

gcloud compute instance-groups managed create $INSTANCES_TEMPLATE \
--size=$INITIAL_SIZE --template=$INSTANCES_TEMPLATE \
--zone=$ZONE

gcloud beta compute instance-groups managed update $INSTANCES_TEMPLATE \
    --default-action-on-vm-failure=DO_NOTHING \
    --zone=$ZONE

gcloud beta compute instance-groups managed resize-requests create \
$INSTANCE_NAME --resize-request=resize-request-$INSTANCE_NAME \
    --count=$RESIZE_NODES \
    --valid-until-duration=$WAIT_DURATION \
    --zone=$ZONE

gcloud beta compute instance-groups managed resize-requests create \
$INSTANCE_NAME_WITH_CONTAINER --resize-request=resize-request-$INSTANCE_NAME_WITH_CONTAINER \
    --resize-by=$RESIZE_NODES \
    --requested-run-duration=$WAIT_DURATION \
    --zone=$ZONE


#try beta
gcloud beta compute instance-groups managed resize-requests create \
    $INSTANCE_NAME --resize-request=resize-request-$INSTANCE_NAME \
    --resize-by=$RESIZE_NODES \
    --requested-run-duration=$WAIT_DURATION \
    --zone=$ZONE


gcloud beta compute instance-groups managed resize-requests delete \
    $INSTANCE_NAME_WITH_CONTAINER --resize-requests=resize-request-$INSTANCE_NAME_WITH_CONTAINER \
    --zone=$ZONE
    
# --valid-until-time=$WAIT_DURATION \

gcloud alpha compute instance-groups managed resize-requests list \
$INSTANCE_NAME --zone=$ZONE

# Wait for the resize request to complete
while true; do gcloud alpha compute instance-groups managed resize-requests list \
$INSTANCE_NAME --zone=$ZONE; sleep 30; done

# Cancel the resize request if needed
gcloud alpha compute instance-groups managed resize-requests cancel \
$INSTANCE_NAME --resize-requests=resize-request-$INSTANCE_NAME

# Delete the cancelled resize request if needed
gcloud alpha compute instance-groups managed resize-requests delete \
$INSTANCE_NAME --resize-requests=resize-request-$INSTANCE_NAME

# Delete the instance group if needed
gcloud beta compute instance-groups managed delete $INSTANCE_NAME --zone=$ZONE

gcloud beta compute instance-templates create-with-container

# Delete the instance template if needed
gcloud compute instance-templates delete $INSTANCES_TEMPLATE_WITH_CONTAINER


ssh-keygen -t rsa -f ~/.ssh/hosseingoogle.com -C hosseins@google.com -b 2048