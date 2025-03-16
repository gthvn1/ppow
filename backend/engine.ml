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

let ball_paddle_collision (state : G.state) (p : G.paddle) : G.state =
  let b = state.ball in

  (* update the position *)
  let x = b.x +. b.dx in
  let y = b.y +. b.dy in

  (* check if the ball hit the paddle *)
  let hit = ball_hit_rect (x, y, b.radius) (p.x, p.y, p.width, p.height) in
  let x, y, dx, dy =
    match hit with
    | None -> (x, y, b.dx, b.dy)
    | Some Left -> (p.x -. b.radius, y, -.b.dx, b.dy)
    | Some Right -> (p.x +. p.width +. b.radius, y, -.b.dx, b.dy)
    | Some Top -> (x, p.y -. b.radius, b.dx, -.b.dy)
    | Some Bottom -> (x, p.y +. p.height +. b.radius, b.dx, -.b.dy)
  in
  { state with ball = { state.ball with x; y; dx; dy } }

let ball_boundaries_collision (state : G.state) : G.state =
  let b = state.ball in
  (* update the position *)
  let x = b.x +. b.dx in
  let y = b.y +. b.dy in
  (* check if the ball hit boundaries *)
  let x, dx =
    if x -. b.radius < 0. then (b.radius, -.b.dx)
    else if x +. b.radius > float state.width then
      (float state.width -. b.radius, -.b.dx)
    else (x, b.dx)
  in
  let y, dy =
    if y -. b.radius < 0. then (b.radius, -.b.dy)
    else if y +. b.radius > float state.height then
      (float state.height -. b.radius, -.b.dy)
    else (y, b.dy)
  in
  { state with ball = { state.ball with x; y; dx; dy } }

let update_state (state : G.state) =
  (* paddles_lst is (id, paddle) *)
  let paddles_lst = G.PMap.to_list state.paddles |> List.map snd in
  List.fold_left ball_paddle_collision state paddles_lst
  |> ball_boundaries_collision

let two_paddles_in_collision (p1 : G.paddle) (p2 : G.paddle) : bool =
  if p1.x +. p1.width <= p2.x then false
  else if p1.x >= p2.x +. p2.width then false
  else if p1.y +. p1.height <= p2.y then false
  else if p1.y >= p2.y +. p2.height then false
  else true

(** [move_paddle state direction] moves the paddle in the given direction. It
    expected to be called with the state under a mutex lock. *)
let move_paddle (state : G.state) (direction : G.direction) (id : int) : G.state
    =
  match G.PMap.find_opt id state.paddles with
  | None ->
      Printf.eprintf "ERROR: Paddle with id %d not found\n" id;
      state
  | Some paddle ->
      let max_height = float state.height -. paddle.height in
      let max_width = float state.width -. paddle.width in
      (* Helper function to constraint the deplacement of the paddle *)
      let clamp min_val max_val v =
        if v < min_val then min_val else if v > max_val then max_val else v
      in
      (* Helper function to check if the given paddle collidse with others *)
      let paddle_collides paddle =
        let p_lst = G.PMap.to_list state.paddles in
        List.fold_left
          (fun acc (p_id, p) ->
            if p_id = id then acc || false
            else acc || two_paddles_in_collision paddle p)
          false p_lst
      in
      let delta = 10. in
      let new_paddle : G.paddle =
        match direction with
        | Up -> { paddle with y = clamp 0. max_height (paddle.y -. delta) }
        | Down -> { paddle with y = clamp 0. max_height (paddle.y +. delta) }
        | Left -> { paddle with x = clamp 0. max_width (paddle.x -. delta) }
        | Right -> { paddle with x = clamp 0. max_width (paddle.x +. delta) }
      in
      if paddle_collides new_paddle then state
      else
        {
          state with
          paddles = G.PMap.update id (fun _ -> Some new_paddle) state.paddles;
        }
