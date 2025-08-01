{***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 51 Franklin Street - Fifth Floor, Boston, MA 02110-1335, USA.   *
 *                                                                         *
 ***************************************************************************

  Abstract:
    Modal form to show all possible fpc options, parsed from -h output,
    and enable/disable in custom compiler options.
}
unit AllCompilerOptions;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Math, Contnrs,
  // LCL
  Forms, Controls, StdCtrls, Buttons, ButtonPanel, EditBtn, ExtCtrls,
  // LazUtils
  LazUTF8, LazLoggerBase,
  // IdeIntf
  IDEImagesIntf, IDEWindowIntf,
  // IDE
  Compiler, LazarusIDEStrConsts;

type

  { TfrmAllCompilerOptions }

  TfrmAllCompilerOptions = class(TForm)
    btnResetOptionsFilter: TSpeedButton;
    ButtonPanel1: TButtonPanel;
    cbShowModified: TCheckBox;
    cbUseComments: TCheckBox;
    edOptionsFilter: TEdit;
    pnlFilter: TPanel;
    sbAllOptions: TScrollBox;
    txtErrorMsg: TStaticText;
    procedure btnResetOptionsFilterClick(Sender: TObject);
    procedure cbShowModifiedClick(Sender: TObject);
    procedure sbMouseWheel(Sender: TObject; {%H-}Shift: TShiftState;
      WheelDelta: Integer; {%H-}MousePos: TPoint; var Handled: Boolean);
    procedure edOptionsFilterChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    FIdleConnected: Boolean;
    FOptionsReader: TCompilerOptReader;
    FOptionsThread: TCompilerOptThread;
    FGeneratedControls: TComponentList;
    FEffectiveFilter: string;
    FEffectiveShowModified: Boolean;
    FInitialRender: Boolean;
    procedure SetIdleConnected(AValue: Boolean);
    procedure OnIdle(Sender: TObject; var {%H-}Done: Boolean);
    procedure CheckBoxClick(Sender: TObject);
    procedure EditChange(Sender: TObject);
    procedure ComboChange(Sender: TObject);
    procedure RenderAndFilterOptions;
  private
    property IdleConnected: Boolean read FIdleConnected write SetIdleConnected;
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
    function ToCustomOptions(aStrings: TStrings): TModalResult;
  public
    property OptionsReader: TCompilerOptReader read FOptionsReader write FOptionsReader;
    property OptionsThread: TCompilerOptThread read FOptionsThread write FOptionsThread;
  end;

var
  frmAllCompilerOptions: TfrmAllCompilerOptions;

implementation

{$R *.lfm}

{ TfrmAllCompilerOptions }

constructor TfrmAllCompilerOptions.Create(TheOwner: TComponent);
begin
  inherited Create(TheOwner);
  FGeneratedControls := TComponentList.Create;
  sbAllOptions.OnMouseWheel := @sbMouseWheel;
end;

destructor TfrmAllCompilerOptions.Destroy;
begin
  IDEDialogLayoutList.SaveLayout(self);
  IdleConnected:=false;
  FGeneratedControls.Clear;
  FreeAndNil(FGeneratedControls);
  inherited Destroy;
end;

function TfrmAllCompilerOptions.ToCustomOptions(aStrings: TStrings): TModalResult;
begin
  Result := FOptionsReader.ToCustomOptions(aStrings, cbUseComments.Checked);
end;

procedure TfrmAllCompilerOptions.FormCreate(Sender: TObject);
begin
  Caption:=Format(lisAllOptions, ['', 'fpc']);
  edOptionsFilter.Hint := lisFilterTheAvailableOptionsList;
  IDEImages.AssignImage(btnResetOptionsFilter, ResBtnListFilter);
  btnResetOptionsFilter.Enabled := False;
  btnResetOptionsFilter.Hint := lisClearTheFilterForOptions;
  cbShowModified.Caption:=lisShowOnlyModified;
  cbUseComments.Caption:=lisUseCommentsInCustomOptions;
  FEffectiveFilter:=#1; // Set an impossible value first, makes sure options are filtered.
  ButtonPanel1.ShowBevel := False;
  FInitialRender := True;
  IdleConnected := True;
  IDEDialogLayoutList.ApplyLayout(self, 600, 500);
