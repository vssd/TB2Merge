{
  TB2Merge.pas

  Utility unit for Toolbar2000 and derived components like TBX or SpTBX to
  merge two sets of toolbar items together. See the included file INFO.txt
  for information on how to use it.

  Version 1.1b - always find the most current version at
  https://github.com/vssd/TB2Merge

  Copyright (C) 2005, 2006, 2018 Volker Siebert <flocke@vssd.de>
  All rights reserved.

  Permission is hereby granted, free of charge, to any person obtaining a
  copy of this software and associated documentation files (the "Software"),
  to deal in the Software without restriction, including without limitation
  the rights to use, copy, modify, merge, publish, distribute, sublicense,
  and/or sell copies of the Software, and to permit persons to whom the
  Software is furnished to do so, subject to the following conditions:

  The above copyright notice and this permission notice shall be included in
  all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
  DEALINGS IN THE SOFTWARE.
}

unit TB2Merge;

interface

uses
  Classes, SysUtils, Menus, Controls, ImgList, TB2Dock, TB2Item;

type
  { TTBMergeError is the exception all functions in this module throw.
  }
  TTBMergeError = class(Exception);

  { TTBUnmergeItem holds a single atomic operation for an "unmerge". This is
    done by simply moving the item back to its old parent and position.
  }
  PTBUnmergeItem = ^TTBUnmergeItem;
  TTBUnmergeItem = record
    Next: PTBUnmergeItem;     // Single linked list
    Item: TTBCustomItem;      // Which item
    Parent: TTBCustomItem;    // Old parent
    ParentIndex: Integer;     // Old parent index
  end;

  { These are the options for the merge process. They tell TBMergeItems
    what to do with a block of items having the same GroupIndex.
  }
  TTBMergeOption = (
    moKeepTarget,             // Keep non-matching target entries
    moRecursive,              // Recurse into matching items' submenus
    moMatchByCaption,         // Identify matching items by their caption
    moMatchByTag,             // Identify matching items by their tag
    moSeparatorAfterItems     // Separators shall belong to their preceding items
  );

  TTBMergeOptions = set of TTBMergeOption;

function  TBMergeItems(Target, Source: TTBCustomItem; Options: TTBMergeOptions): PTBUnmergeItem;
procedure TBUnmergeItems(Target, Source: TTBCustomItem; List: PTBUnmergeItem);
procedure TBFreeUnmergeItems(List: PTBUnmergeItem);
procedure TBFixImageList(Items: TTBCustomItem; Images: TCustomImageList);

type
  { TTBMergedItems is just an OOP wrapper for the functions above. Upon
    creation, the two sets of items are merged and they are automatically
    unmerged when the object is deleted.
  }
  TTBMergedItems = class(TObject)
  private
    FTarget: TComponent;
    FSource: TComponent;
    FUnmergeItems: PTBUnmergeItem;
    FOptions: TTBMergeOptions;

  public
    constructor Create(ATarget, ASource: TComponent; Options: TTBMergeOptions);
    destructor Destroy; override;

    procedure Merge;
    procedure Unmerge;
    procedure Dispose;

    property Target: TComponent read FTarget;
    property Source: TComponent read FSource;
    property UnmergeItems: PTBUnmergeItem read FUnmergeItems;
    property Options: TTBMergeOptions read FOptions;
  end;

type
  { Don't use a TTBToolbarMerger component directly, use the one returned
    by the function "ToolbarMerger".
  }
  TTBToolbarMerger = class(TComponent)
  private
    FMergedItems: TList;

    function GetCount: Integer;
    function GetItem(Index: Integer): TTBMergedItems;

  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure Merge(Target, Source: TComponent; Options: TTBMergeOptions);
    procedure Unmerge(Target, Source: TComponent);
    procedure UnmergeAll(Comp: TComponent);
    procedure Delete(Index: Integer);
    function  IsMerged(Target: TComponent): Integer;
    function  IsMergedWith(Source: TComponent): Integer;
    procedure Clear;

    property Count: Integer read GetCount stored false;
    property Items[Index: Integer]: TTBMergedItems read GetItem stored false;
  end;

function ToolbarMerger: TTBToolbarMerger;

implementation

{$B-,R-}

uses
  Windows, Forms;

{######################################################################
 Misc. declarations
 ######################################################################
}

