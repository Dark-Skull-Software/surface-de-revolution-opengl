unit StructPoints;

interface

uses
  dglOpenGl, Math;

type
	// Vertex 2D flottant
  TVertex2f = packed record
  	x: GLfloat;
    y: GLfloat;
  end;

  // Vertex 3D flottant
  TVertex3f = packed record
  	x: GLfloat;
    y: GLfloat;
    z: GLfloat;
  end;

  // Vecteur 2D flottant
  TVector2f = TVertex2f;
  // Axe de rotation
  TAxis3f = TVertex3f;
  // Vecteur 3D flottant
  TVector3f = TVertex3f;
  // Normale 3D flottant
  TNormal3f = TVertex3f;

  // Segment
  TSegment2f = array[0..1] of TVertex2f;

const
	SIZE_VERTEX_2F = SizeOf(TVertex2f);
  SIZE_AXIS_3F   = SizeOf(TAxis3f);
  SIZE_VERTEX_3F = SizeOf(TVertex3f);
  SIZE_VECTOR_3F = SizeOf(TVector3f);
  SIZE_NORMAL_3F = SizeOf(TNormal3f);


procedure ResetVertex(var Vertex: TVertex2f); overload;
procedure ResetVertex(var Vertex: TVertex3f); overload;
procedure InvertVector(var Vector: TVector3f);
procedure Normalize(var Normal: TNormal3f);
function VertexDistance(a, b: TVertex2f): Single;
function AbsDiffPoints(a, b: TVertex2f): TVector2f;
function DiffPoints(a, b: TVertex2f): TVector2f; overload;
function DiffPoints(a, b: TVertex3f): TVector3f; overload;
function VectProd(a, b: TVector3f): TVector3f;    overload;
function VectProd(a, b, c: TVertex3f): TVector3f; overload;
function Normale(a, b: TVector3f): TNormal3f; overload;
function Normale(a, b, c: TVertex3f): TNormal3f; overload;
function Vertex2f(x, y: GLfloat): TVertex2f;
function Vertex3f(x, y, z: GLfloat): TVertex3f;

function MidVertex(V1, V2: TVertex2f): TVertex2f;
function EqualVertex(V1, V2: TVertex2f): Boolean;
function VertexAngle(V1, V2: TVertex2f): GLFloat;

implementation

procedure ResetVertex(var Vertex: TVertex2f);
begin
  Vertex.x := 0.0;
  Vertex.y := 0.0;
end;

procedure ResetVertex(var Vertex: TVertex3f);
begin
  Vertex.x := 0.0;
  Vertex.y := 0.0;
  Vertex.z := 0.0;
end;

function VectProd(a, b: TVector3f): TVector3f;
begin
	Result.x := a.y * b.z - a.z * b.y;
  Result.y := a.x * b.z - a.z * b.x;
  Result.z := a.x * b.y - a.y * b.x;
end;

function VectProd(a, b, c: TVertex3f): TVector3f;
var
  vectorA, vectorB: TVector3f;
begin
	vectorA := DiffPoints(b, a);
  vectorB := DiffPoints(b, c);
  Result := VectProd(VectorA, VectorB);
end;

procedure InvertVector(var Vector: TVector3f);
begin
	Vector.x := - Vector.x;
  Vector.y := - Vector.y;
  Vector.z := - Vector.z;
end;

procedure Normalize(var Normal: TNormal3f);
var
	Norm: Single;
begin
	Norm := sqrt(Normal.x * Normal.x + Normal.y * Normal.y + Normal.z * Normal.z);
  Normal.x := Normal.x / Norm;
  Normal.y := Normal.y / Norm;
  Normal.z := Normal.z / Norm;
end;

function DiffPoints(a, b: TVertex3f): TVector3f;
begin
	Result.x := b.x - a.x;
  Result.y := b.y - a.y;
  Result.z := b.z - a.z;
end;

function DiffPoints(a, b: TVertex2f): TVector2f;
begin
	Result.x := b.x - a.x;
  Result.y := b.y - a.y;
end;

function AbsDiffPoints(a, b: TVertex2f): TVector2f;
begin
	Result.x := abs(b.x - a.x);
  Result.y := abs(b.y - a.y);
end;

function Normale(a, b: TVector3f): TNormal3f;
begin
  Result := VectProd(a, b);
  Normalize(Result);
end;

function Normale(a, b, c: TVertex3f): TNormal3f;
begin
	Result := VectProd(a, b, c);
  Normalize(Result);
end;

function Vertex2f(x, y: GLfloat): TVertex2f;
begin
	Result.x := x;
  Result.y := y;
end;

function Vertex3f(x, y, z: GLfloat): TVertex3f;
begin
	Result.x := x;
  Result.y := y;
  Result.z := z;
end;

(**
 * Revoie la distance AU CARRE !!
 **)
function VertexDistance(a, b: TVertex2f): Single;
var
  x, y: Single;
begin
	x := a.x - b.x;
  y := a.y - b.y;
  Result := x * x + y * y;
end;


(**
 * Renvoie les coordonnées du point situé au milieu de P1 et P2
 *
 * @param P1 le 1° point
 * @param P2 le 2° point
 *
 * @return les coordonnées du point situé au milieu de P1 et P2
 **)
function MidVertex(V1, V2: TVertex2f): TVertex2f;
begin
  Result.x := (V1.x + V2.x) / 2;
  Result.y := (V1.y + V2.y) / 2;
end;

function EqualVertex(V1, V2: TVertex2f): Boolean;
begin
	Result := ((V1.x = V2.x) and (V1.y = V2.y));
end;

function VertexAngle(V1, V2: TVertex2f): GLFloat;
var
  DX: GLfloat;
  DY: GLfloat;
begin
  DX := V2.x - V1.x;
  DY := V2.y - V1.y;
  Result := ArcTan2(DY, DX);
end;


end.
