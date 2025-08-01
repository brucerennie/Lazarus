unit TestLFMTrees;

{$i runtestscodetools.inc}

interface

uses
  Classes, SysUtils, CodeToolManager, CodeCache, LFMTrees,
  LazLogger, fpcunit, testregistry, TestGlobals;

type

  { TCustomTestLFMTrees }

  TCustomTestLFMTrees = class(TTestCase)
  private
    FControlsCode: TCodeBuffer;
    FLFMCode: TCodeBuffer;
    FUnitCode: TCodeBuffer;
    FSources: TFPList; // list of TCodeBuffer
    procedure CodeToolBossFindDefineProperty(Sender: TObject; const PersistentClassName,
      AncestorClassName, Identifier: string; var IsDefined: boolean);
    function GetSourceCount: integer;
    function GetSources(Index: integer): TCodeBuffer;
  protected
    procedure SetUp; override;
    procedure TearDown; override;
    function AddControls(const aFilename: string = 'controls.pas'; AddCollection: boolean = false): TCodeBuffer;
    function AddFormUnit(const Fields: array of string;
      const aFormClass: string = 'TForm';
      const aFilename: string = 'unit1.pas'): TCodeBuffer;
    function AddSource(aFilename, aSource: string): TCodeBuffer;
  public
    constructor Create; override;
    destructor Destroy; override;
    procedure CheckLFM;
    procedure CheckLFMExpectedError(ErrorType: TLFMErrorType; const CursorPos: TCodeXYPosition; ErrorMsg: string);
    procedure ParseLFM;
    procedure WriteSource(const CursorPos: TCodeXYPosition);
    property SourceCount: integer read GetSourceCount;
    property Sources[Index: integer]: TCodeBuffer read GetSources;
    property ControlsCode: TCodeBuffer read FControlsCode;
    property UnitCode: TCodeBuffer read FUnitCode;
    property LFMCode: TCodeBuffer read FLFMCode;
  end;

  { TTestLFMTrees }

  TTestLFMTrees = class(TCustomTestLFMTrees)
  published
    procedure LFMEmptyForm;
    procedure LFMChildComponent;
    procedure LFMUnitname;
    procedure LFM_RootUnitnameWrong;
    procedure LFM_ChildUnitnameWrong;
    procedure LFM_BinaryData;
    procedure LFM_Set;
    procedure LFM_List;
    procedure LFM_Collection;

    // unicode
    procedure LFMParseUnicode; // todo
  end;

implementation

{ TCustomTestLFMTrees }

function TCustomTestLFMTrees.GetSourceCount: integer;
begin
  Result:=FSources.Count;
end;

procedure TCustomTestLFMTrees.CodeToolBossFindDefineProperty(Sender: TObject;
  const PersistentClassName, AncestorClassName, Identifier: string; var IsDefined: boolean);
begin
  if AncestorClassName='' then ;
  if SameText(PersistentClassName,'TStrings') then begin
    if SameText(Identifier,'Strings') then
      IsDefined:=true;
  end;
  if not IsDefined then
    debugln(['TCustomTestLFMTrees.CodeToolBossFindDefineProperty PersistentClassName="',PersistentClassName,'" Identifier="',Identifier,'"']);
end;

function TCustomTestLFMTrees.GetSources(Index: integer): TCodeBuffer;
begin
  Result:=TCodeBuffer(FSources[Index]);
end;

procedure TCustomTestLFMTrees.SetUp;
begin
  inherited SetUp;
  CodeToolBoss.OnFindDefineProperty:=@CodeToolBossFindDefineProperty;
end;

procedure TCustomTestLFMTrees.TearDown;
var
  i: Integer;
  Buf: TCodeBuffer;
begin
  for i:=0 to FSources.Count-1 do begin
    Buf:=Sources[i];
    Buf.IsDeleted:=true;
    Buf.Source:='';
  end;
  FControlsCode:=nil;
  FUnitCode:=nil;
  FLFMCode:=nil;
  inherited TearDown;
end;

function TCustomTestLFMTrees.AddControls(const aFilename: string; AddCollection: boolean
  ): TCodeBuffer;
var
  Src: String;
