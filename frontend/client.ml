(* client.ml *)
open Js_of_ocaml

let doc = Dom_html.document

let create_canvas () =
  (* Create canvas *)
  let canvas = Dom_html.createCanvas doc in
  canvas##.width := 800;
  canvas##.height := 600;
  canvas

let create_title (str : string) =
  let h1 = Dom_html.createH1 doc in
  h1##.textContent := Js.some (Js.string str);
  h1

let create_usage (str : string) =
  let p = Dom_html.createP doc in
  p##.textContent := Js.some (Js.string str);
  p

(* Ball properties *)
let ball_x = ref 100.
let ball_y = ref 100.
let ball_radius = 10.
let dx = ref 2.
let dy = ref 2.

let animate ctx canvas =
  let rec loop _timestamp =
    (* Clear canvas *)
    ctx##clearRect 0. 0.
      (float_of_int canvas##.width)
      (float_of_int canvas##.height);

    (* Draw ball *)
    ctx##beginPath;
    ctx##arc !ball_x !ball_y ball_radius 0. (2. *. Float.pi) Js._false;
    ctx##.fillStyle := Js.string "green";
    ctx##fill;
    ctx##closePath;

    (* Update ball position *)
    ball_x := !ball_x +. !dx;
    ball_y := !ball_y +. !dy;

    (* Check for wall collisions *)
    if
      !ball_x +. ball_radius > float_of_int canvas##.width
      || !ball_x -. ball_radius < 0.
    then dx := -. !dx;
    if
      !ball_y +. ball_radius > float_of_int canvas##.height
      || !ball_y -. ball_radius < 0.
    then dy := -. !dy;

    (* Request next animation frame *)
    ignore (Dom_html.window##requestAnimationFrame (Js.wrap_callback loop))
  in
  ignore (Dom_html.window##requestAnimationFrame (Js.wrap_callback loop))

let onload _ =
  create_title "PPoW: Ping Pong on the Web" |> Dom.appendChild doc##.body;

  create_usage "Use the arrow keys to move the stick (not yet implemented)"
  |> Dom.appendChild doc##.body;

  let canvas = create_canvas () in
  Graphics_js.open_canvas canvas;
  Dom.appendChild doc##.body canvas;

  let ctx = canvas##getContext Dom_html._2d_ in

  animate ctx canvas;

  Js._true

let () = Dom_html.window##.onload := Dom_html.handler onload
