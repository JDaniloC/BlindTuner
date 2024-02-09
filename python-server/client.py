from pydantic import BaseModel
import socketio
import sys
import socket
import struct

SERVER_URL = 'ws://localhost:8080/wss/'
UDP_ADDR = ('0.0.0.0', 12345)
STRUCT_FORMAT = 'c?'  # char, bool

class Coordinates(BaseModel):
    angle_width: float | None
    angle_width: float | None
    direction: str
    web_id: int
    shot: bool

if len(sys.argv) < 2:
    print("Usage: python client.py <web_id>")
    sys.exit(1)

udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
sio = socketio.Client()
web_id = sys.argv[1]

udp_socket.bind(UDP_ADDR)
sio.connect(SERVER_URL, transports=['websocket'])

while True:
    data, client_addr = udp_socket.recvfrom(struct.calcsize(STRUCT_FORMAT))
    unpacked_data = struct.unpack(STRUCT_FORMAT, data)
    direction = unpacked_data[0]
    shot = unpacked_data[1]

    data = Coordinates(
        direction=direction,
        web_id=web_id,
        shot=shot,
    ).model_dump()
    sio.emit("controller", data)
