module G = Game_types

(*

  0,0 +--------------------------+
      |                          |
      |      (rx, ry) +----+     |
      |               | R  |     |
      |               | E  |     |
      |               | C  |     |
      |               +----+     |
      |                          |
      |  (cx,cy)  O              |
      |       \  |dx,dy|         |
      |                          |
      +--------------------------+ width, height

# Collisions of the ball with wall:
  - Left Wall   (cx - radius < 0) → Reverse dx
  - Right Wall  (cx + radius > width) → Reverse dx
  - Top Wall    (cy - radius < 0) → Reverse dy
  - Bottom Wall (cy + radius > height) → Reverse dy

# Collisions of the ball with the paddle:
  - Rectangle corners:
    - Left (rx), Right (rx + rw), Top (ry), Bottom (ry + rh)

  - let (px, py) the closest point on the rectangle perimeters to the ball center (cx, cy)
    - example:
      +--------+
      | RECT   |
      |        |
      +----x---+
           ^
           |
           O  Ball at (x, y)

  - the closest point x is (x, ry + rh)
       | if cx < rx then px = rx
       | else if cx < rx + rw then px = cx
       | else px = rx + rw
       <=> px = max rx (min cx (rx + rw))
*)

(* it is the side hit by the ball if any *)
type side = Top | Bottom | Left | Right

(* NOTE: It works if the deplacement of the ball is less than the width of the
         paddle. Otherwise when we compute the new coordinate of the ball it can be
         on the other side of the paddle without detecting the hit. It is tunneling
         effect (I think)...
*)
let closest_point_from_rect (cx, cy) (rx, ry, rw, rh) =
  let px = max rx (min cx (rx +. rw)) in
  let py = max ry (min cy (ry +. rh)) in
  (px, py)

let ball_hit_rect (bx, by, radius) (rx, ry, rw, rh) =
  let x, y = closest_point_from_rect (bx, by) (rx, ry, rw, rh) in
  let dist = sqrt (((bx -. x) ** 2.) +. ((by -. y) ** 2.)) in
  if dist <= radius then
    (* Ball hit the rectangle *)
    Some
      (if x = rx then Left
       else if x = rx +. rw then Right
       else if y = ry then Top
       else if y = ry +. rh then Bottom
       else (
         Printf.eprintf
           "closest point is not on the perimeter... return bottom by default";
         Printf.eprintf "closest point is (%f,%f)\n" x y;
         Printf.eprintf "ball at (%f, %f)\n" bx by;
         Printf.eprintf "rect at (%f, %f, w:%f, h:%f)\n" rx ry rw rh;
         Printf.eprintf "distance = %f , radius = %f\n%!" dist radius;
         Bottom))
  else
    (* No collision *)
    None

let update_state (state : G.state) =
  let b = state.ball in
  let rect = state.paddle1 in
  (* update the position *)
  let x = b.x +. b.dx in
  let y = b.y +. b.dy in
  (* check if the ball hit the paddle *)
  let hit =
    ball_hit_rect (x, y, b.radius) (rect.x, rect.y, rect.width, rect.height)
  in
  let x, y, dx, dy =
    match hit with
    | None -> (x, y, b.dx, b.dy)
    | Some Left -> (rect.x -. b.radius, y, -.b.dx, b.dy)
    | Some Right -> (rect.x +. rect.width +. b.radius, y, -.b.dx, b.dy)
    | Some Top -> (x, rect.y -. b.radius, b.dx, -.b.dy)
    | Some Bottom -> (x, rect.y +. rect.height +. b.radius, b.dx, -.b.dy)
  in
  (* check if the ball hit boundaries *)
  let x, dx =
    if x -. b.radius < 0. then (b.radius, -.dx)
    else if x +. b.radius > float state.width then
      (float state.width -. b.radius, -.dx)
    else (x, dx)
  in
  let y, dy =
    if y -. b.radius < 0. then (b.radius, -.dy)
    else if y +. b.radius > float state.height then
      (float state.height -. b.radius, -.dy)
    else (y, dy)
  in
  { state with ball = { state.ball with x; y; dx; dy } }

let move_paddle (state : G.state) (direction : G.direction) : G.state =
  let s = state.paddle1 in
  (* Helper function to constraint the deplacement of the paddle *)
  let clamp min_val max_val v =
    if v < min_val then min_val else if v > max_val then max_val else v
  in
  let max_height = float state.height -. s.height in
  let max_width = float state.width -. s.width in
  let new_paddle : G.paddle =
    match direction with
    | Up -> { s with y = clamp 0. max_height (s.y -. 10.) }
    | Down -> { s with y = clamp 0. max_height (s.y +. 10.) }
    | Left -> { s with x = clamp 0. max_width (s.x -. 10.) }
    | Right -> { s with x = clamp 0. max_width (s.x +. 10.) }
  in
  { state with paddle1 = new_paddle }
