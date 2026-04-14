# https://github.com/orbbec/ros_astra_camera?tab=readme-ov-file

# Assuming you have sourced the ros environment, same below
sudo apt install libgflags-dev  ros-$ROS_DISTRO-image-geometry ros-$ROS_DISTRO-camera-info-manager\
ros-$ROS_DISTRO-image-transport ros-$ROS_DISTRO-image-publisher  libusb-1.0-0-dev libeigen3-dev
ros-$ROS_DISTRO-backward-ros libdw-dev

git clone https://github.com/libuvc/libuvc.git
cd libuvc
mkdir build && cd build
cmake .. && make -j4
sudo make install
sudo ldconfig

mkdir -p ~/ros_ws/src
cd ~/ros_ws/src
git clone https://github.com/orbbec/ros_astra_camera.git

cd ~/ros_ws
catkin_make

OUTPUT_DIR=~/astra_outputs
mkdir -p "$OUTPUT_DIR/images"
mkdir -p "$OUTPUT_DIR/pointclouds"

# ------------------

cd ~/ros_ws
source ./devel/setup.bash
roscd astra_camera
./scripts/create_udev_rules
sudo udevadm control --reload && sudo  udevadm trigger

# terminal 1
source ./devel/setup.bash 
roslaunch astra_camera astra.launch > "$OUTPUT_DIR/astra_launch.log" 2>&1 &

# ------------------

# every 3 hrs
while true; do
    # Get timestamp
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

    echo "[$(date)] Saving image and point cloud..."

    # Call service to save images
    rosservice call /camera/save_images "{}"
      echo "Images saved for $TIMESTAMP"

    # Call service to save point cloud
    rosservice call /camera/save_point_cloud_xyz "{}"
      echo "Point cloud saved for $TIMESTAMP"

    # Move generated output to timestamped files
    if [ -d "$HOME/.ros/image" ]; then
        mv "$HOME/.ros/image" "$OUTPUT_DIR/images/$TIMESTAMP"
    fi
    if [ -d "$HOME/.ros/point_cloud" ]; then
        mv "$HOME/.ros/point_cloud" "$OUTPUT_DIR/pointclouds/$TIMESTAMP"
    fi

    echo "Saved at $OUTPUT_DIR (timestamp $TIMESTAMP)"

    # Wait for the specified interval before repeating
    sleep 10800
done