begin
  Src:=LinesToStr([
    'unit Controls;',
    '{$mode objfpc}{$H+}',
    'interface',
    'uses Classes;',
    'type',
    '  TCaption = type string;',
    '  TAction = class(TComponent)',
    '  published',
    '    property OnExecute: TNotifyEvent;',
    '  end;',
    '',
    '  TControl = class(TComponent)',
    '  published',
    '    property Caption: TCaption;',
    '    property Left: integer;',
    '    property Top: integer;',
    '    property OnClick: TNotifyEvent;',
    '  end;',
    '',
    '  TBitmap = class(TPersistent)',
    '  end;',
    '  TButton = class(TControl)',
    '  published',
    '    property Default: Boolean;',
    '    property Glyph: TBitmap;',
    '    property Lines: TStrings;',
    '  end;',
    '',
    '  TFormStyle = (fsNormal, fsMDIChild, fsMDIForm, fsStayOnTop, fsSplash, fsSystemStayOnTop);',
    '  TFormStyles = set of TFormStyle;',
    '  TForm = class(TControl)',
    '  published',
    '    property FormStyle: TFormStyle;',
    '    property Styles: TFormStyles;',
    '  end;',
    '']);
  if AddCollection then begin
    Src:=Src+LinesToStr([
    '  TColumn = class(TCollectionItem)',
    '  published',
    '    published Width: integer;',
    '  end;',
    '  TColumns = class(TCollection)',
    '  end;',
    '  TGrid = class(TControl)',
    '  published',
    '    property Columns: TColumns;',
    '  end;',
    '']);
  end;
  Src:=Src+LinesToStr([
    'implementation',
    'end.'
    ]);
  FControlsCode:=AddSource(aFilename,Src);
  Result:=FControlsCode;
end;

function TCustomTestLFMTrees.AddFormUnit(const Fields: array of string;
  const aFormClass: string; const aFilename: string): TCodeBuffer;
var
  Src: String;
  i: Integer;
begin
  Src:='';
  for i:=low(Fields) to high(Fields) do begin
    Src:=Src+'    '+Fields[i]+';'+sLineBreak;
  end;
  FUnitCode:=AddSource(aFilename,LinesToStr([
    'unit Unit1;',
    '{$mode objfpc}{$H+}',
    'interface',
    'uses Controls;',
    'type',
    '  '+aFormClass+'1 = class('+aFormClass+')',
    Src+'  end;',
    'implementation',
    'end.'
    ]));
  Result:=FUnitCode;
end;

function TCustomTestLFMTrees.AddSource(aFilename, aSource: string): TCodeBuffer;
begin
  Result:=CodeToolBoss.CreateFile(aFilename);
  FSources.Add(Result);
  Result.Source:=aSource;
end;

constructor TCustomTestLFMTrees.Create;
begin
  inherited Create;
  FSources:=TFPList.Create;
end;

destructor TCustomTestLFMTrees.Destroy;
begin
  FreeAndNil(FSources);
  inherited Destroy;
end;

procedure TCustomTestLFMTrees.CheckLFM;
var
  LFMTree: TLFMTree;
  LFMErr: TLFMError;
begin
  LFMTree:=nil;
  try
    if CodeToolBoss.CheckLFM(UnitCode,LFMCode,LFMTree,true,true,true) then
      exit;
    WriteSource(CodeXYPosition(CodeToolBoss.ErrorColumn,CodeToolBoss.ErrorLine,CodeToolBoss.ErrorCode));
    if LFMTree<>nil then begin
      LFMErr:=LFMTree.FirstError;
      while LFMErr<>nil do begin
        writeln('LFM Error: (',LFMErr.Caret.Y,',',LFMErr.Caret.X,') ',LFMErr.ErrorMessage);
        LFMErr:=LFMErr.NextError;
      end;
    end;
    Fail('CheckLFM error "'+CodeToolBoss.ErrorMessage+'"');
  finally
    LFMTree.Free;
  end;
end;

procedure TCustomTestLFMTrees.CheckLFMExpectedError(ErrorType: TLFMErrorType;
  const CursorPos: TCodeXYPosition; ErrorMsg: string);
var
  LFMTree: TLFMTree;
  LFMErr: TLFMError;
