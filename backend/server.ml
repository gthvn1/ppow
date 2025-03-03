open Lwt.Infix

let state : Game_types.state =
  {
    ball = { x = 100.; y = 100.; radius = 10.; dx = 2.; dy = 2. };
    width = 400;
    height = 300;
  }

(* Websocket handler *)
let websocket_handler websocket =
  Dream.log "Client connected!";

  let rec echo_loop () =
    Dream.receive websocket >>= function
    | None ->
        Dream.log "Client disconnected!";
        Lwt.return_unit
    | Some msg -> (
        Dream.log "Received: %s" msg;
        let client_msg = Sexplib.Sexp.of_string msg in
        match Game_types.client_message_of_sexp client_msg with
        | Game_types.Init ->
            let sexp = Game_types.sexp_of_server_message (Init_ack state) in
            let resp = Sexplib.Sexp.to_string sexp in
            Dream.send websocket resp >>= echo_loop
        | Game_types.Move _ ->
            let sexp = Game_types.sexp_of_server_message (Move_ack state) in
            let resp = Sexplib.Sexp.to_string sexp in
            Dream.send websocket resp >>= echo_loop)
  in
  echo_loop ()

let () =
  Dream.run @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/" (fun _ -> Dream.html "hello world");
         Dream.get "/ws" (fun _ -> Dream.websocket websocket_handler);
       ]
