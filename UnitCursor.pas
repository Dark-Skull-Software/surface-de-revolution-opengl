unit UnitCursor;

interface

uses
	Graphics, dglOpenGL, UnitOpenGL;

var
  DRAW_CURSOR_2D: Integer;

procedure InitCursor2D();

implementation

const
	// Couleur du curseur
  CURSOR_COLOR: TColor =	clLime;

(**
 * Initialise le curseur 2D
 **)
procedure InitCursor2D();
begin
 	if (DRAW_CURSOR_2D = 0) then DRAW_CURSOR_2D := glGenLists(1);

  glNewList(DRAW_CURSOR_2D, GL_COMPILE);
  glEnable(GL_LINE_STIPPLE);
  glPushAttrib(GL_LINE_BIT);

  glColorRGB(CURSOR_COLOR);
  glLineStipple(1, 52275);

  glBegin(GL_LINES);
		glVertex2i(-8,   0);
  	glVertex2i( 8,   0);
	  glVertex2i(  0, -8);
  	glVertex2i(  0,  8);
  glEnd();

  glPopAttrib();
  glDisable(GL_LINE_STIPPLE);
  glEndList();
end;

initialization
	DRAW_CURSOR_2D := 0;

end.
