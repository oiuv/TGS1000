unit uAIPath;

interface

uses
   MapUnit;

type
   TPathNode = record
      f, h, g : Integer;
      x, y : Integer;
      pPrev, pNext : Pointer;
      pDirect : array[0..7] of Pointer;
   end;
   PTPathNode = ^TPathNode;

   TPathStack = record
      pNodePtr : PTPathNode;
      pNext : Pointer;
   end;
   PTPathStack = ^TPathStack;

   TSearchPathClass = class
      private
         m_pOpenNodes : PTPathNode;
         m_pClosedNodes : PTPathNode;

         m_pStack : PTPathStack;

         Maper : TMaper;

         procedure Push (pNode : PTPathNode);
         function Pop : PTPathNode;
         function isOpen (x, y : Integer) : PTPathNode;
         function isClose (x, y : Integer) : PTPathNode;                  
         procedure MakeChild (pN : PTPathNode; dx, dy : Integer);
         procedure makeChildSub (pNode : PTPathNode; x, y, dx, dy : Integer);         
         procedure makeDown (pT : PTPathNode);
      public
         constructor Create;
         destructor Destroy; override;
         procedure SetMaper (aMaper : TMaper);
         function FindPath (sx, sy, dx, dy : Integer) : PTPathNode;
         function GotoPath(x1, y1, x2, y2 : Integer; var x, y : Integer) : boolean;
   end;

var
   SearchPathClass : TSearchPathClass;

implementation

constructor TSearchPathClass.Create;
var
   i : Integer;
begin
   New (m_pOpenNodes);
   if m_pOpenNodes <> nil then begin
      m_pOpenNodes^.f := 0;
      m_pOpenNodes^.h := 0;
      m_pOpenNodes^.g := 0;
      m_pOpenNodes^.x := 0;
      m_pOpenNodes^.y := 0;
      m_pOpenNodes^.pPrev := nil;
      m_pOpenNodes^.pNext := nil;
      for i := 0 to 8 - 1 do begin
         m_pOpenNodes^.pDirect[i] := nil;
      end;
   end;
   New (m_pClosedNodes);
   if m_pClosedNodes <> nil then begin
      m_pClosedNodes^.f := 0;
      m_pClosedNodes^.h := 0;
      m_pClosedNodes^.g := 0;
      m_pClosedNodes^.x := 0;
      m_pClosedNodes^.y := 0;
      m_pClosedNodes^.pPrev := nil;
      m_pClosedNodes^.pNext := nil;
      for i := 0 to 8 - 1 do begin
         m_pClosedNodes^.pDirect[i] := nil;
      end;
   end;
   New (m_pStack);
   if m_pStack <> nil then begin
      m_pStack^.pNodePtr := nil;
      m_pStack^.pNext := nil;
   end;
end;

destructor TSearchPathClass.Destroy;
{
var
   pFN, pTN : PTPathNode;
   pFS, pTS : PTPathStack;
}
begin
   if m_pOpenNodes <> nil then begin
      Dispose (m_pOpenNodes);
   end;
   if m_pClosedNodes <> nil then begin
      Dispose (m_pClosedNodes);
   end;
   if m_pStack <> nil then begin
      Dispose (m_pStack);
   end;

   Inherited Destroy;
end;

procedure TSearchPathClass.SetMaper (aMaper : TMaper);
begin
   Maper := aMaper;
end;

procedure TSearchPathClass.push (pNode : PTPathNode);
var
   pData : PTPathStack;
begin
   New (pData);
   if pData <> nil then begin
      pData^.pNodePtr := pNode;
      pData^.pNext := m_pStack^.pNext;
      m_pStack^.pNext := PData;
   end;
end;

function TSearchPathClass.pop : PTPathNode;
var
   pN : PTPathNode;
   pData : PTPathStack;
begin
   Result := nil;
   try
      pData := m_pStack^.pNext;
      pN := pData^.pNodePtr;
      m_pStack^.pNext := pData^.pNext;
      Dispose (pData);
      Result := pN;
   except
   end;
end;

