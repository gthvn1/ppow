# Ping pong on the Web

- We want to have a ping pong game on the web
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

- [x] start playing with Dream
- [x] start playing with js_of_ocaml
- [x] simple rendering (a ball)
- [x] understand websockets
- [ ] simple communication between backend/frontend to move the ball
- [ ] move the ball alone and interact with a stick
- [ ] implement ping pong

# Changelog

- Can now test that a message can be exchange between client/server:
  - start the server: `./_build/default/backend/server.exe`
  - load the client into browser, click **Send Message**
```sh
❯ ./_build/default/backend/server.exe
02.03.25 14:58:31.674                       Running at http://localhost:8080
02.03.25 14:58:31.674                       Type Ctrl+C to stop
02.03.25 14:58:37.078    dream.logger  INFO REQ 1 GET /ws ::1:53826 fd 6 Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0
02.03.25 14:58:37.078                       REQ 1 Client connected!
02.03.25 14:58:37.078    dream.logger  INFO REQ 1 101 in 106 μs
02.03.25 14:58:39.897                       REQ 1 Received: Hello from client!
02.03.25 14:58:43.135                       REQ 1 Received: Hello from client!
```
- Create a simple client to test the server: `wbesocket_client/client.html`
- Server.ml accept websocket
  - build with `dune build`
  - run: `./_build/default/backend/server.exe`
- Modifying hello.ml into server.ml
- [Dream](https://aantron.github.io/dream/)
  - [hello](https://aantron.github.io/dream/)
- `dune build && ./_build/default/backend/hello.exe`