{ TTBItemAccess is just a hack to get access to the protected members of
  TTBCustomItem, especially: "tbisSubmenu in TTBItemAccess(i).ItemStyle".
}
type
  TTBItemAccess = class(TTBCustomItem);

{ Notify the item about that it's going to be updated (a lot)
}
procedure BeginUpdateItem(Item: TTBCustomItem);
begin
  if Item <> nil then
  begin
    if Item.ParentComponent <> nil then
      if Item.ParentComponent is TTBCustomDockableWindow then
        TTBCustomDockableWindow(Item.ParentComponent).BeginUpdate;

    Item.ViewBeginUpdate;
  end;
end;

{ Notify the item that all updates are finished
}
procedure EndUpdateItem(Item: TTBCustomItem);
begin
  if Item <> nil then
  begin
    Item.ViewEndUpdate;

    if Item.ParentComponent <> nil then
      if Item.ParentComponent is TTBCustomDockableWindow then
        TTBCustomDockableWindow(Item.ParentComponent).EndUpdate;
  end;
end;

{ Get the root item for the given component
}
function GetComponentItems(Comp: TComponent): TTBCustomItem;
var
  Intf: ITBItems;
begin
  if Comp = nil then
    Result := nil
  else if Comp is TTBCustomItem then
    Result := TTBCustomItem(Comp)
  else if Comp.GetInterface(ITBItems, Intf) then
    Result := Intf.GetItems
  else
    Result := nil;
end;

{######################################################################
 Procedure/function interface (non OOP)
 ######################################################################
}

{ Sets the "Images" Property of *ALL* toolbar items to the one
  specified as parameter. }
procedure TBFixImageList(Items: TTBCustomItem; Images: TCustomImageList);
var
  Index: Integer;
  Item: TTBCustomItem;
begin
  if Images <> nil then
    for Index := Items.Count - 1 downto 0 do
    begin
      Item := Items.Items[Index];
      Item.Images := Images;
      if tbisSubmenu in TTBItemAccess(Item).ItemStyle then
        TBFixImageList(Item, Images);
    end;
end;

{ Free all memory associated with the given list of UnmergeItems.
}
procedure TBFreeUnmergeItems(List: PTBUnmergeItem);
var
  Head: PTBUnmergeItem;
begin
  while List <> nil do
  begin
    Head := List;
    List := Head^.Next;

    if (Head^.Item <> nil) and (Head^.Item.Parent = nil) then
      Head^.Item.Free;

    Dispose(Head);
  end;
end;

{ Unmerge the subitems of target and source, using the given list of
  UnmergeItems. While doing this, the list will be freed. The parameters
  Target and Source are same as for the TBMergeItems call that produced
  the list of PTBUnmergeItems.
}
procedure TBUnmergeItems(Target, Source: TTBCustomItem; List: PTBUnmergeItem);
var
  Op: PTBUnmergeItem;
begin
  if (Target <> nil) and (csDestroying in Target.ComponentState) then
    Target := nil;
  if (Source <> nil) and (csDestroying in Source.ComponentState) then
    Source := nil;

  BeginUpdateItem(Target);
  try
    BeginUpdateItem(Source);
    try
      try
        while List <> nil do
        begin
          Op := List;
          List := Op^.Next;

          if Target = nil then
          begin
            // Target was deleted meanwhile, source items are lost
            if Op^.Item.Parent = nil then
              Op^.Item.Free;
          end
          else if Op^.Item.Parent <> nil then
          begin
            // Source that was moved to target
            Op^.Item.Parent.Remove(Op^.Item);

            if Source <> nil then
              Op^.Parent.Insert(Op^.ParentIndex, Op^.Item)
            else
              Op^.Item.Free;
          end
          else
          begin
            // Target was hidden (moved to this queue)
            Op^.Parent.Insert(Op^.ParentIndex, Op^.Item);
          end;

          Dispose(Op);
        end;
      except
        TBFreeUnmergeItems(List);
        raise;
      end;
    finally
      EndUpdateItem(Source);
    end;
  finally
    EndUpdateItem(Target);
  end;
end;

