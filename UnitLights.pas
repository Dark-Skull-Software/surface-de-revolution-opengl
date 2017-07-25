unit UnitLights;

interface

uses
	dglOpenGL, UnitOpenGL;

procedure InitLights();

implementation

procedure InitLights();
var
	lightspecular: TGLLightDesc;
  lightambiant: TGLLightDesc;
  lightdiffuse: TGLLightDesc;
  lightposition1: TGLLightPlace;
  lightdirection1: TGLPosition;
  lightposition2: TGLLightPlace;
  lightdirection2: TGLPosition;
  lightposition3: TGLLightPlace;
  lightdirection3: TGLPosition;
begin
  // Paramètres des lumières
  lightspecular := glLightDesc(0.0, 0.0, 0.0, 1.0);
  lightambiant :=  glLightDesc(0.1, 0.1, 0.1, 1.0);
  lightdiffuse :=  glLightDesc(0.8, 0.8, 0.8, 1.0);

  lightposition1 := glLightPlace( 500.0,  -500.0,   0.0, 1.0);
  lightposition2 := glLightPlace(-500.0,   500.0,   0.0, 1.0);
  lightposition3 := glLightPlace(   0.0,   0.0,   500.0, 1.0);

  lightdirection1 := glPosition(-500.0,    0.0, 0.0);
  lightdirection2 := glPosition( 500.0,    0.0, 0.0);
  lightdirection3 := glPosition(   0.0,    0.0, -500.0);


  // Lumière
  glEnable(GL_LIGHTING);

  // Lumière 0 désactivée
  glDisable(GL_LIGHT0);

  glPushMatrix();
  glTranslatef(0, 0, -500);

  // Lumière1
  glLightfv(GL_LIGHT1, GL_SPECULAR, @lightspecular);
  glLightfv(GL_LIGHT1, GL_AMBIENT,  @lightambiant);
  glLightfv(GL_LIGHT1, GL_DIFFUSE,  @lightdiffuse);
  glLightfv(GL_LIGHT1, GL_POSITION, @lightposition1);
  glLightfv(GL_LIGHT1, GL_SPOT_DIRECTION, @lightdirection1);
  glLighti(GL_LIGHT1, GL_SPOT_EXPONENT, 30);
  glLighti(GL_LIGHT1, GL_SPOT_CUTOFF, 180);
  glLightf(GL_LIGHT1, GL_CONSTANT_ATTENUATION, 0.9);
  glLightf(GL_LIGHT1, GL_QUADRATIC_ATTENUATION, 0);
  glLightf(GL_LIGHT1, GL_LINEAR_ATTENUATION, 0);
  glEnable(GL_LIGHT1);

  glLightfv(GL_LIGHT2, GL_SPECULAR, @lightspecular);
  glLightfv(GL_LIGHT2, GL_AMBIENT,  @lightambiant);
  glLightfv(GL_LIGHT2, GL_DIFFUSE,  @lightdiffuse);
  glLightfv(GL_LIGHT2, GL_POSITION, @lightposition2);
  glLightfv(GL_LIGHT2, GL_SPOT_DIRECTION, @lightdirection2);
  glLighti(GL_LIGHT2, GL_SPOT_EXPONENT, 30);
  glLighti(GL_LIGHT2, GL_SPOT_CUTOFF, 180);
  glLightf(GL_LIGHT2, GL_CONSTANT_ATTENUATION, 0.9);
  glLightf(GL_LIGHT2, GL_QUADRATIC_ATTENUATION, 0);
  glLightf(GL_LIGHT2, GL_LINEAR_ATTENUATION, 0);
  glEnable(GL_LIGHT2);

  glLightfv(GL_LIGHT3, GL_SPECULAR, @lightspecular);
  glLightfv(GL_LIGHT3, GL_AMBIENT,  @lightambiant);
  glLightfv(GL_LIGHT3, GL_DIFFUSE,  @lightdiffuse);
  glLightfv(GL_LIGHT3, GL_POSITION, @lightposition3);
  glLightfv(GL_LIGHT3, GL_SPOT_DIRECTION, @lightdirection3);
  glLighti(GL_LIGHT3, GL_SPOT_EXPONENT, 30);
  glLighti(GL_LIGHT3, GL_SPOT_CUTOFF, 180);
  glLightf(GL_LIGHT3, GL_CONSTANT_ATTENUATION, 0.9);
  glLightf(GL_LIGHT3, GL_QUADRATIC_ATTENUATION, 0);
  glLightf(GL_LIGHT3, GL_LINEAR_ATTENUATION, 0);
  glEnable(GL_LIGHT3);

	glPopMatrix();

  glDisable(GL_LIGHTING);
end;

end.
