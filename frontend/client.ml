(* client.ml *)
open Js_of_ocaml
module G = Game_types

let doc = Dom_html.document
let ball : G.ball ref = ref { G.x = 0.; y = 0.; radius = 0.; dx = 0.; dy = 0. }
let paddles : G.paddle G.PMap.t ref = ref G.PMap.empty

let create_title (str : string) =
  let h1 = Dom_html.createH1 doc in
  h1##.textContent := Js.some (Js.string str);
  h1

let create_usage (str : string) =
  let p = Dom_html.createP doc in
  p##.textContent := Js.some (Js.string str);
  p

let create_input () =
  let input = Dom_html.createInput doc ~_type:(Js.string "text") in
  input##.placeholder := Js.string "up, down, left or right";
  input

let create_button (label : string) =
  let button = Dom_html.createButton doc in
  button##.textContent := Js.some (Js.string label);
  button

let create_status () =
  let p = Dom_html.createP doc in
  (* Set the ID *)
  p##.id := Js.string "status";
  p##.textContent := Js.some (Js.string "Connecting...");
  p

let create_canvas (width : int) (height : int) =
  let canvas = Dom_html.createCanvas doc in
  canvas##.width := width;
  canvas##.height := height;
  canvas##.style##.border := Js.string "1px solid black";
  canvas

let animate (ctx : Dom_html.canvasRenderingContext2D Js.t)
    (canvas : Dom_html.canvasElement Js.t) =
  let rec loop _timestamp =
    (* Clear canvas *)
    ctx##clearRect (Js.float 0.) (Js.float 0.)
      (Js.float (float canvas##.width))
      (Js.float (float canvas##.height));

    ctx##beginPath;
    (* Draw ball *)
    ctx##arc (Js.float !ball.x) (Js.float !ball.y) (Js.float !ball.radius)
      (Js.float 0.)
      (Js.float (2. *. Float.pi))
      Js._false;
    ctx##.fillStyle := Js.string "white";
    ctx##fill;
    ctx##.lineWidth := Js.float 4.;
    ctx##.strokeStyle := Js.string "black";
    ctx##stroke;

    let paddle_lst = G.PMap.to_list !paddles in
    List.iter
      (fun (_id, (paddle : G.paddle)) ->
        ctx##rect (Js.float paddle.x) (Js.float paddle.y)
          (Js.float paddle.width) (Js.float paddle.height);
        ctx##stroke)
      paddle_lst;
    ctx##closePath;

    (* Request next animation frame *)
    ignore (Dom_html.window##requestAnimationFrame (Js.wrap_callback loop))
  in
  ignore (Dom_html.window##requestAnimationFrame (Js.wrap_callback loop))

let start_game width height =
  let canvas = create_canvas width height in
  Dom.appendChild doc##.body canvas;

  Graphics_js.open_canvas canvas;
  Dom.appendChild doc##.body canvas;

  let ctx = canvas##getContext Dom_html._2d_ in

  animate ctx canvas

let setup_websocket () =
  let ws = new%js WebSockets.webSocket (Js.string "ws://localhost:8080/ws") in

  ws##.onopen :=
    Dom.handler (fun _ev ->
        Js.Opt.iter
          (doc##getElementById (Js.string "status"))
          (fun status ->
            status##.textContent := Js.some (Js.string "Connected!"));

        (* Send "init" message only when the WebSocket is open *)
        let init_msg =
          Sexplib.Sexp.to_string @@ G.(sexp_of_client_message Init)
        in
        ws##send (Js.string init_msg);

        Js._false);

  ws##.onmessage :=
    Dom.handler (fun ev ->
        let msg = Js.to_string ev##.data in
        (*print_endline @@ "Received from server: " ^ msg;*)
        let server_msg = Sexplib.Sexp.of_string msg in
        match G.server_message_of_sexp server_msg with
        | Init_ack (width, height) ->
            Js_of_ocaml.Console.console##log
              (Printf.sprintf "Received init ack: %d %d" width height);
            (* Now create the canvas and start the game *)
            start_game width height;
            Js._false
        | Move_ack ->
            Js_of_ocaml.Console.console##log "Received move ack";
            Js._false
        | Update state ->
            ball := state.G.ball;
            paddles := state.G.paddles;
            Js_of_ocaml.Console.console##log "Received state update";
            Js._false);
  ws

let onload _ =
  create_title "PPoW: Ping Pong on the Web" |> Dom.appendChild doc##.body;

  let input = create_input () in
  let btn = create_button "Send" in
  let usage =
    create_usage "Use arrow keys to move the paddle, or use the text input"
  in
  let status = create_status () in
  let ws = setup_websocket () in

  (* Create a DIV to group the input and the button *)
  let div = Dom_html.createDiv doc in
  Dom.appendChild div input;
  Dom.appendChild div btn;

  Dom.appendChild doc##.body usage;
  Dom.appendChild doc##.body div;
  Dom.appendChild doc##.body status;

  (* Setup handler when key is pressed. We want to manage up, down, left and right *)
  let handle_key_event ev =
    let dir =
      match ev##.keyCode with
      | 37 -> Some G.Left
      | 38 -> Some G.Up
      | 39 -> Some G.Right
      | 40 -> Some G.Down
      | _ -> None
    in
    if Option.is_some dir then (
      Js_of_ocaml.Console.console##log "Got some direction";
      let m = G.Move (Option.get dir) in
      let move_msg = Sexplib.Sexp.to_string @@ G.(sexp_of_client_message m) in
      ws##send (Js.string move_msg))
    else Js_of_ocaml.Console.console##log (Js.string "key not managed");
    Js._true
  in
  let ignored_keycode = ref (-1) in
  Dom_html.(
    document##.onkeydown :=
      handler (fun e ->
          ignored_keycode := e##.keyCode;
          handle_key_event e);
    document##.onkeypress :=
      handler (fun e ->
          let k = !ignored_keycode in
          ignored_keycode := -1;
          if e##.keyCode = k then Js._true else handle_key_event e));

  (* Setup the handler when Send button is pressed *)
  btn##.onclick :=
    Dom_html.handler (fun _ ->
        let msg = Js.to_string input##.value in
        match G.direction_of_string msg with
        | None ->
            Js_of_ocaml.Console.console##log
              (Printf.sprintf "%s is not a valid direction" msg);
            Js._true
        | Some d ->
            (if ws##.readyState = WebSockets.OPEN then
               let m = G.Move d in

               let move_msg =
                 Sexplib.Sexp.to_string @@ G.(sexp_of_client_message m)
               in
               ws##send (Js.string move_msg));
            Js._true);

  Js._true

let () = Dom_html.window##.onload := Dom_html.handler onload
