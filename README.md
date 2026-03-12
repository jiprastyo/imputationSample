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
devtools::install_github("easbi/imputationSample")
```

## Penggunaan
Terdapat tiga fungsi utama dalam package ini:
- `create_filter()` digunakan untuk membuat filter yang diinginkan
- `imputation_sample()` digunakan untuk memilih sampel imputasi dari filter yang telah dibuat dengan total weight tertentu
- `mutate_sample()` digunakan untuk mengubah nilai atribut-atribut tertentu dari sampel yang telah dipilih yang teridentifikasi dengan flag tertentu

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
my_filter <- create_filter(
  NAMA_PROV == "ACEH" | NAMA_PROV == "SUMATERA BARAT",
  KLASIFIKASI == 1
)

# Memilih sampel acak dari filter yang telah dibuat
survei_dummy <- imputation_sample(
  x = survei_dummy,
  filters = my_filter,
  weight_aggregate = 45000,
  weight_col = Weight_R,
  iter = 10,
  sample_flag = "aceh_sumbar_1"
)
#> Total data 3.727 / terfilter 485 / terpilih imputasi 42 dengan 10 iterasi, total weight: 44.987 (99.9711%)
#> Baris terpilih ditandai flag=aceh_sumbar_1.

# Mengubah atribut sampel terpilih
survei_dummy <- mutate_sample(
  x = survei_dummy,
  sample_flag = "aceh_sumbar_1",
  kategori = 1,
  jenisKegiatan = 2
)
#> Nilai atribut kategori dari sampel terpilih dengan flag: aceh_sumbar_1 telah diubah menjadi: 1
#> Nilai atribut jenisKegiatan dari sampel terpilih dengan flag: aceh_sumbar_1 telah diubah menjadi: 2
```

### Penanganan Weight Tidak Mencukupi

Apabila total weight yang tersedia dalam data terfilter tidak mencukupi target `weight_aggregate`, fungsi akan otomatis memilih seluruh data terfilter dan memberikan peringatan:

```r
survei_dummy <- imputation_sample(
  x = survei_dummy,
  filters = my_filter,
  weight_aggregate = 999999,
  weight_col = Weight_R,
  iter = 10,
  sample_flag = "all_selected"
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

## Bantuan
Apabila ditemukan bug atau masalah lainnya, silakan buat issue di [GitHub](https://github.com/easbi/imputationSample/issues)
