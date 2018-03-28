{
  MergeExample.dpr

  This file is part of the TB2Merge.pas sample application.
  https://github.com/vssd/TB2Merge

  Copyright (C) 2005, 2006, 2018 Volker Siebert <flocke@vssd.de>
  All rights reserved.
}

program MergeExample;

uses
  Forms,
  TB2Merge in '..\TB2Merge.pas',
  main in 'main.pas' {frmMDIParent},
  child1 in 'child1.pas' {frmMDIChild1},
  child2 in 'child2.pas' {frmMDIChild2};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMDIParent, frmMDIParent);
  Application.Run;
end.
