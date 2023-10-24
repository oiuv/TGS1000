unit uEasyList;

interface

uses
   Classes;

type
   PTEasyNode = ^TEasyNode;
   TEasyNode = record
      Prev : PTEasyNode;
      Next : PTEasyNode;
      Data : Pointer;
   end;

   TEasyList = class
   private
      TopNode, BottomNode : PTEasyNode;
      FCount : Integer;
   protected
      function Get (aIndex : Integer) : Pointer;
   public
      constructor Create;
      destructor Destroy; override;

      procedure Clear;

      procedure Add (aData : Pointer);
      procedure Insert (aData : Pointer; aIndex : Integer);
      procedure Delete (aIndex : Integer);

      property Count : Integer read FCount;
      property Items[aIndex : Integer] : Pointer read Get;
   end;

implementation

constructor TEasyList.Create;
begin
   FCount := 0;

   TopNode := nil;
   BottomNode := nil;
end;

destructor TEasyList.Destroy;
begin
   Clear;
   inherited Destroy;
end;

procedure TEasyList.Clear;
var
   Node : PTEasyNode;
begin
   while TopNode <> nil do begin
      Node := TopNode^.Next;
      Dispose (TopNode);
      Dec (FCount);
      TopNode := Node;
   end;
   BottomNode := nil;
end;

function TEasyList.Get (aIndex : Integer) : Pointer;
var
   i : Integer;
   Node : PTEasyNode;
begin
   Result := nil;

   if (aIndex < 0) or (aIndex >= FCount) then exit;

   Node := TopNode;
   for i := 0 to aIndex - 1 do begin
      Node := Node^.Next;
   end;

   Result := Node^.Data;
end;

procedure TEasyList.Add (aData : Pointer);
var
   Node : PTEasyNode;
begin
   New (Node);

   Node^.Next := nil;
   Node^.Data := aData;

   if BottomNode = nil then begin
      Node^.Prev := nil;
      TopNode := Node;
      BottomNode := Node;
   end else begin
      BottomNode^.Next := Node;
      Node^.Prev := BottomNode;
      BottomNode := Node;
   end;

   Inc (FCount);
end;

procedure TEasyList.Insert (aData : Pointer; aIndex : Integer);
var
   Node, prevNode, nextNode : PTEasyNode;
begin
   nextNode := Items [aIndex];
   if nextNode = nil then exit;

   prevNode := nextNode^.Prev;

   New (Node);
   Node^.Data := aData;

   nextNode^.Prev := Node;
   if prevNode = nil then begin
      Node^.Prev := nil;
      Node^.Next := nextNode;

      TopNode := Node;
   end else begin
      prevNode^.Next := Node;

      Node^.Prev := prevNode;
      Node^.Next := nextNode;
   end;

   Inc (FCount);
end;

procedure TEasyList.Delete (aIndex : Integer);
var
   i : Integer;
   Node, prevNode, nextNode : PTEasyNode;
begin
   if aIndex >= FCount then exit;

   Node := TopNode;
   for i := 0 to aIndex - 1 do begin
      Node := Node^.Next;
   end;

   prevNode := Node^.Prev;
   nextNode := Node^.Next;

   if (prevNode = nil) and (nextNode = nil) then begin
      TopNode := nil;
      BottomNode := nil;
   end else if prevNode = nil then begin
      nextNode^.Prev := nil;
      TopNode := nextNode;
   end else if nextNode = nil then begin
      prevNode^.Next := nil;
      BottomNode := prevNode;
   end else begin
      prevNode^.Next := nextNode;
      nextNode^.Prev := prevNode;
   end;

   Dispose (Node);

   Dec (FCount);
end;

end.
