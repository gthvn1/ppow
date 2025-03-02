(* client.ml *)
open Js_of_ocaml

let doc = Dom_html.document

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
  input##.placeholder := Js.string "Enter a message...";
  input

let create_button (label : string) =
  let button = Dom_html.createButton doc in
  button##.textContent := Js.some (Js.string label);
  button

let create_canvas () =
  let canvas = Dom_html.createCanvas doc in
  canvas##.width := 800;
  canvas##.height := 600;
  canvas##.style##.border := Js.string "1px solid black";
  canvas

let animate ctx canvas =
  let rec loop ball _timestamp =
    (* Clear canvas *)
    ctx##clearRect 0. 0.
      (float_of_int canvas##.width)
      (float_of_int canvas##.height);

    (* Draw ball *)
    ctx##beginPath;
    ctx##arc (Ball.x ball) (Ball.y ball) (Ball.radius ball) 0. (2. *. Float.pi)
      Js._false;
    ctx##.fillStyle := Js.string "green";
    ctx##fill;
    ctx##closePath;

    (* Request next animation frame *)
    ignore
      (Dom_html.window##requestAnimationFrame
         (Js.wrap_callback @@ loop (Ball.update_position ball)))
  in
  ignore
    (Dom_html.window##requestAnimationFrame
       (Js.wrap_callback @@ loop (Ball.new_ball canvas##.width canvas##.height)))

let onload _ =
  create_title "PPoW: Ping Pong on the Web" |> Dom.appendChild doc##.body;

  create_input () |> Dom.appendChild doc##.body;
  create_button "Send" |> Dom.appendChild doc##.body;

  create_usage "Use the arrow keys to move the stick (not yet implemented)"
  |> Dom.appendChild doc##.body;

  let canvas = create_canvas () in
  Graphics_js.open_canvas canvas;
  Dom.appendChild doc##.body canvas;

  let ctx = canvas##getContext Dom_html._2d_ in

  animate ctx canvas;

  Js._true

let () = Dom_html.window##.onload := Dom_html.handler onload
