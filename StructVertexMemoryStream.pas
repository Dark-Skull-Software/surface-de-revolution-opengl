unit StructVertexMemoryStream;

interface

uses
  Classes, dglOpenGL, StructPoints;

const
  DEFAULT_CLOSE_DISTANCE: GLFloat = 10.0;

type
  TVertex2fMemoryStream = class(TMemoryStream)
  private
  	fMin: TVertex2f;
    fMax: TVertex2f;
    fCloseDistance: Single;
    function getVertex(AIndex: Integer): TVertex2f;
    function getVertexCapacity: Integer;
    procedure setVertex(AIndex: Integer; const Value: TVertex2f);
    procedure setVertexCapacity(const Value: Integer);
    { Déclarations privées }
  protected
  	{ Déclarations protégées }
  public
  	{ Déclarations publiques }
    constructor Create();
    procedure SeekVertex(AIndex: Integer);
    procedure CopyAndInvert(VertexMemory: TVertex2fMemoryStream);
    function  LastVertex(): TVertex2f;
    procedure AddVertex(Vertex: TVertex2f);
    procedure FindMinMax();
    procedure UpdateMinMax(Vertex: TVertex2f);
    function ReadCurrentVertex(): TVertex2f;
    procedure WriteCurrentVertex(Vertex: TVertex2f);
    procedure DeleteVertex(Index: Integer);
    property Vertices[AIndex: Integer]: TVertex2f read getVertex write setVertex;
    function FindClose(Vertex: TVertex2f): Integer;
  published
    { Déclarations publiées }
    property VertexCapacity: Integer read getVertexCapacity write setVertexCapacity;
    property CloseDistance: Single read fCloseDistance write fCloseDistance;
    property Min: TVertex2f read fMin write fMin;
    property Max: TVertex2f read fMax write fMax;
  end;

  TVertex3fMemoryStream = class(TMemoryStream)
  private
    function getVertexCapacity: Integer;
    procedure setVertexCapacity(const Value: Integer);
    function getVertex(AIndex: Integer): TVertex3f;
    procedure setVertex(AIndex: Integer; const Value: TVertex3f);
    { Déclarations privées }
  protected
  	{ Déclarations protégées }
  public
  	{ Déclarations publiques }
    procedure AddVertex(Vertex: TVertex3f);
    procedure SeekVertex(AIndex: Integer);
    function ReadCurrentVertex(): TVertex3f;
    procedure WriteCurrentVertex(Vertex: TVertex3f);
    procedure DeleteVertex(Index: Integer);
    property Vertices[AIndex: Integer]: TVertex3f read getVertex write setVertex;
  published
    { Déclarations publiées }
    property VertexCapacity: Integer read getVertexCapacity write setVertexCapacity;
  end;

  TVector3fMemoryStream = class(TVertex3fMemoryStream);
  TNormal3fMemoryStream = class(TVertex3fMemoryStream);

implementation

{ TVertex3fMemoryStream }

(**
 * Renvoie le Vertex à l'indice donné
 *
 * @param AIndex	l'indice 
 **)
function TVertex3fMemoryStream.getVertex(AIndex: Integer): TVertex3f;
begin
  SeekVertex(AIndex);
  Result := ReadCurrentVertex();
end;

(**
 * Calcule la capacité de stockage en termes de vertices
 *
 * @return la capacité en termes de vertices
 **)
function TVertex3fMemoryStream.getVertexCapacity(): Integer;
begin
  Result := Size div SIZE_VERTEX_3F;
end;

(**
 * Positionne le flux à l'indice de vertex donné
 *
 * @param AIndex		l'indice
 **)
procedure TVertex3fMemoryStream.SeekVertex(AIndex: Integer);
begin
  Seek(AIndex * SIZE_VERTEX_3F, soFromBeginning);
end;

(**
 * Définit le vertex à l'indice donné
 *
 * @param AIndex 	l'indice
 * @param Value   le vertex
 **)
procedure TVertex3fMemoryStream.setVertex(AIndex: Integer;
  const Value: TVertex3f);
begin
  SeekVertex(AIndex);
  WriteCurrentVertex(Value);
end;

(**
 * Définit la capacité du flux en termes de vertices
 *
 * @param Value le nombre de vertices à stocker
 **)
procedure TVertex3fMemoryStream.setVertexCapacity(const Value: Integer);
var
  NewSize: Int64;
begin
  NewSize := Value * SIZE_VERTEX_3F;
  if (not (NewSize = Size)) then Size := NewSize; 
end;

(**
 * Ajoute un vertex en fin de liste
 * Augmente la mémoire si nécessaire
 *
 * @param Vertex le vertex
 **)
