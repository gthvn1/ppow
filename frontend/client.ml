(* client.ml *)

let () =
  let open Js_of_ocaml in
  let onload _ =
    let doc = Dom_html.document in
    let h1 = Dom_html.createH1 doc in
    h1##.textContent := Js.some (Js.string "Hello from OCaml!");
    Dom.appendChild doc##.body h1;
    Js._false
  in
  Dom_html.window##.onload := Dom_html.handler onload
