unit UnitSeparator;

interface

uses
	Types;

type
  TSeparator = class(TObject)
  private
  	FPosition: Integer;   			 // Position du séparateur
    FWidth: Integer; 						 // Largeur du séparateur
		FHalfWidth: Single;   			 // Demi-largeur du séparateur
  protected
    procedure SetPosition(Value: Integer);
    procedure SetWidth(Value: Integer);
  public
  	constructor Create();
    function getRect(ParentHeight: Integer): TRect;
  published
		property HalfWidth: Single read FHalfWidth;
	  property Position: Integer read FPosition write SetPosition;
    property Width: Integer read FWidth write SetWidth;
  end;

implementation

const
  SEP_WIDTH = 5;

{ TSeparator }

(**
 * Constructeur
 **)
constructor TSeparator.Create();
begin
  inherited Create();
  FPosition := 0;
  SetWidth(SEP_WIDTH);
end;


(**
 * Définition de la position 
 **)
function TSeparator.getRect(ParentHeight: Integer): TRect;
var
	Left: Integer;
begin
	Left := Round(Position - HalfWidth);
	Result := Types.Rect(Left
                     , 0
                     , Left + Width
                     , ParentHeight);
end;

procedure TSeparator.SetPosition(Value: Integer);
begin
	FPosition := Value;
end;

(**
 * Définition de la largeur du séparateur
 **)
procedure TSeparator.SetWidth(Value: Integer);
begin
  FWidth := Value;
  FHalfWidth := Width / 2;
end;

end.
