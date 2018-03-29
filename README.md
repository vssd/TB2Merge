Consider: This is *really* old stuff.

![Delphi 5-2006](https://img.shields.io/badge/Delphi-5--2006-orange.svg) [![MIT License](http://img.shields.io/badge/license-MIT-blue.svg?style=flat)](https://github.com/vssd/TB2Merge/blob/master/LICENSE)

# TB2Merge

TB2Merge is a utility unit for [Toolbar2000](http://www.jrsoftware.org/tb2k.php) (and derived components like [TBX](https://github.com/plashenkov/TBX) or [SpTBX](https://github.com/SilverpointDev/sptbxlib)) to merge two sets of toolbar items together.

Version 1.1b  
https://github.com/vssd/TB2Merge

Copyright (C) 2005, 2006 Volker Siebert, <flocke@vssd.de>

## Description

The intention for writing this code came from porting an older application with *many* MDI child forms to TBX, using a `TTBXToolBar` as the main menu bar.

### Simple Example

Original main menu bar (top level):

```
  +------+------+-------+------+
  | File | Edit | Extra | Help |
  +------+------+-------+------+
      |      |      |       |
      |      |      +-------+-- GroupIndex = 9
      |      +----------------- GroupIndex = 1
      +------------------------ GroupIndex = 0
```

MDI child menu bar (top level):

```
  +--------+----------+
  | Search | Document |
  +--------+----------+
      |         |
      +---------+-------------- GroupIndex = 5
```

Resulting merged main menu bar (top level):

```
  +------+------+--------+----------+-------+------+
  | File | Edit | Search | Document | Extra | Help |
  +------+------+--------+----------+-------+------+
      |      |      |         |         |       |
      |      |      |         |         +-------+-- GroupIndex = 9
      |      |      +---------+-------------------- GroupIndex = 5
      |      +------------------------------------- GroupIndex = 1
      +-------------------------------------------- GroupIndex = 0
```

## Usage

The unit has several functions and classes, but practically, you will use the singleton `ToolbarMerger` to merge/unmerge toolbars and/or menu bars. It also automatically unmerges the components that are about to be merged, if they are in use by a previous merge operations.

In your child form, you have to implement handlers for the following events:

```pascal
procedure TfrmChild.FormActivate(Sender: TObject);
begin
  ToolbarMerger.Merge(frmMain.tbMainMenu, tbChildMenu, [moRecursive]);
end;

procedure TfrmChild.FormDeactivate(Sender: TObject);
begin
  // If all your child forms have a FormActivate event
  // like above, this handler is not necessary.
  ToolbarMerger.UnmergeAll(tbChildMenu);
end;

procedure TfrmChild.FormDestroy(Sender: TObject);
begin
  ToolbarMerger.UnmergeAll(tbChildMenu);
end;
```

This code can be part of your MDI child window base class, the one that all your other MDI child windows inherit from. Remember: Delphi is "object oriented".

## Options

`ToolbarMerger` works on *ordered* blocks of items having *the same* `GroupIndex` value. This is very similar to the way Delphi merges the menu of MDI children with the main form's menu. But this also means that if your items have the group indexes `(2, 1, 9, 8)` the code won't work as intended &ndash; the indexes have to be *ordered*. Decreasing values are ignored and those items are just put together with the items that precede them, so the list of indexes above works like `(2, 2, 9, 9)`.

There are a few options you can pass to the call of `ToolbarMerger.Merge` that change the way the code works. Consider the example from above, but with both windows having "Edit" menus containing the following items:

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

* `moKeepTarget` / `moRecursive`

  Since there is no match for the indexes 1, 2, 8, and 9 in the above example, you will always get those blocks when merging the menus.
  The difference comes with index 5, because it appears on both sides.

  * If you neither specify `moKeepTarget` nor `moRecursive`, the default action is to replace the entire target block by the source block (the whole menu). This mimics the behavior of the VCL when merging two menus.

    &rarr; You will get `( 1 | 2 | 5D 5E | 8 | 9 )`

  * With `moKeepTarget`, the code tries to find a matching source entry for each target item (read below about how a matching entry is identified).

    If it finds one, the target item is replaced by this match. If not, the target item will be kept in place. After that the remaining unused source items are appended at the end of the target block.

    &rarr; You will get `( 1 | 2 | 5D 5B 5C 5E | 8 | 9 )`

  * `moRecursive` works like `moKeepTarget`, i.e., the code tries to find a matching entry for each target item. The difference comes when it finds two matching items with submenus. Here the target item is kept (incl. all of its properties) and instead the both submenus' items are merged recursively.

* `moMatchByCaption` / `moMatchByTag`

  By default entries are matched by their name, i.e., `tbMainMenuBar.miFileSave` and `tbChildMenuBar.miFileSave` match because they have the same name.

  Using `moMatchByCaption` resp. `moMatchByTag` changes this behavior and items are matched by their caption resp. by their tag number.

* `moSeparatorAfterItems`

  If you specify `moSeparatorAfterItems`, separators are grouped with the items that *precede* them. The default is to group them with the items that follow them.

## Compatibility

  * Verified Delphi versions: 5 to 2006
  * Verified Toolbar2000 versions: 2.1.5 to 2.1.8

## Pre-github history

* 2006-02-12: Version 1.1b
  * Small re-packaging.
  * Verified to work with Toolbar2000 2.1.7 and 2.1.8 - no changes.
* 2006-01-01: Version 1.1a
  * Verified to work with Delphi 2006 - no changes.
* 2005-11-16: Version 1.1
  * Changed version numbering, it's not a beta.
  * Verified to work with Toolbar2000 2.1.6.
  * Translated sample to english.
* 2005-08-09: Version 0.5 (1.0)
  * Complete re-packaging, created the files README, CHANGES, and INFO with (small) documentation in english an german.
  * Changed the license model to M.I.T.
* 2005-07-15: Version 0.4
  * Some further code cleanup.
  * Updated information for `fsMDIChild` windows on how to use the merger.
  * Added the option `moSeparatorAfterItems`.
* 2005-06-30: Version 0.3
  * Changed the way how "hiding" works, hidden items are no longer moved to the source side but are simply kept in our list without parent. This way we can restore them even if the source is destroyed unexpectedly.
* 2005-06-27: Version 0.2
  * Added `TBFixImageList` to merge toolbars with different image lists.
  Changed the way how separator items are grouped, see `FindEndOfGroup`.
* 2005-06-25: Version 0.1
  * Initial version.

## Keywords

Toolbar2000, TB2K, TBX, Menu, AutoMerge, ToolbarMerger, TTBToolbarMerger, TBMergeItems, TBUnmergeItems
