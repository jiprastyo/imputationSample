#' Mengubah nilai atribut-atribut sampel
#' @description Mengubah nilai atribut-atribut sampel dengan flag tertentu
#' @param d Dataset yang digunakan.
#' @param flag Target baris data yang ingin diubah atribut-atributnya.
#' @param ... Daftar mapping atribut dan nilai baru yang diinginkan (dapat dibuat sebanyak mungkin).
#' @return Data yang telah diubah nilai atribut-atributnya.
#' @examples
#' survei_dummy = imputasi(d = survei_dummy, flag = "aceh_desa", status6 = NA, kategori = 1)
#' @export
imputasi <- function(d, flag, ...) {
  quos <- rlang::enquos(...)
  if (missing(d) && "x" %in% names(quos)) {
    d <- rlang::eval_tidy(quos$x)
    quos$x <- NULL
  }
  if (missing(flag) && "sample_flag" %in% names(quos)) {
    flag <- rlang::eval_tidy(quos$sample_flag)
    quos$sample_flag <- NULL
  }
  if (missing(d)) {
    stop("Argumen wajib belum diisi: d.")
  }
  if (missing(flag)) {
    stop("Argumen wajib belum diisi: flag.")
  }

  all_flags <- unique(d$flag)
  if (!flag %in% all_flags) {
    stop(paste("Sampel terpilih dengan flag:", flag, "tidak ditemukan"))
  }

  mutation <- rlang::quos(!!!quos)
  mutation_col <- names(mutation)

  d$temp_id <- 1:nrow(d)

  x_modified <- d %>%
    dplyr::filter(flag == !!flag) %>%
    dplyr::mutate(!!!mutation)

  x_unmodified <- d %>%
    dplyr::filter(flag != !!flag | is.na(flag))

  d <- dplyr::bind_rows(x_unmodified, x_modified) %>%
    dplyr::arrange(temp_id)

  d$temp_id <- NULL

  for (name in mutation_col) {
    message(paste0("Nilai atribut ", name, " dari sampel terpilih dengan flag: ", flag,
                   " telah diubah menjadi: ", x_modified[1, name]))
  }

  return(d)
}

#' @rdname imputasi
#' @export
mutate_sample <- function(x, sample_flag, ...) {
  imputasi(d = x, flag = sample_flag, ...)
}
