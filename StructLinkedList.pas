unit StructLinkedList;

interface

uses
  SysUtils;

type
  TLinkedStruct = class(TObject)
  private
  	{ Déclarations privées }
  	FNext: TLinkedStruct;
    FPrev: TLinkedStruct;
    FLinkedObject: TObject;
    procedure Init();
  protected
  	{ Déclarations protégées }
  public
  	{ Déclarations publiques }
  	constructor Create(); overload;
    constructor Create(AObject: TObject); overload;
    destructor Destroy(); override;
    procedure FreeObject();
  published
  	{ Déclarations publiées }
  	property Next: TLinkedStruct read FNext write FNext;
    property Prev: TLinkedStruct read FPrev write FPrev;
    property LinkedObject: TObject read FLinkedObject write FLinkedObject;
  end;

  TLinkedIterator = class(TObject)
  private
  	{ Déclarations privées }
  	CurrentStruct: TLinkedStruct;
  public
  	{ Déclarations publiques }
  	constructor Create(Struct: TLinkedStruct);
    function HasNext(): Boolean;
    function Next(): TObject;
  end;


  TLinkedObjectList = class(TObject)
  private
  	{ Déclarations privées }
    FHead: TLinkedStruct;
    FTail: TLinkedStruct;
    FOwnsObjects: Boolean;
	  FSize: Integer;
  protected
    { Déclarations protégées }
    function MidIndex(): Integer;
    procedure Init();
    function GetHead: TObject;
    function GetTail: TObject;
    function GetItem(AIndex: Integer): TObject;
    procedure SetItem(AIndex: Integer; const Value: TObject);
    function GetStruct(AIndex: Integer): TLinkedStruct;
    property Structs[AIndex: Integer]: TLinkedStruct read GetStruct;
  public
    { Déclarations publiques }
    constructor Create(); overload;
    constructor Create(AOwnsObjects: Boolean); overload;
    destructor Destroy(); override;
    procedure Add(AObject: TObject);
    procedure Insert(AIndex: Integer; AObject: TObject);
    procedure InsertHead(AObject: TObject);
    procedure InsertTail(AObject: TObject);
    procedure DeleteHead();
    procedure DeleteTail();
    procedure Delete(AIndex: Integer);
    procedure Clear();
    function IndexOf(AObject: TObject): Integer;
    function Iterator(): TLinkedIterator;

    property Items[AIndex: Integer]: TObject read GetItem write SetItem;
  published
  	{ Déclarations publiées }
    property OwnsObjects: Boolean read FOwnsObjects write FOwnsObjects;
  	property Size: Integer read FSize;
    property Head: TObject read GetHead;
    property Tail: TObject read GetTail;
  end;

type
  EOutOfBoundException = class(Exception);

implementation

{ TLinkedStruct }

(**
 * Constructeur sans objet
 **)
constructor TLinkedStruct.Create();
begin
  inherited Create();
  Init();
  FLinkedObject := nil;
end;

(**
 * Constructeur avec objet
 *
 * @param AObject l'objet à associer à la structure
 **)
constructor TLinkedStruct.Create(AObject: TObject);
begin
  inherited Create();
  Init();
  FLinkedObject := AObject;
end;

(**
 * Destructeur
 **)
destructor TLinkedStruct.Destroy;
begin
  inherited Destroy;
end;

(**
 * Libère l'objet associé au pointeur si possible
 **)
procedure TLinkedStruct.FreeObject();
begin
  if (not (Assigned(FLinkedObject))) then exit;
  FLinkedObject.Free();
  FLinkedObject := nil;
end;

(**
 * Initialisation de l'objet
 **)
procedure TLinkedStruct.Init();
begin
  FNext := nil;
  FPrev := nil;
end;

{ TLinkedObjectList }

(**
 * Constructeur sans paramètres
 * Associe les objets à la liste
 **)
constructor TLinkedObjectList.Create();
begin
  inherited Create();
  Init();
  FOwnsObjects := False;
end;

(**
 * Constructeur avec paramètre
 *
 * @param AOwnsObjects		Spécifie si les objets appartiennent à la liste ou pas
 **)
constructor TLinkedObjectList.Create(AOwnsObjects: Boolean);
begin
  inherited Create();
  Init();
  FOwnsObjects := AOwnsObjects;
end;

(**
 * Destructeur
 * Libère la mémoire associée
 **)
destructor TLinkedObjectList.Destroy();
begin
	Clear();
  inherited Destroy();
end;

(**
 * Initialisation
 **)
procedure TLinkedObjectList.Init();
begin
  FHead := nil;
  FTail := nil;
  FSize := 0;
end;

(**
 * Ajoute un objet en fin de liste
 * Crée la liste si elle est vide
 *
 * @param AObject		l'objet à insérer
 **)
procedure TLinkedObjectList.Add(AObject: TObject);
var
  Struct: TLinkedStruct;
begin
	// Liste vide: on créé la liste à proprement parler
	if (Size = 0) then
    begin
    	Struct := TLinkedStruct.Create(AObject);
    	FHead := Struct;
      FTail := Struct;
      inc(FSize);
      exit;
    end;

  // Liste non vide, on insère en fin de liste
  InsertTail(AObject);
