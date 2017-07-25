unit CompoGLPanel;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, dglOpenGL;

type
	TGLErrorEvent = procedure(Sender: TObject; ErrCode: GLEnum; Title: String; Description: String) of object;

  TGLPanel = class(TPanel)
  private
    { D�clarations priv�es }
    fOnEraseBkgnd : TNotifyEvent;
    fOnPaint      : TNotifyEvent;
    fOnMouseEnter : TNotifyEvent;
    fOnMouseLeave : TNotifyEvent;
    fOnInitOpenGL : TNotifyEvent;
    fOnGLError:			TGLErrorEvent;
    
    FOpenGLStarted: Boolean;
    FColorBits:			Byte;
    FDepthBits:			Byte;
    FMouseInside:		Boolean;
  protected
    { D�clarations prot�g�es }    
    // Les Contextes
    DC : HDC;
    RC : HGLRC;
    // Gesion des messages
    procedure WMEraseBkgnd(var Message : TMessage); message WM_ERASEBKGND;
    procedure CMMouseEnter(var Message : TMessage); message CM_MOUSEENTER;
	  procedure CMMouseLeave(var Message : TMessage); message CM_MOUSELEAVE;
	  procedure WndProc(var Message : TMessage); override;

    function  PixelFormatSetup(): Boolean;
  public
    { D�clarations publiques }
    constructor Create(AOwner : TComponent); override;
    destructor Destroy(); override;
    procedure InitOpenGL();
    procedure ShutDownOpenGL();
    function MakeCurrent(): Boolean;
    procedure ViewPort();
    procedure SwapBuffers();
		procedure DoDebug(const Title: String);
  published
    { D�clarations publi�es }
    property OpenGLStarted: Boolean read FOpenGLStarted;
    property MouseInside: Boolean read FMouseInside;
    property ColorBits: Byte read FColorBits write FColorBits;
    property DepthBits: Byte read FDepthBits write FDepthBits;
    property glDC: HDC read DC;
    property Canvas;

    property OnEraseBkgnd : TNotifyEvent  read fOnEraseBkgnd write fOnEraseBkgnd;
    property OnGLError:			TGLErrorEvent read fOnGLError    write fOnGLError;
    property OnInitOpenGL : TNotifyEvent  read fOnInitOpenGL write fOnInitOpenGL;
    property OnPaint :      TNotifyEvent  read fOnPaint      write fOnPaint;
    property OnMouseEnter : TNotifyEvent  read fOnMouseEnter write fOnMouseEnter;
    property OnMouseLeave : TNotifyEvent  read fOnMouseLeave write fOnMouseLeave;
    property OnMouseMove;
    property OnMouseDown;
    property OnMouseUp;
    property OnResize;
    property OnMouseWheel;
  end;

procedure Register;

implementation

uses Variants;

{ TGLPanel }

(**
 * Enregistrement du composant
 **)
procedure Register;
begin
  RegisterComponents('Dark Skull', [TGLPanel]);
end;

(**
 * La souris entre dans le panneau
 **)
procedure TGLPanel.CMMouseEnter(var Message: TMessage);
begin
	FMouseInside := True;
  If Enabled then
  	If Assigned(fOnMouseEnter) then fOnMouseEnter(Self);
	if Assigned(fOnPaint) then fOnPaint(Self);
end;

(**
 * La souris sort du panneau
 **)
procedure TGLPanel.CMMouseLeave(var Message: TMessage);
begin
	FMouseInside := False;
  If Enabled then
    If Assigned(fOnMouseLeave) then fOnMouseLeave(Self);
  if Assigned(fOnPaint) then fOnPaint(Self);
end;

(**
 * Constructeur
 **)
constructor TGLPanel.Create(AOwner : TComponent);
begin
	// Construction du TPanel
  inherited Create(AOwner);

  // Configuration du composant
  BevelInner := bvNone;
  BevelOuter := bvNone;
  Caption    := EmptyStr;

  // Initialisation des �vennements
  fOnEraseBkgnd := nil;
  fOnPaint 			:= nil;
  fOnMouseEnter := nil;
  fOnMouseLeave := nil;

  // Initialisation des param�tres OpenGL
  FOpenGLStarted := False;
  FColorBits 		 := 24;
  FDepthBits		 := 32;
end;

(**
 * S�lectionne le format de pixel correct
 *
 * @return TRUE si Ok
 *         FALSE en cas d'�chec
 **)
function TGLPanel.PixelFormatSetup(): Boolean;
var
  pfd: TPixelFormatDescriptor;
  FormatIndex: Integer;