begin
  LFMTree:=nil;
  try
    if CodeToolBoss.CheckLFM(UnitCode,LFMCode,LFMTree,true,true,true) then begin
      WriteSource(CursorPos);
      Fail('TCustomTestLFMTrees.CheckLFMParseError Missing '+LFMErrorTypeNames[ErrorType]+': '+CursorPos.Code.Filename+'('+IntToStr(CursorPos.Y)+','+IntToStr(CursorPos.X)+'): '+ErrorMsg);
    end;
    if LFMTree=nil then begin
      WriteSource(CursorPos);
      Fail('missing LFMTree');
    end;
    LFMErr:=LFMTree.FirstError;
    while LFMErr<>nil do begin
      //writeln('LFM Error: (',LFMErr.Caret.Y,',',LFMErr.Caret.X,') ',LFMErr.ErrorMessage);
      if (CursorPos.Code=LFMErr.Source)
          and (CursorPos.X=LFMErr.Caret.X)
          and (CursorPos.Y=LFMErr.Caret.Y)
          and (ErrorType=LFMErr.ErrorType)
          and (LFMErr.ErrorMessage=ErrorMsg) then
      begin
        // error found
        exit;
      end;
      LFMErr:=LFMErr.NextError;
    end;

    writeln('LFM Error Candidates:');
    LFMErr:=LFMTree.FirstError;
    while LFMErr<>nil do begin
      writeln('LFM-Error: ',LFMErr.ErrorType,': (',LFMErr.Caret.Y,',',LFMErr.Caret.X,') ',LFMErr.ErrorMessage);
      LFMErr:=LFMErr.NextError;
    end;
    Fail('TCustomTestLFMTrees.CheckLFMParseError Missing '+LFMErrorTypeNames[ErrorType]+': '+CursorPos.Code.Filename+'('+IntToStr(CursorPos.Y)+','+IntToStr(CursorPos.X)+'): '+ErrorMsg);
  finally
    LFMTree.Free;
  end;
end;

procedure TCustomTestLFMTrees.ParseLFM;
var
  LFMTree: TLFMTree;
  LFMErr: TLFMError;
begin
  LFMTree:=nil;
  try
    if CodeToolBoss.ParseLFM(LFMCode,LFMTree) then exit;
    WriteSource(CodeXYPosition(CodeToolBoss.ErrorColumn,CodeToolBoss.ErrorLine,CodeToolBoss.ErrorCode));
    if LFMTree<>nil then begin
      LFMErr:=LFMTree.FirstError;
      while LFMErr<>nil do begin
        writeln('LFM Error: (',LFMErr.Caret.Y,',',LFMErr.Caret.X,') ',LFMErr.ErrorMessage);
        LFMErr:=LFMErr.NextError;
      end;
    end;
    Fail('CheckLFM error "'+CodeToolBoss.ErrorMessage+'"');
  finally
    LFMTree.Free;
  end;
end;

procedure TCustomTestLFMTrees.WriteSource(const CursorPos: TCodeXYPosition);

  procedure MyWriteSources(AtCursorPos: boolean);
  var
    i, LineNo: Integer;
    Line: String;
    CurCode: TCodeBuffer;
  begin
    for i:=0 to SourceCount-1 do begin
      CurCode:=Sources[i];
      if AtCursorPos then begin
        if (CurCode<>CursorPos.Code) then continue;
      end else begin
        if (CurCode=CursorPos.Code) then continue;
      end;
      writeln('WriteSources ',i,'/',SourceCount,' ',CurCode.Filename);
      for LineNo:=1 to CurCode.LineCount do begin
        Line:=CurCode.GetLine(LineNo-1,false);
        if (CurCode=CursorPos.Code) and (LineNo=CursorPos.Y) then begin
          write('*');
          Line:=LeftStr(Line,CursorPos.X-1)+'|'+copy(Line,CursorPos.X,length(Line));
        end;
        writeln(Format('%:4d: ',[LineNo]),Line);
      end;
    end;
  end;

begin
  writeln('TCustomTestLFMTrees.WriteSource CursorPos=',dbgs(CursorPos));
  // write good sources
  MyWriteSources(false);
  // write error source
  MyWriteSources(true);
end;

{ TTestLFMTrees }

procedure TTestLFMTrees.LFMEmptyForm;
begin
  AddControls;
  AddFormUnit([]);
  FLFMCode:=AddSource('unit1.lfm',LinesToStr([
    'object Form1: TForm1',
    'end'
    ]));
  CheckLFM;
end;

