#' Membuat filter yang diinginkan
#' @param ... Daftar filter yang diinginkan (dapat dibuat sebanyak mungkin).
#' @return Filter yang dapat digunakan untuk memfilter data dalam fungsi \code{\link{penanda}}.
#' @examples
#' filter1 = buatfilter(NAMA_PROV == "ACEH", KLASIFIKASI == "1", JenisKegiatan != 2)
#' filter2 = buatfilter(NAMA_PROV == "ACEH" | NAMA_PROV == "RIAU", KLASIFIKASI == "2", JenisKegiatan %in% c(1,2,3))
#' @export
buatfilter <- function(...) {
  return(dplyr::quos(...))
}

#' @rdname buatfilter
#' @export
create_filter <- function(...) {
  buatfilter(...)
}
