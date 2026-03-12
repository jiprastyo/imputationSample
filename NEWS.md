# imputationSample

## 0.2.5
- Dukungan multi-flag dalam filter yang sama (pemilihan bertahap berdasarkan prioritas).
- `weight_aggregate` dan `iter` menerima vektor (atau satu nilai yang direplikasi) untuk tiap tahap.
- Pembaruan dokumentasi dan contoh penggunaan.
- Penambahan alias fungsi baru: `buatfilter()`, `penanda()`, `imputasi()` (nama lama tetap tersedia).

## 0.2.4
- Penyesuaian minor dokumentasi.

## 0.2.3
- Perbaikan kompatibilitas R 4.5: menggunakan `cli::col_red()` untuk warna merah, menghindari mixed escape types dalam string literal.
- Setiap baris pesan warning menggunakan `message()` terpisah.

## 0.2.2
- Perbaikan kompatibilitas R 4.5: mengganti `\033` (octal) dengan `\x1b` (hex) pada ANSI escape codes.

## 0.2.1
- Perbaikan format angka: mengganti `formatC` dengan regex-based separator untuk menghilangkan warning `prettyNum`.
- Pesan warning menggunakan `message()` (bukan `warning()`) untuk output yang lebih bersih tanpa prefix function call.
- Format pesan `WARNING!` berwarna merah pada baris tersendiri.
- Newline setelah kalimat pada pesan warning untuk keterbacaan.
- Pesan flag dipersingkat menjadi `Baris terpilih ditandai flag=X.`

## 0.2.0
- Penanganan kasus filter kosong (tidak lagi error, mengembalikan data tanpa perubahan).
- Penanganan kasus target weight lebih kecil dari weight terkecil (warning, bukan error).
- Penanganan kasus total weight tidak mencukupi target (seluruh data terfilter dipilih otomatis, tanpa iterasi).
- Optimasi kode: penggunaan `dplyr::pull()` langsung, `dplyr::bind_rows()` pada `mutate_sample()`.
- Perbaikan contoh dokumentasi: `%in% c(...)` (sebelumnya tanpa `c()`).
- Format pesan output diperbarui.
- Dependency `foreign` dihapus dari `Depends`.

## 0.1.1
- Rilis awal.
