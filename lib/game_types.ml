open Sexplib.Std

module Ball = struct
  type t = { x : float; y : float; radius : float; dx : float; dy : float }
  [@@deriving sexp]
end

type state = { width : int; height : int; ball : Ball.t } [@@deriving sexp]
type server_message = Init_ack of state | Move_ack of state [@@deriving sexp]
type direction = Up | Down | Left | Right [@@deriving sexp]
type client_message = Init | Move of direction [@@deriving sexp]

let direction_of_string (str : string) : direction option =
  match String.lowercase_ascii str with
  | "up" -> Some Up
  | "down" -> Some Down
  | "left" -> Some Left
  | "right" -> Some Right
  | _ -> None
