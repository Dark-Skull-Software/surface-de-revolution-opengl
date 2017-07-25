unit StructLinkedList;

interface

uses
  SysUtils;

type
  TLinkedStruct = class(TObject)
  private
  	{ D�clarations priv�es }
  	FNext: TLinkedStruct;
    FPrev: TLinkedStruct;
    FLinkedObject: TObject;
    procedure Init();
  protected
  	{ D�clarations prot�g�es }
  public
  	{ D�clarations publiques }
  	constructor Create(); overload;
    constructor Create(AObject: TObject); overload;
    destructor Destroy(); override;
    procedure FreeObject();
  published
  	{ D�clarations publi�es }
  	property Next: TLinkedStruct read FNext write FNext;
    property Prev: TLinkedStruct read FPrev write FPrev;
    property LinkedObject: TObject read FLinkedObject write FLinkedObject;
  end;

  TLinkedIterator = class(TObject)
  private
  	{ D�clarations priv�es }
  	CurrentStruct: TLinkedStruct;
  public
  	{ D�clarations publiques }
  	constructor Create(Struct: TLinkedStruct);
    function HasNext(): Boolean;
    function Next(): TObject;
  end;


  TLinkedObjectList = class(TObject)
  private
  	{ D�clarations priv�es }
    FHead: TLinkedStruct;
    FTail: TLinkedStruct;
    FOwnsObjects: Boolean;
	  FSize: Integer;
  protected
    { D�clarations prot�g�es }
    function MidIndex(): Integer;
    procedure Init();
    function GetHead: TObject;
    function GetTail: TObject;
    function GetItem(AIndex: Integer): TObject;
    procedure SetItem(AIndex: Integer; const Value: TObject);
    function GetStruct(AIndex: Integer): TLinkedStruct;
    property Structs[AIndex: Integer]: TLinkedStruct read GetStruct;
  public
    { D�clarations publiques }
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
  	{ D�clarations publi�es }
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
 * @param AObject l'objet � associer � la structure
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
 * Lib�re l'objet associ� au pointeur si possible
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
 * Constructeur sans param�tres
 * Associe les objets � la liste
 **)
constructor TLinkedObjectList.Create();
begin
  inherited Create();
  Init();
  FOwnsObjects := False;
end;

(**
 * Constructeur avec param�tre
 *
 * @param AOwnsObjects		Sp�cifie si les objets appartiennent � la liste ou pas
 **)
constructor TLinkedObjectList.Create(AOwnsObjects: Boolean);
begin
  inherited Create();
  Init();
  FOwnsObjects := AOwnsObjects;
end;

(**
 * Destructeur
 * Lib�re la m�moire associ�e
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
 * Cr�e la liste si elle est vide
 *
 * @param AObject		l'objet � ins�rer
 **)
procedure TLinkedObjectList.Add(AObject: TObject);
var
  Struct: TLinkedStruct;
begin
	// Liste vide: on cr�� la liste � proprement parler
	if (Size = 0) then
    begin
    	Struct := TLinkedStruct.Create(AObject);
    	FHead := Struct;
      FTail := Struct;
      inc(FSize);
      exit;
    end;

  // Liste non vide, on ins�re en fin de liste
  InsertTail(AObject);
end;


(**
 * Renvoie l'objet plac� en t�te de liste
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
 * Renvoie l'objet plac� en fin de liste
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
 * D�termine l'indice de l'objet pass� en param�tre
 *
 * @param AObject 	 l'objet � rechercher
 *
 * @return l'indice de l'objet 	si trouv�
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
 * Ins�re un objet dans la liste
 *
 * @param AIndex 		l'indice d'insertion
 * @param AObject		l'objet � ins�rer
 *
 * @throws EOutOfBoundException 			si l'indice est hors de limite
 **)
procedure TLinkedObjectList.Insert(AIndex: Integer; AObject: TObject);
var
  Struct: TLinkedStruct;
  StructPrev: TLinkedStruct;
  StructNext: TLinkedStruct;
begin
	// Insertion en 1� �l�ment
	if (AIndex = 0) then
    begin
    	InsertHead(AObject);
    	exit;
    end;

  // Insertion en dernier �l�ment
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
  	// Et on g�re les exceptions
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

  // Et on incr�mente le compteur
  inc(FSize);
end;

(**
 * Renvoie l'�l�ment � l'indice donn�
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
 * D�finit l'�l�ment � l'indice donn�
 *
 * @param AIndex 	l'indice donn�
 * @param Value   l'objet � placer
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
 * Renvoie le pointeur d'indice donn�
 * Recherche en mode ascendant ou descendant selon la position de l'indice dans la liste
 *
 * @param AIndex 		l'indice du pointeur
 *
 * @return					le pointeur d'indice donn�
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
 * Ins�re un objet en t�te de liste
 * Cr�� la liste si n�cessaire
 *
 * @param AObject	l'objet � ins�rer
 **)
procedure TLinkedObjectList.InsertHead(AObject: TObject);
var
  Struct: TLinkedStruct;
begin
  // Liste vide: on ajoute l'�l�ment
	if (Size = 0) then
    begin
     	Add(AObject);
      exit;
    end;

  // Liste contenant au moins un �l�ment, on ajoute en t�te
  Struct := TLinkedStruct.Create(AObject);
  Struct.Next := FHead;
  FHead.Prev := Struct;
  FHead := Struct;
  inc(FSize);
end;

(**
 * Ins�re un objet en fin de liste
 * Cr��e la liste si n�cessaire
 *
 * @param AObject	l'objet � ins�rer
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
    
	// On ajoute l'�l�ment en fin de liste
	Struct := TLinkedStruct.Create(AObject);
  FTail.Next := Struct;
  Struct.Prev := FTail;
  FTail := Struct;
  inc(FSize);
end;

(**
 * Vide la liste
 * Lib�re la m�moire associ�e � la structure
 * Lib�re les objets si la liste en est propri�taire
 **)
procedure TLinkedObjectList.Clear();
var
  Struct: TLinkedStruct;
  StructToFree: TLinkedStruct;
begin
	// Liste d�j� vide, on sort !
  if (FSize = 0) then exit;

  Struct := FHead;
  while (Assigned(Struct)) do
    begin
      StructToFree := Struct;
      Struct := Struct.Next;
      // Si on est propri�taire, on lib�re l'objet
    	if (OwnsObjects) then StructToFree.FreeObject();
      // On lib�re le pointeur dans tous les cas
      StructToFree.Free();
    end;

  // On remet en place les variables Taille, T�te et Queue
  Init();
end;

(**
 * Supprime l'objet situ� � l'indice donn�
 **)
procedure TLinkedObjectList.Delete(AIndex: Integer);
var
  Struct: TLinkedStruct;
  StructPrev: TLinkedStruct;
  StructNext: TLinkedStruct;
begin
	// Insertion en 1� �l�ment
	if (AIndex = 0) then
    begin
    	DeleteHead();
    	exit;
    end;

  // Insertion en dernier �l�ment
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
  	// Et on g�re les exceptions
    on E: EOutOfBoundException  do raise EOutOfBoundException.Create(E.Message);
  else
    exit;
  end;

  // Une fois qu'on a les 2 pointeurs qui encadrent, on effectue la suppression
  StructPrev.Next := StructNext;
  StructNext.Prev := StructPrev;

  // On lib�re la m�moire
  if (OwnsObjects) then Struct.FreeObject();
  Struct.Free();

  // Et on incr�mente le compteur
  dec(FSize);
end;


(**
 * Supprime la t�te de la liste
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