end;


(**
 * Renvoie l'objet placé en tête de liste
 *
 * @return l'objet 	si la liste est non vide
 *				 nil 			si la liste est vide
 **)
function TLinkedObjectList.GetHead(): TObject;
begin
	Result := nil;
  if (not (Assigned(FHead))) then exit;
 	Result := FHead.LinkedObject;
end;

(**
 * Renvoie l'objet placé en fin de liste
 *
 * @return l'objet 	si la liste est non vide
 *				 nil 			si la liste est vide
 **)
function TLinkedObjectList.GetTail(): TObject;
begin
	Result := nil;
  if (not (Assigned(FTail))) then exit;
 	Result := FTail.LinkedObject;
end;

(**
 * Détermine l'indice de l'objet passé en paramètre
 *
 * @param AObject 	 l'objet à rechercher
 *
 * @return l'indice de l'objet 	si trouvé
 *         -1									 	sinon
 **)
function TLinkedObjectList.IndexOf(AObject: TObject): Integer;
var
  i: Integer;
  Struct: TLinkedStruct;
begin
	Result := -1;
  if (not (Assigned(FHead))) then exit;

  i := 0;
  Struct := FHead;
  while (Assigned(Struct)) do
    begin
    	if (AObject = Struct.LinkedObject) then
        begin
        	Result := i;
          exit;
        end;
      inc(i);
    	Struct := Struct.Next;
    end;
end;

(**
 * Insère un objet dans la liste
 *
 * @param AIndex 		l'indice d'insertion
 * @param AObject		l'objet à insérer
 *
 * @throws EOutOfBoundException 			si l'indice est hors de limite
 **)
procedure TLinkedObjectList.Insert(AIndex: Integer; AObject: TObject);
var
  Struct: TLinkedStruct;
  StructPrev: TLinkedStruct;
  StructNext: TLinkedStruct;
begin
	// Insertion en 1° élément
	if (AIndex = 0) then
    begin
    	InsertHead(AObject);
    	exit;
    end;

  // Insertion en dernier élément
  if (AIndex = Size) then
    begin
    	Add(AObject);
      exit;
    end;

  // Insertion en milieu de liste
  try
  	// On recherche les 2 pointeurs qui encadrent
  	StructPrev := GetStruct(Pred(AIndex));
    StructNext := StructPrev.Next;
  except
  	// Et on gère les exceptions
    on E: EOutOfBoundException  do raise EOutOfBoundException.Create(E.Message);
  else
    exit;
  end;

  // Une fois qu'on a les 2 pointeurs qui encadrent, on effectue l'insertion
	Struct := TLinkedStruct.Create(AObject);
  StructPrev.Next := Struct;
  StructNext.Prev := Struct;
  Struct.Prev := StructPrev;
  Struct.Next := StructNext;

  // Et on incrémente le compteur
  inc(FSize);
end;

(**
 * Renvoie l'élément à l'indice donné
 *
 * @param AIndex		l'indice
 *
 * @return 					l'objet correspondant
 *
 * @throws EOutOfBoundException 			si l'indice est hors de limite
 **)
function TLinkedObjectList.GetItem(AIndex: Integer): TObject;
var
  Struct: TLinkedStruct;
begin
  Struct := GetStruct(AIndex);
  Result := Struct.LinkedObject;
end;

(**
 * Définit l'élément à l'indice donné
 *
 * @param AIndex 	l'indice donné
 * @param Value   l'objet à placer
 *
 * @throws EOutOfBoundException 			si l'indice est hors de limite
 **)
procedure TLinkedObjectList.SetItem(AIndex: Integer; const Value: TObject);
var
  Struct: TLinkedStruct;
begin
	Struct := GetStruct(AIndex);
  Struct.LinkedObject := Value;
end;


(**
 * Renvoie le pointeur d'indice donné
 * Recherche en mode ascendant ou descendant selon la position de l'indice dans la liste
 *
 * @param AIndex 		l'indice du pointeur
 *
 * @return					le pointeur d'indice donné
 *
 * @throws EOutOfBoundException 			si l'indice est hors de limite
 **)
function TLinkedObjectList.GetStruct(AIndex: Integer): TLinkedStruct;
var
  i: Integer;
  Struct: TLinkedStruct;
begin
	if (AIndex < 0) or (AIndex >= Size) then
    begin
      raise EOutOfBoundException.CreateFmt('Index %d incorrect', [AIndex]);
      exit;
    end;

  // Indice <= Indice du milieu de liste : parcours ascendant
  if (AIndex <= MidIndex()) then
    begin
		  i := 0;
		  Struct := FHead;
		  while (i < AIndex) do
  			begin
		    	Struct := Struct.Next;
    		  inc(i);
    		end;
    end
  // Indice > Indice du milieu de liste : parcours descendant
  else
  	begin
    	i := Pred(FSize);
      Struct := FTail;
      while (i > AIndex) do
        begin
        	Struct := Struct.Prev;
          dec(i);
        end;
    end;

  Result := Struct;
end;

