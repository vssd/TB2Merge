{
  main.pas

  This file is part of the TB2Merge.pas sample application.
  Info at https://github.com/vssd/TB2Merge

  Copyright (C) 2005, 2006, 2018 Volker Siebert <flocke@vssd.de>
  All rights reserved.
}

unit main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  Menus, ComCtrls, ExtCtrls, ImgList, TB2MDI, TB2Item, TB2Dock, TB2Toolbar;

type
  TfrmMDIParent = class(TForm)
    TBDock1: TTBDock;
    TBDock2: TTBDock;
    tbMainMenuBar: TTBToolbar;
    TBSubmenuItem1: TTBSubmenuItem;
    TBItem1: TTBItem;
    TBItem2: TTBItem;
    TBItem3: TTBItem;
    TBItem4: TTBItem;
    TBSeparatorItem1: TTBSeparatorItem;
    TBItem5: TTBItem;
    TBSubmenuItem2: TTBSubmenuItem;
    TBItem6: TTBItem;
    TBSeparatorItem2: TTBSeparatorItem;
    TBItem7: TTBItem;
    TBItem8: TTBItem;
    TBItem9: TTBItem;
    TBSubmenuItem3: TTBSubmenuItem;
    TBSubmenuItem4: TTBSubmenuItem;
    TBItem10: TTBItem;
    TBImageList1: TTBImageList;
    TBMDIHandler1: TTBMDIHandler;
    TBMDIWindowItem1: TTBMDIWindowItem;
    TBItem11: TTBItem;
    TBSeparatorItem3: TTBSeparatorItem;
    StatusBar1: TStatusBar;
    Timer1: TTimer;
    procedure Timer1Timer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure TBItem1Click(Sender: TObject);
    procedure TBItemClick(Sender: TObject);
  end;

var
  frmMDIParent: TfrmMDIParent;

function BlendColor(c1, c2: TColor; Percent: Integer): TColor;

implementation

{$R *.dfm}

uses
  child1, child2;

const
  Msg = 'Choose File>New to open windows and watch the menu change while you cycle through them';

var
  Counter: Integer = 0;

function BlendColor(c1, c2: TColor; Percent: Integer): TColor;
begin
  c1 := ColorToRGB(c1);
  c2 := ColorToRGB(c2);

  Result := RGB((GetRValue(c1) * (100 - Percent) + GetRValue(c2) * Percent) div 100,
                (GetGValue(c1) * (100 - Percent) + GetGValue(c2) * Percent) div 100,
                (GetBValue(c1) * (100 - Percent) + GetBValue(c2) * Percent) div 100);
end;

procedure TfrmMDIParent.FormCreate(Sender: TObject);
begin
  TBImageList1.BkColor := BlendColor(tbMainMenuBar.Color, clGreen, 20);
end;

procedure TfrmMDIParent.TBItemClick(Sender: TObject);
begin
  if Sender is TTBItem then
    MessageDlg(Caption + ': ' + StripHotkey(TTBItem(Sender).Caption), mtInformation, [mbOk], 0);
end;

procedure TfrmMDIParent.TBItem1Click(Sender: TObject);
begin
  case Counter mod 2 of
    0: begin
      frmMDIChild1 := nil;
      Application.CreateForm(TfrmMDIChild1, frmMDIChild1);
    end;
    1: begin
      frmMDIChild2 := nil;
      Application.CreateForm(TfrmMDIChild2, frmMDIChild2);
    end;
  end;
  inc(Counter);

  Timer1.Enabled := false;
  StatusBar1.Panels[0].Text := Msg;
end;

procedure TfrmMDIParent.Timer1Timer(Sender: TObject);
begin
  if StatusBar1.Panels[0].Text = '' then
    StatusBar1.Panels[0].Text := Msg
  else
    StatusBar1.Panels[0].Text := '';
end;

end.
