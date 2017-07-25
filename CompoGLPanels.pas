unit CompoGLPanels;

interface

uses
  Types, Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ExtCtrls, dglOpenGL, CompoGLPanel, UnitSeparator, UnitMath;

type
  TGLPanels = class(TGLPanel)
  private
  	FSeparator: TSeparator;   				// S�parateur
    FSeparatorPos: Single;						// position du s�parateur, en pourcentage
    FLeftRect: TRect; 								// Rectangle de gauche
    FRightRect: TRect;                // Rectangle de droite
    MovingSep: Boolean;								// En train de bouger le s�parateur

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
  MovingSep := False; // On ne d�place pas le s�parateur
  FSeparator := TSeparator.Create;
  FSeparatorPos := 0.5; // On le place au milieu � la cr�ation
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
  // D�sactiver ces 3 �vennements suffit � d�sactiver les autres OnMouse***{Left/Right}
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
 * On d�place le s�parateur
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
	// Si la valeur d�passe les bornes, on la replace
	if (Pos > Max) then Pos := Max;
  if (Pos < Min) then Pos := Min;
  // On l'attribue au s�parateur
  Separator.Position := Pos;
  // On calcule la position en pourcentage
  FSeparatorPos := Pos / ClientWidth;
  // On met � jour les rectangles de d�limitation
  UpdateRects();
end;

(**
 * On enfonce un bouton de la souris
 *
 * @param Sender	l'objet qui d�clenche l'�vennement
 * @param Button 	le bouton rel�ch�
 * @param Shift		l'�tat des touches maj, ctrl, alt
 * @param X				l'absisse de la souris
 * @param Y				l'ordonn�e de la souris
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

  // Si on est � gauche du panel, on d�clenche l'�vennement
  if (X < Rect.Left) and (Assigned(FOnMouseDownLeft)) then
  	FOnMouseDownLeft(Sender, Button, Shift, X, Y);
    
	// Si on est � droite, on d�clenche l'�vennement de droite
  if (X > Rect.Right) and (Assigned(FOnMouseDownRight)) then
  	FOnMouseDownRight(Sender, Button, Shift, X, Y);  	
end;

(**
 * On d�place la souris
 *
 * @param Sender	l'objet qui d�clenche l'�vennement
 * @param Shift		l'�tat des touches maj, ctrl, alt
 * @param X				l'absisse de la souris
 * @param Y				l'ordonn�e de la souris
 **)
procedure TGLPanels.PanelGLMouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  SepRect: TRect;
begin
	FMousePos := Point(X, Y);

	// En train de d�placer le s�parateur, on ne fait rien d'autre
	if (MovingSep) then
  	begin
    	// On met le curseur du s�parateur
    	Cursor := crSizeWE;
      // On met � jour la position du s�parateur
      MoveSeparator(X);
    end
  // On ne d�place pas le s�parateur
  else
  	begin
    	// On d�termine la zone occup�e par le s�parateur
		  SepRect := Separator.getRect(ClientHeight);
      // Si le curseur est sur le s�parateur, on prend le curseur de s�paration
      if (PointInRect(X, Y, SepRect))
      	then Cursor := crSizeWE;
   		// Si on est � gauche du panel, on d�clenche l'�vennement
  		if (X < SepRect.Left) and (Assigned(FOnMouseMoveLeft)) then
  			FOnMouseMoveLeft(Sender, Shift, X, Y);
			// Si on est � droite, on d�clenche l'�vennement de droite
  		if (X > SepRect.Right) and (Assigned(FOnMouseMoveRight)) then
  			FOnMouseMoveRight(Sender, Shift, X, Y);
  	end;

  DoDebug('PanelGLMouseMove');

 	DrawGLScene();
end;


(**
 * On Rel�che un bouton de la souris
 *
 * @param Sender	l'objet qui d�clenche l'�vennement
 * @param Button 	le bouton rel�ch�
 * @param Shift		l'�tat des touches maj, ctrl, alt
 * @param X				l'absisse de la souris
 * @param Y				l'ordonn�e de la souris
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
    
  // Si on est � gauche du panel, on d�clenche l'�vennement
  if (X < Rect.Left) and (Assigned(FOnMouseUpLeft)) then
  	FOnMouseUpLeft(Sender, Button, Shift, X, Y);
	// Si on est � droite, on d�clenche l'�vennement de droite
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
  // On dessine la sc�ne
  DrawGLScene();
  DoDebug('PanelGLPaint');
end;

(**
 * On redimensionne le Paneau
 * On d�place le s�parateur en pourcentage
 **)
procedure TGLPanels.PanelGLResize(Sender: TObject);
begin
  Separator.Position := Round(SeparatorPos * ClientWidth);
  UpdateRects();
end;


(**
 * Met � jour la position du s�parateur, en pourcentage
 *
 * @param Percent la position, en pourcentage de la largeur
 **)
procedure TGLPanels.SetSeparatorPos(Percent: Single);
begin
  FSeparatorPos := Percent;
	UpdateSeparatorPos();
end;

(**
 * Met � jour les rectangles d�limitant les zones
 **)
procedure TGLPanels.UpdateRects();
var
  SepRect: TRect;
begin
	// Si on n'a pas de handle ou pas de contr�le parent, on sort
	if not ((HandleAllocated) and (HasParent)) then exit;

  // On d�termine le rectangle de s�paration
	SepRect := Separator.getRect(ClientHeight);
  // Le rectangle de gauche
  FLeftRect := Rect(0, 0, SepRect.Left, ClientHeight);
  // Le rectangle de droite
  FRightRect := Rect(SepRect.Right + 1, 0, ClientWidth, ClientHeight);

  // On d�clenche les �vennements si n�cessaire
  if Assigned(fOnResizeLeft) then fOnResizeLeft(Self);
  if Assigned(fOnResizeRight) then fOnResizeRight(Self);
end;

(**
 * Met � jour la position du s�parateur
 * Met � jour les rectangles de d�limitation �galement
 **)
procedure TGLPanels.UpdateSeparatorPos();
begin
	// Si on n'a pas de handle ou pas de contr�le parent, on sort
  if not ((HandleAllocated) and (HasParent)) then exit;
	Separator.Position := Round(SeparatorPos * ClientWidth);
	UpdateRects();
end;


end.
