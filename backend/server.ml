open Lwt.Infix
module G = Game_types
module E = Engine

(* keep connected clients and their sticks.
   We are expecting a maximum of 4 clients to play a double *)
module WebSocketSet = Set.Make (struct
  type t = Dream.websocket * int

  (* Fix issue#1: Use physical equality instead of structural one *)
  let compare (w1, _) (w2, _) = if w1 == w2 then 0 else -1
end)

let clients_set : WebSocketSet.t ref = ref WebSocketSet.empty
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
  |> Lwt_list.iter_p (fun (client, _) -> Dream.send client resp)
  >>= fun () ->
  Lwt_mutex.unlock clients_mutex;
  game_loop ()

(* Websocket handler *)
let websocket_handler websocket =
  Dream.log "Client connected!";
  Lwt_mutex.lock clients_mutex >>= fun () ->
  (* TODO: as each client will have its own paddle we need to keep the paddle
     associated to the client. *)
  clients_set := WebSocketSet.add (websocket, 0) !clients_set;
  Lwt_mutex.unlock clients_mutex;
  let rec loop () =
    Dream.receive websocket >>= function
    | None ->
        Dream.log "Client disconnected!";
        Lwt_mutex.lock clients_mutex >>= fun () ->
        clients_set := WebSocketSet.remove (websocket, 0) !clients_set;
        Lwt_mutex.unlock clients_mutex;
        Dream.close_websocket websocket
    | Some msg -> (
        Dream.log "Received: %s" msg;
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
            let new_state = E.move_paddle state d in
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
      G.paddle1 = { x = 30.; y = 40.; width = 5.; height = 40. };
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