begin
  FillChar(pfd, SizeOf(pfd), 0);
  with pfd do
    begin
      nSize := SizeOf(pfd);
      nVersion := 1;
      dwFlags := PFD_DRAW_TO_WINDOW
              or PFD_SUPPORT_OPENGL
              or PFD_DOUBLEBUFFER;
      iPixelType := PFD_TYPE_RGBA;
      cColorBits := FColorBits;
      cDepthBits := FDepthBits;
      iLayerType := PFD_MAIN_PLANE;
    end;
  FormatIndex := ChoosePixelFormat(DC, @pfd);
  Result := Boolean(FormatIndex);
  if (Result) then
    begin
      Result := SetPixelFormat(DC, Integer(Result), @pfd);
      if (not Result) then ShowMessage('Erreur dans setpixelformat');
    end
  else
  	ShowMessage('Erreur dans choosepixelformat');
end;

(**
 * Destructeur
 **)
destructor TGLPanel.Destroy();
begin
	// Lib�ration des ressources OpenGL
  ShutDownOpenGL();
  // Lib�ration du TPanel
  inherited Destroy();
end;

(**
 * Initialisation du composant.
 * Doit �tre appel�e manuellement apr�s affectation du parent
 **)
procedure TGLPanel.InitOpenGL();
var
  ErrCode: GLEnum;
begin
	// R�cup�ration du DC
  DC := GetDC(Handle);
  if (DC = 0) then
    begin
	    MessageDlg('Erreur r�cup�ration DC', mtError, [mbOK], 0);
	    exit;
    end;

  // S�lection du format de pixel
  if not (PixelFormatSetup()) then
    begin
	    MessageDlg('Erreur PixelFormatSetup', mtError, [mbOK], 0);
    	exit;
    end;

  // Cr�ation du contexte de rendu
  RC := wglCreateContext(DC);
  if (RC = 0) then
    begin
	    MessageDlg('Erreur Cr�ation Contexte OpenGL', mtError, [mbOK], 0);
	  	exit;
    end;


  // S�lection du contexte pour le prochain rendu
  if (not (MakeCurrent())) then
    begin
	    MessageDlg('Erreur D�finition Contexte OpenGL', mtError, [mbOK], 0);
      exit;
    end;

  // On active les extensions GL
  ActivateRenderingContext(DC, RC);

	// On affiche le code d'erreur s'il y en a 1
  ErrCode := glGetError;
  if not (ErrCode = GL_NO_ERROR) then
  	begin
	    MessageDlg('Erreur dans Init : ' + gluErrorString(ErrCode), mtError, [mbOK], 0);
      exit;
    end;

  // Si on arrive ici, c'est que l'initialisation s'est bien pass�e
  FOpenGLStarted := True;

  // On d�clenche l'�vennement
  if (Assigned(fOnInitOpenGL)) then
  	fOnInitOpenGL(Self);
end;

(**
 * Finalisation et lib�ration du contexte OpenGL
 **)
procedure TGLPanel.ShutDownOpenGL();
begin
	if (OpenGLStarted) and (HasParent)  then
    begin
    	wglMakeCurrent(DC, 0);
    	wglDeleteContext(RC);
		 	ReleaseDC(Handle, DC);
      FOpenGLStarted := False;
  	end;
end;

(**
 * Effacement de la fen�tre
 **)
procedure TGLPanel.WMEraseBkgnd (var Message : TMessage);
begin
  If Assigned(fOnEraseBkgnd) then
    fOnEraseBkgnd(Self);
end;

(**
 * Gestion des messages
 **)
procedure TGLPanel.WndProc(var Message : TMessage);
var
  Ps: TPaintStruct;
begin
	case Message.Msg of
  	WM_PAINT:
      begin
	      If (FOpenGLStarted) and (Assigned(fOnPaint)) then
        	begin
	          BeginPaint(Handle, Ps);
  		   	  fOnPaint(Self);
            EndPaint(Handle, Ps);
          end
        else
        	inherited;
      end;
  else
  	inherited;
  end;
end;

(**
 * Fais de ce panneau le contexte OpenGL courant
 *
 * @return	True 	en cas de succ�s
 *          False sinon
 **)
function TGLPanel.MakeCurrent: Boolean;
begin
  Result := wglMakeCurrent(DC, RC);
end;

(**
 * D�finit la fen�tre de vision
 **)
procedure TGLPanel.ViewPort;
begin
  glViewport(0, 0, ClientWidth, ClientHeight);
end;

(**
 * On �change les buffers
 **)
procedure TGLPanel.SwapBuffers;
begin
  Windows.SwapBuffers(glDC);
end;

(**
 * On traite toutes les erreurs OpenGL accumul�es
 *
 * @param Title 	le titre associ� aux erreurs
 **)
procedure TGLPanel.DoDebug(const Title: String);
var
  ErrCode: GLEnum;
begin
	if not (Assigned(fOnGLError)) then exit;

	ErrCode := glGetError();
	while (ErrCode <> GL_NO_ERROR) do
  	begin
			fOnGLError(Self, ErrCode, Title, gluErrorString(errCode));
      ErrCode := glGetError();
	  end;
end;

end.
