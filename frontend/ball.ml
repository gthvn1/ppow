type t = {
  x : float;
  y : float;
  radius : float;
  dx : float;
  dy : float;
  width : int;
  height : int;
}

let new_ball (width : int) (height : int) : t =
  { x = 100.; y = 100.; radius = 10.; dx = 2.; dy = 2.; width; height }

let radius (ball : t) : float = ball.radius
let x (ball : t) : float = ball.x
let y (ball : t) : float = ball.y

let update_position (ball : t) : t =
  let new_x = ball.x +. ball.dx in
  let new_y = ball.y +. ball.dy in

  let new_dx =
    if
      new_x +. ball.radius > float_of_int ball.width
      || new_x -. ball.radius < 0.
    then -.ball.dx
    else ball.dx
  in

  let new_dy =
    if
      new_y +. ball.radius > float_of_int ball.height
      || new_y -. ball.radius < 0.
    then -.ball.dy
    else ball.dy
  in
  { ball with x = new_x; y = new_y; dx = new_dx; dy = new_dy }
