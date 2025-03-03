open Sexplib.Std

type ball = { x : float; y : float; radius : float; dx : float; dy : float }
[@@deriving sexp]

type state = { width : int; height : int; ball : ball } [@@deriving sexp]

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
