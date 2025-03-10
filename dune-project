(lang dune 3.17)

(name ppow)

(generate_opam_files true)

(package
 (name ppow)
 (allow_empty true)
 (license GPL-3.0-only)
 (authors "Me")
 (maintainers "gthvn1@example.com")
 (homepage "https://github.com/gthvn1/ppow")
 (bug_reports "https://github.com/gthvn1/ppow/issues")
 (synopsis "Ping Pong on the Web")
 (version 0.1)
 (depends
   dream
   graphics
   js_of_ocaml
   js_of_ocaml-lwt
   ppx_sexp_conv
   sexplib))
