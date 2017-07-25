unit UnitAxis;

interface

uses
  Graphics, dglOpengL, UnitOpenGL, UnitFont;

var
  DRAW_AXIS_3D: Integer;

procedure InitAxis3D();

implementation

const
	AXIS_COLOR:    TColor  = clLime;
  AXIS_LENGTH:   Integer = 100;
  AXIS_TEXT_POS: Integer = 120;

(**
 * Création d'un axe 3D
 **)
procedure InitAxis3D();
var
  I: Integer;
begin
	if (DRAW_AXIS_3D = 0) then DRAW_AXIS_3D := glGenLists(1);

  glNewList(DRAW_AXIS_3D, GL_COMPILE);

	glDisable(GL_LIGHTING);

  I := AXIS_LENGTH;
  glColorRGB(AXIS_COLOR);
  glBegin(GL_LINES);
    glVertex3i(0, 0, 0); glVertex3i(I, 0, 0);
    glVertex3i(0, 0, 0); glVertex3i(0, I, 0);
    glVertex3i(0, 0, 0); glVertex3i(0, 0, I);
  glEnd();

  I := AXIS_TEXT_POS;
  glPrint('X', I, 0, 0, AXIS_COLOR);
  glPrint('Y', 0, I, 0, AXIS_COLOR);
  glPrint('Z', 0, 0, I, AXIS_COLOR);

  glEnable(GL_LIGHTING);

  glEndList();
end;

initialization
	DRAW_AXIS_3D := 0;

end.
