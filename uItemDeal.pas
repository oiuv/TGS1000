unit uItemDeal;

interface

uses
   Classes, SysUtils, uKeyClass, DefType;

type
   TItemDealData = record
      boSold : Boolean;
      
      ItemName : String [20];
      ItemCount : Integer;
      ItemColor : Integer;

      ItemOwner : String [20];
      ItemCustomer : String [20];
      
      PriceName : String [20];
      PriceCount : Integer;

      GetItemDate : TDateTime;
      SellItemDate : TDateTime;
   end;
   PTItemDealData = ^TItemDealData;

   TItemDeal = class
   private
      DataList : TList;
      NameKey : TStringKeyClass;
      ItemNameKey : TStringKeyClass;
   public
      constructor Create;
      destructor Destroy; override;

      procedure Clear;

      function LoadFromFile (aFileName : String) : Boolean;
      function SaveToFile (aFileName : String) : Boolean;

      function RegistItem (var aItemData : TItemData; aOwner : String; aPriceItem : String; aPriceCount : Integer) : Boolean;
      function UnRegistItem (var aItemData : TItemData; aOwner : String; aPriceItem : String; aPriceCount : Integer) : Boolean;
      function SellItem (var aItemData : TItemData; aCustomer : String) : Boolean;
   end;

implementation

constructor TItemDeal.Create;
begin
   DataList := TList.Create;
   NameKey := TStringKeyClass.Create;
   ItemNameKey := TStringKeyClass.Create;
end;

destructor TItemDeal.Destroy;
begin
   Clear;
   NameKey.Free;
   ItemNameKey.Free;
   DataList.Free;
   
   inherited Destroy;
end;

procedure TItemDeal.Clear;
var
   i : Integer;
   pd : PTItemDealData;
begin
   for i := 0 to DataList.Count - 1 do begin
      pd := DataList.Items [i];
      Dispose (pd);
   end;
   DataList.Clear;
   NameKey.Clear;
   ItemNameKey.Clear;
end;

function TItemDeal.LoadFromFile (aFileName : String) : Boolean;
begin
   Result := false;

   if not FileExists (aFileName) then exit;

   Result := true;
end;

function TItemDeal.SaveToFile (aFileName : String) : Boolean;
begin
   Result := false;
end;

function TItemDeal.RegistItem (var aItemData : TItemData; aOwner : String; aPriceItem : String; aPriceCount : Integer) : Boolean;
begin
   Result := false;
end;

function TItemDeal.UnRegistItem (var aItemData : TItemData; aOwner : String; aPriceItem : String; aPriceCount : Integer) : Boolean;
begin
   Result := false;
end;

function TItemDeal.SellItem (var aItemData : TItemData; aCustomer : String) : Boolean;
begin
   Result := false;
end;

end.