procedure TTestLFMTrees.LFMChildComponent;
begin
  AddControls;
  AddFormUnit(['Button1: TButton']);
  FLFMCode:=AddSource('unit1.lfm',LinesToStr([
    'object Form1: TForm1',
    '  Left = 300',
    '  object Button1: TButton',
    '    Caption = ''ClickMe''',
    '    Default = True',
    '  end',
    'end'
    ]));
  CheckLFM;
end;

procedure TTestLFMTrees.LFMUnitname;
begin
  AddControls;
  AddFormUnit(['Button1: Controls.TButton']);
  FLFMCode:=AddSource('unit1.lfm',LinesToStr([
    'object Form1: unit1/TForm1',
    '  object Button1: Controls/TButton',
    '  end',
    'end'
    ]));
  CheckLFM;
end;

procedure TTestLFMTrees.LFM_RootUnitnameWrong;
begin
  AddControls;
  AddFormUnit(['Button1: TButton']);
  FLFMCode:=AddSource('unit1.lfm',LinesToStr([
    'object Form1: Fool/TForm1',
    '  object Button1: Controls/TButton',
    '  end',
    'end'
    ]));
  CheckLFMExpectedError(lfmeMissingRoot,CodeXYPosition(15,1,FLFMCode),'unitname Fool mismatch');
end;

procedure TTestLFMTrees.LFM_ChildUnitnameWrong;
begin
  AddControls;
  AddFormUnit(['Button1: TButton']);
  FLFMCode:=AddSource('unit1.lfm',LinesToStr([
    'object Form1: unit1/TForm1',
    '  object Button1: Fool/TButton',
    '  end',
    'end'
    ]));
  CheckLFMExpectedError(lfmeObjectIncompatible,CodeXYPosition(19,2,FLFMCode),'Controls expected, but Fool found. See unit1.pas(7,5)');
end;

procedure TTestLFMTrees.LFM_BinaryData;
begin
  AddControls;
  AddFormUnit(['Button1: TButton']);
  FLFMCode:=AddSource('unit1.lfm',LinesToStr([
    'object Form1: TForm1',
    '  object Button1: TButton',
    '    Glyph.Data = {',
    '      36040000424D3604000000000000360000002800000010000000100000000100',
    '      49EE000000000004000064000000640000000000000000000000000000000000',
    '    }',
    '    Caption = ''ClickMe''',
    '    Default = True',
    '  end',
    'end'
    ]));
  CheckLFMExpectedError(lfmeIdentifierNotFound,CodeXYPosition(11,3,FLFMCode),'identifier Data not found in class "TBitmap"');
end;

procedure TTestLFMTrees.LFM_Set;
begin
  AddControls;
  AddFormUnit(['Button1: TButton']);
  FLFMCode:=AddSource('unit1.lfm',LinesToStr([
    'object Form1: TForm1',
    '  FormStyle = fsNormal',
    '  Styles = []',
    '  Styles = [fsNormal]',
    '  Styles = [fsNormal,fsStayOnTop]',
    'end'
    ]));
  CheckLFM;
end;

procedure TTestLFMTrees.LFM_List;
begin
  AddControls;
  AddFormUnit(['Button1: TButton']);
  FLFMCode:=AddSource('unit1.lfm',LinesToStr([
    'object Form1: TForm1',
    '  object Button1: TButton',
    '    Lines.Strings = (',
    '      ''Memo1''',
    '      ''Foo''',
    '    )',
    '  end',
    'end'
    ]));
  CheckLFM;
end;

procedure TTestLFMTrees.LFM_Collection;
begin
  AddControls('controls.pas',true);
  AddFormUnit(['Grid1: TGrid']);
  FLFMCode:=AddSource('unit1.lfm',LinesToStr([
    'object Form1: TForm1',
    '  object Grid1: TGrid',
    '    Columns = <',
    '      item',
    '        Title.Caption = ''Title''',
    '        Width = 10',
    '      end',
    '      item',
    '        Width = 10',
    '      end>',
    '  end',
    'end'
    ]));
  CheckLFM;
end;

procedure TTestLFMTrees.LFMParseUnicode;
begin
  exit;

  FLFMCode:=AddSource('unit1.lfm',LinesToStr([
    'object Förmchen1: TFörmchen1',
    '  object Knöpfchen1: TKnöpfchen',
    '  end',
    'end'
    ]));
  ParseLFM;
end;

initialization
  RegisterTest(TTestLFMTrees);

end.