procedure TVertex3fMemoryStream.AddVertex(Vertex: TVertex3f);
begin
  SetSize(Size + SIZE_VERTEX_3F);
  Seek(- SIZE_VERTEX_3F, soFromEnd);
  WriteCurrentVertex(Vertex);
end;

(**
 * Lit le vertex à la position courante
 *
 * @return le vertex à la position courante
 **)
function TVertex3fMemoryStream.ReadCurrentVertex(): TVertex3f;
begin
  Read(Result, SIZE_VERTEX_3F);
end;

(**
 * Supprime le vertex à l'indice donné
 *
 * @param Index
 **)
procedure TVertex3fMemoryStream.DeleteVertex(Index: Integer);
var
	Vertex: TVertex3f;
	MaxIndex: Integer;
  i: Integer;
begin
	MaxIndex := Pred(VertexCapacity);

	// Si on est pas en bout de liste
	if (Index < MaxIndex) then
    begin
			// On déplace la mémoire avant de supprimer ce qui est inutile
		  SeekVertex(Index + 1);
  		for i := (Index + 1) to MaxIndex do
    		begin
      		Vertex := ReadCurrentVertex();
      		Seek(- (SIZE_VERTEX_3F shl 1), soFromCurrent);
      		WriteCurrentVertex(Vertex);
      		Seek(SIZE_VERTEX_3F, soFromCurrent);
    		end;
    end;

  // Suppression du dernier élément
  VertexCapacity := VertexCapacity - 1;
end;

(**
 * Ecrit un vertex à la position courrante
 *
 * @param Vertex le vertex à écrire
 **)
procedure TVertex3fMemoryStream.WriteCurrentVertex(Vertex: TVertex3f);
begin
  Write(Vertex, SIZE_VERTEX_3F);
end;

{ TVertex2fMemoryStream }

(**
 * Constructeur
 **)
constructor TVertex2fMemoryStream.Create;
begin
  inherited Create();
  ResetVertex(fMin);
  ResetVertex(fMax);
  fCloseDistance := DEFAULT_CLOSE_DISTANCE;
end;

(**
 * Copie un flux mémoire et l'inverse
 *
 * @param VertexMemory		le flux à copier et à inverser sur l'axe X
 **)
procedure TVertex2fMemoryStream.CopyAndInvert(VertexMemory: TVertex2fMemoryStream);
var
  i: Integer;
  Vertex: TVertex2f;
begin
  VertexCapacity := VertexMemory.VertexCapacity;
  for i := 0 to Pred(VertexCapacity) do
    begin
    	Vertex := VertexMemory.Vertices[i];
      Vertex.x := - Vertex.x;
      Vertices[i] := Vertex;
    end;
end;

(**
 * Effectue un parcours complet pour déterminer les absisses et ordonnée
 * minimales et maximales
 **)
procedure TVertex2fMemoryStream.FindMinMax();
var
  i: Integer;
  Vertex: TVertex2f;
begin
	// Si la liste est vide, on remet à 0 le min et le max
	if (Size = 0) then
  	begin
    	ResetVertex(fMin);
    	ResetVertex(fMax);
    	exit;
    end;

  // Sinon, on prend les coordonnées du 1° point
  fMin := Vertices[0];
  fMax := fMin;

  // Et on analyse tous les autres
  for i := 0 to Pred(VertexCapacity) do
    begin
    	Vertex := Vertices[i];
    	UpdateMinMax(Vertex);
    end;
end;

(**
 * Met à jour les min et max en fonction des coordonnées d'un point
 *
 * @param Vertex 		les coordonnées du point
 **)
procedure TVertex2fMemoryStream.UpdateMinMax(Vertex: TVertex2f);
begin
	if (VertexCapacity = 1) then
    begin
    	fMin := Vertex;
      fMax := Vertex;
      exit;
    end;
	if (Vertex.x < fMin.x) then fMin.x := Vertex.x;
  if (Vertex.x > fMax.x) then fMax.x := Vertex.x;
  if (Vertex.y < fMin.y) then fMin.y := Vertex.y;
  if (Vertex.y > fMax.y) then fMax.y := Vertex.y;
end;

(**
 * Renvoie le vertex à l'indice donné
 *
 * @param AIndex 	l'indice
 *
 * @return le vertex lu
 **)
function TVertex2fMemoryStream.getVertex(AIndex: Integer): TVertex2f;
begin
	SeekVertex(AIndex);
  Result := ReadCurrentVertex();
end;

(**
 * Calcule la capacité de stockage en terme de vertices
 *
 * @return le nombre de vertices stockables dans le flux
 **)
