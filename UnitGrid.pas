unit UnitGrid;

interface

uses
	dglOpenGL, UnitOpenGL, Graphics;

const
  // Espace de la grille
  GRID_SIZE: GLFloat = 40;
  // Couleur de la grille
  GRID_COLOR: TColor = TColor($8C8C8C);
  // Taille des traits à l'origine
	GRID_AXIS_SIZE: GLFloat = 2;

var
  // N° de liste OpenGL
	DRAW_GRID: Cardinal;

procedure InitGrid(MidX: GLFloat; MidY: GLFloat; Size: GLFloat; Color: TColor);

implementation

(**
 * Dessine la grille
 *
 * @param MidX		la taille en X
 * @param MidY 		la taille en Y
 * @param Size		la taille du maillage de la grille
 * @param	Color		la couleur de la grille
 **)
procedure InitGrid(MidX: GLFloat; MidY: GLFloat; Size: GLFloat; Color: TColor);
var
  i: Integer;
  tmp: GLFloat;
begin
	if (DRAW_GRID = 0) then DRAW_GRID := glGenLists(1);

	glNewList(DRAW_GRID, GL_COMPILE);

	// On sauvegarde les couleurs et la taille des lignes
  glPushAttrib(GL_COLOR_BUFFER_BIT);
  glPushAttrib(GL_LINE_BIT);

  // La couleur
  glColorRGB(Color);

  // Les 2 axes principaux
  glLineWidth(GRID_AXIS_SIZE);
  glBegin(GL_LINES);
  	// Axe vertical
  	glVertex2f(0, -MidY);
    glVertex2f(0,  MidY);
    // Axe horizontal
    glVertex2f(-MidX, 0);
    glVertex2f( MidX, 0);
  glEnd;

  // Les autres lignes
  glLineWidth(1.0);
  glBegin(GL_LINES);
  // Les lignes verticales
 	for i := 0 to Round(MidX / Size) do
    begin
    	tmp := i * Size;
      glVertex2f(  tmp, -MidY);
      glVertex2f(  tmp,  MidY);
      glVertex2f(- tmp, -MidY);
      glVertex2f(- tmp,  MidY);
    end;
    // Les lignes horizontales
    for i := 0 to Round(MidY / Size) do
    begin
    	tmp := i * Size;
      glVertex2f(- MidX,   tmp);
      glVertex2f(  MidX,   tmp);
      glVertex2f(- MidX, - tmp);
      glVertex2f(  MidX, - tmp);
    end;
  glEnd;

  // On restaure les lignes et les couleurs
  glPopAttrib();
  glPopAttrib();

  glEndList();
end;

initialization
	DRAW_GRID := 0;

end.