(**
 * Renvoie l'indice du milieu de liste
 *
 * @return	l'indice du milieu de liste
 **)
function TLinkedObjectList.MidIndex: Integer;
begin
  Result := FSize shr 1;
end;

(**
 * Insère un objet en tête de liste
 * Créé la liste si nécessaire
 *
 * @param AObject	l'objet à insérer
 **)
procedure TLinkedObjectList.InsertHead(AObject: TObject);
var
  Struct: TLinkedStruct;
begin
  // Liste vide: on ajoute l'élément
	if (Size = 0) then
    begin
     	Add(AObject);
      exit;
    end;

  // Liste contenant au moins un élément, on ajoute en tête
  Struct := TLinkedStruct.Create(AObject);
  Struct.Next := FHead;
  FHead.Prev := Struct;
  FHead := Struct;
  inc(FSize);
end;

(**
 * Insère un objet en fin de liste
 * Créée la liste si nécessaire
 *
 * @param AObject	l'objet à insérer
 **)
procedure TLinkedObjectList.InsertTail(AObject: TObject);
var
  Struct: TLinkedStruct;
begin
	if (Size = 0) then
    begin
    	Add(AObject);
      exit;
    end;
    
	// On ajoute l'élément en fin de liste
	Struct := TLinkedStruct.Create(AObject);
  FTail.Next := Struct;
  Struct.Prev := FTail;
  FTail := Struct;
  inc(FSize);
end;

(**
 * Vide la liste
 * Libère la mémoire associée à la structure
 * Libère les objets si la liste en est propriétaire
 **)
procedure TLinkedObjectList.Clear();
var
  Struct: TLinkedStruct;
  StructToFree: TLinkedStruct;
begin
	// Liste déjà vide, on sort !
  if (FSize = 0) then exit;

  Struct := FHead;
  while (Assigned(Struct)) do
    begin
      StructToFree := Struct;
      Struct := Struct.Next;
      // Si on est propriétaire, on libère l'objet
    	if (OwnsObjects) then StructToFree.FreeObject();
      // On libère le pointeur dans tous les cas
      StructToFree.Free();
    end;

  // On remet en place les variables Taille, Tête et Queue
  Init();
end;

(**
 * Supprime l'objet situé à l'indice donné
 **)
procedure TLinkedObjectList.Delete(AIndex: Integer);
var
  Struct: TLinkedStruct;
  StructPrev: TLinkedStruct;
  StructNext: TLinkedStruct;
begin
	// Insertion en 1° élément
	if (AIndex = 0) then
    begin
    	DeleteHead();
    	exit;
    end;

  // Insertion en dernier élément
  if (AIndex = Size) then
    begin
    	DeleteTail();
      exit;
    end;

  // Suppression en milieu de liste
  try
  	// On recherche les 2 pointeurs qui encadrent
    Struct := GetStruct(AIndex);
  	StructPrev := Struct.Prev;
    StructNext := Struct.Next;
  except
  	// Et on gère les exceptions
    on E: EOutOfBoundException  do raise EOutOfBoundException.Create(E.Message);
  else
    exit;
  end;

  // Une fois qu'on a les 2 pointeurs qui encadrent, on effectue la suppression
  StructPrev.Next := StructNext;
  StructNext.Prev := StructPrev;

  // On libère la mémoire
  if (OwnsObjects) then Struct.FreeObject();
  Struct.Free();

  // Et on incrémente le compteur
  dec(FSize);
end;


(**
 * Supprime la tête de la liste
 *
 * @throws EOutOfBoundException		si liste vide
 **)
procedure TLinkedObjectList.DeleteHead();
var
  Struct: TLinkedStruct;
begin
  if (FSize = 0) then
  	raise EOutOfBoundException.Create('Liste vide');

  Struct := FHead;
  FHead := FHead.Next;
  if (Assigned(FHead)) then FHead.Prev := nil;

  if (OwnsObjects) then Struct.FreeObject();
  Struct.Free();
  dec(FSize);
end;

(**
 * Supprime la fin de la liste
 *
 * @throws EOutOfBoundException		si liste vide
 **)
procedure TLinkedObjectList.DeleteTail();
var
  Struct: TLinkedStruct;
begin
  if (FSize = 0) then
  	raise EOutOfBoundException.Create('Liste vide');

  Struct := FTail;
  FTail := FTail.Prev;
  if (Assigned(FTail)) then FTail.Next := nil;

  if (OwnsObjects) then Struct.FreeObject();
  Struct.Free();
  dec(FSize);
end;

function TLinkedObjectList.Iterator: TLinkedIterator;
begin
  Result := TLinkedIterator.Create(FHead);
end;

{ TLinkedIterator }

constructor TLinkedIterator.Create(Struct: TLinkedStruct);
begin
  inherited Create();
  CurrentStruct := Struct;
end;

function TLinkedIterator.HasNext: Boolean;
begin
  Result := Assigned(CurrentStruct);
end;

function TLinkedIterator.Next(): TObject;
begin
	Result := CurrentStruct.LinkedObject;
  CurrentStruct := CurrentStruct.Next;
end;

end.
