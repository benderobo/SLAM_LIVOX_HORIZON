FROM ros:noetic-ros-base-focal

SHELL ["/bin/bash", "-lc"]
ENV DEBIAN_FRONTEND=noninteractive

# Базовые инструменты + catkin + PCL + pcl_conversions
RUN apt-get update && apt-get install -y --no-install-recommends \
    git ca-certificates curl \
    build-essential cmake pkg-config \
    python3-catkin-tools python3-rosdep python3-vcstool \
    ros-noetic-pcl-ros ros-noetic-pcl-conversions \
    ros-noetic-rosbridge-server \
    && rm -rf /var/lib/apt/lists/*

# rosdep (не валим билд если уже инициализирован)
RUN rosdep init 2>/dev/null || true && rosdep update || true

# Livox-SDK2 (ставим в /usr/local)
WORKDIR /opt
RUN git clone --recursive https://github.com/Livox-SDK/Livox-SDK2.git \
 && cd Livox-SDK2 \
 && mkdir -p build && cd build \
 && cmake .. -DCMAKE_BUILD_TYPE=Release \
 && make -j$(nproc) \
 && make install \
 && ldconfig

# Рабочая папка
WORKDIR /ws

# Копируем catkin workspace (если есть)
COPY ws/ /ws/

# Собираем catkin workspace
RUN [ -d /ws/catkin_ws ] && { \
    source /opt/ros/noetic/setup.bash && \
    cd /ws/catkin_ws && \
    catkin config --extend /opt/ros/noetic --cmake-args -DCMAKE_BUILD_TYPE=Release && \
    catkin build -j$(nproc); \
} || echo "No catkin_ws found, skipping build"

EXPOSE 11311 9090

CMD ["bash"]