{ Merge the subitems of target and source, using the given options. The return
  value is a list of "unmerge" UnmergeItems that will revert all modifications.
}
function TBMergeItems(Target, Source: TTBCustomItem; Options: TTBMergeOptions): PTBUnmergeItem;
var
  List: PTBUnmergeItem;

  { Find the end of the group of items from "Items" starting at index "Start".
    Upon exit, the parameter "Stop" is set to the index of the first item
    *AFTER* the found group and "Group" to the found "GroupIndex".

    If "Start" points to a valid item in the list, the value of "Group" is
    "Items.Items[Start].GroupIndex" and "Stop" is at least "Start+1".

    If "Start" points beyond the list, "Stop" is set equal to "Start".
  }
  procedure FindEndOfGroup(Items: TTBCustomItem; var Start: Integer; out Stop, Group: Integer);
  begin
    if not (moSeparatorAfterItems in Options) then
    begin
      // First skip over all separator items, i.e., find the "real" start
      Stop := Start;
      while (Stop < Items.Count) and
            (tbisSeparator in TTBItemAccess(Items.Items[Stop]).ItemStyle) do
        inc(Stop);

      if Stop = Items.Count then
        Group := 0
      else
      begin
        // We found the first item with a real group index
        Group := Items.Items[Stop].GroupIndex;
        inc(Stop);

        // Now collect all items having at least this group index
        while (Stop < Items.Count) and (Items.Items[Stop].GroupIndex <= Group) do
          inc(Stop);

        // If we did not reach the end, remove all trailing separator items
        if Stop < Items.Count then
          while (Stop > Start) and
                (tbisSeparator in TTBItemAccess(Items.Items[Stop - 1]).ItemStyle) do
            dec(Stop);
      end;
    end
    else if Start < Items.Count then
    begin
      Group := Items.Items[Start].GroupIndex;
      Stop := Start + 1;
      while (Stop < Items.Count) and (Items.Items[Stop].GroupIndex <= Group) do
        inc(Stop);
    end
    else
    begin
      Group := 0;
      Stop := Start;
    end;
  end;

  { Move one item from OldParent.Items[OldIndex] to its new position at
    NewParent.Items[NewIndex] and store the corresponding "unmerge"
    operation in our List. Returns true upon successful completion.
  }
  function MoveItem(NewParent: TTBCustomItem; NewIndex: Integer;
                    OldParent: TTBCustomItem; OldIndex: Integer): Boolean;
  var
    Op: PTBUnmergeItem;
  begin
    Result := (OldIndex >= 0) and (OldIndex < OldParent.Count);
    if Result then
    begin
      New(Op);
      try
        Op^.Next := List;
        Op^.Item := OldParent.Items[OldIndex];
        Op^.Parent := OldParent;
        Op^.ParentIndex := OldIndex;

        OldParent.Delete(OldIndex);

        if NewParent <> nil then
          try
            NewParent.Insert(NewIndex, Op^.Item);
          except
            OldParent.Insert(OldIndex, Op^.Item);
            raise;
          end;

        List := Op;
      except
        Dispose(Op);
        raise;
      end;
    end;
  end;

  { Move all items between SrcStart and SrcStop (excluding) to the target
    side, adjusting the index parameters accordingly.
  }
  procedure MoveItems(TgtItems: TTBCustomItem; var TgtStart, TgtStop: Integer;
                      SrcItems: TTBCustomItem; var SrcStart, SrcStop: Integer);
  begin
    while (SrcStart < SrcStop) and
          MoveItem(TgtItems, TgtStart, SrcItems, SrcStart) do
    begin
      dec(SrcStop);
      inc(TgtStart);
      inc(TgtStop);
    end;
  end;

  { Hide all items between SrcStart and SrcStop (excluding).
  }
  procedure HideItems(SrcItems: TTBCustomItem; var SrcStart, SrcStop: Integer);
  begin
    while (SrcStart < SrcStop) and
          MoveItem(nil, 0, SrcItems, SrcStart) do
      dec(SrcStop);
  end;

  { Returns the string used to identify a matching item.
  }
  function GetItemIdent(Item: TTBCustomItem): string;
  begin
    if moMatchByCaption in Options then
      Result := StripHotkey(Item.Caption)
    else if moMatchByTag in Options then
      Result := IntToStr(Item.Tag)
    else
      Result := Item.Name;
  end;

  { Look for a matching item for "Find" in the given range of items.
  }
  function FindMatchingItem(Items: TTBCustomItem; Start, Stop: Integer;
                            Find: TTBCustomItem): Integer;
  var
    LookFor: string;
  begin
    LookFor := GetItemIdent(Find);

    Result := -1;

    while (Start < Stop) and (Result < 0) do
    begin
      if CompareText(LookFor, GetItemIdent(Items.Items[Start])) = 0 then
        Result := Start;

      inc(Start);
    end;
  end;

  { Merge the subitems of TgtItems (the target) and SrcItems (the source)
  }
  procedure MergeItems(TgtItems, SrcItems: TTBCustomItem);
  var
    TgtStart, TgtStop, TgtGroup: Integer;
    SrcStart, SrcStop, SrcGroup: Integer;
    Match: Integer;
  begin
    TgtStart := 0;
    FindEndOfGroup(TgtItems, TgtStart, TgtStop, TgtGroup);

    SrcStart := 0;
    FindEndOfGroup(SrcItems, SrcStart, SrcStop, SrcGroup);

    while (TgtStart < TgtStop) and (SrcStart < SrcStop) do
    begin
      if TgtGroup < SrcGroup then
      begin
        // Target block's "GroupIndex" is less than the source block's, the
        // target block of items will be kept (no modification).
        TgtStart := TgtStop;
      end
      else if SrcGroup < TgtGroup then
      begin
        // Source block's "GroupIndex" is less than the target block's, the
        // source block will be inserted completely.
        MoveItems(TgtItems, TgtStart, TgtStop, SrcItems, SrcStart, SrcStop);
      end
      else
      begin
        if moKeepTarget in Options then
        begin
          // Add new entries from source to target and replace them resp.
          // merge the subitems of matching ones.
          while TgtStart < TgtStop do
          begin
            // Find match for the next item on the target side
            Match := FindMatchingItem(SrcItems, SrcStart, SrcStop, TgtItems.Items[TgtStart]);
            if Match < 0 then
            begin
              // No match found
              inc(TgtStart);
            end
            else if (moRecursive in Options) and
                    (tbisSubmenu in TTBItemAccess(SrcItems.Items[SrcStart]).ItemStyle) and
                    (tbisSubmenu in TTBItemAccess(TgtItems.Items[TgtStart]).ItemStyle) then
            begin
              // Recurse into both lists of subitems
              MergeItems(TgtItems.Items[TgtStart], SrcItems.Items[SrcStart]);
              inc(SrcStart);
              inc(TgtStart);
            end
            else
            begin
              // Hide old target item
              MoveItem(nil, 0, TgtItems, TgtStart);
              // Move source to target
              MoveItem(TgtItems, TgtStart, SrcItems, Match);
              dec(SrcStop);
              inc(TgtStart);
            end;
          end;
        end;

        // Replace target with source, i.e. hide target items and move source
        // items to the target side. For moKeepTarget, the target side is
        // already empty (TgtStart = TgtStop) and the remainder of the source
        // side must be copied completely.
        HideItems(TgtItems, TgtStart, TgtStop);
        MoveItems(TgtItems, TgtStart, TgtStop, SrcItems, SrcStart, SrcStop);
      end;

      if TgtStart >= TgtStop then
        // Find next group on target side
        FindEndOfGroup(TgtItems, TgtStart, TgtStop, TgtGroup);

      if SrcStart >= SrcStop then
        // Find next group on source side
        FindEndOfGroup(SrcItems, SrcStart, SrcStop, SrcGroup);
    end;

    // Either the target or the source side reached its end. Just copy
    // the remainding source items over to the end of the target side.
    SrcStop := SrcItems.Count;
    MoveItems(TgtItems, TgtStart, TgtStop, SrcItems, SrcStart, SrcStop);
  end;

