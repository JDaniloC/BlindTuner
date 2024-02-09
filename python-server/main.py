from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from fastapi import FastAPI
import socketio

sio = socketio.AsyncServer(async_mode='asgi',
                           cors_allowed_origins=[])
socket_app = socketio.ASGIApp(sio)

app = FastAPI(title="Controller server", docs_url="/api/docs")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.mount("", socket_app)

class Coordinates(BaseModel):
    angle_width: float | None
    angle_width: float | None
    direction: str
    web_id: int
    shot: bool

class Session(BaseModel):
    sid: str
    web_id: int

server_map: dict[int, str] = dict()

@sio.event
async def connect(sid: str, environ: dict):
    print(f"Connected: {sid}")

@sio.event
async def connect(sid: str, environ: dict, auth: Session):
    if auth:
        session = Session(sid=sid, web_id=auth["web_id"])
        server_map[session.web_id] = session.sid
        await sio.save_session(sid, session)
        print(f"Connected: {session}")

@sio.on('controller')
async def control_handler(sid: str, data: Coordinates, *args, **kwargs):
    print(f"Received: {sid} {data} {args} {kwargs}")
    control = Coordinates(**data)
    server_sid = server_map[control.web_id]
    if server_sid is not None:
        await sio.emit('control', data, to=server_sid)

@sio.event
async def disconnect(sid: str):
    session: Session = await sio.get_session(sid)
    if session: del server_map[session.web_id]
