unit UnitOpenGL;

interface

uses
  dglOpenGL, Types, Windows, Graphics, StructPoints;

type
  // Eclairage
  TGLLightDesc = packed record
    red:   GLFloat;
    green: GLFloat;
    blue:  GLFloat;
    alpha: GLFloat;
  end;

  // Emplacement de lumière
  TGLLightPlace = packed record
    x: GLFloat;
    y: GLFLoat;
    z: GLFLoat;
    w: GLFLoat;
  end;

  // Position
  TGLPosition = packed record
    x: GLFLoat;
    y: GLFLoat;
    z: GLFLoat;
  end;

procedure glColorRGB(color: TColor);
procedure glClearColorRGB(Color: TColor);
procedure glTranslate(Point2D: TVertex2f); overload;
procedure glVertex(Vertex2D: TVertex2f); overload;
procedure glVertex(Vertex3D: TVertex3f); overload;
procedure glVertex(Position: TGLPosition); overload;
procedure glVertex(Place: TGLLightPlace); overload;
procedure glVertexInvX(Vertex2D: TVertex2f); overload;
procedure glViewPortRect(Rect: TRect);
function glLightDesc(red, green, blue, alpha: GLFloat): TGLLightDesc; overload;
function glLightDesc(Color: TColor; alpha: GLFloat): TGLLightDesc; overload;
function glLightPlace(x, y, z, w: GLFloat): TGLLightPlace;
function glPosition(x, y, z: GLFloat): TGLPosition;

const
	ViewDelta: GLfloat = 0.375;

implementation

procedure glColorRGB(Color: TColor);
var
  r, g, b: byte;
begin
	r := GetRValue(Color);
  g := GetGValue(Color);
  b := GetBValue(Color);
  glColor3ub(r, g, b);
end;

procedure glClearColorRGB(Color: TColor);
var
  r, g, b: byte;
begin
	r := GetRValue(Color);
  g := GetGValue(Color);
  b := GetBValue(Color);
	glClearColor(r / 255, g / 255, b / 255, 0);
end;

procedure glTranslate(Point2D: TVertex2f);
begin
	glTranslatef(Point2D.X, Point2D.Y, 0.0);
end;

procedure glVertex(Vertex3D: TVertex3f);
begin
  glVertex3f(Vertex3D.x, Vertex3D.y, Vertex3D.z);
end;

procedure glVertex(Vertex2D: TVertex2f);
begin
	glVertex2f(Vertex2D.x, Vertex2D.y);
end;

procedure glVertex(Position: TGLPosition);
begin
	glVertex3f(Position.x, Position.y, Position.z);
end;

procedure glVertex(Place: TGLLightPlace);
begin
	glVertex4f(Place.x, Place.y, Place.z, Place.w);
end;

procedure glVertexInvX(Vertex2D: TVertex2f);
begin
	glVertex2f(- Vertex2D.x, Vertex2D.y);
end;

function glLightDesc(red, green, blue, alpha: GLFloat): TGLLightDesc;
begin
	Result.red := red;
  Result.green := green;
  Result.blue := blue;
  Result.alpha := alpha;
end;

function glLightDesc(Color: TColor; alpha: GLFloat): TGLLightDesc;
var
  rb, gb, bb: Byte;
begin
	rb := GetRValue(Color);
  gb := GetGValue(Color);
  bb := GetBValue(Color);
  Result.red   := rb / 255;
  Result.green := gb / 255;
  Result.blue  := bb / 255;
  Result.alpha := alpha;
end;

function glLightPlace(x, y, z, w: GLFloat): TGLLightPlace;
begin
	Result.x := x;
  Result.y := y;
  Result.z := z;
  Result.w := w;
end;

function glPosition(x, y, z: GLFloat): TGLPosition;
begin
	Result.x := x;
  Result.y := y;
  Result.z := z;
end;

procedure glViewPortRect(Rect: TRect);
begin
	glViewport(Rect.Left
           , Rect.Top
           , Rect.Right - Rect.Left + 1
           , Rect.Bottom - Rect.Top + 1);
end;



var
  Old8087CW: Word; // Sauvegarde du mode FPU

initialization
  // Sauvegarde de l'état de la FPU
  Old8087CW := Get8087CW;
  // Désactivation des exceptions virgules flottantes
  Set8087CW($133F);
  // Utilisation DGLOPENGL
  InitOpenGL();

finalization
  // Restitution de l'état de la FPU
  Set8087CW(Old8087CW);
end.