begin
  // Do not merge components that are about to be destroyed
  if (Target = nil) or (csDestroying in Target.ComponentState) or
     (Source = nil) or (csDestroying in Source.ComponentState) then
  begin
    Result := nil;
    exit;
  end;

  BeginUpdateItem(Target);
  try
    BeginUpdateItem(Source);
    try
      List := nil;
      try
        if moRecursive in Options then
          include(Options, moKeepTarget);

        MergeItems(Target, Source);
      except
        TBUnmergeItems(Target, Source, List);
        raise;
      end;
    finally
      EndUpdateItem(Source);
    end;
  finally
    EndUpdateItem(Target);
  end;

  Result := List;
end;

{######################################################################
 TTBMergedItems
 ######################################################################
}

constructor TTBMergedItems.Create(ATarget, ASource: TComponent; Options: TTBMergeOptions);
begin
  inherited Create;

  FTarget := ATarget;
  FSource := ASource;
  FOptions := Options;
  FUnmergeItems := nil;

  Merge;
end;

destructor TTBMergedItems.Destroy;
begin
  Unmerge;

  inherited;
end;

procedure TTBMergedItems.Merge;
begin
  if FUnmergeItems = nil then
    FUnmergeItems := TBMergeItems(GetComponentItems(FTarget),
                                  GetComponentItems(FSource),
                                  FOptions);