function TSearchPathClass.isOpen (x, y : Integer) : PTPathNode;
var
   pNode : PTPathNode;
begin
   Result := nil;
   pNode := m_pOpenNodes^.pNext;
   while pNode <> nil do begin
      if (pNode^.x = x) and (pNode^.y = y) then begin
         Result := pNode;
         exit;   
      end;
      pNode := pNode^.pNext;
   end;
end;

function TSearchPathClass.isClose (x, y : Integer) : PTPathNode;
var
   pNode : PTPathNode;
begin
   Result := nil;
   pNode := m_pClosedNodes^.pNext;
   while pNode <> nil do begin
      if (pNode^.x = x) and (pNode^.y = y) then begin
         Result := pNode;
         exit;
      end;
      pNode := pNode^.pNext;
   end;
end;

procedure TSearchPathClass.makeDown (pT : PTPathNode);
var
   i : Integer;
   pD, pF : PTPathNode;
begin
   for i := 0 to 8 - 1 do begin
      pD := pT^.pDirect[i];
      if pD = nil then break;
      if pD^.g > pT^.g + 1 then begin
         pD^.g := pT^.g + 1;
         pD^.f := pD^.g + pD^.h;
         pD^.pPrev := pT;
         push (pD);
      end;
   end;
   while m_pStack^.pNext <> nil do begin
      pF := pop();
      for i := 0 to 8 - 1 do begin
         pD := pF^.pDirect[i];
         if pD = nil then break;
         if pD^.g > pF^.g + 1 then begin
            pD^.g := pF^.g + 1;
            pD^.f := pD^.g + pD^.h;
            pD^.pPrev := pF;
            push(pD);
         end;
      end;
   end;
end;

procedure TSearchPathClass.makeChildSub (pNode : PTPathNode; x, y, dx, dy : Integer);
   procedure InsertNode (pT : PTPathNode);
   var
      pOne, pTwo : PTPathNode;
   begin
      if m_pOpenNodes^.pNext = nil then begin
         m_pOpenNodes^.pNext := pT;
         exit;
      end;
      pOne := m_pOpenNodes;
      pTwo := pOne^.pNext;
      while (pTwo <> nil) and (pTwo^.f < pT^.f) do begin
         pOne := pTwo;
         pTwo := pOne^.pNext;
      end;
      pT^.pNext := pTwo;
      pOne^.pNext := pT;
   end;
var
   i, g : Integer;
   pT, pN : PTPathNode;
begin
   g := pNode^.g + 1;
   pT := isOpen (x, y);
   if pT <> nil then begin
      for i := 0 to 8 - 1 do begin
         if pNode^.pDirect[i] = nil then break;
      end;
      pNode^.pDirect[i] := pT;
      if g < pT^.g then begin
         pT^.g := g;
         pT^.f := pT^.g + pT^.h;
         pT^.pPrev := pNode;
      end;
   end else begin
      pT := isClose (x, y);
      if pT <> nil then begin
         for i := 0 to 8 - 1 do begin
            if pNode^.pDirect[i] = nil then break;
         end;
         pNode^.pDirect[i] := pT;
         if g < pT^.g then begin
            pT^.g := g;
            pT^.f := pT^.g + pT^.h;
            pT^.pPrev := pNode;
            makeDown(pT);
         end;
      end else begin
         New (pN);
         if pN = nil then exit;
         pN^.g := x - dx;
         pN^.g := Abs(pN^.g);
         pN^.h := y - dy;
         pN^.h := Abs(pN^.h);
         pN^.h := pN^.g + pN^.h;
         pN^.g := g;
         pN^.f := g + pN^.h;
         pN^.x := x;
         pN^.y := y;
         pN^.pPrev := pNode;
         pN^.pNext := nil;
         for i := 0 to 8 - 1 do begin
            pN^.pDirect[i] := nil;
         end;

         InsertNode(pN);
         for i := 0 to 8 - 1 do begin
            if pNode^.pDirect[i] = nil then break;
         end;
         pNode^.pDirect[i] := pN;
      end;
   end;
end;