function TVertex2fMemoryStream.getVertexCapacity(): Integer;
begin
  Result := Size div SIZE_VERTEX_2F;
end;

(**
 * Lit les coordonnées du dernier vertex de la liste
 *
 * @return les coordonnées du dernier vertex
 **)
function TVertex2fMemoryStream.LastVertex(): TVertex2f;
begin
  if (Size = 0) then
    begin
	    ResetVertex(Result);
      exit;
    end;

	Seek(- SIZE_VERTEX_2F, soFromEnd);
  Result := ReadCurrentVertex();
end;

(**
 * Positionne le flux à l'indice de vertex donné
 *
 * @param AIndex		l'indice
 **)
procedure TVertex2fMemoryStream.SeekVertex(AIndex: Integer);
begin
  Seek(AIndex * SIZE_VERTEX_2F, soFromBeginning);
end;

(**
 * définit le vertex à l'indice donné
 *
 * @param AIndex	l'indice de stockager
 * @param Value		la valeur à stocker
 **)
procedure TVertex2fMemoryStream.setVertex(AIndex: Integer;
  const Value: TVertex2f);
begin
  SeekVertex(AIndex);
  WriteCurrentVertex(Value);
end;

(**
 * Modifie la taille du flux mémoire en nombre de vertices
 *
 * @param Value le nombre de vertices à stocker
 **)
procedure TVertex2fMemoryStream.setVertexCapacity(const Value: Integer);
var
  NewSize: Int64;
begin
  NewSize := Value * SIZE_VERTEX_2F;
  if (not (NewSize = Size)) then Size := NewSize;
end;

(**
 * Ajoute un vertex en fin de liste
 * Ajoute un bloc mémoire au flux par la même occasion
 *
 * @param Vertex les coordonnées du vertex à ajouter
 **)
procedure TVertex2fMemoryStream.AddVertex(Vertex: TVertex2f);
begin
  SetSize(Size + SIZE_VERTEX_2F);
  Seek(- SIZE_VERTEX_2F, soFromEnd);
  WriteCurrentVertex(Vertex);
end;


(**
 * Lit le vertex à la position courante
 *
 * @return le vertex lu à la position courante
 **)
function TVertex2fMemoryStream.ReadCurrentVertex(): TVertex2f;
begin
  Read(Result, SIZE_VERTEX_2F);
end;

(**
 * Supprime le vertex d'indice donné
 *
 * @param Index l'indice du point à supprimer
 **)
procedure TVertex2fMemoryStream.DeleteVertex(Index: Integer);
var
	Vertex: TVertex2f;
	MaxIndex: Integer;
  i: Integer;
begin
  MaxIndex := Pred(VertexCapacity);

  // Si on est en dehors des bornes, on quitte l'application
  if (Index < 0) or (Index > MaxIndex) then exit;

	// Si on est pas en bout de liste
	if (Index < MaxIndex) then
    begin
			// On déplace la mémoire avant de supprimer ce qui est inutile
		  SeekVertex(Index + 1);
  		for i := (Index + 1) to MaxIndex do
    		begin
      		Vertex := ReadCurrentVertex();
      		Seek(- (SIZE_VERTEX_2F shl 1), soFromCurrent);
      		WriteCurrentVertex(Vertex);
      		Seek(SIZE_VERTEX_2F, soFromCurrent);
    		end;
    end;

  // Suppression du dernier élément
  VertexCapacity := VertexCapacity - 1;
end;

(**
 * Ecrit le vertex à la position courrante
 *
 * @param Vertex		le vertex à écrire dans le flux
 **)
procedure TVertex2fMemoryStream.WriteCurrentVertex(Vertex: TVertex2f);
begin
  Write(Vertex, SIZE_VERTEX_2F);
end;

(**
 * Renvoie l'indice d'un point proche géographiquement du point donné
 *
 * @param Vertex le vertex donnant la position à chercher
 *
 * @return -1 si non trouvé
 *          l'indice sinon
 **)
function TVertex2fMemoryStream.FindClose(Vertex: TVertex2f): Integer;
var
  i: Integer;
  Distance: Single;
  CurrentVertex: TVertex2f;
  SquareDistance: Single;
begin
	Result := -1;
  if (Size = 0) then exit;

  // On calcule la distance au carré (pour éviter de calculer les racines plus tard)
  SquareDistance := fCloseDistance * fCloseDistance;

  Seek(0, soFromBeginning);
	for i := 0 to Pred(VertexCapacity) do
    begin
    	CurrentVertex := ReadCurrentVertex();
      Distance := VertexDistance(Vertex, CurrentVertex);
      if (Distance <= SquareDistance) then
        begin
        	Result := i;
          exit;
        end;
    end;
end;

end.
