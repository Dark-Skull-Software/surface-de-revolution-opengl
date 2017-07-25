unit UnitCodeProfiler;

interface

uses
  Windows, Classes, Types, Contnrs, Math;

type
	(**
   * Informations sur une section de code
   **)
  TCodeProfileSectionInfo = class(TObject)
  private
  	{ Déclarations privées }
    FSectionName:		String;		// Nom de la section
  	FTimeSum:				Cardinal;	// Temps total d'exécution
    FPreviousTime: 	Cardinal; // Temps de démarrage de la section
    FCallsCount:		Cardinal; // Compteur d'appels
    FStarted:				Boolean;  // 1 si la section est démarrée
  protected
  	{ Déclarations protégées }
  public
  	{ Déclarations publiques }
    constructor Create(); overload;
    constructor Create(Name: String); overload;
    procedure IncreaseCount();
    procedure BeginSection();
    procedure EndSection();
    procedure Reset();
    function getOutPutString(const GlobalTimeSum: Cardinal): String;
  published
    { Déclarations publiées }
  	property TimeSum:      Cardinal read FTimeSum;
    property PreviousTime: Cardinal read FPreviousTime;
    property CallsCount:   Cardinal read FCallsCount;
    property SectionName:  String   read FSectionName write FSectionName;
    property Started:      Boolean  read FStarted;
  end;

  (**
   * Gestionnaire de profils
   **)
  TCodeProfileManager = class(TObjectList)
  private
  	{ Déclarations privées }
    FFileName: String;
    FGlobalSection: TCodeProfileSectionInfo;
    FSectionNames: TStrings;
    FDebugInfos: TStringList;
  protected
  	{ Déclarations protégées }
    function GetSection(Index: Integer): TCodeProfileSectionInfo;
    procedure SetSection(Index: Integer; Value: TCodeProfileSectionInfo);
    procedure Init();
    procedure Release();
    function GetTime(): String;
    procedure AddLogEntryWithTime(const Text: String);
    procedure AddLogEntry(const Text: String);
    procedure AddLogSeparator();
  public
  	{ Déclarations publiques }
    constructor Create(FileName: String; SectionNames: TStrings);
    destructor Destroy(); override;
    procedure Reset();
    procedure DoOutput();
    procedure BeginSection(const SectionIndex: Integer);
    procedure EndSection(const SectionIndex: Integer);
    property Items[Index: Integer]: TCodeProfileSectionInfo read GetSection write SetSection;
  published
    { Déclarations publiées }
    property GlobalSection: TCodeProfileSectionInfo read FGlobalSection;
    property FileName: String read FFileName write FFileName;
    property SectionNames: TStrings read FSectionNames write FSectionNames;
    property DebugInfos: TStringList read FDebugInfos;
  end;


implementation

uses SysUtils;

{ TCodeProfileManager }

(**
 * Constructeur
 *
 * @param FileName			le nom du fichier
 * @param SectionNames  Un TStrings contenant le nom des sections à enregistrer
 **)
constructor TCodeProfileManager.Create(FileName: String;
																		   SectionNames: TStrings);
begin
	inherited Create(True);
  FFileName := FileName;
  FSectionNames := SectionNames;
  Init();
end;

(**
 * Destructeur
 **)
destructor TCodeProfileManager.Destroy();
begin
	Release();
	inherited Destroy();
end;

(**
 * Ajoute une entrée au fichier de log
 **)
procedure TCodeProfileManager.AddLogEntry(const Text: String);
begin
	DebugInfos.Add(Format('%s', [Text]));
end;

(**
 * Ajoute une entrée au fichier de log avec le temps
 **)
procedure TCodeProfileManager.AddLogEntryWithTime(const Text: String);
begin
  DebugInfos.Add(Format('[%s] %s', [GetTime(), Text]));
  AddLogSeparator();
end;

(**
 * Ajoute un séparateur au fichier de log
 **)
procedure TCodeProfileManager.AddLogSeparator();
begin
	DebugInfos.Add('');
  DebugInfos.Add('=============================================');
  DebugInfos.Add('');  
end;

(**
 * Génère la sortie du profiler
 **)
procedure TCodeProfileManager.DoOutput();
var
  i: Integer;
  TimeSum: Cardinal;
