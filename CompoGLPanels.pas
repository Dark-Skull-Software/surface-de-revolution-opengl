unit CompoGLPanels;

interface

uses
  Types, Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, dglOpenGL, CompoGLPanel, UnitSeparator, UnitMath;

type
  TGLPanels = class(TGLPanel)
  private
  	FSeparator: TSeparator;   				// Séparateur
    FSeparatorPos: Single;						// position du séparateur, en pourcentage
    FLeftRect: TRect; 								// Rectangle de gauche
    FRightRect: TRect;                // Rectangle de droite
    MovingSep: Boolean;								// En train de bouger le séparateur

    FOnMouseMoveLeft: TMouseMoveEvent;
    FOnMouseMoveRight: TMouseMoveEvent;
    FOnMouseDownLeft: TMouseEvent;
    FOnMouseDownRight: TMouseEvent;
    FOnMouseUpLeft: TMouseEvent;
    FOnMouseUpRight: TMouseEvent;
    FOnResizeRight: TNotifyEvent;
    FOnResizeLeft: TNotifyEvent;
    FOnMouseWheelRight: TMouseWheelEvent;
    FOnMouseWheelLeft: TMouseWheelEvent;
  protected
	  FMousePos: TPoint;  				// La position de la souris
  	procedure SetSeparatorPos(Percent: Single);

  	procedure PanelGLPaint(Sender: TObject);
    procedure PanelGLResize(Sender: TObject);
    procedure PanelGLMouseDown(Sender: TObject; Button: TMouseButton;
    					Shift: TShiftState; X, Y: Integer);
    procedure PanelGLMouseUp(Sender: TObject; Button: TMouseButton;
    					Shift: TShiftState; X, Y: Integer);
    procedure PanelGLMouseMove(Sender: TObject; Shift: TShiftState;
					    X, Y: Integer);
    procedure PanelGLMouseWheel(Sender: TObject; Shift: TShiftState;
	    WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure DrawGLScene(); virtual; abstract;
  public
  	constructor Create(AOwner : TComponent); override;
    destructor Destroy(); override;
    procedure MoveSeparator(Pos: Integer);
    procedure UpdateSeparatorPos();
    procedure UpdateRects();

    function MouseInLeftRect(): Boolean;
    function MouseInRightRect(): Boolean;
  published
    property Separator: TSeparator read FSeparator;
    property SeparatorPos: Single read FSeparatorPos write SetSeparatorPos;
    property LeftRect: TRect read FLeftRect;
    property RightRect: TRect read FRightRect;
    property MousePos: TPoint read FMousePos;

    property OnMouseMoveLeft: TMouseMoveEvent read FOnMouseMoveLeft write FOnMouseMoveLeft;
    property OnMouseMoveRight: TMouseMoveEvent read FOnMouseMoveRight write FOnMouseMoveRight;
    property OnMouseDownLeft: TMouseEvent read FOnMouseDownLeft write FOnMouseDownLeft;
    property OnMouseDownRight: TMouseEvent read FOnMouseDownRight write FOnMouseDownRight;
    property OnMouseUpLeft: TMouseEvent read FOnMouseUpLeft write FOnMouseUpLeft;
    property OnMouseUpRight: TMouseEvent read FOnMouseUpRight write FOnMouseUpRight;
    property OnResizeLeft: TNotifyEvent read fOnResizeLeft write fOnResizeLeft;
    property OnResizeRight:	TNotifyEvent read fOnResizeRight write fOnResizeRight;
    property OnMouseWheelLeft: TMouseWheelEvent read FOnMouseWheelLeft write FOnMouseWheelLeft;
    property OnMouseWheelRight: TMouseWheelEvent read FOnMouseWheelRight write FOnMouseWheelRight;
  end;

implementation

{ TGLPanels }

(**
 * Constructor
 **)
constructor TGLPanels.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  MovingSep := False; // On ne déplace pas le séparateur
  FSeparator := TSeparator.Create;
  FSeparatorPos := 0.5; // On le place au milieu à la création
  OnPaint := PanelGLPaint;
  OnResize := PanelGLResize;
  OnMouseDown := PanelGLMouseDown;
  OnMouseUp := PanelGLMouseUp;
  OnMouseMove := PanelGLMouseMove;
  OnMouseWheel := PanelGLMouseWheel;
end;

(**
 * Destructeur
 **)
destructor TGLPanels.Destroy;
begin
	MovingSep := False;
	OnPaint := nil;
  OnResize := nil;
  // Désactiver ces 3 évennements suffit à désactiver les autres OnMouse***{Left/Right}
  OnMouseDown := nil;
  OnMouseUp := nil;
  OnMouseMove := nil;
  FSeparator.Free;
  inherited Destroy;
end;


(**
 * Regarde si la souris est dans le rectangle de gauche
 **)
function TGLPanels.MouseInLeftRect: Boolean;
begin
  Result := (MouseInside) and PointInRect(FMousePos, LeftRect);
end;

(**
 * Regarde si la souris est dans le rectangle de droite
 **)
function TGLPanels.MouseInRightRect: Boolean;
begin
  Result := (MouseInside) and PointInRect(FMousePos, RightRect);
end;

(**
 * On déplace le séparateur
 *
 * @param Pos la position voulue
 **)
procedure TGLPanels.MoveSeparator(Pos: Integer);
var
	Min: Integer;
	Max: Integer;
begin
	// On calcule les positions Maximale et Minimale
	Max := Round(ClientWidth - Separator.HalfWidth);
  Min := Round(Separator.Width - Separator.HalfWidth);
	// Si la valeur dépasse les bornes, on la replace
	if (Pos > Max) then Pos := Max;
  if (Pos < Min) then Pos := Min;
  // On l'attribue au séparateur
  Separator.Position := Pos;
  // On calcule la position en pourcentage
  FSeparatorPos := Pos / ClientWidth;
  // On met à jour les rectangles de délimitation
  UpdateRects();
end;

(**
 * On enfonce un bouton de la souris
 *
 * @param Sender	l'objet qui déclenche l'évennement
 * @param Button 	le bouton relâché
 * @param Shift		l'état des touches maj, ctrl, alt
 * @param X				l'absisse de la souris
 * @param Y				l'ordonnée de la souris
 **)
procedure TGLPanels.PanelGLMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Rect: TRect;
begin
  Rect := Separator.getRect(ClientHeight);
	if (PointInRect(X, Y, Rect)) and (Button = mbLeft) then
  	begin
      MovingSep := True;
    	exit;
    end;

  // Si on est à gauche du panel, on déclenche l'évennement
  if (X < Rect.Left) and (Assigned(FOnMouseDownLeft)) then
  	FOnMouseDownLeft(Sender, Button, Shift, X, Y);
    
	// Si on est à droite, on déclenche l'évennement de droite
  if (X > Rect.Right) and (Assigned(FOnMouseDownRight)) then
  	FOnMouseDownRight(Sender, Button, Shift, X, Y);  	
end;

(**
 * On déplace la souris
 *
 * @param Sender	l'objet qui déclenche l'évennement
 * @param Shift		l'état des touches maj, ctrl, alt
 * @param X				l'absisse de la souris
 * @param Y				l'ordonnée de la souris
 **)
procedure TGLPanels.PanelGLMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  SepRect: TRect;
begin
	FMousePos := Point(X, Y);

	// En train de déplacer le séparateur, on ne fait rien d'autre
	if (MovingSep) then
  	begin
    	// On met le curseur du séparateur
    	Cursor := crSizeWE;
      // On met à jour la position du séparateur
      MoveSeparator(X);
    end
  // On ne déplace pas le séparateur
  else
  	begin
    	// On détermine la zone occupée par le séparateur
		  SepRect := Separator.getRect(ClientHeight);
      // Si le curseur est sur le séparateur, on prend le curseur de séparation
      if (PointInRect(X, Y, SepRect))
      	then Cursor := crSizeWE;
   		// Si on est à gauche du panel, on déclenche l'évennement
  		if (X < SepRect.Left) and (Assigned(FOnMouseMoveLeft)) then
  			FOnMouseMoveLeft(Sender, Shift, X, Y);
			// Si on est à droite, on déclenche l'évennement de droite
  		if (X > SepRect.Right) and (Assigned(FOnMouseMoveRight)) then
  			FOnMouseMoveRight(Sender, Shift, X, Y);
  	end;

  DoDebug('PanelGLMouseMove');

 	DrawGLScene();
end;


(**
 * On Relâche un bouton de la souris
 *
 * @param Sender	l'objet qui déclenche l'évennement
 * @param Button 	le bouton relâché
 * @param Shift		l'état des touches maj, ctrl, alt
 * @param X				l'absisse de la souris
 * @param Y				l'ordonnée de la souris
 **)
procedure TGLPanels.PanelGLMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
var
  Rect: TRect;
begin
  Rect := Separator.getRect(ClientHeight);
  if (MovingSep) and (Button = mbLeft) then
  	begin
	    MovingSep := False;
      exit;
    end;
    
  // Si on est à gauche du panel, on déclenche l'évennement
  if (X < Rect.Left) and (Assigned(FOnMouseUpLeft)) then
  	FOnMouseUpLeft(Sender, Button, Shift, X, Y);
	// Si on est à droite, on déclenche l'évennement de droite
  if (X > Rect.Right) and (Assigned(FOnMouseUpRight)) then
  	FOnMouseUpRight(Sender, Button, Shift, X, Y);
end;

procedure TGLPanels.PanelGLMouseWheel(Sender: TObject; Shift: TShiftState;
  WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  Rect: TRect;
begin
	Handled := true;
  Rect := Separator.getRect(ClientHeight);

  if (MousePos.X < Rect.Left) and (Assigned(FOnMouseWheelLeft)) then
  	FOnMouseWheelLeft(Sender, Shift, WheelDelta, MousePos, Handled);
	if (MousePos.X > Rect.Right) and (Assigned(FOnMouseWheelRight)) then
  	FOnMouseWheelRight(Sender, Shift, WheelDelta, MousePos, Handled);
end;

procedure TGLPanels.PanelGLPaint(Sender: TObject);
begin
  // On dessine la scène
  DrawGLScene();
  DoDebug('PanelGLPaint');
end;

(**
 * On redimensionne le Paneau
 * On déplace le séparateur en pourcentage
 **)
procedure TGLPanels.PanelGLResize(Sender: TObject);
begin
  Separator.Position := Round(SeparatorPos * ClientWidth);
  UpdateRects();
end;


(**
 * Met à jour la position du séparateur, en pourcentage
 *
 * @param Percent la position, en pourcentage de la largeur
 **)
procedure TGLPanels.SetSeparatorPos(Percent: Single);
begin
  FSeparatorPos := Percent;
	UpdateSeparatorPos();
end;

(**
 * Met à jour les rectangles délimitant les zones
 **)
procedure TGLPanels.UpdateRects();
var
  SepRect: TRect;
begin
	// Si on n'a pas de handle ou pas de contrôle parent, on sort
	if not ((HandleAllocated) and (HasParent)) then exit;

  // On détermine le rectangle de séparation
	SepRect := Separator.getRect(ClientHeight);
  // Le rectangle de gauche
  FLeftRect := Rect(0, 0, SepRect.Left, ClientHeight);
  // Le rectangle de droite
  FRightRect := Rect(SepRect.Right + 1, 0, ClientWidth, ClientHeight);

  // On déclenche les évennements si nécessaire
  if Assigned(fOnResizeLeft) then fOnResizeLeft(Self);
  if Assigned(fOnResizeRight) then fOnResizeRight(Self);
end;

(**
 * Met à jour la position du séparateur
 * Met à jour les rectangles de délimitation également
 **)
procedure TGLPanels.UpdateSeparatorPos();
begin
	// Si on n'a pas de handle ou pas de contrôle parent, on sort
  if not ((HandleAllocated) and (HasParent)) then exit;
	Separator.Position := Round(SeparatorPos * ClientWidth);
	UpdateRects();
end;


end.
