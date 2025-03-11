open Sexplib.Std

type ball = { x : float; y : float; radius : float; dx : float; dy : float }
[@@deriving sexp]

type paddle = { x : float; y : float; width : float; height : float }
[@@deriving sexp]

module PMap = struct
  include Map.Make (Int)

  (* Convert IntMap.t to Sexp *)
  let sexp_of_t sexp_of_v m =
    to_seq m |> List.of_seq |> [%sexp_of: (int * v) list]

  (* Convert Sexp back to IntMap.t *)
  let t_of_sexp v_of_sexp sexp =
    [%of_sexp: (int * v) list] sexp |> List.to_seq |> of_seq
end

type state = { width : int; height : int; ball : ball; paddles : paddle PMap.t }
[@@deriving sexp]

type server_message = Init_ack of (int * int) | Move_ack | Update of state
[@@deriving sexp]

type direction = Up | Down | Left | Right [@@deriving sexp]
type client_message = Init | Move of direction [@@deriving sexp]

let direction_of_string (str : string) : direction option =
  match String.lowercase_ascii str with
  | "up" -> Some Up
  | "down" -> Some Down
  | "left" -> Some Left
  | "right" -> Some Right
  | _ -> None
