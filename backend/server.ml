open Lwt.Infix
module G = Game_types

(* list of connected clients *)
let clients = ref []
let board_width = ref 400
let board_height = ref 300

let update_state (state : G.state) =
  let b = state.ball in
  let new_x = b.x +. b.dx in
  let new_y = b.y +. b.dy in
  let x, dx =
    if new_x -. b.radius < 0. then (b.radius, -.b.dx)
    else if new_x +. b.radius > float state.width then
      (float state.width -. b.radius, -.b.dx)
    else (new_x, b.dx)
  in
  let y, dy =
    if new_y -. b.radius < 0. then (b.radius, -.b.dy)
    else if new_y +. b.radius > float state.height then
      (float state.height -. b.radius, -.b.dy)
    else (new_y, b.dy)
  in
  { state with ball = { x; y; radius = b.radius; dx; dy } }

let rec game_loop (state : G.state) =
  let fps = 60. in
  (* frames per second *)
  Lwt_unix.sleep (1. /. fps) >>= fun () ->
  let new_state = update_state state in
  let sexp = G.sexp_of_server_message (Update new_state) in
  let resp = Sexplib.Sexp.to_string sexp in
  Lwt_list.iter_p (fun websocket -> Dream.send websocket resp) !clients
  >>= fun () -> game_loop new_state

(* Websocket handler *)
let websocket_handler websocket =
  Dream.log "Client connected!";
  clients := websocket :: !clients;

  let rec loop () =
    Dream.receive websocket >>= function
    | None ->
        Dream.log "Client disconnected!";
        clients := List.filter (fun w -> w <> websocket) !clients;
        Lwt.return_unit
    | Some msg -> (
        Dream.log "Received: %s" msg;
        let client_msg = Sexplib.Sexp.of_string msg in
        match G.client_message_of_sexp client_msg with
        | G.Init ->
            let sexp =
              G.sexp_of_server_message (Init_ack (!board_width, !board_height))
            in
            let resp = Sexplib.Sexp.to_string sexp in
            Dream.send websocket resp >>= loop
        | G.Move _ ->
            let sexp = G.sexp_of_server_message Move_ack in
            let resp = Sexplib.Sexp.to_string sexp in
            Dream.send websocket resp >>= loop)
  in
  loop ()

let () =
  let state : G.state =
    {
      ball : G.ball = { x = 100.; y = 100.; radius = 10.; dx = 2.; dy = 2. };
      stick1 : G.stick = { G.x = 30.; y = 40.; width = 2.; height = 40. };
      width = !board_width;
      height = !board_height;
    }
  in

  Lwt.async (fun () -> game_loop state);
  Dream.run @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/" (fun _ -> Dream.html "hello world");
         Dream.get "/ws" (fun _ -> Dream.websocket websocket_handler);
       ]
