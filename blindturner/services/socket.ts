import React from 'react'; // To work @env import

import io from 'socket.io-client';
import { BACKEND_URL } from '@env'; // eslint-disable-line

const randomNumber = Math.floor(Math.random() * 1000);

const socket = io(BACKEND_URL as string, {
  path: "/socket.io",
  transports: ["websocket"],
  auth: { web_id: randomNumber }
});

export default socket;
export { randomNumber };