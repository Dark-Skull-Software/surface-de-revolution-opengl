unit StructSurfaceOfRevolution;

interface

uses
	Classes, Contnrs, dglOpenGL, UnitMath, UnitOpenGL, StructLinkedList,
  StructPoints, StructVertexMemoryStream;

type
	TSurfaceOfRevolution = class(TLinkedObjectList)
  private
  	{ D�clarations priv�es }
    FMemory2D: TVertex2fMemoryStream; // Le profil 2D
    FTemp3D:   TVertex3fMemoryStream; // Liste des points 3D temporaires
    FTemp2D: TVertex2f;		 // Le point temporaire
    FSliceCount: Integer;
    function GetCount(): Integer;
    function GetList(Slice: Integer): TVertex3fMemoryStream;
    procedure SetList(Slice: Integer; const Value: TVertex3fMemoryStream);
    function GetPoint3D(Slice: Integer; Pos: Integer): TVertex3f;
    procedure setPoint3D(Slice, Pos: Integer; const Value: TVertex3f);
  protected
  	{ D�clarations prot�g�es }
    procedure SetSliceCount(Value: Integer);
  public
  	{ D�clarations publiques }
    constructor Create();
    destructor Destroy(); override;

    procedure ClearModel();
    procedure Add(Vertex: TVertex2f); overload;
    procedure Move(Index: Integer; Coords: TVertex2f);
    procedure Delete(Index: Integer);
    procedure Generate();
    procedure GenerateTemp(Vertex: TVertex2f);

    property Items[Slice: Integer]: TVertex3fMemoryStream read GetList write SetList;
    property Points3D[Slice: Integer; Pos: Integer]: TVertex3f read getPoint3D write setPoint3D;
  published
  	{ D�clarations publi�es }
    property SliceCount: Integer read FSliceCount write SetSliceCount;
    property Memory2D: TVertex2fMemoryStream read FMemory2D;
    property Temp3D: TVertex3fMemoryStream read FTemp3D;
    property Temp2D: TVertex2f read FTemp2D;
    property Count: Integer read GetCount;
  end;

implementation

const
	// Nombre de tranches par d�faut
  DEFAULT_SLICE_COUNT = 100;

{ TSurfaceOfRevolution }

constructor TSurfaceOfRevolution.Create();
begin
  inherited Create(True);
  ResetVertex(FTemp2D);
  FMemory2D := TVertex2fMemoryStream.Create();
  FTemp3D   := TVertex3fMemoryStream.Create();
  SetSliceCount(DEFAULT_SLICE_COUNT);
end;

function TSurfaceOfRevolution.GetPoint3D(Slice, Pos: Integer): TVertex3f;
begin
  Result := Items[Slice].Vertices[Pos];
end;

procedure TSurfaceOfRevolution.setPoint3D(Slice, Pos: Integer;
  const Value: TVertex3f);
begin
  Items[Slice].Vertices[Pos] := Value;
end;

(**
 * D�finit le nombre de "tranches"
 *
 * @param Value le nombre de tranches
 **)
procedure TSurfaceOfRevolution.SetSliceCount(Value: Integer);
var
  Memory: TVertex3fMemoryStream;
begin
	if (Value <= 0) then exit;
	if (FSliceCount = Value) then exit;

  Temp3D.VertexCapacity := Value;

 	// On supprime les �l�ments en exc�dent
  while (FSliceCount > Value) do
     begin
       inherited Delete(Pred(FSliceCount));
       Dec(FSliceCount);
     end;

  // On ajoute les �l�ments manquants
  while (FSliceCount < Value) do
    begin
    	Memory := TVertex3fMemoryStream.Create();
      Memory.VertexCapacity := Count;
        
      inherited Add(Memory);
      Inc(FSliceCount);
    end;

  // On reg�n�re le mod�le
  Generate();
end;


(**
 * G�n�re le mod�le en fonction du slice 2D
 **)
procedure TSurfaceOfRevolution.Generate();
var
	point: Integer;						// Le point en cours
  slice: Integer;           // La variable de parcours des tranches
  angle: Extended;					// L'angle courant
  sinus, cosinus: Extended; // Le sinus et cosinus pour la tranche courante
  Point2D: TVertex2f;       // Le point � projeter
  Point3D: TVertex3f;				// Le point projett�
  Iterator: TLinkedIterator;
  Memory3D: TVertex3fMemoryStream;
  PointCount: Integer;
begin
	Iterator := Self.Iterator();
  try
  	// Le nombre de points par tranche
  	PointCount := Count;

		// Pour chaque tranche
		for slice := 0 to Pred(FSliceCount) do
    	begin
        Memory3D := TVertex3fMemoryStream(Iterator.Next());

    		// On calcule l'angle, le sinus et le cosinus
      	angle   := GetSliceAngle(FSliceCount, slice);
      	sinus   := sin(angle);
      	cosinus := cos(angle);

      	// Pour chaque point du mod�le 2D
      	for point := 0 to Pred(PointCount) do
        	begin
        		// On r�cup�re le point � projeter et le point projet�
          	Point2D := FMemory2D.Vertices[point];
            Point3D := Memory3D.Vertices[point];

          	// On calcule les coordonn�es
        		Point3D.x := Point2D.x * cosinus;
          	Point3D.y := Point2D.y;
          	Point3D.z := Point2D.x * sinus;

          	// On les affecte
            Memory3D.Vertices[point] := Point3D;
        	end;
    	end;
  finally
  	Iterator.Free();
  end;
end;

