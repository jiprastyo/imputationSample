# imputationSample

## Deskripsi
imputationSample 
merupakan paket program R untuk memilih baris-baris dalam suatu mikrodata, 
berdasarkan target jumlah data tertimbang yang telah ditentukan sebelumnya, berdasar kriteria/filter tertentu.

Paket ini mendukung berbagai kasus khusus, seperti:
- Kriteria penentuan/filter tidak menemukan baris data yang sesuai,
- Jumlah agregat data tertimbang di mikrodata lebih kecil dari target,
- Multi target jumlah agregat data tertimbang dalam satu kriteria yang sama.

## Instalasi
```
install.packages("devtools")
devtools::install_github("jiprastyo/imputationSample")
```

## Penggunaan
Terdapat tiga fungsi utama dalam package ini:
1. `buatfilter()` atau `create_filter()` digunakan untuk membuat filter yang diinginkan
2. `penanda()` atau `imputation_sample()` digunakan untuk memilih sampel imputasi dari filter yang telah dibuat dengan total weight tertentu
3. `imputasi()` atau `mutate_sample()` digunakan untuk mengubah nilai atribut-atribut tertentu dari sampel yang telah dipilih yang teridentifikasi dengan flag tertentu

Versi paket yang terinstal dapat dicek dengan:
```r
packageVersion("imputationSample")
```

## Fungsi Utama

**1. buatfilter() atau create_filter()**  
Membuat filter untuk digunakan pada `penanda()`/`imputation_sample()` (baru: `buatfilter`, lama: `create_filter`).
Argumen yang dapat digunakan:
- `...` satu atau lebih kondisi logika yang akan di-AND-kan

**2. penanda() atau imputation_sample()**  
Memilih sampel imputasi dan memberi flag (baru: `penanda`, lama: `imputation_sample`). Argumen yang dapat digunakan:
- `d` atau `x` data
- `f` atau `filters` filter
- `wsum` atau `weight_aggregate` target weight
- `wvar` atau `weight_col` kolom weight
- `i` atau `iter` iterasi
- `flag` atau `sample_flag` target baris data

**3. imputasi() atau mutate_sample()**  
Mengubah atribut pada baris dengan flag tertentu (baru: `imputasi`, lama: `mutate_sample`). Argumen yang dapat digunakan:
- `d` atau `x` data
- `flag` atau `sample_flag` target baris data
- `...` pasangan `kolom = nilai_baru` (bisa lebih dari satu)

## Implementasi

```r
library(imputationSample)

# Lihat data dummy
survei_dummy
#> # A tibble: 3,727 x 225
#>   urutan tahun Weight_R SMT   KODE_PROV NAMA_PROV KODE_KAB NAMA_KAB KLASIFIKASI ...
#>    <dbl> <dbl>    <dbl> <chr> <dbl+lbl> <chr>        <dbl> <chr>    <dbl+lbl>   ...
#> 1     12 20182     1078 1     11        ACEH             1 SIMEULUE 2           ...
#> 2     22 20182      666 1     11        ACEH             1 SIMEULUE 2           ...
#> 3     27 20182      508 1     11        ACEH             1 SIMEULUE 2           ...
#> # ... with 3,724 more rows, and 216 more variables

# Buat filter (baru: buatfilter, lama: create_filter) untuk memilih sampel acak
# dari provinsi ACEH atau SUMATERA BARAT dengan klasifikasi Perkotaan
my_filter <- buatfilter( # atau create_filter()
  NAMA_PROV == "ACEH" | NAMA_PROV == "SUMATERA BARAT",
  KLASIFIKASI == 1
)

# Memilih sampel (baru: penanda, lama: imputation_sample) dari filter yang telah dibuat
survei_dummy <- penanda(
  d = survei_dummy,
  f = my_filter,
  wsum = 45000,
  wvar = Weight_R,
  i = 10,
  flag = "aceh_sumbar_1"
)
#> Total data 3.727 / terfilter 485 / terpilih imputasi 42 dengan 10 iterasi, total weight: 44.987 (99.9711%)
#> Baris terpilih ditandai flag=aceh_sumbar_1.

# Mengubah atribut (baru: imputasi, lama: mutate_sample) pada sampel terpilih
survei_dummy <- imputasi(
  d = survei_dummy,
  flag = "aceh_sumbar_1",
  kategori = 1,
  jenisKegiatan = 2
)
#> Nilai atribut kategori dari sampel terpilih dengan flag: aceh_sumbar_1 telah diubah menjadi: 1
#> Nilai atribut jenisKegiatan dari sampel terpilih dengan flag: aceh_sumbar_1 telah diubah menjadi: 2
```

### Multi-flag dalam Filter yang Sama (Prioritas)

