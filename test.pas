uses SDL, math;

type
  bytePtr = ^byte;

  tpoint = record
    x, y: integer;
  end;
  ppoint = ^tpoint;

  tpoly = record
    points: array[1..24] of tpoint;
    npoints: byte;
    r, g, b: byte;
  end;
  ppoly = ^tpoly;

var
  disp: PSDL_Surface;
  dispw, disph: integer;
  polys: array[1..100] of tpoly;
  npolys: integer;

procedure putPixel(x, y: integer; r, g, b: byte);
var
  p: bytePtr;
begin
  if (x < 0) or (y < 0) or (x >= dispw) or (y >= disph) then exit;
  p := bytePtr(disp^.pixels + (y*dispw + x)*4);
  p^ := b;
  (p+1)^ := g;
  (p+2)^ := r;
end;

procedure drawPoly(p: ppoly);
var
  i: qword;
  buf: array of boolean;
  x1, y1, x2, y2: integer;
  xx1, yy1, xx2, yy2: integer;
  bw, bh, x, y, j: integer;
begin
  x1 := dispw;
  y1 := disph;
  x2 := 0;
  y2 := 0;
  for i := 1 to p^.npoints do begin
    x1 := min(x1, p^.points[i].x);
    y1 := min(y1, p^.points[i].y);
    x2 := max(x2, p^.points[i].x);
    y2 := max(y2, p^.points[i].y);
  end;

  bw := x2-x1;
  bh := y2-y1;

  setLength(buf, bw*bh);
  for i := 0 to bw*bh-1 do
    buf[i] := false;

  for i := 1 to p^.npoints do begin
    j := i mod p^.npoints + 1;
    xx1 := min(p^.points[i].x, p^.points[j].x)-x1;
    yy1 := min(p^.points[i].y, p^.points[j].y)-y1;
    xx2 := max(p^.points[i].x, p^.points[j].x)-x1;
    yy2 := max(p^.points[i].y, p^.points[j].y)-y1;
    for y := yy1 to yy2 do begin
      x := ((((y-yy1)*100) div (yy2-yy1+1)) * (xx2-xx1)) div 100 + xx1;
      buf[y*bw+x] := true;
    end;
  end;

  for y := 0 to bh-1 do begin
    x1 := -1;
    x2 := -1;
    for x := 0 to bw-1 do
      if buf[y*bw+x] then begin
        if x1 = -1 then x1 := x;
        x2 := x;
      end;
    if x1 = -1 then continue;
    for x := x1 to x2 do
        buf[y*bw+x] := true;
  end;

  for i := 0 to bw*bh-1 do
    if buf[i] then
      putPixel(i mod bw + x1, i div bw + y1, p^.r, p^.g, p^.b);

  setLength(buf, 0);
end;

procedure draw;
var
  i: integer;
begin
  SDL_FillRect(disp, nil, SDL_MapRGB(disp^.format, $00, $00, $00));

  for i := 1 to npolys do
    drawPoly(@polys[i]);

  putPixel(dispw div 2, disph div 2, $ff, $ff, $ff);
  putPixel(dispw div 2 + 10, disph div 2, $ff, $00, $00);

  SDL_Flip(disp);
end;

procedure mainLoop;
var
  ev: TSDL_Event;
  quit: boolean;
begin
  quit := false;

  while not quit do begin
    while SDL_PollEvent(@ev) <> 0 do
      case ev.type_ of
        SDL_QUITEV: quit := true;
        SDL_VIDEORESIZE: begin
          dispw := ev.resize.w;
          disph := ev.resize.h;
          SDL_FreeSurface(disp);
          disp := SDL_SetVideoMode(dispw, disph, 32, SDL_RESIZABLE);
        end;
      end;

    draw;
  end;
end;

begin
  { init sdl }
  assert(SDL_Init(SDL_INIT_EVERYTHING) >= 0);
  dispw := 640;
  disph := 480;
  disp := SDL_SetVideoMode(dispw, disph, 32, SDL_RESIZABLE);
  assert(disp <> nil);

  npolys := 2;
  polys[1].npoints := 4;
  polys[1].points[1].x := 100;
  polys[1].points[1].y := 100;
  polys[1].points[2].x := 300;
  polys[1].points[2].y := 120;
  polys[1].points[3].x := 310;
  polys[1].points[3].y := 300;
  polys[1].points[4].x := 100;
  polys[1].points[4].y := 260;
  polys[1].r := $00;
  polys[1].g := $00;
  polys[1].b := $ff;
  polys[2].npoints := 3;
  polys[2].points[1].x := 250;
  polys[2].points[1].y := 270;
  polys[2].points[2].x := 150;
  polys[2].points[2].y := 200;
  polys[2].points[3].x := 150;
  polys[2].points[3].y := 170;
  polys[2].r := $ff;
  polys[2].g := $00;
  polys[2].b := $00;

  mainLoop;

  { end sdl }
  SDL_FreeSurface(disp);
  SDL_Quit;
end.
