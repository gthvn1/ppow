module G = Game_types

let update_state (state : G.state) =
  let b = state.ball in
  let new_x = b.x +. b.dx in
  let new_y = b.y +. b.dy in
  let x, dx =
    if new_x -. b.radius < 0. then (b.radius, -.b.dx)
    else if new_x +. b.radius > float state.width then
      (float state.width -. b.radius, -.b.dx)
    else (new_x, b.dx)
  in
  let y, dy =
    if new_y -. b.radius < 0. then (b.radius, -.b.dy)
    else if new_y +. b.radius > float state.height then
      (float state.height -. b.radius, -.b.dy)
    else (new_y, b.dy)
  in
  { state with ball = { x; y; radius = b.radius; dx; dy } }

let move_stick (state : G.state) (direction : G.direction) =
  match direction with
  | Up -> state
  | Down -> state
  | Left -> state
  | Right -> state