Skenario: kita ingin dua tahap pemilihan dari filter yang sama. Tahap pertama adalah prioritas utama,
tahap kedua mengambil sisa data yang belum terpilih (flag = 0 atau NA) dan memberi flag berbeda.
Jika `wsum`/`weight_aggregate` atau `i`/`iter` hanya satu nilai, nilai tersebut akan digunakan untuk semua tahap.

```r
survei_dummy <- penanda( # baru: penanda, lama: imputation_sample
  d = survei_dummy,
  f = my_filter,
  wsum = c(30000, 15000),
  wvar = Weight_R,
  i = 10,
  flag = c("prioritas_1", "prioritas_2")
)
```

### Penanganan Weight Tidak Mencukupi

Apabila total weight yang tersedia dalam data terfilter tidak mencukupi target `wsum`/`weight_aggregate`, fungsi akan otomatis memilih seluruh data terfilter dan memberikan peringatan:

```r
survei_dummy <- penanda( # baru: penanda, lama: imputation_sample
  d = survei_dummy,
  f = my_filter,
  wsum = 999999,
  wvar = Weight_R,
  i = 10,
  flag = "all_selected"
)
#> âš  WARNING!
#> [NAMA_PROV == "ACEH" | NAMA_PROV == "SUMATERA BARAT", KLASIFIKASI == 1] tidak mencukupi target.
#> Weight tersedia 485.230 / target 999.999 / kekurangan 514.769.
#> Semua data terfilter dipilih.
#> Total data 3.727 / terfilter 485 / terpilih imputasi 485 dengan 0 iterasi
#>   (seluruh data terfilter), total weight: 485.230 (48.5233%)
#> Baris terpilih ditandai flag=all_selected.
```

## Changelog

### v0.2.6
- Pembaruan struktur README dan penjelasan fungsi
- Penambahan informasi attribution fork
- Perubahan argumen formal `imputasi()` ke `d` dan `flag` (argumen lama tetap didukung)

### v0.2.5
- Dukungan multi-flag dalam filter yang sama (pemilihan bertahap berdasarkan prioritas)
- `weight_aggregate` dan `iter` menerima vektor (atau satu nilai yang direplikasi) untuk tiap tahap
- Pembaruan dokumentasi dan contoh penggunaan
- Penambahan alias fungsi baru: `buatfilter()`, `penanda()`, `imputasi()` (nama lama tetap tersedia)
- Perubahan nama argumen formal `penanda()` ke `d`, `f`, `wsum`, `wvar`, `i`, `flag` (argumen lama tetap didukung)

### v0.2.4
- Penyesuaian minor dokumentasi

### v0.2.3
- Perbaikan kompatibilitas R 4.5: menggunakan `cli::col_red()` untuk warna merah, menghindari mixed escape types dalam string literal
- Setiap baris pesan warning menggunakan `message()` terpisah

### v0.2.2
- Perbaikan kompatibilitas R 4.5: mengganti `\033` (octal) dengan `\x1b` (hex) pada ANSI escape codes

### v0.2.1
- Perbaikan format angka: mengganti `formatC` dengan regex-based separator untuk menghilangkan warning `prettyNum`
- Pesan warning menggunakan `message()` (bukan `warning()`) untuk output yang lebih bersih tanpa prefix function call
- Format pesan `âš  WARNING!` berwarna merah pada baris tersendiri
- Newline setelah kalimat pada pesan warning untuk keterbacaan
- Pesan flag dipersingkat menjadi `Baris terpilih ditandai flag=X.`

### v0.2.0
- Penanganan kasus filter kosong (tidak lagi error, mengembalikan data tanpa perubahan)
- Penanganan kasus target weight lebih kecil dari weight terkecil (warning, bukan error)
- Penanganan kasus total weight tidak mencukupi target (seluruh data terfilter dipilih otomatis, tanpa iterasi)
- Optimasi kode: penggunaan `dplyr::pull()` langsung, `dplyr::bind_rows()` pada `mutate_sample()`
- Perbaikan contoh dokumentasi: `%in% c(...)` (sebelumnya tanpa `c()`)
- Format pesan output diperbarui
- Dependency `foreign` dihapus dari `Depends`

### v0.1.1
- Rilis awal

## Credits dan Attribution
- [@im-perativa](https://github.com/im-perativa) - penulis dan pengelola asli
- [@easbi](https://github.com/easbi) - fork pertama
- [@jiprastyo](https://github.com/jiprastyo) - fork kedua / pengembangan saat ini

## Bantuan
Apabila ditemukan bug atau masalah lainnya, silakan buat issue di [GitHub](https://github.com/easbi/imputationSample/issues)
