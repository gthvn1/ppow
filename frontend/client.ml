(* client.ml *)
open Js_of_ocaml

let doc = Dom_html.document

let draw_rectangle context =
  context##fillRect 50. 50. 100. 100. (* Draws a rectangle *)

let create_canvas () =
  (* Create canvas *)
  let canvas = Dom_html.createCanvas doc in
  canvas##.width := 800;
  canvas##.height := 600;
  canvas

let create_header (str : string) =
  let h1 = Dom_html.createH1 doc in
  h1##.textContent := Js.some (Js.string str);
  h1

let onload _ =
  let h1 = create_header "Hello from OCaml" in
  Dom.appendChild doc##.body h1;

  let canvas = create_canvas () in
  Graphics_js.open_canvas canvas;
  Dom.appendChild doc##.body canvas;

  let ctx = canvas##getContext Dom_html._2d_ in
  draw_rectangle ctx;

  Js._true

let () = Dom_html.window##.onload := Dom_html.handler onload
