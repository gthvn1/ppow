open Lwt.Infix
module G = Game_types
module E = Engine

(* list of connected clients *)
let clients = ref []

(* The state is updated in different threads so we need a shared game
state *)
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
  Lwt_list.iter_p (fun websocket -> Dream.send websocket resp) !clients
  >>= fun () -> game_loop ()

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
            Lwt_mvar.take game_state >>= fun state ->
            let width = state.width in
            let height = state.height in
            Lwt_mvar.put game_state state >>= fun () ->
            let sexp = G.sexp_of_server_message (Init_ack (width, height)) in
            let resp = Sexplib.Sexp.to_string sexp in
            Dream.send websocket resp >>= loop
        | G.Move d ->
            Lwt_mvar.take game_state >>= fun state ->
            let new_state = E.move_stick state d in
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
      G.stick1 = { x = 30.; y = 40.; width = 5.; height = 40. };
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
