<img src="images/screenshot_two_clients.png" alt="OCaml plays ping pong" />

# Intro

We are developing a ping pong game on the web to learn how the frontend and backend communicate.
The game is written in OCaml because we enjoy working with the language and we want to enhance our
skills.

- Tech Stack:

  - Backend: OCaml with [Dream](https://aantron.github.io/dream/)
  - Frontend: HTML5 Canvas + [js_of_ocaml](https://ocsigen.org/js_of_ocaml/latest/manual/overview)
    - Here are [some examples](https://github.com/ocsigen/js_of_ocaml/blob/master/examples)
  - Communication: [WebSocket](https://developer.mozilla.org/en-US/docs/Web/API/WebSocket)

- How It Works:

  - A new paddle is created for each client that connects.
  - Clients can interact with the ball using its paddle (currently the only action available).
  - The frontend listens for keyboard events and sends actions to the backend.
  - The backend processes these actions, updates the game state, and sends updates to all clients.
  - The frontend receives these updates and renders the game state accordingly.

- Serialization:

  - WebSocket messages are serialized using _S-expressions_, as both the backend and frontend are written in OCaml. This makes it easier to serialize and deserialize OCaml values.

# Build & run

- Personally we work in a local switch: `opam switch create ./`
  - my compiler is `ocaml-base-compiler.5.3.0`, also tested with `5.2.1`
- when developing you can install extra packages like *ocaml-lsp-server*,
  *ocamlformat*, *utop*, etc...
  - ensure your environment is properly updated: `eval $(opam env)`
- if you use a local switch everything should be already installed
  - otherwise install dependencies: `opam install . --deps-only`
  - update your environment: `eval $(opam env)`
- build ppow: `dune build`
- run the server: `dune exec ppow_server` or `./_build/default/backend/server.exe`
- start client: open the `index.html` in the browser
  - you can start another client by openning the `index.html` in another tab or another browser.
- You can also install it: `dune install`
- once installed in your switch you should be able to run: `ppow_server`

# Todo

- [x] start playing with Dream
- [x] start playing with js_of_ocaml
- [x] simple rendering (a ball)
- [x] understand websockets
- [x] simple communication between backend/frontend to move the ball
- [x] move the ball alone
- [x] move one paddle
- [x] add interaction between paddle and ball
- [x] handle multiple connections
- [x] add another paddle managed by others clients
- [ ] add rules to implement something that looks like ping pong

# Changelog

- `2025-03-16`:
  - Add `shell.nix`
  - Display all paddles. Now if we connect another client
  we see two paddles. Only the first one is managed so it is the next
  step to manage all paddles.
  - Manage collision between ball and all paddles
  - Manage collision between paddles
  - Client manages his own paddle

- `2025-03-11`:
  - Use a Map to keep track of paddles in the game
    - the paddle is associated to an ID
    - the ID is the client ID so from the server we will be able to only
    move the paddle of a client (not yet implemented)
    - each client owns a paddle
  - Keep track of the next ID
  - Generate a paddle when the client is connected
  - Remove the paddle when the client is disconnected
  - We generate several paddle but we only update the first one

- `2025-03-08`:
  - Detect hits with boundaries and paddle

- `2025-03-05`:
  - Use another CSS and group input and button in a div
  - Fix an issue when hitting walls with the ball
  - Add the first paddle
  - Move the paddle by sending message
  - Move the paddle using arrow keys
    - TODO: it moves but we need to manage boundaries and collision

- `2025-03-03`:
  - Remove `websocket_client` because frontend is working now
  - Create `lib/game_types.ml` that describes
    - the state of the game
    - the client message
      - init to get the canvas size and the ball position
      - move to direction
    - the server message
      - ack to init
      - ack to move
    - Init of canvas is done
    - Messages are exchanged
    - Ball is moving... next is interaction
```sh
❯ dune build && ./_build/default/backend/server.exe
03.03.25 19:46:48.853                       Running at http://localhost:8080
03.03.25 19:46:48.853                       Type Ctrl+C to stop
03.03.25 19:46:52.173    dream.logger  INFO REQ 1 GET /ws ::1:39938 fd 6 Mozilla/5.0 (X11; Linux x86_64; rv:128.0) Gecko/20100101 Firefox/128.0
03.03.25 19:46:52.173                       REQ 1 Client connected!
03.03.25 19:46:52.173    dream.logger  INFO REQ 1 101 in 79 μs
03.03.25 19:46:52.185                       REQ 1 Received: Init
03.03.25 19:46:57.243                       REQ 1 Received: (Move Up)
03.03.25 19:47:01.971                       REQ 1 Received: (Move Left)
```
- `2025-03-02`:
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

- `2025-03-01`:
    - Create a simple client to test the server: `wbesocket_client/client.html`
    - Server.ml accept websocket
      - build with `dune build`
      - run: `./_build/default/backend/server.exe`
    - Modifying hello.ml into server.ml
    - [Dream](https://aantron.github.io/dream/)
      - [hello](https://aantron.github.io/dream/)
    - `dune build && ./_build/default/backend/hello.exe`
