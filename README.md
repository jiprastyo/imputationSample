# imputationSample

## Deskripsi
`imputationSample` merupakan package dalam bahasa pemrograman **R** yang dapat digunakan untuk memilih sampel imputasi dengan weight yang telah ditentukan.

Package ini mendukung penanganan kasus-kasus khusus seperti:
- Filter yang tidak menghasilkan data
- Target weight yang terlalu kecil
- Total weight tersedia yang tidak mencukupi target (seluruh data terfilter akan dipilih otomatis)

## Instalasi
```
install.packages("devtools")
devtools::install_github("jiprastyo/imputationSample")
```

## Penggunaan
Terdapat tiga fungsi utama dalam package ini:
- `buatfilter()` atau `create_filter()` digunakan untuk membuat filter yang diinginkan
- `penanda()` atau `imputation_sample()` digunakan untuk memilih sampel imputasi dari filter yang telah dibuat dengan total weight tertentu
- `imputasi()` atau `mutate_sample()` digunakan untuk mengubah nilai atribut-atribut tertentu dari sampel yang telah dipilih yang teridentifikasi dengan flag tertentu

Versi paket yang terinstal dapat dicek dengan:
```r
packageVersion("imputationSample")
```

## Fungsi Utama

**buatfilter() atau create_filter()**  
Membuat filter untuk digunakan pada `penanda()`/`imputation_sample()`.
Argumen yang dapat digunakan:
- `...` satu atau lebih kondisi logika yang akan di-AND-kan

**penanda() atau imputation_sample()**  
Memilih sampel imputasi dan memberi flag. Argumen yang dapat digunakan:
- `d` data (alias: `x`)
- `f` filter (alias: `filters`)
- `wsum` target weight (alias: `weight_aggregate`)
- `wvar` kolom weight (alias: `weight_col`)
- `i` iterasi (alias: `iter`)
- `flag` identitas sampel (alias: `sample_flag`)

**imputasi() atau mutate_sample()**  
Mengubah atribut pada baris dengan flag tertentu. Argumen yang dapat digunakan:
- `x` data
- `sample_flag` flag target
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

# Buat filter untuk memilih sampel acak dari provinsi ACEH atau SUMATERA BARAT
# dengan klasifikasi Perkotaan
my_filter <- buatfilter( # atau create_filter()
  NAMA_PROV == "ACEH" | NAMA_PROV == "SUMATERA BARAT",
  KLASIFIKASI == 1
)

# Memilih sampel acak dari filter yang telah dibuat
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

# Mengubah atribut sampel terpilih
survei_dummy <- imputasi(
  x = survei_dummy,
  sample_flag = "aceh_sumbar_1",
  kategori = 1,
  jenisKegiatan = 2
)
#> Nilai atribut kategori dari sampel terpilih dengan flag: aceh_sumbar_1 telah diubah menjadi: 1
#> Nilai atribut jenisKegiatan dari sampel terpilih dengan flag: aceh_sumbar_1 telah diubah menjadi: 2
```

### Tips Pemendekan Argumen

Penamaan variabel bebas, tapi pastikan tidak memakai nama yang sama untuk objek berbeda.
Berikut alias final yang disepakati:
- `d` untuk data
- `f` untuk filters
- `wsum` untuk weight_aggregate
- `wvar` untuk weight_col
- `i` untuk iter
- `flag` untuk sample_flag

Contoh pemakaian (menggunakan `penanda()`, dapat diganti `imputation_sample()`):

```r
d <- survei_dummy
f <- buatfilter(level_1_co == 12, level_2_co == 11, k10 >= 15)
wsum <- c(5000, 6000)
wvar <- w_finalR5
i <- 10
flag <- c("status4_1", "status4_2")

d <- penanda(
  d = d,
  f = f,
  wsum = wsum,
  wvar = wvar,
  i = i,
  flag = flag
)
```

### Multi-flag dalam Filter yang Sama (Prioritas)

Skenario: kita ingin dua tahap pemilihan dari filter yang sama. Tahap pertama adalah prioritas utama,
tahap kedua mengambil sisa data yang belum terpilih (flag = 0 atau NA) dan memberi flag berbeda.
Jika `weight_aggregate` atau `iter` hanya satu nilai, nilai tersebut akan digunakan untuk semua tahap.

```r
survei_dummy <- penanda( # atau imputation_sample()
  d = survei_dummy,
  f = my_filter,
  wsum = c(30000, 15000),
  wvar = Weight_R,
  i = 10,
  flag = c("prioritas_1", "prioritas_2")
)
```

### Penanganan Weight Tidak Mencukupi

Apabila total weight yang tersedia dalam data terfilter tidak mencukupi target `weight_aggregate`, fungsi akan otomatis memilih seluruh data terfilter dan memberikan peringatan:

```r
survei_dummy <- penanda( # atau imputation_sample()
  d = survei_dummy,
  f = my_filter,
  wsum = 999999,
  wvar = Weight_R,
  i = 10,
  flag = "all_selected"
)
#> ⚠ WARNING!
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
- Format pesan `⚠ WARNING!` berwarna merah pada baris tersendiri
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

## Credits
- [@im-perativa](https://github.com/im-perativa) — penulis dan pengelola asli
- [@jiprastyo](https://github.com/jiprastyo) — penanganan edge-case, optimasi kode, pembaruan dokumentasi (v0.2.0)

## Attribution
- Fork 1: github.com/easbi (repo turunan pertama dari im-perativa)
- Fork 2: github.com/jiprastyo (repo turunan kedua / pengembangan saat ini)

## Bantuan
Apabila ditemukan bug atau masalah lainnya, silakan buat issue di [GitHub](https://github.com/easbi/imputationSample/issues)