procedure TSearchPathClass.MakeChild (pN : PTPathNode; dx, dy : Integer);
var
   x, y : Integer;
begin
   x := pN^.x;
   y := pN^.y;

   dec(y);
   if Maper.isMoveable (x, y) or ((x = dx) and (y = dy)) then makeChildSub(pN, x, y, dx, dy);
   inc(x);
   if Maper.isMoveable (x, y) or ((x = dx) and (y = dy))  then makeChildSub(pN, x, y, dx, dy);
   inc(y);
   if Maper.isMoveable (x, y) or ((x = dx) and (y = dy))  then makeChildSub(pN, x, y, dx, dy);
   inc(y);
   if Maper.isMoveable (x, y) or ((x = dx) and (y = dy))  then makeChildSub(pN, x, y, dx, dy);
   dec(x);
   if Maper.isMoveable (x, y) or ((x = dx) and (y = dy))  then makeChildSub(pN, x, y, dx, dy);
   dec(x);
   if Maper.isMoveable (x, y) or ((x = dx) and (y = dy))  then makeChildSub(pN, x, y, dx, dy);
   dec(y);
   if Maper.isMoveable (x, y) or ((x = dx) and (y = dy))  then makeChildSub(pN, x, y, dx, dy);
   dec(y);
   if Maper.isMoveable (x, y) or ((x = dx) and (y = dy))  then makeChildSub(pN, x, y, dx, dy);
end;

function TSearchPathClass.FindPath (sx, sy, dx, dy : Integer) : PTPathNode;
var
   i, MaxTry : Integer;
   pS, pBest : PTPathNode;
begin
   Result := nil;

   New (pS);
   // MaxTry := Abs (dx - sx) * 1000 + Abs(dy - sy) * 1000 + 1;
   MaxTry := 20;
   pS^.g := 0;
   pS^.h := abs(dx - sx) + abs(dy - sy);
   pS^.f := pS^.g + pS^.h;
   pS^.x := sx;
   pS^.y := sy;
   pS^.pNext := nil;
   pS^.pPrev := nil;
   for i := 0 to 8 - 1 do begin
      pS^.pDirect[i] := nil;
   end;
   m_pOpenNodes^.pNext := pS;
   while true do begin
      pBest := m_pOpenNodes^.pNext;
      if pBest = nil then exit;
      if pBest^.g >= MaxTry then begin
         Result := pBest;
         exit;
      end;
      if (pBest^.x = dx) and (pBest^.y = dy) then begin
         Result := pBest;
         exit;
      end;
      m_pOpenNodes^.pNext := pBest^.pNext;
      pBest^.pNext := m_pClosedNodes^.pNext;
      m_pClosedNodes^.pNext := pBest;
      MakeChild (pBest, dx, dy);
   end;
end;

function TSearchPathClass.GotoPath(x1, y1, x2, y2 : Integer; var x, y : Integer) : boolean;
var
   // boflag : Boolean;
   pBest, pF, pT : PTPathNode;
begin
   Result := true;

   m_pOpenNodes^.pPrev := nil;
   m_pOpenNodes^.pNext := nil;
   m_pClosedNodes^.pPrev := nil;
   m_pClosedNodes^.pNext := nil;
   m_pStack^.pNodePtr := nil;
   m_pStack^.pNext := nil;

   pBest := FindPath(x1, y1, x2, y2);
   if pBest <> nil then begin
      while pBest^.g > 1 do pBest := pBest^.pPrev;
      x := pBest^.x;
      y := pBest^.y;
   end else begin
      Result := false;
   end;

   pF := m_pOpenNodes^.pNext;
   while pF <> nil do begin
      pT := pF;
      pF := pF^.pNext;
      Dispose (pT);
   end;
   pF := m_pClosedNodes^.pNext;
   while pF <> nil do begin
      pT := pF;
      pF := pF^.pNext;
      Dispose (pT);
   end;
end;

initialization
begin
   SearchPathClass := TSearchPathClass.Create;
end;

finalization
begin
   SearchPathClass.Free;
end;

end.