end;

procedure TTBMergedItems.Unmerge;
var
  List: PTBUnmergeItem;
begin
  if FUnmergeItems <> nil then
  begin
    List := FUnmergeItems;
    FUnmergeItems := nil;
    TBUnmergeItems(GetComponentItems(FTarget),
                   GetComponentItems(FSource),
                   List);
  end;
end;

procedure TTBMergedItems.Dispose;
var
  List: PTBUnmergeItem;
begin
  if FUnmergeItems <> nil then
  begin
    List := FUnmergeItems;
    FUnmergeItems := nil;
    TBFreeUnmergeItems(List);
  end;
end;

{######################################################################
 TTBToolbarMerger
 ######################################################################
}

constructor TTBToolbarMerger.Create(AOwner: TComponent);
begin
  inherited;

  FMergedItems := TList.Create;
end;

destructor TTBToolbarMerger.Destroy;
begin
  Clear;
  FreeAndNil(FMergedItems);

  inherited;
end;

procedure TTBToolbarMerger.Notification(AComponent: TComponent; Operation: TOperation);
var
  Index: Integer;
  OldItem: TTBMergedItems;

  function ObjName(Obj: TComponent): string;
  begin
    if Obj = nil then
      Result := 'nil'
    else if Obj.Name <> '' then
      Result := Obj.Name
    else
      Result := Obj.ClassName + Format('(%p)', [Pointer(Obj)]);
  end;

  function ObjFullName(Obj: TComponent): string;
  begin
    if Obj.Owner = nil then
      Result := ObjName(Obj)
    else
      Result := ObjName(Obj.Owner) + '.' + ObjName(Obj);
  end;

  procedure GiveWarning(Item: TTBMergedItems);
  var
    s: string;
  resourcestring
    S_Warning = 'WARNING';
    S_Header = '{@}:'#13#10#13#10'Component {C} destroyed with'#13#10;
    S_ItemsInto = 'items still merged into {T}.';
    S_ItemsFrom = 'items still merged from {S}.';
    S_FormInfo = #13#10#13#10'You probably forgot to unmerge them in your'#13#10'{O}.FormDestroy event.';
  begin
    s := S_Header;
    if AComponent = Item.Source then
      s := s + S_ItemsInto
    else
      s := s + S_ItemsFrom;

    s := StringReplace(s, '{@}', ObjFullName(Self), [rfReplaceAll]);
    s := StringReplace(s, '{C}', ObjFullName(AComponent), [rfReplaceAll]);
    s := StringReplace(s, '{T}', ObjFullName(Item.Target), [rfReplaceAll]);
    s := StringReplace(s, '{S}', ObjFullName(Item.Source), [rfReplaceAll]);

    if OldItem.Source.Owner is TCustomForm then
      s := s + StringReplace(S_FormInfo, '{O}', ObjName(Item.Source.Owner), [rfReplaceAll]);

    { Raising an exception here *MAY* cause a complete crash.
    }
    Windows.MessageBox(0, PChar(s), PChar(S_Warning),
      MB_OK or MB_ICONWARNING or MB_SERVICE_NOTIFICATION);
  end;

begin
  inherited;

  if Operation <> opRemove then
    exit;

  for Index := Count - 1 downto 0 do
  begin
    OldItem := Items[Index];
    if (AComponent = OldItem.Target) or
       (AComponent = OldItem.Source) then
    begin
      if (not (csDestroying in OldItem.Target.ComponentState)) or
         (not (csDestroying in OldItem.Source.ComponentState)) then
        // At least one of both is not being destroyed
        GiveWarning(OldItem);

      Delete(Index);
    end;
  end;
end;

function TTBToolbarMerger.GetCount: Integer;
begin
  Result := FMergedItems.Count;
end;

function TTBToolbarMerger.GetItem(Index: Integer): TTBMergedItems;
begin
  Result := TTBMergedItems(FMergedItems[Index]);
