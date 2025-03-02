open Lwt.Infix

(* Websocket handler *)
let websocket_handler websocket =
  Dream.log "Client connected!";

  let rec echo_loop () =
    Dream.receive websocket >>= function
    | None ->
        Dream.log "Client disconnected!";
        Lwt.return_unit
    | Some msg ->
        Dream.log "Received: %s" msg;
        Dream.send websocket msg >>= echo_loop
  in
  echo_loop ()

let () =
  Dream.run @@ Dream.logger
  @@ Dream.router
       [
         Dream.get "/" (fun _ -> Dream.html "hello world");
         Dream.get "/ws" (fun _ -> Dream.websocket websocket_handler);
       ]
