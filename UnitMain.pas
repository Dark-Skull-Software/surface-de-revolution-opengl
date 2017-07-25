unit UnitMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls, ComCtrls, ToolWin, ShellAPI, Contnrs, dglOpenGL,
  CompoGLPanelsSDR, UnitCodeProfiler;

type
  TFormMain = class(TForm)
    StatusBar: TStatusBar;
    ToolBar: TToolBar;
    ToolButtonDrawPoints: TToolButton;
    ToolButtonDrawLines: TToolButton;
    ToolButtonDrawFilled: TToolButton;
    Separator1: TToolButton;
    ToolButtonOrtho: TToolButton;
    ToolButtonPersp: TToolButton;
    Separator2: TToolButton;
    ToolButtonNbPoints: TToolButton;
    Separator3: TToolButton;
    ToolButtonNew: TToolButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ToolButtonDrawPointsClick(Sender: TObject);
    procedure ToolButtonDrawLinesClick(Sender: TObject);
    procedure ToolButtonDrawFilledClick(Sender: TObject);
    procedure ToolButtonOrthoClick(Sender: TObject);
    procedure ToolButtonPerspClick(Sender: TObject);
    procedure ToolButtonNbPointsClick(Sender: TObject);
    procedure ToolButtonNewClick(Sender: TObject);
  private
    { Déclarations privées }
    Debug: TStringList;    // Liste contenant le texte pour le Débugage
    PanelGL: TGLPanelsSDR; // Le panel servant à l'affichage
    procedure DoError(Sender: TObject; ErrCode: GLEnum; Title: String; Description: String);
  public
    { Déclarations publiques }
    procedure ExceptionGL(Sender: TObject; E: Exception);
  end;

var
  FormMain: TFormMain;


implementation

uses Types;

{$R *.dfm}

(**
 * Création de la fiche
 **)
procedure TFormMain.FormCreate(Sender: TObject);
begin
  PanelGL := TGLPanelsSDR.Create(Self);
  PanelGL.Parent := Self;
  PanelGL.Align := alClient;
  PanelGL.InitOpenGL();
  PanelGL.OnGLError := DoError;
  ActiveControl := PanelGL;

	Debug := TStringList.Create;
	Application.OnException := ExceptionGL;
end;


(**
 * Libération de la fiche
 **)
procedure TFormMain.FormDestroy(Sender: TObject);
begin
	if (Debug.Count > 0) then
	  Debug.SaveToFile('debug.log');
  Debug.Free();
  PanelGL.Free();
end;


(**
 * Réaction en cas d'erreur OpenGL
 **)
procedure TFormMain.DoError(Sender: TObject; ErrCode: GLEnum; Title,
  Description: String);
begin
  Caption := Title + ' ' + Description;
  Debug.Add(Caption);
  MessageDlg(Caption, mtError, [mbOK], 0);
end;


(**
 * Réaction en cas d'exception de l'Application
 **)
procedure TFormMain.ExceptionGL(Sender: TObject; E: Exception);
begin
	MessageDlg('Exception : ' + E.Message, mtError, [mbOK], 0);
  PanelGL.DoDebug('Exception');
end;


(**
 * Sélection du mode de dessin "Points"
 **)
procedure TFormMain.ToolButtonDrawPointsClick(Sender: TObject);
begin
  ToolButtonDrawPoints.Down := True;
  ToolButtonDrawLines.Down  := False;
  ToolButtonDrawFilled.Down := False;
  PanelGL.PolygonMode := GL_POINT;
  PanelGL.DrawGLScene();
end;


(**
 * On choisit le mode de dessin "Lignes"
 **)
procedure TFormMain.ToolButtonDrawLinesClick(Sender: TObject);
begin
  ToolButtonDrawPoints.Down := False;
  ToolButtonDrawLines.Down  := True;
  ToolButtonDrawFilled.Down := False;
  PanelGL.PolygonMode := GL_LINE;
  PanelGL.DrawGLScene();
end;


(**
 * On choisit le mode de dessin "Polygones Pleins"
 **)
procedure TFormMain.ToolButtonDrawFilledClick(Sender: TObject);
begin
  ToolButtonDrawPoints.Down := False;
  ToolButtonDrawLines.Down  := False;
  ToolButtonDrawFilled.Down := True;
  PanelGL.PolygonMode := GL_FILL;
  PanelGL.DrawGLScene();
end;


(**
 * On choisit la projection orthogonale
 **)
procedure TFormMain.ToolButtonOrthoClick(Sender: TObject);
begin
  ToolButtonOrtho.Down := True;
  ToolButtonPersp.Down := False;
  PanelGL.Perspective  := False;
	PanelGL.DrawGLScene();
end;


(**
 * On choisit la projection perspective
 **)
procedure TFormMain.ToolButtonPerspClick(Sender: TObject);
begin
	ToolButtonOrtho.Down := False;
  ToolButtonPersp.Down := True;
  PanelGL.Perspective  := True;
  PanelGL.DrawGLScene();
end;


(**
 * On définit la nouvelle résolution du profil
 **)
procedure TFormMain.ToolButtonNbPointsClick(Sender: TObject);
var
  s: String;
  i: Integer;
begin
  s := InputBox('Résolution'
              , 'Veuillez Saisir le nombre de points'
              , IntToStr(PanelGL.SoR.SliceCount));
  try
		i := StrToInt(s);
    PanelGL.SoR.SliceCount := i;
    PanelGL.UpdateModel();
    PanelGL.DrawGLScene();
  except
  end;
end;


(**
 * Nouveau modèle... On élimine l'ancien
 **)
procedure TFormMain.ToolButtonNewClick(Sender: TObject);
begin
  PanelGL.SoR.ClearModel();
  PanelGL.SoR.Memory2D.FindMinMax();
  PanelGL.UpdateModel();
  PanelGL.DrawGLScene();
end;

end.
