unit UnitModel2D;

interface

uses
	dglOpenGL, UnitOpenGL, Graphics, UnitSquare, StructVertexMemoryStream;

const
	// Couleur modèle fil de fer
  MODEL2D_WIRE_COLOR = TColor($CF6760);       // rgb(96, 103, 207);
  // Couleur modèle mirroir
  MODEL2D_MIRROR_COLOR = clTeal;

var
	DRAW_MODEL2D: Cardinal;

(**
 * Initialise le modèle 2D
 *
 * @param PointList		la liste des points
 **)
procedure InitModel2D(PointList: TVertex2fMemoryStream);

implementation

var
  MirrorVertexMemory: TVertex2fMemoryStream;

procedure InitModel2D(PointList: TVertex2fMemoryStream);
var
	i: Integer;
  NbIndices: Integer;
begin
	if (DRAW_MODEL2D = 0) then DRAW_MODEL2D := glGenLists(1);

	glNewList(DRAW_MODEL2D, GL_COMPILE);

  // On sauvegarde les couleurs et la taille des lignes
  glPushAttrib(GL_COLOR_BUFFER_BIT);
  glPushAttrib(GL_LINE_BIT);

  // S'il y a au moins 2 points, on trace les lignes
  NbIndices := PointList.VertexCapacity;
  if (NbIndices > 1) then
  	begin
    	// On calcule le modèle mirroir
    	MirrorVertexMemory.CopyAndInvert(PointList);
      
		  glEnableClientState(GL_VERTEX_ARRAY);

      // On dessine le modèle
      glColorRGB(MODEL2D_WIRE_COLOR);
		  glVertexPointer(2, GL_FLOAT, 0, PointList.Memory);
		  glDrawArrays(GL_LINE_STRIP, 0, NbIndices);

      // On dessine son mirroir
      glColorRGB(MODEL2D_MIRROR_COLOR);
		  glVertexPointer(2, GL_FLOAT, 0, MirrorVertexMemory.Memory);
		  glDrawArrays(GL_LINE_STRIP, 0, NbIndices);

		  glDisableClientState(GL_VERTEX_ARRAY);
    end;

	// S'il y a au moins un point, on trace les carrés
  if (NbIndices > 0) then
    begin
		  // On dessine les points de sélection
 			for i := 0 to Pred(NbIndices) do
	  		begin
      		glPushMatrix;
   	    		glTranslate(PointList.Vertices[i]);
		    		glCallList(DRAW_SMALL_SQUARE);
      		glPopMatrix;
    		end;
    end;

  // On restaure les lignes et les couleurs
  glPopAttrib();
  glPopAttrib();

  glEndList;
end;

initialization
	DRAW_MODEL2D := 0;
  MirrorVertexMemory := TVertex2fMemoryStream.Create();

finalization
	MirrorVertexMemory.Free();

end.