end;

function TTBToolbarMerger.IsMerged(Target: TComponent): Integer;
begin
  Result := Count - 1;
  while (Result >= 0) and (Items[Result].Target <> Target) do
    dec(Result);
end;

function TTBToolbarMerger.IsMergedWith(Source: TComponent): Integer;
begin
  Result := Count - 1;
  while (Result >= 0) and (Items[Result].Source <> Source) do
    dec(Result);
end;

procedure TTBToolbarMerger.Merge(Target, Source: TComponent; Options: TTBMergeOptions);
var
  NewItem: TTBMergedItems;
resourcestring
  SSourceUsed = 'TTBToolbarMerger.Merge: Source is target of another merge operation';
  STargetUsed = 'TTBToolbarMerger.Merge: Target is source of another merge operation';
begin
  // Some sanity-checks
  if Application.Terminated or
     (Target = nil) or (csDestroying in Target.ComponentState) or
     (Source = nil) or (csDestroying in Source.ComponentState) or
     (Target = Source) then
    exit;

  // Check if source is target of another operation
  if IsMerged(Source) >= 0 then
    raise TTBMergeError.Create(SSourceUsed);

  // Check if target is source of another operation
  if IsMergedWith(Target) >= 0 then
    raise TTBMergeError.Create(STargetUsed);

  // If source is already source of another operation, unmerge that operation
  Unmerge(nil, Source);

  // If target is already target of another operation, unmerge that operation
  Unmerge(Target, nil);

  // Merge the NewItem
  NewItem := TTBMergedItems.Create(Target, Source, Options);

  if NewItem.UnmergeItems = nil then
    // Nothing done, no need to store it
    FreeAndNil(NewItem)
  else
  begin
    // Ask for notifications
    Target.FreeNotification(Self);
    Source.FreeNotification(Self);

    // Add it to the list
    FMergedItems.Add(NewItem);
  end;
end;

procedure TTBToolbarMerger.Delete(Index: Integer);
var
  OldItem: TTBMergedItems;
begin
  // Extract item from the list
  OldItem := Items[Index];
  FMergedItems.Delete(Index);

  // Remove the notifications we have set
  OldItem.Target.RemoveFreeNotification(Self);
  OldItem.Source.RemoveFreeNotification(Self);

  // This will also unmerge the item
  FreeAndNil(OldItem);
end;

procedure TTBToolbarMerger.Unmerge(Target, Source: TComponent);
var
  Index: Integer;
begin
  // Step through all unmerge sets
  for Index := Count - 1 downto 0 do
    if ((Target = nil) or (Items[Index].Target = Target)) and
       ((Source = nil) or (Items[Index].Source = Source)) then
      Delete(Index);
end;

procedure TTBToolbarMerger.UnmergeAll(Comp: TComponent);
var
  Index: Integer;
begin
  // Step through all unmerge sets
  for Index := Count - 1 downto 0 do
    if (Items[Index].Target = Comp) or (Items[Index].Source = Comp) then
      Delete(Index);
end;

procedure TTBToolbarMerger.Clear;
begin
  while Count > 0 do
    Delete(Count - 1);
end;

{######################################################################
 ToolbarMerger
 ######################################################################
}

type
  TGlobalToolbarMerger = class(TTBToolbarMerger)
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

{ The global variable we use as toolbar merger for all operations.

  Note: since GlobalToolbarMerger is owned by the global application object,
  there's no need to free it in a "finalization" block. It will be freed
  automatically as soon as the global application object is being freed.
}
var
  GlobalToolbarMerger: TTBToolbarMerger;

constructor TGlobalToolbarMerger.Create(AOwner: TComponent);
begin
  { NOTE: This is put before (and not after) the call to the inherited
    constructor to avoid double creation of the instance in some cases.
  }
  GlobalToolbarMerger := Self;
  inherited;
end;

destructor TGlobalToolbarMerger.Destroy;
begin
  inherited;
  { NOTE: This is put *AFTER* the inherited destructor to avoid
    re-creation of the instance in some rare cases.
  }
  GlobalToolbarMerger := nil;
end;

function ToolbarMerger: TTBToolbarMerger;
begin
  if GlobalToolbarMerger <> nil then
    Result := GlobalToolbarMerger
  else
    Result := TGlobalToolbarMerger.Create(Application);
end;

end.
