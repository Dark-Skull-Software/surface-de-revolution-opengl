unit UnitFont;

interface

uses
	Graphics, Windows, dglOpenGL, UnitOpenGL;

var
	FontBase: GLuint;

  
procedure BuildFont(DC: HDC; Size: Integer; FontName: String);
procedure KillFont();
procedure glPrint(Text: String; X, Y, Z: GLint; Color: TColor);

implementation

(**
 * Construit la police
 **)
procedure BuildFont(DC: HDC; Size: Integer; FontName: String);
var
	Font: HFONT;
begin
  FontBase := glGenLists(256);
  Font := CreateFont(Size,
                     0,
                     0,
                     0,
                     FW_NORMAL,
                     0,
                     0,
                     0,
                     ANSI_CHARSET,
                     OUT_TT_PRECIS,
                     CLIP_DEFAULT_PRECIS,
                     ANTIALIASED_QUALITY,
                     FF_DONTCARE or DEFAULT_PITCH,
                     Pchar(FontName));
  SelectObject(DC, Font);
  wglUseFontBitmaps(DC, 0, 255, FontBase);
end;

(**
 * Libère la police
 **)
procedure KillFont();
begin
  glDeleteLists(FontBase, 96);
end;

(**
 * Dessine du texte
 **)
procedure glPrint(Text: String; X, Y, Z: GLint; Color: TColor);
begin
  if (Text = '') then exit;
  glPushAttrib(GL_LIST_BIT);
  glColorRGB(Color);
  glRasterPos3i(X, Y, Z);
  glListBase(FontBase);
  glCallLists(length(Text), GL_UNSIGNED_BYTE, PChar(Text));
  glPopAttrib();
end;

end.
