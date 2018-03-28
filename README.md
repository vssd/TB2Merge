Consider: This project is *old*, really ***old***...

# TB2Merge

Utility unit for Toolbar2000 (and derived components like TBX or SpTBX) to merge two sets of toolbar items together.

Version 1.1b - always find the most current version at https://github.com/vssd/TB2Merge

Copyright (C) 2005, 2006, 2018 Volker Siebert <flocke@vssd.de>

All rights reserved.
License: MIT

## Required Versions

Verified Delphi versions: 5 to 2006.
Verified Toolbar2000 versions: 2.1.5 to 2.1.8.

## Introduction

The intention for writing this code came from porting an older application with *many* MDI child forms to TBX, using a TTBXToolBar as the main menu bar.

The most important thing first: `ToolbarMerger` works on *ordered* blocks of items having *the same* `GroupIndex` value. This is very similar to the way Delphi merges the menu of MDI children with the main form's menu. But this also means that if your items have the indexes (2, 1, 9, 8) the code won't work as intended - the indexes have to be *ordered*.

Decreasing values are ignored and those items are just put together with the items that precede them, so the list of indexes above is equal to (2, 2, 9, 9). The only exception to this rule are separator items, because there is no way to assign a `GroupIndex` to them.

By default, they are grouped together with items that follow them, but this behaviour can be changed with the option `moSeparatorAfterItems`.

## Simple Example

Original main menu bar (top level):

```
  +------+------+-------+------+
  | File | Edit | Extra | Help |
  +------+------+-------+------+
      |      |      |       |
      |      |      +-------+-- GroupIndex = 9
      +------+----------------- GroupIndex = 0
```

MDI child menu bar (top level):

```
  +--------+----------+
  | Search | Document |
  +--------+----------+
      |         |
      +---------+-------------- GroupIndex = 1
```

Resulting merged main menu bar (top level):

```
  +------+------+--------+----------+-------+------+
  | File | Edit | Search | Document | Extra | Help |
  +------+------+--------+----------+-------+------+
```

The main advantage of this is that the new menu items, together with their event methods and actions, still belong to their old owner. Thus, `Item.OnClick` is raised in the owner window's context.

## Options and merging

This unit can even do more, because it can recurse into existing menu items and e.g. replace just the "&Save" and "&Print" entries by new ones defined by the child's menu while keeping all other entries from the "File" menu.

There are a few options you can pass to the call of `ToolbarMerger.Merge` that change the way the code works. Consider the following situation:

```
             Original menu            Merged-in menu
              ( Target )                ( Source )
             +-----------+         +----------------------+
           1 | Undo      |       2 | Repeat               |
           1 | Redo      |         +----------------------+ ---+ S B
  T B +---   +-----------+       5 | Cut              [D] |    | o l
  a l |    5 | Cut   [A] |       5 | Paste special... [E] | ---+ u o
  r o |    5 | Copy  [B] |         +----------------------+      r c
  g c +--- 5 | Paste [C] |       8 | Insert object...     |      c k
  e k        +-----------+         +----------------------+      e
  t        9 | Find      |
           9 | Replace   |
             +-----------+
```

* `moKeepTarget`, `moRecursive`

  Since there is no match for the indexes 1, 2, 8, and 9 in the above example, you will always get those blocks when merging these menus.
  The difference comes with index 5, because it appears on both sides.

  * If you neither specify `moKeepTarget` nor `moRecursive`, the default action is to replace the entire target block by the source block (the whole menu). This mimics the behaviour of the VCL when merging two menus.

    --> You will get `( 1 | 2 | 5D 5E | 8 | 9 )`

  * With `moKeepTarget`, the code tries to find a matching source entry for each target item (read below about how a matching entry is identified).

    If it finds one, the target item is replaced by this match. If not, the target item will be kept in place. After that the remaining unused source items are appended at the end of the target block.

    --> You will get `( 1 | 2 | 5D 5B 5C 5E | 8 | 9 )`

  * `moRecursive` works like `moKeepTarget`, i.e., the code tries to find a matching entry for each target item. The difference comes when it finds two matching items with submenus. Here the target item is kept (incl. all of its properties) and instead the both submenus' items are merged recursively.

* `moMatchByCaption`, `moMatchByTag`

  *(only relevant with `moKeepTarget` or `moRecursive`)*

  By default the system identifies matching entries by their name, i.e., `tbMainMenuBar.miFileSave` and `tbChildMenuBar.miFileSave` match because they have the same name.

  Using `moMatchByCaption` resp. `moMatchByTag` changes this behaviour and items are identified by their caption resp. by their tag number.

* `moSeparatorAfterItems`

  If you specify `moSeparatorAfterItems`, separators are grouped with the items that *precede* them. The default is to group them with the items that follow them.

## Usage

Practically, you will use the global `ToolbarMerger` (it's a function but should be used like a variable) to merge and unmerge two toolbars and/or menu bars. It also automatically unmerges the two components if they are already used in other merge operations.

### Sample usage for `fsMDIChild` forms

The `interface` part:

```pascal
type
  TfrmChild = class(TForm)
  ...
  protected
    procedure WMMDIActivate(var Message: TWMMDIActivate); message WM_MDIACTIVATE;
    ...
  end;
```

The `implementation` part:

```pascal
procedure TfrmChild.WMMDIActivate(var Message: TWMMDIActivate);
begin
  inherited;
  if Message.ActiveWnd = Handle then
    ToolbarMerger.Merge(frmMain.tbMainMenu, tbChildMenu, [])
  else
    ToolbarMerger.UnmergeAll(tbChildMenu);
end;
```

### Sample usage for all forms

Events:

```pascal
procedure TfrmChild.FormActivate(Sender: TObject);
begin
  ToolbarMerger.Merge(frmMain.tbMainMenu, tbChildMenu, []);
end;

procedure TfrmChild.FormDeactivate(Sender: TObject);
begin
  // This is normally *NOT* necessary
  ToolbarMerger.UnmergeAll(tbChildMenu);
end;

procedure TfrmChild.FormDestroy(Sender: TObject);
begin
  ToolbarMerger.UnmergeAll(tbChildMenu);
end;
```

Also, take a look at the included sample application, a few lines of code often say more than 1,000 words ;)
