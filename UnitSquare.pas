unit UnitSquare;

interface

uses
	dglOpenGL, UnitOpenGL, Graphics;

const
  // Taille des carrés en pixels (* 2)
  SMALL_SQUARE_SIZE : GLFloat = 1.5;

var
  // N° de liste des carrés
	DRAW_SMALL_SQUARE: Cardinal;


procedure InitSquare();

implementation

procedure InitSquare();
var
  i: GLFloat;
begin
  if (DRAW_SMALL_SQUARE = 0) then DRAW_SMALL_SQUARE := glGenLists(1);

	i := SMALL_SQUARE_SIZE;
	glNewList(DRAW_SMALL_SQUARE, GL_COMPILE);
    glPushMatrix;
    glColor3ub(255, 60, 100);
		glBegin(GL_LINE_LOOP);
    	glVertex2f(-i, -i);
      glVertex2f( i, -i);
      glVertex2f( i,  i);
      glVertex2f(-i,  i);
    glEnd;
    glPopMatrix;
  glEndList;
end;

initialization
	DRAW_SMALL_SQUARE := 0;

end.
