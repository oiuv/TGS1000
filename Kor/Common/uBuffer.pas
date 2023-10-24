unit uBuffer;

interface

uses
   Classes, SysUtils;

const
   MAX_HAVE_PACKET = 8192;

type
   TBuffer = class
   private
      FPutSize, FGetSize : Integer;
      
      FSize : Integer;
      FCount : Integer;

      ReadPos, WritePos : Integer;
      BufferPtr : PChar;
   protected
   public
      constructor Create (aSize : Integer);
      destructor Destroy; override;

      procedure Clear;

      function View (aData : PChar; aSize : Integer) : Boolean;
      function Get (aData : PChar; aSize : Integer) : Boolean;
      function Put (aData : PChar; aSize : Integer) : Boolean;
      function Flush (aSize : Integer) : Boolean;

      property Count : Integer read FCount;

      property Size : Integer read FSize;
      property ReadAt : Integer read ReadPos;
      property WriteAt : Integer read WritePos;
      property PutSize : Integer read FPutSize;
      property GetSize : Integer read FGetSize;
   end;

   TPacketBuffer = class
   private
      FCount : Integer;

      ReadPos, WritePos : Integer;
      HavePacketSize : array [0..MAX_HAVE_PACKET - 1] of Integer;
      HavePacketBuffer : TBuffer;
   public
      constructor Create (aSize : Integer);
      destructor Destroy; override;

      procedure Clear;

      function View (aData : PChar) : Boolean;
      function Get (aData : PChar) : Boolean;
      function Put (aData : PChar; aSize : Integer) : Boolean;
      function Flush : Boolean;

      property Count : Integer read FCount;
   end;

implementation

constructor TBuffer.Create (aSize : Integer);
begin
   FGetSize := 0;
   FPutSize := 0;
   
   BufferPtr := nil;
   FSize := 0;
   FCount := 0;
   ReadPos := 0;
   WritePos := 0;

   if aSize <= 0 then exit;

   GetMem (BufferPtr, aSize);
   if BufferPtr = nil then exit;

   FSize := aSize;
end;

destructor TBuffer.Destroy;
begin
   if BufferPtr <> nil then begin
      FreeMem (BufferPtr, FSize);
   end;

   inherited Destroy;
end;

procedure TBuffer.Clear;
begin
   FCount := 0;
   ReadPos := 0;
   WritePos := 0;
end;

function TBuffer.View (aData : PChar; aSize : Integer) : Boolean;
var
   nSize, pSize : Integer;
begin
   Result := false;
   if aSize <= 0 then exit;
   if FCount < aSize then exit;

   if WritePos > ReadPos then begin
      Move ((BufferPtr + ReadPos)^, aData^, aSize);
   end else begin
      if aSize <= FSize - ReadPos then begin
         Move ((BufferPtr + ReadPos)^, aData^, aSize);
      end else begin
         nSize := FSize - ReadPos;
         pSize := aSize - nSize;
         Move ((BufferPtr + ReadPos)^, aData^, nSize);
         Move (BufferPtr^, (aData + nSize)^, pSize);
      end;
   end;
   Result := true;
end;

function TBuffer.Get (aData : PChar; aSize : Integer) : Boolean;
var
   nSize, pSize : Integer;
begin
   Result := false;
   if aSize <= 0 then exit;
   if FCount < aSize then exit;

//   FGetSize := FGetSize + aSize;

   if aSize <= FSize - ReadPos then begin
      Move ((BufferPtr + ReadPos)^, aData^, aSize);
      ReadPos := ReadPos + aSize;
   end else begin
      nSize := FSize - ReadPos;
      pSize := aSize - nSize;
      Move ((BufferPtr + ReadPos)^, aData^, nSize);
      Move (BufferPtr^, (aData + nSize)^, pSize);
      ReadPos := pSize;
   end;

   if ReadPos = FSize then ReadPos := 0;

   FCount := FCount - aSize;
   
   Result := true;
end;

function TBuffer.Flush (aSize : Integer) : Boolean;
var
   nSize, pSize : Integer;
begin
   Result := false;
   if aSize <= 0 then exit;
   if FCount < aSize then exit;

//   FGetSize := FGetSize + aSize;

   if aSize <= FSize - ReadPos then begin
      ReadPos := ReadPos + aSize;
   end else begin
      nSize := FSize - ReadPos;
      pSize := aSize - nSize;
      ReadPos := pSize;
   end;

   if ReadPos = FSize then ReadPos := 0;

   FCount := FCount - aSize;

   Result := true;
end;

function TBuffer.Put (aData : PChar; aSize : Integer) : Boolean;
var
   nSize, pSize : Integer;
begin
   Result := false;
   if aSize <= 0 then exit;
   if FSize - FCount < aSize then exit;

//   FPutSize := FPutSize + aSize;

   if aSize <= FSize - WritePos then begin
      Move (aData^, (BufferPtr + WritePos)^, aSize);
      WritePos := WritePos + aSize;
   end else begin
      nSize := FSize - WritePos;
      pSize := aSize - nSize;
      Move (aData^, (BufferPtr + WritePos)^, nSize);
      Move ((aDAta + nSize)^, BufferPtr^, pSize);
      WritePos := pSize;
   end;

   if WritePos = FSize then WritePos := 0;

   FCount := FCount + aSize;

   Result := true;
end;

// TPacketBuffer
constructor TPacketBuffer.Create (aSize : Integer);
begin
   FCount := 0;

   ReadPos := 0;
   WritePos := 0;
   FillChar (HavePacketSize, SizeOf (HavePacketSize), 0);

   HavePacketBuffer := TBuffer.Create (aSize);
end;

destructor TPacketBuffer.Destroy;
begin
   HavePacketBuffer.Free;
   inherited Destroy;
end;

procedure TPacketBuffer.Clear;
begin
   FCount := 0;
   ReadPos := 0;
   WritePos := 0;
   
   FillChar (HavePacketSize, SizeOf (HavePacketSize), 0);

   HavePacketBuffer.Clear;
end;

function TPacketBuffer.View (aData : PChar) : Boolean;
begin
   Result := false;
   
   if FCount <= 0 then exit;

   Result := HavePacketBuffer.View (aData, HavePacketSize[ReadPos]);
end;

function TPacketBuffer.Get (aData : PChar) : Boolean;
begin
   Result := false;
   
   if FCount <= 0 then exit;

   if HavePacketBuffer.Get (aData, HavePacketSize[ReadPos]) = false then exit;
   HavePacketSize[ReadPos] := 0;
   Inc (ReadPos);
   Dec (FCount);
   if ReadPos >= MAX_HAVE_PACKET then ReadPos := 0;

   Result := true;
end;

function TPacketBuffer.Put (aData : PChar; aSize : Integer) : Boolean;
begin
   Result := false;

   if FCount >= MAX_HAVE_PACKET then exit;

   if HavePacketBuffer.Put (aData, aSize) = false then exit;
   HavePacketSize[WritePos] := aSize;
   Inc (WritePos);
   Inc (FCount);
   if WritePos >= MAX_HAVE_PACKET then WritePos := 0;

   Result := true;
end;

function TPacketBuffer.Flush : Boolean;
begin
   Result := false;
   if FCount <= 0 then exit;

   if HavePacketBuffer.Flush (HavePacketSize[ReadPos]) = false then exit;
   HavePacketSize [ReadPos] := 0;
   Inc (ReadPos);
   Dec (FCount);
   if ReadPos >= MAX_HAVE_PACKET then ReadPos := 0;

   Result := true;
end;

end.