end;

procedure TfrmAllCompilerOptions.edOptionsFilterChange(Sender: TObject);
begin
  btnResetOptionsFilter.Enabled := edOptionsFilter.Text<>'';
  // Filter the list of options in OnIdle handler
  IdleConnected := True;
end;

procedure TfrmAllCompilerOptions.btnResetOptionsFilterClick(Sender: TObject);
begin
  edOptionsFilter.Text := '';
  btnResetOptionsFilter.Enabled := False;
end;

procedure TfrmAllCompilerOptions.cbShowModifiedClick(Sender: TObject);
begin
  IdleConnected := True;
end;

procedure TfrmAllCompilerOptions.SetIdleConnected(AValue: Boolean);
begin
  if csDestroying in ComponentState then
    AValue:=false;
  if FIdleConnected = AValue then exit;
  FIdleConnected := AValue;
  if FIdleConnected then
    Application.AddOnIdleHandler(@OnIdle)
  else
    Application.RemoveOnIdleHandler(@OnIdle);
end;

procedure TfrmAllCompilerOptions.OnIdle(Sender: TObject; var Done: Boolean);

  function FormatTimeWithMs(aTime: TDateTime): string;
  var
    fs: TFormatSettings;
  begin
    fs.TimeSeparator := ':';
    Result := FormatDateTime('nn:ss', aTime, fs)+'.'+FormatDateTime('zzz', aTime);
  end;

var
  StartTime: TDateTime;
begin
  IdleConnected := False;
  if FOptionsThread=nil then exit;
  Screen.BeginWaitCursor;
  try
    FOptionsThread.EndParsing; // make sure the options are read

    with FOptionsReader do
      if FOptionsReader.CompilerVersion = '' then
        Caption := Format(lisAllOptions, ['', CompilerExecutable])
      else
        Caption := Format(lisAllOptions, [' ' + CompilerVersion, CompilerExecutable]);

    txtErrorMsg.Visible := FOptionsReader.ErrorMsg <> '';
    if FOptionsReader.ErrorMsg <> '' then
      txtErrorMsg.Caption := FOptionsReader.ErrorMsg
    else begin
      StartTime := Now;
      RenderAndFilterOptions;
      DebugLn(Format('AllCompilerOptions: Time for reading options: %s, rendering GUI: %s',
                     [FormatTimeWithMs(FOptionsThread.ReadTime),
                      FormatTimeWithMs(Now-StartTime)]));

      if FInitialRender then
      begin
        txtErrorMsg.Caption := lisCheckCompilerPath;
        txtErrorMsg.Visible := FOptionsReader.RootOptGroup.Count <= 0;
      end;
    end;

  finally
    Screen.EndWaitCursor;
  end;
  FInitialRender := False;
end;

