unit UnitModel3D;

interface

uses
  Graphics, Math, dglOpenGL, UnitOpenGL, UnitSquare, UnitModel2D,
  StructPoints, StructVertexMemoryStream, StructSurfaceOfRevolution;

const
	MODEL3D_EMISSION_COLOR = TColor($200100);

var
	DRAW_MODEL3D:    Cardinal;
  MODEL3D_AMBIANT: TGLLightDesc;
  MODEL3D_DIFFUSE: TGLLightDesc;

procedure InitModel3D(SoR: TSurfaceOfRevolution);
procedure DrawProfile3D(SoR: TSurfaceOfRevolution);
procedure DrawTempProfile3D(SoR: TSurfaceOfRevolution);
procedure DrawTempBand3DArray(SoR: TSurfaceOfRevolution);

implementation

var
  // Mémoire de stockage pour les vertices
  VertexMemory: TVertex3fMemoryStream;
  NormalMemory: TNormal3fMemoryStream;

  
(**
 * Initialise le modèle 2D
 *
 * @param PointList		la liste des points
 **)
procedure InitModel3D(SoR: TSurfaceOfRevolution);
var
  point, slice: Integer;
  PointA, PointB, PointC: TVertex3f;
	Normal: TNormal3f;
begin
	// On génère le n° de liste si ce n'est pas déjà fait
  if (DRAW_MODEL3D = 0) then DRAW_MODEL3D := glGenLists(1);

  // On commence la liste
  glNewList(DRAW_MODEL3D, GL_COMPILE);

  // On définit les matériaux
  glMaterialfv(GL_FRONT_AND_BACK, GL_AMBIENT, @MODEL3D_AMBIANT);
  glMaterialfv(GL_FRONT_AND_BACK, GL_DIFFUSE, @MODEL3D_DIFFUSE);

//  glEnable(GL_NORMALIZE);
	glEnable(GL_RESCALE_NORMAL);

//  for point := 1 to Pred(SoR.List2D.Count) do
	for point := 1 to Pred(SoR.Count) do
  	begin
      glBegin(GL_QUAD_STRIP);
  	  for slice := 0 to SoR.SliceCount do
    		begin
        	PointB := SoR.Points3D[slice mod SoR.SliceCount, point];
    		  PointA := SoR.Points3D[slice mod SoR.SliceCount, point - 1];
        	PointC := SoR.Points3D[(slice + 1) mod SoR.SliceCount, point];
					Normal := VectProd(PointA, PointB, PointC);
          Normalize(Normal);

      		glNormal3f(Normal.x, Normal.y, Normal.z);
          glVertex(PointB);
          glVertex(PointA);
    	  end;
      glEnd();
    end;

//  glDisable(GL_NORMALIZE);
	glDisable(GL_RESCALE_NORMAL);

  glEndList();
end;


(**
 * On dessine le profil
 *
 * @param SoR la matrice des points
 **)
procedure DrawProfile3D(SoR: TSurfaceOfRevolution);
var
  slice: Integer;
  polygonmode: GLenum;
  mode: GLenum;
begin
	// On récupère le mode
	glGetIntegerv(GL_POLYGON_MODE, @polygonmode);
  // En fonction du mode, on dessine soit des points soit des lignes
  mode := IfThen(polygonmode = GL_POINT, GL_POINTS, GL_LINE_LOOP);

  // On débute le tracé
	glBegin(mode);
	for slice := 0 to pred(SoR.SliceCount) do
    begin
 	  	glVertex(SoR.Points3D[slice, 0]);
   	end;
  glEnd();
end;

(**
 * On dessine le profil temporaire
 *
 * @param SoR la matrice des points
 **)
procedure DrawTempProfile3D(SoR: TSurfaceOfRevolution);
var
//  slice: Integer;
  Point3D: TVertex3f;
  polygonmode: GLenum;
  mode: GLenum;
begin
	if (SoR.SliceCount = 0) then exit;

	// On récupère le mode
	glGetIntegerv(GL_POLYGON_MODE, @polygonmode);
  // En fonction du mode, on dessine soit des points soit des lignes
  mode := IfThen(polygonmode = GL_POINT, GL_POINTS, GL_LINE_LOOP);

  // On débute le tracé
(*	glBegin(mode);
	for slice := 0 to pred(SoR.SliceCount) do
    begin
    	Point3D := SoR.Temp3D.Vertices[slice];
      Point3D.y := 0;
    	glVertex(Point3D);
   	end;
  glEnd();*)

  Point3D := SoR.Temp3D.Vertices[0];

  glPushMatrix();
  glTranslatef(0, -Point3D.y, 0);

  glEnableClientState(GL_VERTEX_ARRAY);
  glVertexPointer(3, GL_FLOAT, 0, SoR.Temp3D.Memory);
  glDrawArrays(mode, 0, SoR.SliceCount);
  glDisableClientState(GL_VERTEX_ARRAY);

  glPopMatrix();
end;

(**
 * On dessine la bande temporaire
 *
 * @param SoR la matrice des points
 **)
procedure DrawTempBand3DArray(SoR: TSurfaceOfRevolution);
var
	slice: Integer;
  index: Integer;
  NbIndices: Integer;
  PointA, PointB, PointC: TVertex3f;
	Normal: TNormal3f;
begin
	// On calcule le nombre d'indices à générer ("x shl 1" = "x * 2")
  NbIndices := (SoR.SliceCount + 1) shl 1;
  VertexMemory.VertexCapacity := NbIndices;
  NormalMemory.VertexCapacity := NbIndices;

  // On construit le tableau
  for slice := 0 to SoR.SliceCount do
    begin
    	// On calcule la normale
      PointB := SoR.Temp3D.Vertices[slice mod SoR.SliceCount];
 		  PointA := SoR.Points3D[slice mod SoR.SliceCount, Pred(SoR.Count)];
     	PointC := SoR.Points3D[(slice + 1) mod SoR.SliceCount, Pred(SoR.Count)];
      Normal := VectProd(PointA, PointB, PointC);
      Normalize(Normal);

      // On place les points
      index := slice shl 1;
      VertexMemory.Vertices[index] := PointB;
      NormalMemory.Vertices[index] := Normal;
      inc(index);
      VertexMemory.Vertices[index] := PointA;
      NormalMemory.Vertices[index] := Normal;
    end;

	// On autorise le calcul des normales
// 	glEnable(GL_NORMALIZE);
	glEnable(GL_RESCALE_NORMAL);

  // On dessine le tout
  glEnableClientState(GL_NORMAL_ARRAY);
  glEnableClientState(GL_VERTEX_ARRAY);
  glVertexPointer(3, GL_FLOAT, 0, VertexMemory.Memory);
  glNormalPointer(   GL_FLOAT, 0, NormalMemory.Memory);
  glDrawArrays(GL_QUAD_STRIP, 0, NbIndices);
  glDisableClientState(GL_VERTEX_ARRAY);
  glDisableClientState(GL_NORMAL_ARRAY);

  // On désactive le calcul des normales
//  glDisable(GL_NORMALIZE);
	glDisable(GL_RESCALE_NORMAL);
end;


initialization
  VertexMemory := TVertex3fMemoryStream.Create();
  NormalMemory := TNormal3fMemoryStream.Create();
  DRAW_MODEL3D    := 0;
	MODEL3D_AMBIANT := glLightDesc(MODEL2D_WIRE_COLOR, 1.0);
  MODEL3D_DIFFUSE := glLightDesc(MODEL2D_WIRE_COLOR, 1.0);

finalization
  NormalMemory.Free();
  VertexMemory.Free();

end.
