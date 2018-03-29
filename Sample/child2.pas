{
  child2.pas

  This file is part of the TB2Merge.pas sample application.
  Info at https://github.com/vssd/TB2Merge

  Copyright (C) 2005, 2006 Volker Siebert <flocke@vssd.de>
  All rights reserved.
}

unit child2;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Menus, ImgList, TB2Item, TB2Dock, TB2Toolbar;

type
  TfrmMDIChild2 = class(TForm)
    TBDock1: TTBDock;
    tbChildMenuBar: TTBToolbar;
    TBImageList1: TTBImageList;
    TBSubmenuItem1: TTBSubmenuItem;
    TBItem1: TTBItem;
    TBItem2: TTBItem;
    TBItem3: TTBItem;
    TBItem4: TTBItem;
    Panel1: TPanel;
    TBSubmenuItem2: TTBSubmenuItem;
    TBItem5: TTBItem;
    TBSeparatorItem1: TTBSeparatorItem;
    TBItem7: TTBItem;
    TBItem8: TTBItem;
    TBItem9: TTBItem;
    TBSubmenuItem3: TTBSubmenuItem;
    TBItem6: TTBItem;
    TBItem10: TTBItem;
    TBSeparatorItem2: TTBSeparatorItem;
    TBItem11: TTBItem;
    TBItem12: TTBItem;
    TBSubmenuItem4: TTBSubmenuItem;
    TBItem13: TTBItem;
    TBSeparatorItem3: TTBSeparatorItem;
    TBItem14: TTBItem;
    TBSubmenuItem5: TTBSubmenuItem;
    TBSubmenuItem6: TTBSubmenuItem;
    TBSubmenuItem7: TTBSubmenuItem;
    TBSubmenuItem8: TTBSubmenuItem;
    TBSubmenuItem9: TTBSubmenuItem;
    procedure TBItemClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormDeactivate(Sender: TObject);
    procedure FormActivate(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  end;

var
  frmMDIChild2: TfrmMDIChild2;

implementation

uses
  TB2Merge, main;

{$R *.dfm}

var
  Counter: Integer = 0;

procedure TfrmMDIChild2.FormCreate(Sender: TObject);
begin
  Counter := Counter + 1;
  Caption := 'BLUE child ' + IntToStr(Counter);
  Panel1.Caption := Caption;

  TBImageList1.BkColor := BlendColor(tbChildMenuBar.Color, Panel1.Font.Color, 20);

  TBFixImageList(tbChildMenuBar.Items, tbChildMenuBar.Images);
end;

procedure TfrmMDIChild2.FormActivate(Sender: TObject);
begin
  ToolbarMerger.Merge(frmMDIParent.tbMainMenuBar, tbChildMenuBar, [moRecursive, moMatchByCaption]);
end;

procedure TfrmMDIChild2.FormDeactivate(Sender: TObject);
begin
  ToolbarMerger.UnmergeAll(tbChildMenuBar);
end;

procedure TfrmMDIChild2.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
end;

procedure TfrmMDIChild2.FormDestroy(Sender: TObject);
begin
  ToolbarMerger.UnmergeAll(tbChildMenuBar);
end;

procedure TfrmMDIChild2.TBItemClick(Sender: TObject);
begin
  if Sender is TTBItem then
    MessageDlg(Caption + ': ' + StripHotkey(TTBItem(Sender).Caption), mtInformation, [mbOk], 0);
end;

end.