(**
 * Ajoute un point dans la liste
 *
 * Le point sera clon�, puis projett�
 *
 * @param Point		le point � ajouter
 **)
procedure TSurfaceOfRevolution.Add(Vertex: TVertex2f);
var
  Vertex3D: TVertex3f;

  Iterator: TLinkedIterator;
  Memory3D: TVertex3fMemoryStream;
begin
	// On ajoute le point � la liste 2D
  FMemory2D.AddVertex(Vertex);
  // On met � jour le minimum/maximum
  FMemory2D.UpdateMinMax(Vertex);

  // On ajoute un point dans toutes les tranches
  ResetVertex(Vertex3D);
  Iterator := Self.Iterator();
  try
		while (Iterator.HasNext) do
    	begin
    		Memory3D := TVertex3fMemoryStream(Iterator.Next());
				Memory3D.AddVertex(Vertex3D);
    	end;
  finally
  	Iterator.Free();
  end;

	// On met � jour les coordonn�es des derniers points
  Move(Pred(FMemory2D.VertexCapacity), Vertex);
end;

(**
 * D�place un point du profil 2D et g�n�re la section 3D correspondante
 *
 * @param Index		l'indice du point � d�placer
 * @param Coords	les nouvelles coordonn�es
 **)
procedure TSurfaceOfRevolution.Move(Index: Integer; Coords: TVertex2f);
var
  slice: Integer;           // La variable de parcours des tranches
  angle: Extended;					// L'angle courant
  sinus, cosinus: Extended; // Le sinus et cosinus pour la tranche courante
  Point3D: TVertex3f;				// Le point projett�

  Iterator: TLinkedIterator;
  Memory3D: TVector3fMemoryStream;
begin
	// On affecte les coordonn�es au profil 2D
  FMemory2D.Vertices[Index] := Coords;

  Iterator := Self.Iterator();
  try
	  // Pour chaque tranche
		for slice := 0 to Pred(FSliceCount) do
    	begin
      	// On r�cup�re le Flux m�moire associ� au profil 3D
        Memory3D := TVector3fMemoryStream(Iterator.Next());

        // On r�cup�re le point projet�
        Point3D := Memory3D.Vertices[Index];

    		// On calcule l'angle, le sinus et le cosinus
	      angle   := GetSliceAngle(FSliceCount, slice);
  	    sinus   := sin(angle);
    	  cosinus := cos(angle);

      	// On calcule les coordonn�es
    		Point3D.x := Coords.x * cosinus;
      	Point3D.y := Coords.y;
      	Point3D.z := Coords.x * sinus;

      	// On les affecte
        Memory3D.Vertices[Index] := Point3D;
    	end;
  finally
  	Iterator.Free();
  end;
end;

(**
 * On supprime le point d'indice donn�
 *
 * @param Index 	l'indice du point
 **)
procedure TSurfaceOfRevolution.Delete(Index: Integer);
var
  Iterator: TLinkedIterator;
  Memory3D: TVertex3fMemoryStream;
begin
	// On supprime le point 2D correspondant
  Memory2D.DeleteVertex(Index);
  // On met � jour le min et le max
  Memory2D.FindMinMax();

  // Pour chaque tranche aussi
  Iterator := Self.Iterator();
  try
	  while (Iterator.HasNext()) do
  	  begin
    		Memory3D := TVertex3fMemoryStream(Iterator.Next);
    	  Memory3D.DeleteVertex(Index);
    	end;
  finally
  	Iterator.Free();
  end;

end;

destructor TSurfaceOfRevolution.Destroy();
begin
	ClearModel();
	FMemory2D.Free();
  FTemp3D.Free();
  inherited Destroy();
end;

procedure TSurfaceOfRevolution.GenerateTemp(Vertex: TVertex2f);
var
  slice: Integer;
  angle, sinus, cosinus: Extended;
  Vertex3D: TVertex3f;
begin
	FTemp2D := Vertex;
	for slice := 0 to Pred(SliceCount) do
    begin
      Vertex3D := Temp3D.Vertices[slice];

    	angle := GetSliceAngle(SliceCount, slice);
      sinus := sin(angle);
      cosinus := cos(angle);

      Vertex3D.x := Vertex.x * cosinus;
      Vertex3D.y := Vertex.y;
      Vertex3D.z := Vertex.x * sinus;

      Temp3D.Vertices[slice] := Vertex3D;
    end;
end;

(**
 * Renvoie le nombre de points dans le profil
 **)
function TSurfaceOfRevolution.GetCount(): Integer;
begin
	Result := FMemory2D.VertexCapacity;
end;

(**
 * Vide la matrice
 **)
procedure TSurfaceOfRevolution.ClearModel();
var
  Iterator: TLinkedIterator;
  Memory3D: TVector3fMemoryStream;
begin
	// On vide la liste 2D
  FMemory2D.Clear();
  
	// On vide les listes 3D
	Iterator := Self.Iterator();
  try
    while (Iterator.HasNext()) do
      begin
      	Memory3D := TVector3fMemoryStream(Iterator.Next());
        Memory3D.Clear();
      end;
  finally
    Iterator.Free();
  end;
end;

function TSurfaceOfRevolution.GetList(Slice: Integer): TVertex3fMemoryStream;
begin
  Result := TVertex3fMemoryStream(inherited GetItem(Slice));
end;

procedure TSurfaceOfRevolution.SetList(Slice: Integer; const Value: TVertex3fMemoryStream);
begin
  inherited SetItem(Slice, Value);
end;



end.
