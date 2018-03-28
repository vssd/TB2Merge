{
  child1.pas

  This file is part of the TB2Merge.pas sample application.
  Info at https://github.com/vssd/TB2Merge

  Copyright (C) 2005, 2006, 2018 Volker Siebert <flocke@vssd.de>
  All rights reserved.
}

unit child1;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, Menus, ExtCtrls, ImgList, TB2Item, TB2Dock, TB2Toolbar;

type
  TfrmMDIChild1 = class(TForm)
    TBDock1: TTBDock;
    tbChildMenuBar: TTBToolbar;
    TBImageList1: TTBImageList;
    TBSubmenuItem1: TTBSubmenuItem;
    TBItem1: TTBItem;
    TBItem2: TTBItem;
    TBItem3: TTBItem;
    TBSeparatorItem1: TTBSeparatorItem;
    TBItem4: TTBItem;
    TBItem5: TTBItem;
    TBItem6: TTBItem;
    TBItem7: TTBItem;
    Panel1: TPanel;
    procedure TBItemClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormCreate(Sender: TObject);
  protected
    procedure WMMDIActivate(var Message: TWMMDIActivate); message WM_MDIACTIVATE;
  end;

var
  frmMDIChild1: TfrmMDIChild1;

implementation

uses
  TB2Merge, main;

{$R *.dfm}

var
  Counter: Integer = 0;

procedure TfrmMDIChild1.FormCreate(Sender: TObject);
begin
  Counter := Counter + 1;
  Caption := 'RED child ' + IntToStr(Counter);
  Panel1.Caption := Caption;

  TBImageList1.BkColor := BlendColor(tbChildMenuBar.Color, Panel1.Font.Color, 20);

  TBFixImageList(tbChildMenuBar.Items, tbChildMenuBar.Images);
end;

procedure TfrmMDIChild1.WMMDIActivate(var Message: TWMMDIActivate);
begin
  inherited;

  if Message.ActiveWnd = Handle then
    ToolbarMerger.Merge(frmMDIParent.tbMainMenuBar, tbChildMenuBar, [])
  else
    ToolbarMerger.UnmergeAll(tbChildMenuBar);
end;

procedure TfrmMDIChild1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmMDIChild1.TBItemClick(Sender: TObject);
begin
  if Sender is TTBItem then
    MessageDlg(Caption + ': ' + StripHotkey(TTBItem(Sender).Caption), mtInformation, [mbOk], 0);
end;

end.
