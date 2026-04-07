#!/usr/bin/env bash
set -euo pipefail

CONTAINER="ros1_noetic_horizon"
COMPOSE_FILE="/home/pi5/ros1_horizon/docker-compose.yml"
MAP_DIR="/home/pi5/ros1_horizon/ws/maps"

run_ros() {
  docker exec -i "$CONTAINER" bash -lc "
    source /opt/ros/noetic/setup.bash
    source /ws/catkin_ws/devel/setup.bash
    export ROS_MASTER_URI=http://127.0.0.1:11311
    export ROS_IP=127.0.0.1
    unset ROS_HOSTNAME
    $1
  "
}

container_exists() {
  docker ps -a --format '{{.Names}}' | grep -qx "$CONTAINER"
}

container_running() {
  docker ps --format '{{.Names}}' | grep -qx "$CONTAINER"
}

need_container() {
  if ! container_running; then
    echo "[slam.sh] container $CONTAINER is not running"
    echo "[slam.sh] run: /home/pi5/slam.sh up"
    exit 1
  fi
}

case "${1:-}" in

  up)
    echo "[slam.sh] starting SLAM container..."
    docker compose -f "$COMPOSE_FILE" up -d slam
    sleep 3
    docker compose -f "$COMPOSE_FILE" ps
    ;;

  driver)
    need_container
    if [[ "${2:-}" == "bg" ]]; then
      echo "[slam.sh] starting Livox driver in background..."
      nohup docker exec -i "$CONTAINER" bash -lc '
        source /opt/ros/noetic/setup.bash
        source /ws/catkin_ws/devel/setup.bash
        export ROS_MASTER_URI=http://127.0.0.1:11311
        export ROS_IP=127.0.0.1
        unset ROS_HOSTNAME
        roslaunch --screen livox_ros_driver livox_lidar_msg.launch
      ' >/tmp/livox_driver.log 2>&1 &
      echo "[slam.sh] livox driver log: /tmp/livox_driver.log"
    else
      echo "[slam.sh] starting Livox driver..."
      run_ros "roslaunch --screen livox_ros_driver livox_lidar_msg.launch"
    fi
    ;;

  bridge)
    need_container
    if [[ "${2:-}" == "bg" ]]; then
      echo "[slam.sh] starting rosbridge in background..."
      nohup docker exec -i "$CONTAINER" bash -lc '
        source /opt/ros/noetic/setup.bash
        source /ws/catkin_ws/devel/setup.bash
        export ROS_MASTER_URI=http://127.0.0.1:11311
        export ROS_IP=127.0.0.1
        unset ROS_HOSTNAME
        roslaunch rosbridge_server rosbridge_websocket.launch port:=9090
      ' >/tmp/rosbridge.log 2>&1 &
      echo "[slam.sh] rosbridge log: /tmp/rosbridge.log"
    else
      echo "[slam.sh] starting rosbridge..."
      run_ros "roslaunch rosbridge_server rosbridge_websocket.launch port:=9090"
    fi
    ;;

  check)
    echo "== docker containers =="
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}" | grep -E "NAMES|ros1_noetic_horizon|livox_noetic_horizon|rosbridge_noetic_horizon|rviz_noetic_horizon" || true
    echo
    echo "== ports (9090/11311) =="
    ss -lntp 2>/dev/null | egrep '9090|11311' || true
    echo

    if ! container_running; then
      echo "[slam.sh] container $CONTAINER is not running"
      exit 1
    fi

    echo "== ROS check =="
    run_ros '
      echo "-- nodes --"
      rosnode list || true
      echo
      echo "-- key topics --"
      rostopic list | egrep "/Laser_map|/Odometry|/cloud_registered|/livox/imu|/livox/lidar|/tf|/path" || true
      echo
      echo "-- topic info /livox/lidar --"
      rostopic info /livox/lidar || true
      echo
      echo "-- topic info /livox/imu --"
      rostopic info /livox/imu || true
      echo
      echo "-- hz livox lidar (3s) --"
      timeout 3 rostopic hz /livox/lidar || true
      echo
      echo "-- hz cloud_registered (3s) --"
      timeout 3 rostopic hz /cloud_registered || true
    '
    ;;

  build)
    need_container
    echo "[slam.sh] building catkin workspace..."
    docker exec -i "$CONTAINER" bash -lc '
      source /opt/ros/noetic/setup.bash
      cd /ws/catkin_ws
      catkin_make
    '
    ;;

  save)
    need_container
    echo "[slam.sh] saving map to $MAP_DIR ..."
    mkdir -p "$MAP_DIR"
    run_ros "
      mkdir -p /ws/maps
      cd /ws/maps
      rosrun pcl_ros pointcloud_to_pcd input:=/Laser_map
    "
    ;;

  logs)
    if container_exists; then
      docker logs -f "$CONTAINER"
    else
      echo "[slam.sh] container $CONTAINER does not exist"
      exit 1
    fi
    ;;

  down)
    echo "[slam.sh] stopping stack..."
    docker compose -f "$COMPOSE_FILE" down --remove-orphans || true
    ;;

  runall)
    echo "[slam.sh] full startup..."
    /home/pi5/slam.sh up
    sleep 3
    /home/pi5/slam.sh driver bg
    sleep 5
    /home/pi5/slam.sh bridge bg
    sleep 2
    /home/pi5/slam.sh check
    ;;

  restart)
    echo "[slam.sh] restarting full stack..."
    /home/pi5/slam.sh down
    sleep 2
    /home/pi5/slam.sh runall
    ;;

  *)
    echo "usage: $0 {up|driver|bridge|check|build|save|logs|down|runall|restart}"
    echo
    echo "examples:"
    echo "  /home/pi5/slam.sh up"
    echo "  /home/pi5/slam.sh driver"
    echo "  /home/pi5/slam.sh driver bg"
    echo "  /home/pi5/slam.sh bridge"
    echo "  /home/pi5/slam.sh bridge bg"
    echo "  /home/pi5/slam.sh check"
    echo "  /home/pi5/slam.sh build"
    echo "  /home/pi5/slam.sh save"
    echo "  /home/pi5/slam.sh logs"
    echo "  /home/pi5/slam.sh down"
    echo "  /home/pi5/slam.sh runall"
    echo "  /home/pi5/slam.sh restart"
    exit 1
    ;;
esac
