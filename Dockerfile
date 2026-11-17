FROM osrf/ros:jazzy-desktop-full

ENV DEBIAN_FRONTEND=noninteractive

# 1. Cài đặt các thư viện cơ bản + ninja-build để tăng tốc biên dịch
RUN apt-get update && apt-get install -y --no-install-recommends \
    git cmake ninja-build build-essential wget curl nano python3-pip \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/env

# 2. Micro-XRCE-DDS-Agent (shallow clone + ninja build + cleanup build cache)
RUN git clone --depth 1 -b v2.4.3 https://github.com/eProsima/Micro-XRCE-DDS-Agent.git \
    && cd Micro-XRCE-DDS-Agent && mkdir build && cd build \
    && cmake -GNinja .. && ninja install && ldconfig /usr/local/lib/ \
    && rm -rf /opt/env/Micro-XRCE-DDS-Agent/build

# 3. PX4-Autopilot (SITL + Gazebo Harmonic)
# Shallow clone giúp giảm ~2GB tải mạng nhưng vẫn giữ ĐẦY ĐỦ models, worlds và scripts
RUN git clone --depth 1 --recurse-submodules --shallow-submodules https://github.com/PX4/PX4-Autopilot.git
RUN bash PX4-Autopilot/Tools/setup/ubuntu.sh --no-nuttx
RUN cd PX4-Autopilot && make px4_sitl_default

# 4. px4_msgs — build từ source để match đúng PX4 version
RUN mkdir -p /opt/px4_msgs_ws/src \
    && git clone --depth 1 https://github.com/PX4/px4_msgs.git /opt/px4_msgs_ws/src/px4_msgs
RUN . /opt/ros/jazzy/setup.sh \
    && cd /opt/px4_msgs_ws \
    && colcon build --symlink-install --parallel-workers $(nproc)

# 5. Python dependencies (đặt ở cuối để khi thêm lib mới chỉ mất vài giây rebuild)
RUN pip3 install --no-cache-dir pyrvo pathfinding --break-system-packages

# 6. Auto-source môi trường
RUN echo "source /opt/ros/jazzy/setup.bash" >> ~/.bashrc \
    && echo "source /opt/px4_msgs_ws/install/setup.bash" >> ~/.bashrc \
    && echo "source /workspace/ros2_ws/install/setup.bash 2>/dev/null || true" >> ~/.bashrc

WORKDIR /workspace/ros2_ws
