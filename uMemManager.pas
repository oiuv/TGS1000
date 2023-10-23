unit uMemManager;

interface

uses
   Classes, SysUtils, BasicObj, uUser, uMonster, uNpc, uGuild, uGuildSub;

type
   TMemData = record
      StartAddr : Pointer;
      AllocSize : Integer;
   end;
   PTMemData = ^TMemData;

   TMemManager = class
   private
      DataList : TList;
   public
      constructor Create;
      destructor Destroy; override;

      function FindAllocData (aAddr : Pointer; aSize : Integer) : PTMemData; 

      function CreateTUser : TUser;
      procedure FreeTUser (aUser : TUser);

      function CreateTMonster : TMonster;
      procedure FreeTMonster (aMonster : TMonster);

      function CreateTNpc : TNpc;
      procedure FreeTNpc (aNpc : TNpc);

      function CreateTItemObject : TItemObject;
      procedure FreeTItemObject (aItemObject : TItemObject);

      function CreateTDynamicObject : TDynamicObject;
      procedure FreeTDynamicObject (aDynamicObject : TDynamicObject);

      function CreateTGuildObject : TGuildObject;
      procedure FreeTGuildObject (aGuildObject : TGuildObject);

      function CreateTGuildNpc : TGuildNpc;
      procedure FreeTGuildNpc (aGuildNpc : TGuildNpc);
   end;

   procedure _Move (const Source; var Dest; Count: Integer);

var
   MemManager : TMemManager;

implementation

uses
   SVMain;

procedure _Move (const Source; var Dest; Count: Integer);
begin
   Move (Source, Dest, Count);
end;   

constructor TMemManager.Create;
begin
   DataList := TList.Create;
end;

destructor TMemManager.Destroy;
var
   i : Integer;
   pd : PTMemData;
begin
   if DataList.Count > 0 then begin
      frmMain.WriteLogInfo (format ('Found remained TMemData (%d)', [DataList.Count]));
   end;

   for i := 0 to DataList.Count - 1 do begin
      pd := DataList.Items [i];
      Dispose (pd);
   end;
   DataList.Clear;
   DataList.Free;

   inherited Destroy;
end;

function TMemManager.FindAllocData (aAddr : Pointer; aSize : Integer) : PTMemData;
var
   i : Integer;
   pd : PTMemData;
begin
   for i := 0 to DataList.Count - 1 do begin
      pd := DataList.Items [i];
      if pd^.StartAddr = aAddr then begin
         if pd^.AllocSize = aSize then begin
            Dispose (pd);
            DataList.Delete (i);
            exit;
         end;
      end;
   end;

   frmMain.WriteLogInfo ('Cannot find TMemData (TUser)');
end;

function TMemManager.CreateTUser : TUser;
var
   pd : PTMemData;
   User : TUser;
begin
   New (pd);
   User := TUser.Create;
   pd^.StartAddr := User;
   pd^.AllocSize := SizeOf (TUser);
   DataList.Add (pd);
   Result := User;
end;

function TMemManager.CreateTMonster : TMonster;
var
   pd : PTMemData;
   Monster : TMonster;
begin
   New (pd);
   Monster := TMonster.Create;
   pd^.StartAddr := Monster;
   pd^.AllocSize := SizeOf (TMonster);
   DataList.Add (pd);
   Result := Monster;
end;

function TMemManager.CreateTNpc : TNpc;
var
   pd : PTMemData;
   Npc : TNpc;
begin
   New (pd);
   Npc := TNpc.Create;
   pd^.StartAddr := Npc;
   pd^.AllocSize := SizeOf (TNpc);
   DataList.Add (pd);
   Result := Npc;
end;

function TMemManager.CreateTItemObject : TItemObject;
begin
   Result := TItemObject.Create;
end;

function TMemManager.CreateTDynamicObject : TDynamicObject;
begin
   Result := TDynamicObject.Create;
end;

function TMemManager.CreateTGuildObject : TGuildObject;
begin
   Result := TGuildObject.Create;
end;

function TMemManager.CreateTGuildNpc : TGuildNpc;
begin
   Result := TGuildNpc.Create;
end;

procedure TMemManager.FreeTUser (aUser : TUser);
begin
   FindAllocData (aUser, SizeOf (TUser));
   aUser.Free;
end;

procedure TMemManager.FreeTMonster (aMonster : TMonster);
begin
   FindAllocData (aMonster, SizeOf (TMonster));
   aMonster.Free;
end;

procedure TMemManager.FreeTNpc (aNpc : TNpc);
begin
   FindAllocData (aNpc, SizeOf (TNpc));
   aNpc.Free;
end;

procedure TMemManager.FreeTItemObject (aItemObject : TItemObject);
begin
   aItemObject.Free;
end;

procedure TMemManager.FreeTDynamicObject (aDynamicObject : TDynamicObject);
begin
   aDynamicObject.Free;
end;

procedure TMemManager.FreeTGuildObject (aGuildObject : TGuildObject);
begin
   aGuildObject.Free;
end;

procedure TMemManager.FreeTGuildNpc (aGuildNpc : TGuildNpc);
begin
   aGuildNpc.Free;
end;

initialization
begin
   MemManager := TMemManager.Create;
end;

finalization
begin
   MemManager.Free;
end;

end.