begin
	GlobalSection.EndSection();

  DebugInfos.Add('');
  DebugInfos.Add('Profiler Summary');
  DebugInfos.Add(Format('-----------------------------------------------', []));
  DebugInfos.Add(Format('%%temps (ms) - appels - Section', []));
	DebugInfos.Add(Format('-----------------------------------------------', []));

  TimeSum := 0;

  for i := 0 to Pred(Count) do
  	begin
    AddLogEntry((Items[i] as TCodeProfileSectionInfo).getOutPutString(GlobalSection.TimeSum));
    TimeSum := TimeSum + (Items[i] as TCodeProfileSectionInfo).TimeSum;
    end;

  DebugInfos.Add('');
	DebugInfos.Add(Format('%f%% (%u ms) - %s',
  										 [(GlobalSection.TimeSum - Min(TimeSum, GlobalSection.TimeSum)) * 100 / GlobalSection.TimeSum,
											  (GlobalSection.TimeSum - Min(TimeSum, GlobalSection.TimeSum)),
											  'Autres']));

  DebugInfos.Add(Format('-----------------------------------------------', []));
	DebugInfos.Add(Format('Total %u ms', [GlobalSection.TimeSum]));

  DebugInfos.SaveToFile(FileName);
end;


(**
 * Renvoie le temps courant
 **)
function TCodeProfileManager.GetTime: String;
begin
 Result := TimeToStr(Time);
end;

(**
 * Initialisation
 **)
procedure TCodeProfileManager.Init();
var
  i: Integer;
begin
	// On construit la liste qui va contenir les infos de debug
  FDebugInfos := TStringList.Create();
  FGlobalSection := TCodeProfileSectionInfo.Create();

  // On construit les éléments de debug
  for i := 0 to Pred(FSectionNames.Count) do
  	begin
    	Add(TCodeProfileSectionInfo.Create(FSectionNames.Strings[i]));
    end;

  Reset();
  AddLogEntryWithTime('Session started');
end;

(**
 * Finalisation
 **)
procedure TCodeProfileManager.Release();
begin
  AddLogEntryWithTime('Session closed');
	GlobalSection.EndSection();
end;


(**
 * Réinitialise la section globale
 **)
procedure TCodeProfileManager.Reset;
begin
  GlobalSection.Reset();
  GlobalSection.BeginSection();
end;

{ TCodeProfileSectionInfo }

(**
 * Constructeur
 **)
constructor TCodeProfileSectionInfo.Create();
begin
  inherited Create();
  Reset();
end;

(**
 * On débute une section
 **)
procedure TCodeProfileSectionInfo.BeginSection;
begin
	if (FStarted) then exit;

	FStarted := True;
  FPreviousTime := GetTickCount();
  IncreaseCount();
end;

(**
 * On termine une section
 **)
procedure TCodeProfileSectionInfo.EndSection();
begin
	if (not FStarted) then exit;

  FTimeSum := FTimeSum + (GetTickCount() - FPreviousTime);
	FStarted := False;
end;

(**
 * On incrémente le compteur
 **)
procedure TCodeProfileSectionInfo.IncreaseCount();
begin
	Inc(FCallsCount);
end;

(**
 * Réinitialise la section
 **)
procedure TCodeProfileSectionInfo.Reset();
begin
  FCallsCount := 0;
  FStarted := False;
  FTimeSum := 0;
end;

(**
 * Génère la chaîne de sortie
 *
 * @param GlobalTimeSum		le temps total
 *
 * @return la chaîne
 **)
function TCodeProfileSectionInfo.getOutPutString(const GlobalTimeSum: Cardinal): String;
begin
	Result := Format('%f%% (%u ms) - %u appels - %s', [TimeSum * 100 / GlobalTimeSum,
																			  TimeSum,
                                        CallsCount,
																			  SectionName]);
end;

function TCodeProfileManager.GetSection(
  Index: Integer): TCodeProfileSectionInfo;
begin
  Result := TCodeProfileSectionInfo(inherited getItem(Index));
end;

procedure TCodeProfileManager.SetSection(Index: Integer;
  Value: TCodeProfileSectionInfo);
begin
   inherited SetItem(Index, Value);
end;

constructor TCodeProfileSectionInfo.Create(Name: String);
begin
  inherited Create();
  Reset();
  FSectionName := Name;
end;

procedure TCodeProfileManager.BeginSection(const SectionIndex: Integer);
begin
  Items[SectionIndex].BeginSection();
end;

procedure TCodeProfileManager.EndSection(const SectionIndex: Integer);
begin
  Items[SectionIndex].EndSection();
end;

end.
