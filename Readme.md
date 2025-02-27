# Ping pong in the browser

- We want to have a ping pong game in the browser.
- Backend in OCaml -> Dream?
- Frontend: HTML5 Canvas + Javascript (js_of_ocaml)?
- Communication: WebSockets? 

- The frontend listens for keyboard/mouse events, sends actions to the backend
- It receives game state updates from the backend and renders them.

- WebSocket Messages examples:
  - Client to server:
    - `{ "action": "move", "direction": "left" }`
  - Server to client:
    - `{ "ball": { "x": 100, "y": 150 }, "stick1": { "y": 120 }, "stick2": { "y": 200 } }`

# Architecture

- Backend in OCaml using Dream for WebSockets.
- Frontend in OCaml using js_of_ocaml to render the game.
- WebSockets for real-time communication between client and server.

# Steps

- [ ] start playing with Dream
- [ ] start playing with js_of_ocaml
- [ ] simple rendering (a ball)
- [ ] understand websockets
- [ ] simple communication between backend/frontend to move the ball
- [ ] move the ball alone and interact with a stick
- [ ] implement ping pong

## Step1

- [Dream](https://aantron.github.io/dream/)
  - [hello](https://aantron.github.io/dream/)
- `dune build && ./_build/default/backend/hello.exe`
