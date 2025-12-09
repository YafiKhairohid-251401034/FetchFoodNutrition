program FetchFoodNutrition;

{$mode objfpc}{$H+}
uses
  SysUtils, fphttpclient, jsonparser, fpjson, opensslsockets;

type
  productHasil = record
    nama: string;
    merek: string;
    calories: real;
    fat: real;
    carbo: real;
    protein: real;
end;
  productArrayType = array[1..99] of productHasil;

procedure welcome;
begin
  Writeln('======================================');
  Writeln('            SELAMAT DATANG            ');
  Writeln('======================================');
end;

var
  products: productArrayType;
  FoodName, URL, Response: string;
  JSONData, Product: TJSONData;
  ProductsArray: TJSONArray;

  i, n: integer;

label checkpointN;

function insertProducts(baseArray: TJSONArray; n: integer): productArrayType;
var
  i: integer;
  Nutriments: TJSONData;
  res: array[1..99] of productHasil;
begin
  for i := 1 to n do
    begin
      Product := baseArray.items[i];
      res[i].nama := Product.FindPath('product_name').AsString;
      res[i].merek := Product.FindPath('brands').AsString;
      Nutriments := Product.FindPath('nutriments');
      res[i].calories := Nutriments.FindPath('energy-kcal_100g').AsFloat;
      res[i].fat := Nutriments.FindPath('fat_100g').AsFloat;
      res[i].carbo := Nutriments.FindPath('carbohydrates_100g').AsFloat;
      res[i].protein := Nutriments.FindPath('proteins_100g').AsFloat;
    end;
  insertProducts := res;
end;

begin
  welcome;
  write('Masukkan nama makanan: ');
  readLn(FoodName);
  checkpointN:
  write('Masukkan jumlah makanan yang ingin dikeluarkan (maksimal 16)');
  readln(n);
  if n > 16 then goto checkpointN
  else if n < 1 then goto checkpointN;

  FoodName := StringReplace(FoodName, ' ', '%20', [rfReplaceAll]);

  URL := 'https://world.openfoodfacts.org/cgi/search.pl?search_terms='
         + FoodName + '&search_simple=1&action=process&json=1';

  try
    Response := TFPHTTPClient.SimpleGet(URL);

    JSONData := GetJSON(Response);

    ProductsArray := TJSONArray(JSONData.FindPath('products'));

    if (ProductsArray = nil) or (ProductsArray.Count = 0) then
    begin
      Writeln('Tidak ditemukan produk untuk pencarian tersebut.');
      Exit;
    end;

    products := insertProducts(ProductsArray, n);

    for i := 1 to n do
    begin
      Writeln;
      Writeln('=== Informasi Produk ===');
      Writeln('Nama: ', products[i].nama);
      Writeln('Merek: ', products[i].merek);
      Writeln;
      Writeln('=== Nutrisi per 100g ===');

      Writeln('Kalori: ', products[i].calories:0:2);

      Writeln('Lemak: ', products[i].fat:0:2);

      Writeln('Karbohidrat: ', products[i].carbo:0:2);

      Writeln('Protein: ', products[i].protein:0:2);
    end;
  except
    on E: Exception do
      Writeln('Terjadi kesalahan: ', E.Message);
  end;
end.