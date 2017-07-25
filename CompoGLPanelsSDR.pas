unit CompoGLPanelsSDR;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, Types, Math, dglOpenGL, CompoGLPanel, CompoGLPanels, UnitOpenGL,
  UnitSeparator, UnitMath, UnitLights, UnitSquare, UnitGrid,
  UnitModel2D, UnitModel3D, UnitFont, UnitCursor, UnitAxis,
  StructPoints, StructVertexMemoryStream, StructSurfaceOfRevolution;

type
  TPanel2DMouseAction = (pma2None, pma2Insert, pma2Move, pma2Delete);
	TPanel3DMouseAction = (pma3None, pma3Rotate, pma3Zoom);


  TGLPanelsSDR = class(TGLPanels)
  private
  	{ Déclarations privées }
  	XMid_2D: Single;					// Centre X du panel 2D
    XMid_3D: Single;          // Centre X du panel 3D
    YMid: Single;             // Centre Y
    FPerspective: Boolean;		// Mode perspective ou pas
    FPolygonMode: GLEnum; 		// GL_POINT, GL_LINE ou GL_FILL

    FSoR:	TSurfaceOfRevolution;        // La Surface de Revolution
    FProfile2D: TVertex2fMemoryStream; // le profil 2D
    MousePoint: TVertex2f;			       // Point correspondant à la position de la souris dans la fenêtre 2D

    // Rotation / Zoom du modèle
    Action2D :    TPanel2DMouseAction;  // Action 2D
    Action3D :    TPanel3DMouseAction;  // En train d'effectuer une rotation ou un zoom du modèle ?
    RotatingAxis: TAxis3f;              // Angle de rotation
    ZoomFactor:   GLFloat;
    MouseInitial: Types.TPoint;         // Position initiale de la souris
  protected
  	procedure PanelGLInitGL(Sender: TObject);
    procedure PanelGLResize2D(Sender: TObject);
    procedure PanelGLResize3D(Sender: TObject);
    procedure PanelGLMouseMove2D(Sender: TObject; Shift: TShiftState;
    					X: Integer; Y: Integer);
    procedure PanelGLMouseDown2D(Sender: TObject; Button: TMouseButton;
    					Shift: TShiftState; X: Integer; Y: Integer);
	  procedure PanelGLMouseUp2D(Sender: TObject; Button: TMouseButton;
    					Shift: TShiftState; X: Integer; Y: Integer);
    procedure PanelGLMouseMove3D(Sender: TObject; Shift: TShiftState;
    					X: Integer; Y: Integer);
    procedure PanelGLMouseDown3D(Sender: TObject; Button: TMouseButton;
    					Shift: TShiftState; X: Integer; Y: Integer);
	  procedure PanelGLMouseUp3D(Sender: TObject; Button: TMouseButton;
    					Shift: TShiftState; X: Integer; Y: Integer);
    procedure PanelGLMouseWheel2D(Sender: TObject; Shift: TShiftState;
	    WheelDelta: Integer; MousePos: Types.TPoint; var Handled: Boolean);
    procedure PanelGLMouseWheel3D(Sender: TObject; Shift: TShiftState;
	    WheelDelta: Integer; MousePos: Types.TPoint; var Handled: Boolean);
    procedure PanelGLKey(Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure DrawScene();
    procedure DrawSeparator();
    procedure DrawSceneSpline();
    procedure DrawScenePersp();
  public
  	constructor Create(AOwner: TComponent); override;
    destructor Destroy(); override;
    procedure DrawGLScene(); override;
    procedure UpdateModel();

    function IsMouseSplineNegative(): Boolean;
  published
  	property Perspective: Boolean read FPerspective write FPerspective;
    property PolygonMode: GLEnum read FPolygonMode write FPolygonMode;
    property SoR: TSurfaceOfRevolution read FSoR;
		property Profile2D: TVertex2fMemoryStream read FProfile2D;
  end;

implementation

const
	// Couleur de fond
  BACK_COLOR = TColor($606060);

{ TGLPanelsSDR }

(**
 * Construction
 **)
constructor TGLPanelsSDR.Create(AOwner: TComponent);
begin
	// Constructeur hérité
  inherited Create(AOwner);

  // Variables simples
  XMid_2D := 0.0;
  XMid_3D := 0.0;
  YMid    := 0.0;
  MouseInitial := Point(0, 0);
  Action2D := pma2None;
  Action3D := pma3None;
  FPerspective := False;
  PolygonMode := GL_FILL;

  // Variables objets
  FSoR := TSurfaceOfRevolution.Create();
	FProfile2D := SoR.Memory2D;
  
  ResetVertex(RotatingAxis);
  ResetVertex(MousePoint);
  ZoomFactor := 1.0;

  // Les évennements
  OnInitOpenGL      := PanelGLInitGL;
  OnResizeLeft      := PanelGLResize2D;
  OnResizeRight     := PanelGLResize3D;
  OnMouseMoveLeft   := PanelGLMouseMove2D;
  OnMouseMoveRight  := PanelGLMouseMove3D;
  OnMouseDownLeft   := PanelGLMouseDown2D;
  OnMouseDownRight  := PanelGLMouseDown3D;
  OnMouseUpLeft     := PanelGLMouseUp2D;
  OnMouseUpRight    := PanelGLMouseUp3D;
  OnMouseWheelLeft  := PanelGLMouseWheel2D;
  OnMouseWheelRight := PanelGLMouseWheel3D;
  OnKeyUp           := PanelGLKey;
  OnKeyDown				  := PanelGLKey;
end;

(**
 * Destructeur
 **)
destructor TGLPanelsSDR.Destroy();
begin
	// La police
 	KillFont();

	// Libération objets
  FProfile2D := nil;
  FSoR.Free();

  // Destructeur hérité
  inherited Destroy();
end;

(**
 * Dessin de la scène OpenGL
 **)
procedure TGLPanelsSDR.DrawGLScene();
begin
  if (OpenGLStarted) then DrawScene();
end;

(**
 * Dessin de la scène OpenGL
 **)
procedure TGLPanelsSDR.DrawScene();
begin
	// Initialisation de la fenêtre
  glViewPortRect(ClientRect);

  // On efface le fond
  glClearColorRGB(BACK_COLOR);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  // On dessine la scène de gauche
  DrawSceneSpline();
  DoDebug('DrawSceneSpline');
  
  // On dessine la scène de droite
  DrawScenePersp();
  DoDebug('DrawScenePersp');
  
  // On dessine le séparateur
  DrawSeparator();
  DoDebug('DrawSeparator');


  // On vide le buffer
  glFlush();

  // On échange les buffers
  SwapBuffers();

  // On affiche le code d'erreur s'il y en a 1
  DoDebug('DrawScene');
end;


(**
 * Dessine la partie 3D
 **)
procedure TGLPanelsSDR.DrawScenePersp();
var
	Width: Integer;
  MidHeight: GLFloat;
begin
	// Si le panneau est invisible, on sort
	if (RightRect.Left >= ClientWidth) then exit;

  // On calcule les coordonnées
  Width := RightRect.Right - RightRect.Left + 1;
  glViewportRect(RightRect);

  DoDebug('DrawScene - ViewPort');

  // On configure la matrice de projection
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
	if (Perspective) then
	  gluPerspective(50, Width / ClientHeight, 1, 1000)
  else
    glOrtho(-XMid_3D, XMid_3D, -YMid, YMid, 0, 1000);

  DoDebug('DrawScene - Matrice de Projection');

  // La matrice du modèle
	glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();
  glEnable(GL_LIGHTING);
  glEnable(GL_DEPTH_TEST);
  // On définit le type d'affichage: solide, point ou ligne
  glPolygonMode(GL_FRONT_AND_BACK, PolygonMode);

  DoDebug('DrawScene - ModelView');

  // On effectue une translation
  glTranslatef(0, 0, -500);
  // On effectue une rotation du modèle
	glRotatef(RotatingAxis.X, 1, 0, 0);
  glRotatef(RotatingAxis.Z, 0, 0, 1);
  DoDebug('DrawScene - Placement');

  // On effectue le zoom
  glScalef(ZoomFactor, ZoomFactor, ZoomFactor);
  glCallList(DRAW_AXIS_3D);

  DoDebug('DrawScene - Axe 3D');

  // On centre le modèle sur l'origine en Y
  if (SoR.Count > 0) then
  	begin
		  if (MouseInLeftRect()) then
      	MidHeight := (Max(Profile2D.Max.Y, SoR.Temp2D.Y)
        		         + Min(Profile2D.Min.Y, SoR.Temp2D.Y)) / 2
		  else
  			MidHeight := (Profile2D.Max.Y + Profile2D.Min.Y) / 2;
      glTranslatef(0, - MidHeight, 0);
  end;


	glCallList(DRAW_MODEL3D);
  if (SoR.Count = 1) and (not (Action2D = pma2Insert)) then DrawProfile3D(SoR);
  
  DoDebug('DrawScene - Modèle 3D');

  // On dessine le profil temporaire
  if (MouseInLeftRect()) and (SoR.Count = 0) and (Action2D = pma2Insert) then
    DrawTempProfile3D(SoR);

  DoDebug('DrawScene - DrawProfile3D');
  // On dessine la bande temporaire
  if (MouseInLeftRect()) and (SoR.Count > 0) and (Action2D = pma2Insert) then
  	begin
			DrawTempBand3DArray(SoR);
      DoDebug('DrawScene - DrawBand3D');
    end;

  // On relâche les matrices
  glDisable(GL_LIGHTING);
  glDisable(GL_DEPTH_TEST);

  // On réactive le remplissage plein
  // On définit le type d'affichage: solide, point ou ligne
  glPolygonMode(GL_FRONT_AND_BACK, GL_FILL);
end;

(**
 * Dessine la partie 2D
 **)
procedure TGLPanelsSDR.DrawSceneSpline();
begin
	if (LeftRect.Right <= 0) then exit;

	// Initialisation de la fenêtre
  glViewportRect(LeftRect);

  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrtho(- XMid_2D - ViewDelta, XMid_2D - ViewDelta, - YMid - ViewDelta, YMid - ViewDelta, -1.0, 1.0);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  // On dessine la grille
  glCallList(DRAW_GRID);
  // On dessine le modèle
  glCallList(DRAW_MODEL2D);

  // On dessine le trait de sélection en cours si possible
  if (SoR.Count > 0) and (MouseInLeftRect()) and (Action2D = pma2Insert) then
    begin
		  glColorRGB(MODEL2D_WIRE_COLOR);
      glBegin(GL_LINES);
        glVertex(Profile2D.LastVertex());
        glVertex(SoR.Temp2D);
      glEnd();

      // Et le symétrique
      glColorRGB(MODEL2D_MIRROR_COLOR);
      glBegin(GL_LINES);
        glVertexInvX(Profile2D.LastVertex());
        glVertexInvX(SoR.Temp2D);
      glEnd();
    end;

  // Dessin du point de sélection et du curseur
  if (MouseInLeftRect()) then
  	begin

    	if (Action2D = pma2Insert) then
        begin
		  		glPushMatrix();
	  				glTranslatef(SoR.Temp2D.x, SoR.Temp2D.y, 0);
        		// On dessine le point de sélection courant
		  			glCallList(DRAW_SMALL_SQUARE);
    		  glPopMatrix();
      	end;

      glPushMatrix();
      	// On dessine le curseur à sa vraie position
      	if (IsMouseSplineNegative()) then
        	glTranslatef(- MousePoint.x, MousePoint.y, 0)
        else
	      	glTranslatef(MousePoint.x, MousePoint.y, 0);
  			// On dessine le curseur
			  glCallList(DRAW_CURSOR_2D);
      glPopMatrix();
    end;
end;

(**
 * Dessine le séparateur
 **)
procedure TGLPanelsSDR.DrawSeparator;
var
  SepRect: TRect;
begin
	glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glOrtho(-1.0, 1.0, -1.0, 1.0, -0.1, 0.1);

  SepRect := Separator.getRect(ClientHeight);

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;

  glViewportRect(SepRect);
  glColorRGB(clBlack);
  glRectf(-1.0, -1.0, 1.0, 1.0);

  DecreaseRect(SepRect);

	glViewportRect(SepRect);
  glColorRGB(clSilver);
  glRectf(-1.0, -1.0, 1.0, 1.0);
end;

function TGLPanelsSDR.IsMouseSplineNegative(): Boolean;
var
  MousePos: Types.TPoint;
begin
  GetCursorPos(MousePos);
  MousePos := ScreenToClient(MousePos);
	Result := (MousePos.X < XMid_2D);
end;

procedure TGLPanelsSDR.PanelGLInitGL(Sender: TObject);
begin
 	glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  glEnable(GL_DEPTH_TEST);

  DoDebug('Init - projection');

  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity();

  DoDebug('Init - modelview');

  glShadeModel(GL_SMOOTH);

	glHint(GL_POLYGON_SMOOTH_HINT, GL_NICEST);
  glHint(GL_PERSPECTIVE_CORRECTION_HINT, GL_NICEST);
	glEnable(GL_POLYGON_SMOOTH);

  DoDebug('Init - Shade');

  InitLights();

  DoDebug('Init - Lights');

  BuildFont(DC, 12, 'Courier New');

  DoDebug('Init - Fonts');

  InitAxis3D();
  InitCursor2D();
  InitSquare();
 	InitGrid(XMid_2D, YMid, GRID_SIZE, GRID_COLOR);
	UpdateModel();

  DoDebug('Init - Models');
end;


(**
 * On Appuie sur le bouton dans le panel 2D
 **)
procedure TGLPanelsSDR.PanelGLKey(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key = VK_CONTROL) or (Key = VK_SHIFT) then
    begin
    	if (MouseInLeftRect()) then
        begin
          PanelGLMouseMove2D(Sender, Shift, MousePos.X, MousePos.Y);
          DrawGLScene();
        end;
    end;
end;

procedure TGLPanelsSDR.PanelGLMouseDown2D(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  Index: Integer;
begin
  if (Button = mbLeft) and (MouseInLeftRect()) then
  	begin
    	Action2D := pma2Insert;
      PanelGLMouseMove2D(Sender, Shift, X, Y);
      DrawGLScene();
    end;

  if (Button = mbRight) and (MouseInLeftRect()) then
    begin
    	Index := Profile2D.FindClose(MousePoint);
      if (Index > -1) then
        begin
        	SoR.Delete(Index);
          UpdateModel();
          DrawGLScene();
        end;
    end;
end;

(**
 * On Appuie sur le bouton dans le panel 3D
 **)
procedure TGLPanelsSDR.PanelGLMouseDown3D(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
	// Si la souris n'est pas dans le rectangle 3D, on désactive l'action
	if not (MouseInRightRect()) then
  	begin
	    Action3D := pma3None;
    	exit;
    end;

	case Button of
  	mbLeft:
    	Action3D := pma3Rotate;
    mbRight:
    	Action3D := pma3Zoom;
  end;

	MouseInitial := Point(X, Y);
end;

(**
 * On déplace la souris dans le panel 2D
 **)
procedure TGLPanelsSDR.PanelGLMouseMove2D(Sender: TObject; Shift: TShiftState;
				  X: Integer; Y: Integer);
var
  i: Integer;
  TempPoint: TVertex2f;
begin
	// Si on passe dans le panneau 2D, on désactive les commandes 3D
	Action3D := pma3None;

  // On choisit le curseur (on désactive le curseur pour dessiner le notre)
	Cursor := crNone;
  MousePoint := Vertex2f(Abs(X - XMid_2D), YMid - Y);
  TempPoint := MousePoint;

  if (Action2D = pma2Insert) then
    begin
    	// Touche majuscule enfoncée : on essaie de trouver un point proche !
  		if (ssShift in Shift) and (Profile2D.VertexCapacity > 0) then
    		begin
    			i := Profile2D.FindClose(MousePoint);
      		if (i > -1) then TempPoint := Profile2D.Vertices[i];
    		end;

  		// Touche contrôle,
  		if (ssCtrl in Shift) and (Profile2D.VertexCapacity > 0) then
    		begin
      		TempPoint := FindCloserPoint(Profile2D.LastVertex, MousePoint);
    		end;

      // On génère le profil temporaire
		  SoR.GenerateTemp(TempPoint);
    end;
end;

(**
 * On déplace la souris dans le panel 3D
 **)
procedure TGLPanelsSDR.PanelGLMouseMove3D(Sender: TObject; Shift: TShiftState;
				  X: Integer; Y: Integer);
begin
	Action2D := pma2None;
  Cursor := crSizeAll;
  
  if (Action3D = pma3Rotate) then
    begin
      RotatingAxis.X := RotatingAxis.X + (Y - MouseInitial.Y);
    	RotatingAxis.Z := RotatingAxis.Z - (X - MouseInitial.X);
    end;

  if (Action3D = pma3Zoom) then
    begin
    	ZoomFactor := ZoomFactor + ((X - MouseInitial.X) + (MouseInitial.Y - Y)) / 100;
    end;
    
  if (Action3D <> pma3None) then
  	begin
    	MouseInitial.X := X;
      MouseInitial.Y := Y;
    end;
end;

(**
 * On Relâche le bouton dans le panel 2D
 **)
procedure TGLPanelsSDR.PanelGLMouseUp2D(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
	if (Action2D = pma2Insert) and (Button = mbLeft) then
    begin
		  SoR.Add(SoR.Temp2D);
		  UpdateModel();
      Action2D := pma2None;
    end;
end;

(**
 * On Relâche le bouton dans le panel 3D
 **)
procedure TGLPanelsSDR.PanelGLMouseUp3D(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Action3D = pma3Rotate) and (Button = mbLeft) then
  	Action3D := pma3None;
  if (Action3D = pma3Zoom) and (Button = mbRight) then
  	Action3D := pma3None;
end;

(**
 * On redimensionne le panel 2D
 **)
procedure TGLPanelsSDR.PanelGLMouseWheel2D(Sender: TObject;
  Shift: TShiftState; WheelDelta: Integer; MousePos: Types.TPoint;
  var Handled: Boolean);
begin

end;

procedure TGLPanelsSDR.PanelGLMouseWheel3D(Sender: TObject;
  Shift: TShiftState; WheelDelta: Integer; MousePos: Types.TPoint;
  var Handled: Boolean);
begin
  ZoomFactor := ZoomFactor + WheelDelta / 1000;
  DrawScene();
end;

procedure TGLPanelsSDR.PanelGLResize2D(Sender: TObject);
begin
	XMid_2D := LeftRect.Right / 2;
  YMid := ClientHeight / 2;
  InitGrid(XMid_2D, YMid, GRID_SIZE, GRID_COLOR);
end;

(**
 * On redimensionne le panel 3D
 **)
procedure TGLPanelsSDR.PanelGLResize3D(Sender: TObject);
begin
	XMid_3D := (ClientWidth - RightRect.Left + 1) / 2;
  YMid := ClientHeight / 2;
end;

(**
 * Met à jour le modèle et signale qu'on a besoin de redessiner la scène
 **)
procedure TGLPanelsSDR.UpdateModel();
begin
	InitModel2D(Profile2D);
  InitModel3D(SoR);
end;

end.
