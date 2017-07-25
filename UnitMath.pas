unit UnitMath;

interface

uses
  Math, Types, StructPoints;

const
	PI_2     : extended = pi * 2;
  PI_4     : extended = pi * 4;
  PI_DIV_4 : extended = pi / 4;
  PI_DIV_8 : extended = pi / 8;
  PI_DIV_16: extended = pi / 16;

function GetSliceAngle(const SliceCount: Integer; const SliceIndex: Integer): Extended;
function PointInRect(X, Y: Integer; const R: TRect): Boolean; overload;
function PointInRect(Point: TPoint; const R: TRect): Boolean; overload;
procedure DecreaseRect(var Rect: TRect);
function FindCloserAngle(angle: Single): Single;
function FindCenter(A, B, C: TVertex2f): TVertex2f;
function FindCloserPoint(Center, Point: TVertex2f): TVertex2f;

implementation

(**
 * Calcul de l'angle de la tranche
 *
 * @param SliceCount 		le nombre de tranches
 * @param SliceIndex    l'indice de la tranche
 *
 * @return l'angle correspondant, en radians
 **)
function GetSliceAngle(const SliceCount: Integer; const SliceIndex: Integer): Extended;
begin
	Result := (PI_2 / SliceCount) * SliceIndex;
end;

(**
 * Regarde si un point se situe à l'intérieur d'un rectangle
 *
 * @param X		l'absisse du point
 * @param Y 	l'ordonnée du point
 * @param R   le rectangle
 *
 * @return True si le point est dans le rectangle
 *         False sinon
 **)
function PointInRect(X, Y: Integer; const R: TRect): Boolean;
begin
	Result := (X >= R.Left) and (X <= R.Right) and (Y >= R.Top) and (Y <= R.Bottom);
end;

(**
 * Regarde si un point se situe à l'intérieur d'un rectangle
 *
 * @param Point		les coordonnées du point
 * @param R   		le rectangle
 *
 * @return True si le point est dans le rectangle
 *         False sinon
 **)
function PointInRect(Point: TPoint; const R: TRect): Boolean;
begin
	Result := PointInRect(Point.X, Point.Y, R);
end;

(**
 * Décrémente le rectangle d'une unité sur chaque bord
 **)
procedure DecreaseRect(var Rect: TRect);
begin
	Inc(Rect.Left);
  Dec(Rect.Right);
  Inc(Rect.Top);
  Dec(Rect.Bottom);
end;

(**
 * Essaie de trouver l'angle (en 1/4 de pi) le plus proche de l'angle indiqué
 **)
function FindCloserAngle(angle: Single): Single;
var
  i: Integer;
	alpha: Single;
begin
	for i := -4 to 4 do
    begin
    	alpha := i * PI_DIV_4;
      if (abs(alpha - angle) <= PI_DIV_4) then
        begin
        	Result := alpha;
          exit;
        end;
    end;
  Result := 0;
end;

function ModFloat(AValue, AModulo: Single): Single;
begin
	Result := AValue;
  AModulo := Abs(AModulo);
	while (Result >= AModulo) do
    Result := AValue - AModulo;
  while (Result <= (- AModulo)) do
    Result := AValue + AModulo;
end;

function IfThen(ACondition: Boolean; AIfTrue: Single; AIfFalse: Single): Single; overload;
begin
	if (ACondition) then
    Result := AIfTrue
  else
  	Result := AIfFalse;
end;

function IfThen(ACondition: Boolean; AIfTrue: TVertex2f; AIfFalse: TVertex2f): TVertex2f; overload;
begin
	if (ACondition) then
    Result := AIfTrue
  else
  	Result := AIfFalse;
end;



(**
 * Trouve le centre du cercle passant par le points A, B et C
 *
 * @param A un point
 * @param B un point
 * @param C un point
 *
 * @return les coordonnées du centre du cercle passant par A, B et C
 *
 * @todo : gérer les cas particuliers
 * A, B et C alignés
 * A et B alignés horizontalement
 * A et C alignés horizontalement
 **)
function FindCenter(A, B, C: TVertex2f): TVertex2f;
var
	G, H: TVertex2f;
  ag, ah: Single;
  bg, bh: Single;
