#' @title Memilih sampel imputasi
#' @description Memilih sampel imputasi dari filter yang telah dibuat dengan total weight tertentu
#' @param d Dataset yang digunakan.
#' @param f Filter yang telah dibuat dengan fungsi \code{\link{buatfilter}}.
#' @param wsum Besaran agregat weight dari sampel terpilih yang diinginkan.
#' Dapat berupa vektor dengan panjang sama dengan \code{flag}; jika panjang 1 maka akan direplikasi.
#' @param wvar Kolom yang digunakan sebagai weight dalam pemilihan sampel apabila tersedia.
#' @param i Jumlah iterasi pengacakan dan pengambilan sampel yang diinginkan (semakin tinggi maka weight akan semakin sesuai).
#' Dapat berupa vektor dengan panjang sama dengan \code{flag}; jika panjang 1 maka akan direplikasi.
#' @param flag Target baris data yang dihasilkan. Untuk kondisi default flag bernilai (integer) 1.
#' Jika berupa vektor, pemilihan sampel dilakukan bertahap (prioritas), di mana setiap tahap hanya memilih
#' baris yang belum memiliki flag (flag = 0 atau NA) dalam filter yang sama.
#' Nama argumen lama `x`, `filters`, `weight_aggregate`, `weight_col`, `iter`, `sample_flag` tetap diterima.
#' @return Data yang telah diberi flag untuk sampel terpilih yang selanjutnya dapat diubah atributnya menggunakan fungsi \code{\link{imputasi}}.
#' @examples
#' # Membuat filter berbeda
#' filter_1 = buatfilter(NAMA_PROV == "ACEH", KLASIFIKASI == 1)
#' filter_2 = buatfilter(NAMA_PROV == "RIAU" | NAMA_PROV == "SUMATERA BARAT", KLASIFIKASI == 2)
#' penanda(d = survei_dummy, f = filter_1, wsum = 10000, wvar = Weight_R)
#' penanda(d = survei_dummy, f = filter_2, wsum = 5000, wvar = Weight_R)
#'
#' # Membandingkan hasil sampel dengan jumlah iterasi berbeda
#' my_filter = buatfilter(NAMA_PROV == "SUMATERA BARAT", KLASIFIKASI == 2)
#' penanda(d = survei_dummy, f = my_filter, wsum = 73955, wvar = Weight_R, i = 1)
#' penanda(d = survei_dummy, f = my_filter, wsum = 73955, wvar = Weight_R, i = 100)
#'
#' # Multi-flag dalam filter yang sama (prioritas)
#' my_filter = buatfilter(NAMA_PROV == "ACEH", KLASIFIKASI == 1)
#' penanda(
#'   d = survei_dummy,
#'   f = my_filter,
#'   wsum = c(30000, 15000),
#'   wvar = Weight_R,
#'   i = 10,
#'   flag = c("prioritas_1", "prioritas_2")
#' )
#'
#' # Contoh alias singkat (d, f, wsum, wvar, i, flag)
#' d <- survei_dummy
#' f <- buatfilter(NAMA_PROV == "ACEH", KLASIFIKASI == 1)
#' wsum <- c(30000, 15000)
#' wvar <- Weight_R
#' i <- 10
#' flag <- c("prioritas_1", "prioritas_2")
#' d <- penanda(d = d, f = f, wsum = wsum,
#'              wvar = wvar, i = i, flag = flag)
#' @export
penanda <- function(d, f, wsum, wvar, i = 1, flag = 1, ...) {
  dots <- list(...)
  has_d <- !missing(d)
  has_f <- !missing(f)
  has_wsum <- !missing(wsum)
  has_wvar <- !missing(wvar)
  has_i <- !missing(i)
  has_flag <- !missing(flag)

  if (!has_d && "x" %in% names(dots)) {
    d <- dots$x
    has_d <- TRUE
  }
  if (!has_f && "filters" %in% names(dots)) {
    f <- dots$filters
    has_f <- TRUE
  }
  if (!has_wsum && "weight_aggregate" %in% names(dots)) {
    wsum <- dots$weight_aggregate
    has_wsum <- TRUE
  }
  if (!has_wvar && "weight_col" %in% names(dots)) {
    wvar <- dots$weight_col
    has_wvar <- TRUE
  }
  if (!has_i && "iter" %in% names(dots)) {
    i <- dots$iter
  }
  if (!has_flag && "sample_flag" %in% names(dots)) {
    flag <- dots$sample_flag
  }

  missing_args <- c()
  if (!has_d) missing_args <- c(missing_args, "d")
  if (!has_f) missing_args <- c(missing_args, "f")
  if (!has_wsum) missing_args <- c(missing_args, "wsum")
  if (!has_wvar) missing_args <- c(missing_args, "wvar")
  if (length(missing_args) > 0) {
    stop(paste0("Argumen wajib belum diisi: ", paste(missing_args, collapse = ", "), "."))
  }

  wvar <- dplyr::enquo(wvar)
  fnum <- function(x) {
    s <- as.character(as.integer(x))
    gsub("(?<=\\d)(?=(\\d{3})+$)", ".", s, perl = TRUE)
  }
  warn_banner <- paste0(cli::col_red("\u26A0 WARNING!"))

  if (!"temp_id" %in% colnames(d)) {
    d$temp_id <- 1:nrow(d)
  }

  if (!"flag" %in% colnames(d)) {
    d$flag <- 0 # Create default column for flagging
  }

  n_flags <- length(flag)
  n_weights <- length(wsum)
  n_iters <- length(i)
  multi_mode <- (n_flags > 1 || n_weights > 1 || n_iters > 1)

  if (multi_mode) {
    n_stage <- max(n_flags, n_weights, n_iters)
    if (n_flags == 1) {
      stop("Untuk multi-flag, flag harus berupa vektor dengan panjang >= 2.")
    }
    if (n_flags != n_stage) {
      stop("Panjang flag harus sama dengan jumlah tahap.")
    }
    if (n_weights != 1 && n_weights != n_stage) {
      stop("Panjang wsum harus 1 atau sama dengan jumlah tahap.")
    }
    if (n_iters != 1 && n_iters != n_stage) {
      stop("Panjang i harus 1 atau sama dengan jumlah tahap.")
    }
    if (n_weights == 1) {
      wsum <- rep(wsum, n_stage)
    }
    if (n_iters == 1) {
      i <- rep(i, n_stage)
    }
  }

  run_once <- function(d, wsum, i, flag, exclude_flag) {
    d_filtered <- d %>%
      dplyr::filter(!!!f)

    if (exclude_flag) {
      d_filtered <- d_filtered %>%
        dplyr::filter(flag == 0 | is.na(flag))
    }

    n_all <- nrow(d)
    n_filtered <- nrow(d_filtered)

    # --- Adjustment 1: Handle empty filter result ---
    if (n_filtered == 0) {
      message("")
      message(warn_banner)
      message("Tidak ada data yang sesuai dengan filter. Data dikembalikan tanpa perubahan.")
      message(paste0("Total data ", fnum(n_all), " / terfilter 0 / terpilih imputasi 0 dengan ", i,
                     " iterasi, total weight: 0 (0%)"))
      message(paste0("Baris terpilih ditandai flag=", flag, "."))
      return(d)
    }

    weight_values <- d_filtered %>% dplyr::pull(!!wvar)
    total_weight_available <- sum(weight_values)
    min_weight <- min(weight_values)

    # --- Adjustment 2: Handle weight_aggregate < min single weight ---
    if (wsum < min_weight) {
      message("")
      message(warn_banner)
      message(paste0("Total weight yang dimasukkan (", fnum(wsum),
                     ") lebih kecil dari weight terkecil (", fnum(min_weight),
                     "). Tidak ada sampel yang dapat dipilih."))
      message(paste0("Total data ", fnum(n_all), " / terfilter ", fnum(n_filtered),
                     " / terpilih imputasi 0 dengan ", i,
                     " iterasi, total weight: 0 (0%)"))
      message(paste0("Baris terpilih ditandai flag=", flag, "."))
      return(d)
    }

    # --- Adjustment 3: If total available weight <= target, select all filtered rows directly ---
    if (total_weight_available <= wsum) {
      filter_text <- paste(sapply(f, function(f) deparse(rlang::quo_get_expr(f))), collapse = ", ")
      message("")
      message(warn_banner)
      message(paste0("[", filter_text, "] tidak mencukupi target."))
      message(paste0("Weight tersedia ", fnum(total_weight_available),
                     " / target ", fnum(wsum),
                     " / kekurangan ", fnum(wsum - total_weight_available), "."))
      message("Semua data terfilter dipilih.")
      d[d$temp_id %in% d_filtered$temp_id, "flag"] <- flag
      pct <- round(total_weight_available / wsum * 100, 4)
      message(paste0("Total data ", fnum(n_all), " / terfilter ", fnum(n_filtered),
                     " / terpilih imputasi ", fnum(n_filtered), " dengan 0 iterasi (seluruh data terfilter), total weight: ",
                     fnum(total_weight_available), " (", pct, "%)"))
      message(paste0("Baris terpilih ditandai flag=", flag, "."))
      return(d)
    }

    limit <- wsum
    candidates <- list()

    for (iter_i in 1:i) {
      d_iter <- d_filtered %>%
        dplyr::sample_frac() %>%
        dplyr::select(!!wvar, temp_id)

      left <- n_filtered
      groups <- list()
      j <- 1

      while (left > 0) {
        cums <- cumsum(d_iter[[1]]) # Weight column
        indexes <- cums <= limit
        last <- sum(indexes)

        group <- d_iter[[2]][indexes] # Temporary id column
        group_sum <- cums[last]

        if (last != 0) {
          d_iter <- d_iter[!indexes,]
          groups[[j]] <- list(member = group, n = length(group), sum = group_sum)
          j <- j + 1
        } else {
          d_iter <- d_iter[-1, ]
        }

        left <- nrow(d_iter)
      }

      groups_final = min(which(sapply(groups, "[[", "sum") == max(sapply(groups, "[[", "sum"))))
      candidates[[iter_i]] <- groups[[groups_final]]
    }
    candidates_final = min(which(sapply(candidates, "[[", "sum") == max(sapply(candidates, "[[", "sum"))))

    d[d$temp_id %in% candidates[[candidates_final]]$member, "flag"] <- flag

    n_selected <- candidates[[candidates_final]]$n
    w_selected <- candidates[[candidates_final]]$sum
    pct <- round(w_selected / wsum * 100, 4)

    message(paste0("Total data ", fnum(n_all), " / terfilter ", fnum(n_filtered),
                   " / terpilih imputasi ", fnum(n_selected), " dengan ", i,
                   " iterasi, total weight: ", fnum(w_selected), " (", pct, "%)"))
    message(paste0("Baris terpilih ditandai flag=", flag, "."))
    return(d)
  }

  if (!multi_mode) {
    d <- run_once(d, wsum, i, flag, exclude_flag = FALSE)
    d$temp_id <- NULL
    return(d)
  }

  for (stage_i in seq_len(n_stage)) {
    message("")
    message(paste0("Tahap ", stage_i, "/", n_stage, ": prioritas flag=", flag[stage_i],
                   ", target weight=", fnum(wsum[stage_i]), ", iter=", i[stage_i], "."))
    d <- run_once(d, wsum[stage_i], i[stage_i], flag[stage_i], exclude_flag = TRUE)
  }

  d$temp_id <- NULL
  return(d)
}

#' @rdname penanda
#' @export
imputation_sample <- function(x, filters, weight_aggregate, weight_col, iter = 1, sample_flag = 1) {
  penanda(d = x, f = filters, wsum = weight_aggregate, wvar = weight_col, i = iter, flag = sample_flag)
}
