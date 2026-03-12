#' @title Memilih sampel imputasi
#' @description Memilih sampel imputasi dari filter yang telah dibuat dengan total weight tertentu
#' @param x Dataset yang digunakan.
#' @param filters Filter yang telah dibuat dengan fungsi \code{\link{buatfilter}}.
#' @param weight_aggregate Besaran agregat weight dari sampel terpilih yang diinginkan.
#' Dapat berupa vektor dengan panjang sama dengan \code{sample_flag}; jika panjang 1 maka akan direplikasi.
#' @param weight_col Kolom yang digunakan sebagai weight dalam pemilihan sampel apabila tersedia.
#' @param iter Jumlah iterasi pengacakan dan pengambilan sampel yang diinginkan (semakin tinggi maka weight akan semakin sesuai).
#' Dapat berupa vektor dengan panjang sama dengan \code{sample_flag}; jika panjang 1 maka akan direplikasi.
#' @param sample_flag Identitas dari sampel yang dihasilkan. Untuk kondisi default sample_flag bernilai (integer) 1.
#' Jika berupa vektor, pemilihan sampel dilakukan bertahap (prioritas), di mana setiap tahap hanya memilih
#' baris yang belum memiliki flag (flag = 0 atau NA) dalam filter yang sama.
#' @return Data yang telah diberi flag untuk sampel terpilih yang selanjutnya dapat diubah atributnya menggunakan fungsi \code{\link{imputasi}}.
#' @examples
#' # Membuat filter berbeda
#' filter_1 = buatfilter(NAMA_PROV == "ACEH", KLASIFIKASI == 1)
#' filter_2 = buatfilter(NAMA_PROV == "RIAU" | NAMA_PROV == "SUMATERA BARAT", KLASIFIKASI == 2)
#' penanda(x = survei_dummy, filters = filter_1, weight_aggregate = 10000, weight_col = Weight_R)
#' penanda(x = survei_dummy, filters = filter_2, weight_aggregate = 5000, weight_col = Weight_R)
#'
#' # Membandingkan hasil sampel dengan jumlah iterasi berbeda
#' my_filter = buatfilter(NAMA_PROV == "SUMATERA BARAT", KLASIFIKASI == 2)
#' penanda(x = survei_dummy, filters = my_filter, weight_aggregate = 73955, weight_col = Weight_R, iter = 1)
#' penanda(x = survei_dummy, filters = my_filter, weight_aggregate = 73955, weight_col = Weight_R, iter = 100)
#'
#' # Multi-flag dalam filter yang sama (prioritas)
#' my_filter = buatfilter(NAMA_PROV == "ACEH", KLASIFIKASI == 1)
#' penanda(
#'   x = survei_dummy,
#'   filters = my_filter,
#'   weight_aggregate = c(30000, 15000),
#'   weight_col = Weight_R,
#'   iter = 10,
#'   sample_flag = c("prioritas_1", "prioritas_2")
#' )
#'
#' # Contoh alias singkat (d, f, wsum, wvar, i, flag)
#' d <- survei_dummy
#' f <- buatfilter(NAMA_PROV == "ACEH", KLASIFIKASI == 1)
#' wsum <- c(30000, 15000)
#' wvar <- Weight_R
#' i <- 10
#' flag <- c("prioritas_1", "prioritas_2")
#' d <- penanda(x = d, filters = f, weight_aggregate = wsum,
#'              weight_col = wvar, iter = i, sample_flag = flag)
#' @export
penanda <- function(x, filters, weight_aggregate, weight_col, iter = 1, sample_flag = 1) {
  weight_col <- dplyr::enquo(weight_col)
  fnum <- function(x) {
    s <- as.character(as.integer(x))
    gsub("(?<=\\d)(?=(\\d{3})+$)", ".", s, perl = TRUE)
  }
  warn_banner <- paste0(cli::col_red("\u26A0 WARNING!"))

  if (!"temp_id" %in% colnames(x)) {
    x$temp_id <- 1:nrow(x)
  }

  if (!"flag" %in% colnames(x)) {
    x$flag <- 0 # Create default column for flagging
  }

  n_flags <- length(sample_flag)
  n_weights <- length(weight_aggregate)
  n_iters <- length(iter)
  multi_mode <- (n_flags > 1 || n_weights > 1 || n_iters > 1)

  if (multi_mode) {
    n_stage <- max(n_flags, n_weights, n_iters)
    if (n_flags == 1) {
      stop("Untuk multi-flag, sample_flag harus berupa vektor dengan panjang >= 2.")
    }
    if (n_flags != n_stage) {
      stop("Panjang sample_flag harus sama dengan jumlah tahap.")
    }
    if (n_weights != 1 && n_weights != n_stage) {
      stop("Panjang weight_aggregate harus 1 atau sama dengan jumlah tahap.")
    }
    if (n_iters != 1 && n_iters != n_stage) {
      stop("Panjang iter harus 1 atau sama dengan jumlah tahap.")
    }
    if (n_weights == 1) {
      weight_aggregate <- rep(weight_aggregate, n_stage)
    }
    if (n_iters == 1) {
      iter <- rep(iter, n_stage)
    }
  }

  run_once <- function(x, weight_aggregate, iter, sample_flag, exclude_flag) {
    x_filtered <- x %>%
      dplyr::filter(!!!filters)

    if (exclude_flag) {
      x_filtered <- x_filtered %>%
        dplyr::filter(flag == 0 | is.na(flag))
    }

    n_all <- nrow(x)
    n_filtered <- nrow(x_filtered)

    # --- Adjustment 1: Handle empty filter result ---
    if (n_filtered == 0) {
      message("")
      message(warn_banner)
      message("Tidak ada data yang sesuai dengan filter. Data dikembalikan tanpa perubahan.")
      message(paste0("Total data ", fnum(n_all), " / terfilter 0 / terpilih imputasi 0 dengan ", iter,
                     " iterasi, total weight: 0 (0%)"))
      message(paste0("Baris terpilih ditandai flag=", sample_flag, "."))
      return(x)
    }

    weight_values <- x_filtered %>% dplyr::pull(!!weight_col)
    total_weight_available <- sum(weight_values)
    min_weight <- min(weight_values)

    # --- Adjustment 2: Handle weight_aggregate < min single weight ---
    if (weight_aggregate < min_weight) {
      message("")
      message(warn_banner)
      message(paste0("Total weight yang dimasukkan (", fnum(weight_aggregate),
                     ") lebih kecil dari weight terkecil (", fnum(min_weight),
                     "). Tidak ada sampel yang dapat dipilih."))
      message(paste0("Total data ", fnum(n_all), " / terfilter ", fnum(n_filtered),
                     " / terpilih imputasi 0 dengan ", iter,
                     " iterasi, total weight: 0 (0%)"))
      message(paste0("Baris terpilih ditandai flag=", sample_flag, "."))
      return(x)
    }

    # --- Adjustment 3: If total available weight <= target, select all filtered rows directly ---
    if (total_weight_available <= weight_aggregate) {
      filter_text <- paste(sapply(filters, function(f) deparse(rlang::quo_get_expr(f))), collapse = ", ")
      message("")
      message(warn_banner)
      message(paste0("[", filter_text, "] tidak mencukupi target."))
      message(paste0("Weight tersedia ", fnum(total_weight_available),
                     " / target ", fnum(weight_aggregate),
                     " / kekurangan ", fnum(weight_aggregate - total_weight_available), "."))
      message("Semua data terfilter dipilih.")
      x[x$temp_id %in% x_filtered$temp_id, "flag"] <- sample_flag
      pct <- round(total_weight_available / weight_aggregate * 100, 4)
      message(paste0("Total data ", fnum(n_all), " / terfilter ", fnum(n_filtered),
                     " / terpilih imputasi ", fnum(n_filtered), " dengan 0 iterasi (seluruh data terfilter), total weight: ",
                     fnum(total_weight_available), " (", pct, "%)"))
      message(paste0("Baris terpilih ditandai flag=", sample_flag, "."))
      return(x)
    }

    limit <- weight_aggregate
    candidates <- list()

    for (i in 1:iter) {
      x_iter <- x_filtered %>%
        dplyr::sample_frac() %>%
        dplyr::select(!!weight_col, temp_id)

      left <- n_filtered
      groups <- list()
      j <- 1

      while (left > 0) {
        cums <- cumsum(x_iter[[1]]) # Weight column
        indexes <- cums <= limit
        last <- sum(indexes)

        group <- x_iter[[2]][indexes] # Temporary id column
        group_sum <- cums[last]

        if (last != 0) {
          x_iter <- x_iter[!indexes,]
          groups[[j]] <- list(member = group, n = length(group), sum = group_sum)
          j <- j + 1
        } else {
          x_iter <- x_iter[-1, ]
        }

        left <- nrow(x_iter)
      }

      groups_final = min(which(sapply(groups, "[[", "sum") == max(sapply(groups, "[[", "sum"))))
      candidates[[i]] <- groups[[groups_final]]
    }
    candidates_final = min(which(sapply(candidates, "[[", "sum") == max(sapply(candidates, "[[", "sum"))))

    x[x$temp_id %in% candidates[[candidates_final]]$member, "flag"] <- sample_flag

    n_selected <- candidates[[candidates_final]]$n
    w_selected <- candidates[[candidates_final]]$sum
    pct <- round(w_selected / weight_aggregate * 100, 4)

    message(paste0("Total data ", fnum(n_all), " / terfilter ", fnum(n_filtered),
                   " / terpilih imputasi ", fnum(n_selected), " dengan ", iter,
                   " iterasi, total weight: ", fnum(w_selected), " (", pct, "%)"))
    message(paste0("Baris terpilih ditandai flag=", sample_flag, "."))
    return(x)
  }

  if (!multi_mode) {
    x <- run_once(x, weight_aggregate, iter, sample_flag, exclude_flag = FALSE)
    x$temp_id <- NULL
    return(x)
  }

  for (i in seq_len(n_stage)) {
    message("")
    message(paste0("Tahap ", i, "/", n_stage, ": prioritas flag=", sample_flag[i],
                   ", target weight=", fnum(weight_aggregate[i]), ", iter=", iter[i], "."))
    x <- run_once(x, weight_aggregate[i], iter[i], sample_flag[i], exclude_flag = TRUE)
  }

  x$temp_id <- NULL
  return(x)
}

#' @rdname penanda
#' @export
imputation_sample <- function(x, filters, weight_aggregate, weight_col, iter = 1, sample_flag = 1) {
  penanda(x, filters, weight_aggregate, weight_col, iter, sample_flag)
}
