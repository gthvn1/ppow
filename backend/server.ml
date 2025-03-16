open Lwt.Infix
module G = Game_types
module E = Engine

(* keep connected clients. *)
module WebSocketSet = Set.Make (struct
  type t = Dream.websocket

  (* Fix issue#1: Use physical equality instead of structural one *)
  let compare w1 w2 = if w1 == w2 then 0 else -1
end)

let clients_set : WebSocketSet.t ref = ref WebSocketSet.empty
let client_next_id = ref 0
let clients_mutex = Lwt_mutex.create ()

(* State is updated in different threads so we need a shared game state *)
let game_state = Lwt_mvar.create_empty ()

let rec game_loop () =
  let fps = 60. in
  (* frames per second *)
  Lwt_unix.sleep (1. /. fps) >>= fun () ->
  Lwt_mvar.take game_state >>= fun state ->
  let new_state = E.update_state state in
  Lwt_mvar.put game_state new_state >>= fun () ->
  let sexp = G.sexp_of_server_message (Update new_state) in
  let resp = Sexplib.Sexp.to_string sexp in
  (* Now that we have the new game state we can send it to all connected clients *)
  Lwt_mutex.lock clients_mutex >>= fun () ->
  WebSocketSet.to_list !clients_set
  |> Lwt_list.iter_p (fun client -> Dream.send client resp)
  >>= fun () ->
  Lwt_mutex.unlock clients_mutex;
  game_loop ()

(* Websocket handler *)
let websocket_handler websocket =
  (* Get an ID to be able to associate a paddle with client *)
  Lwt_mutex.lock clients_mutex >>= fun () ->
  let myid = !client_next_id in
  clients_set := WebSocketSet.add websocket !clients_set;
  Dream.log "Client connected with id %d!" myid;
  client_next_id := !client_next_id + 1;
  Lwt_mutex.unlock clients_mutex;

  (* We have an id so we can create the paddle *)
  Lwt_mvar.take game_state >>= fun state ->
  let p : G.paddle = { x = 30.; y = 40.; width = 5.; height = 40. } in
  let new_state = { state with paddles = G.PMap.add myid p state.paddles } in
  Lwt_mvar.put game_state new_state >>= fun () ->
  (* main loop *)
  let rec loop () =
    Dream.receive websocket >>= function
    | None ->
        (* Remove the client from the set *)
        Dream.log "Client disconnected!";
        Lwt_mutex.lock clients_mutex >>= fun () ->
        clients_set := WebSocketSet.remove websocket !clients_set;
        Lwt_mutex.unlock clients_mutex;
        (* Remove the paddle *)
        Lwt_mvar.take game_state >>= fun state ->
        let new_state =
          { state with paddles = G.PMap.remove myid state.paddles }
        in
        Lwt_mvar.put game_state new_state >>= fun () ->
        Dream.close_websocket websocket
    | Some msg -> (
        Dream.log "Received from id %d: %s" myid msg;
        let client_msg = Sexplib.Sexp.of_string msg in
        match G.client_message_of_sexp client_msg with
        | G.Init ->
            Lwt_mvar.take game_state >>= fun state ->
            let width = state.width in
            let height = state.height in
            Lwt_mvar.put game_state state >>= fun () ->
            let sexp = G.sexp_of_server_message (Init_ack (width, height)) in
            let resp = Sexplib.Sexp.to_string sexp in
            Dream.send websocket resp >>= loop
        | G.Move d ->
            Lwt_mvar.take game_state >>= fun state ->
            let new_state = E.move_paddle state d myid in
            Lwt_mvar.put game_state new_state >>= fun () ->
            let sexp = G.sexp_of_server_message Move_ack in
            let resp = Sexplib.Sexp.to_string sexp in
            Dream.send websocket resp >>= loop)
  in
  loop ()

let () =
  let init_state : G.state =
    {
      G.width = 400;
      G.height = 300;
      G.ball = { x = 100.; y = 100.; radius = 5.; dx = 2.; dy = 2. };
      G.paddles = G.PMap.empty;
    }
  in
  Lwt_mvar.put game_state init_state |> ignore;
  Lwt.async (fun () -> game_loop ());
  Dream.run @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/" (fun _ -> Dream.html "hello world");
         Dream.get "/ws" (fun _ -> Dream.websocket websocket_handler);
       ]