begin
  // Les points médianes
	G := MidVertex(A, C);
  H := MidVertex(A, B);

  // Cas particulier (A = B = C)
  if (EqualVertex(A, B) and (EqualVertex(A, C))) then
    begin
    	Result := A;
      exit;
    end;

  // Cas particulier (A = B)
  if (EqualVertex(A, B)) then
    begin
    	Result := MidVertex(A, C);
      exit;
    end;

  // Cas particulier (A = C)
  if (EqualVertex(A, C)) then
    begin
    	Result := MidVertex(A, B);
      exit;
    end;

  // Cas particulier (A = B)
  if (EqualVertex(B, C)) then
    begin
    	Result := MidVertex(A, B);
      exit;
    end;

	// Cas particuliers (Ay = By = Cy)
  if ((A.y = C.y) and (A.y = B.y)) then
    begin
      Result.x := (A.x + B.x + C.y) / 3;
			Result.y := - MaxInt;
      exit;
    end;

  // Cas particuliers (Ay = Cy)
  if (A.y = C.y) then
    begin
    	ah := (A.x - B.x) / (B.y - A.y);
      bh := H.y - H.x * ah;
      Result.x := G.x;
      Result.y := ah * Result.x + bh;
    	exit;
    end;

  // Cas particuliers (Ay = By)
  if (A.y = B.y) then
    begin
			ag := (A.x - C.x) / (C.y - A.y);
      bg := G.y - G.x * ag;
      Result.x := H.x;
      Result.y := ag * Result.x + bg;
      exit;
    end;

  // Cas particuliers (Ax = Bx = Cx)
  if ((A.x = C.x) and (A.x = B.x)) then
    begin
      Result.x := - MaxInt;
			Result.y := (A.y + B.y + C.y) / 3;
      exit;
    end;

  // Cas particuliers (Ax = Cx)
  if (A.x = C.x) then
    begin
    	ah := (A.x - B.x) / (B.y - A.y);
      bh := H.y - H.x * ah;
      Result.y := G.y;
      Result.x := (Result.y - bh) / ah;
    	exit;
    end;

  // Cas particulier (Ax = Bx)
  if (A.x = B.x) then
    begin
    	ag := (A.x - C.x) / (C.y - A.y);
      bg := G.y - G.x * ag;
      Result.y := H.y;
      Result.x := (Result.y - bg) / ag;
      exit;
    end;

	// Les coefficients directeurs
	ag := (A.x - C.x) / (C.y - A.y);
  ah := (A.x - B.x) / (B.y - A.y);

  // Les bases
  bh := H.y - H.x * ah;

  // Cas particulier : ah = ag
  if (ah = ag) then
  	Result.x := ((G.y - H.y) + (H.x * ah) - (G.x * ag)) * MaxInt
  else
	  Result.x := ((G.y - H.y) + (H.x * ah) - (G.x * ag)) / (ah - ag);
  Result.y := ah * Result.x + bh;
end;

function FindCloserPoint(Center, Point: TVertex2f): TVertex2f;
var
  AbsDiff: TVertex2f;
  Diff: TVertex2f;
  ratio: Single;
begin
  AbsDiff := AbsDiffPoints(Center, Point);
  ratio := AbsDiff.x / AbsDiff.y;

  if (ratio <= 0.5) then
    begin
    	Result.x := Center.x;
      Result.y := Point.y;
      exit;
    end;

  if (ratio >= 2.0) then
    begin
      Result.x := Point.x;
      Result.y := Center.y;
      exit;
    end;

  Diff := DiffPoints(Center, Point);

  if (ratio <= 1.0) then
    begin
    	Result.x := Center.x + Sign(Diff.x) * AbsDiff.y;
      Result.y := Point.y;

      // On vérifie qu'on est pas entrés dans les négatifs
      if (Result.x < 0) then
        begin
        	Result.x := 0;
          AbsDiff.y := Center.x;
          Result.y  := Center.y + Sign(Diff.y) * AbsDiff.y;
        end;
    	exit;
    end;

  if (ratio > 1.0) then
    begin
      Result.x := Point.x;
      Result.y := Center.y + Sign(Diff.y) * AbsDiff.x;
    	exit;
    end;
    
	Result := Point;
end;

end.
