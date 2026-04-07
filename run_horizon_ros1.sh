#!/usr/bin/env bash
set -euo pipefail

C=ros1_noetic_horizon

# ВАЖНО: broadcast code, который реально видит SDK (у тебя в логах он с хвостом "1")
BC="${1:-3WEDH5900101971}"
HOST_IP="${2:-192.168.123.100}"
LIDAR_IP="${3:-192.168.123.51}"

docker exec -u 0 "$C" bash -lc "
set -e
CFG=/ws/catkin_ws/src/livox_ros_driver/livox_ros_driver/config/livox_lidar_config.json
test -f \"\$CFG\"

python3 - <<PY
import json
cfg_path = \"$CFG\"
bc = \"$BC\"
host_ip = \"$HOST_IP\"
lidar_ip = \"$LIDAR_IP\"

with open(cfg_path,'r') as f:
    data=json.load(f)

# вычищаем и оставляем РОВНО один lidar в конфиге
entry = {
  \"broadcast_code\": bc,
  \"enable_connect\": True,
  \"host_ip\": host_ip,
  \"lidar_ip\": lidar_ip
}

# разные версии конфига: lidar_config или lidar
if isinstance(data.get('lidar_config'), list):
    data['lidar_config'] = [entry]
elif isinstance(data.get('lidar'), list):
    data['lidar'] = [entry]
else:
    data['lidar_config'] = [entry]

with open(cfg_path,'w') as f:
    json.dump(data,f,indent=2)
print('OK patched:', cfg_path)
print('broadcast_code=', bc)
print('host_ip=', host_ip, 'lidar_ip=', lidar_ip)
PY

# жестко гасим всё ROS внутри контейнера (чтобы не было run_id mismatch)
pkill -f rosmaster || true
pkill -f roslaunch || true
pkill -f rosout || true
pkill -f livox_ros_driver_node || true
sleep 1

source /opt/ros/noetic/setup.bash
source /ws/catkin_ws/devel/setup.bash

export ROS_MASTER_URI=http://$HOST_IP:11311
export ROS_IP=$HOST_IP
unset ROS_HOSTNAME

# поднимаем master и сразу драйвер
roscore >/tmp/roscore.log 2>&1 &
sleep 2

exec roslaunch livox_ros_driver livox_lidar_msg.launch --screen
"