procedure TfrmAllCompilerOptions.sbMouseWheel(Sender: TObject;
  Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  with sbAllOptions.VertScrollBar do
    Position := Position - Sign(WheelDelta) * Increment;
  Handled := True;
end;

procedure TfrmAllCompilerOptions.CheckBoxClick(Sender: TObject);
var
  cb: TCheckBox;
  Opt: TCompilerOpt;
begin
  cb := Sender as TCheckBox;
  Opt := FOptionsReader.FindOptionById(cb.Tag);
  if Assigned(Opt) then
  begin
    if cb.Checked then
      Opt.Value := 'True'
    else
      Opt.Value := '';
  end;
end;

procedure TfrmAllCompilerOptions.EditChange(Sender: TObject);
var
  ed: TCustomEdit;
  Opt: TCompilerOpt;
begin
  ed := Sender as TCustomEdit;
  Opt := FOptionsReader.FindOptionById(ed.Tag);
  if Assigned(Opt) then
    Opt.Value := ed.Text;
end;

procedure TfrmAllCompilerOptions.ComboChange(Sender: TObject);
var
  cb: TComboBox;
  Opt: TCompilerOpt;
begin
  cb := Sender as TComboBox;
  Opt := FOptionsReader.FindOptionById(cb.Tag);
  if Assigned(Opt) then
    Opt.Value := cb.Text;
end;

procedure TfrmAllCompilerOptions.RenderAndFilterOptions;
var
  Opt: TCompilerOpt;
  yLoc: Integer;
  Container: TCustomControl;

  { Calculated Heights and Left positions considering Runtime PPI }
  lEditHeight: integer;      // Edit + Dropdown lists
  lCbHeight: integer;        // Checkboxes and labels
  lLeftMargin,               // Leftmost position  of text
  lIndentPixs,               // Nb of pixels to multiply by Indentation to
                             // place left text
  lLeftDescrGroup: integer;  // Nb of pixels where comments sould start

  { Replace TCompilerOpt.CalcLeft to repsect screen PPI scaling }
  function CalcLeft(aRefCntrl: TControl; aOpt: TCompilerOpt) : integer;
  begin
    if (aRefCntrl is TEdit) or (aRefCntrl is TComboBox) then
      Result := aRefCntrl.Left + aRefCntrl.Width + lLeftMargin
    else begin
      Result := Container.Canvas.GetTextWidth(aOpt.Option) + aRefCntrl.Left + lCbHeight;
      if Result < lLeftDescrGroup then
        Result := lLeftDescrGroup;
    end;
  end;

  function MakeOptionCntrl(aCntrlClass: TControlClass; aCaption: string;
    aTopOffs: integer=0): TControl;
  // Header Label or TCheckBox
  begin
    Result := aCntrlClass.Create(Nil);
    Result.Parent := Container;
    Result.Top := yLoc+aTopOffs;
    Result.Left := Opt.Indentation * lIndentPixs;
    Result.Height := lCbHeight;
    Result.Caption := aCaption;
    Result.Tag := Opt.Id;
    FGeneratedControls.Add(Result);
  end;

  function MakeEditCntrl(aLbl: TControl; aCntrlClass: TControlClass): TControl;
  // TEdit or TComboBox
  begin
    Result := aCntrlClass.Create(Nil);
    Result.Parent := Container;
    Result.AnchorSide[akTop].Control := aLbl;
    Result.AnchorSide[akTop].Side := asrCenter;
    Result.Left := lLeftDescrGroup;       // Now use Left instead of anchors
    Result.Width := 20 * lLeftMargin;
    Result.Height := lEditHeight;
    Result.Anchors := [akLeft,akTop];
    Result.Tag := Opt.Id;
    FGeneratedControls.Add(Result);
  end;

  procedure MakeDescrLabel(aCntrl: TControl; aLeft: integer);
  // Description label after CheckBox / Edit control
  var
    Lbl: TLabel;
  begin
    Lbl := TLabel.Create(Nil);
    Lbl.Parent := Container;
    Lbl.Caption := Opt.Description;
    Lbl.AnchorSide[akTop].Control := aCntrl;
    Lbl.AnchorSide[akTop].Side := asrCenter;
    Lbl.Height := lCbHeight;
    Lbl.Left := aLeft;
    Lbl.Anchors := [akLeft,akTop];
    Lbl.OnMouseWheel := @sbMouseWheel;
    FGeneratedControls.Add(Lbl);
  end;

  procedure RenderOneLevel(aParentGroup: TCompilerOptGroup);
  var
    Cntrl, Lbl: TControl;
    cb: TComboBox;
    i: Integer;
  begin
    for i := 0 to aParentGroup.Count-1 do begin
      Opt := aParentGroup[i];
      if Opt.Ignored or not Opt.Visible then Continue;  // Maybe filtered out
      case Opt.EditKind of
        oeGroup, oeSet: begin                   // Label for group or set
          Cntrl := MakeOptionCntrl(TLabel, Opt.Option+Opt.Suffix);
          TLabel(Cntrl).OnMouseWheel := @sbMouseWheel;
          MakeDescrLabel(Cntrl, CalcLeft(Cntrl,Opt));
        end;
        oeBoolean: begin                        // CheckBox
          Cntrl := MakeOptionCntrl(TCheckBox, Opt.Option);
          TCheckBox(Cntrl).Checked := (Opt.Value='True') or (Opt.Value='+');
          TCheckBox(Cntrl).OnMouseWheel := @sbMouseWheel;
          Cntrl.OnClick := @CheckBoxClick;
          MakeDescrLabel(Cntrl, CalcLeft(Cntrl, Opt));
        end;
        oeSetElem: begin                        // Sub-item for set, CheckBox
          Cntrl := MakeOptionCntrl(TCheckBox, Opt.Option+Opt.Description);
          TCheckBox(Cntrl).Checked := Opt.Value='True';
          TCheckBox(Cntrl).OnMouseWheel := @sbMouseWheel;
          Cntrl.OnClick := @CheckBoxClick;
        end;
        oeNumber, oeText, oeSetValue: begin    // Edit
          Lbl := MakeOptionCntrl(TLabel, Opt.Option+Opt.Suffix, lIndentPixs {3});
          TLabel(Lbl).OnMouseWheel := @sbMouseWheel;
          Cntrl := MakeEditCntrl(Lbl, TEdit);
          if Opt.EditKind <> oeText then
            TEdit(Cntrl).Width := 16 * lLeftMargin ;
          TEdit(Cntrl).Text := Opt.Value;
          TEdit(Cntrl).OnChange := @EditChange;
          TEdit(Cntrl).OnMouseWheel := @sbMouseWheel;
          MakeDescrLabel(Cntrl, CalcLeft(Cntrl, nil));
        end;
        oeList: begin                           // ComboBox
          Lbl := MakeOptionCntrl(TLabel, Opt.Option+Opt.Suffix, lIndentPixs {3});
          TLabel(Lbl).OnMouseWheel := @sbMouseWheel;
          Cntrl := MakeEditCntrl(Lbl, TComboBox);
          cb := TComboBox(Cntrl);
          cb.Style := csDropDownList;
          if Assigned(Opt.Choices) then
            cb.Items.Assign(Opt.Choices);
          cb.Text := Opt.Value;
          cb.OnChange := @ComboChange;
          MakeDescrLabel(Cntrl, CalcLeft(Cntrl, nil));
        end
        else
          raise Exception.Create('TCompilerOptsRenderer.Render: Unknown EditKind.');
      end;
      Inc(yLoc, Cntrl.Height+2);
      if Opt is TCompilerOptGroup then
        RenderOneLevel(TCompilerOptGroup(Opt));  // Show other levels recursively
    end;
  end;
       
  { determine dimensions using height of existing controls }
  procedure PickupLeftsAndHeights;
  begin
    lCbHeight := cbShowModified.Height;
    lEditHeight := edOptionsFilter.Height;

    lLeftMargin := lEditHeight div 4;
    lIndentPixs := lEditHeight div 8;
    lLeftDescrGroup := lLeftMargin * 16;
  end;

begin
  if (FEffectiveFilter = edOptionsFilter.Text)
  and (FEffectiveShowModified = cbShowModified.Checked) then Exit;
  Container := sbAllOptions;
  Container.Perform(CM_PARENTFONTCHANGED, 0, 0);
  Container.DisableAutoSizing{$IFDEF DebugDisableAutoSizing}('TfrmAllCompilerOptions.RenderAndFilterOptions'){$ENDIF};
  PickupLeftsAndHeights;
  try
    // First filter and set Visible flag.
    FOptionsReader.FilterOptions(UTF8LowerCase(edOptionsFilter.Text),
                                 cbShowModified.Checked);
    // Then create and place new controls in GUI
    FGeneratedControls.Clear;
    yLoc := 0;
    RenderOneLevel(FOptionsReader.RootOptGroup);
    FEffectiveFilter := edOptionsFilter.Text;
    FEffectiveShowModified := cbShowModified.Checked;
    FocusControl(edOptionsFilter);
  finally
    Container.EnableAutoSizing{$IFDEF DebugDisableAutoSizing}('TfrmAllCompilerOptions.RenderAndFilterOptions'){$ENDIF};
    Container.Invalidate;
  end;
end;

end.

