#!/usr/bin/env bash
set -euo pipefail

ROS_MASTER="http://192.168.123.100:11311"
ROS_IP="192.168.123.100"
IMG="ros1_horizon_with_rviz:latest"
NAME="rviz_noetic_horizon"
RVIZ_CFG="/ws/catkin_ws/src/fast_lio/rviz_cfg/loam_livox.rviz"

export DISPLAY="${DISPLAY:-:0}"

# Разрешаем контейнерам ходить в X11 (только локально)
command -v xhost >/dev/null 2>&1 && xhost +local:docker >/dev/null 2>&1 || true

# Перезапуск контейнера RViz
docker rm -f "$NAME" >/dev/null 2>&1 || true

docker run --rm -it \
  --name "$NAME" \
  --net=host \
  -e DISPLAY="$DISPLAY" \
  -e ROS_MASTER_URI="$ROS_MASTER" \
  -e ROS_IP="$ROS_IP" \
  -e ROS_HOSTNAME= \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v /home/pi5/ros1_horizon/ws:/ws:rw \
  "$IMG" \
  bash -lc "source /opt/ros/noetic/setup.bash && rviz -d '$RVIZ_CFG'"
