program sdr3;

uses
  Forms,
  UnitMain in 'UnitMain.pas' {FormMain},
  UnitOpenGL in 'UnitOpenGL.pas',
  UnitGrid in 'UnitGrid.pas',
  UnitSquare in 'UnitSquare.pas',
  UnitModel2D in 'UnitModel2D.pas',
  CompoGLPanel in 'CompoGLPanel.pas',
  UnitModel3D in 'UnitModel3D.pas',
  StructSurfaceOfRevolution in 'StructSurfaceOfRevolution.pas',
  UnitMath in 'UnitMath.pas',
  CompoGLPanels in 'CompoGLPanels.pas',
  UnitSeparator in 'UnitSeparator.pas',
  CompoGLPanelsSDR in 'CompoGLPanelsSDR.pas',
  UnitLights in 'UnitLights.pas',
  UnitCodeProfiler in 'UnitCodeProfiler.pas',
  UnitFont in 'UnitFont.pas',
  UnitCursor in 'UnitCursor.pas',
  UnitAxis in 'UnitAxis.pas',
  StructPoints in 'StructPoints.pas',
  StructLinkedList in 'StructLinkedList.pas',
  StructVertexMemoryStream in 'StructVertexMemoryStream.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TFormMain, FormMain);
  Application.Run;
end.
