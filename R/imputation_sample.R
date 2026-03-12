#' @title Memilih sampel imputasi
#' @description Memilih sampel imputasi dari filter yang telah dibuat dengan total weight tertentu
#' @param x Dataset yang digunakan.
#' @param filters Filter yang telah dibuat dengan fungsi \code{\link{create_filter}}.
#' @param weight_aggregate Besaran agregat weight dari sampel terpilih yang diinginkan.
#' @param weight_col Kolom yang digunakan sebagai weight dalam pemilihan sampel apabila tersedia.
#' @param iter Jumlah iterasi pengacakan dan pengambilan sampel yang diinginkan (semakin tinggi maka weight akan semakin sesuai).
#' @param sample_flag Identitas dari sampel yang dihasilkan. Untuk kondisi default sample_flag bernilai (integer) 1
#' @return Data yang telah diberi flag untuk sampel terpilih yang selanjutnya dapat diubah atributnya menggunakan fungsi \code{\link{mutate_sample}}.
#' @examples
#' # Membuat filter berbeda
#' filter_1 = create_filter(NAMA_PROV == "ACEH", KLASIFIKASI == 1)
#' filter_2 = create_filter(NAMA_PROV == "RIAU" | NAMA_PROV == "SUMATERA BARAT", KLASIFIKASI == 2)
#' imputation_sample(x = survei_dummy, filters = filter_1, weight_aggregate = 10000, weight_col = Weight_R)
#' imputation_sample(x = survei_dummy, filters = filter_2, weight_aggregate = 5000, weight_col = Weight_R)
#'
#' # Membandingkan hasil sampel dengan jumlah iterasi berbeda
#' my_filter = create_filter(NAMA_PROV == "SUMATERA BARAT", KLASIFIKASI == 2)
#' imputation_sample(x = survei_dummy, filters = my_filter, weight_aggregate = 73955, weight_col = Weight_R, iter = 1)
#' imputation_sample(x = survei_dummy, filters = my_filter, weight_aggregate = 73955, weight_col = Weight_R, iter = 100)
#' @export
imputation_sample <- function(x, filters, weight_aggregate, weight_col, iter = 1, sample_flag = 1) {
  weight_col <- dplyr::enquo(weight_col)
  fnum <- function(x) {
    s <- as.character(as.integer(x))
    gsub("(?<=\\d)(?=(\\d{3})+$)", ".", s, perl = TRUE)
  }

  if (!"temp_id" %in% colnames(x)) {
    x$temp_id <- 1:nrow(x)
  }

  if (!"flag" %in% colnames(x)) {
    x$flag <- 0 # Create default column for flagging
  }

  x_filtered <- x %>%
    dplyr::filter(!!!filters)

  n_all <- nrow(x)
  n_filtered <- nrow(x_filtered)

  # --- Adjustment 1: Handle empty filter result ---
  if (n_filtered == 0) {
    message(paste0("\n\033[31m\u26A0 WARNING!\033[0m\n",
                   "Tidak ada data yang sesuai dengan filter. Data dikembalikan tanpa perubahan."))
    x$temp_id <- NULL
    message(paste0("Total data ", fnum(n_all), " / terfilter 0 / terpilih imputasi 0 dengan ", iter,
                   " iterasi, total weight: 0 (0%)"))
    message(paste0("Baris terpilih ditandai flag=", sample_flag, "."))
    return(x)
  }

  weight_values <- x_filtered %>% dplyr::pull(!!weight_col)
  total_weight_available <- sum(weight_values)
  min_weight <- min(weight_values)

  # --- Adjustment 2: Handle weight_aggregate < min single weight ---
  # Changed from stop() to warning, select 0 rows
  if (weight_aggregate < min_weight) {
    message(paste0("\n\033[31m\u26A0 WARNING!\033[0m\n",
                   "Total weight yang dimasukkan (", fnum(weight_aggregate),
                   ") lebih kecil dari weight terkecil (", fnum(min_weight),
                   "). Tidak ada sampel yang dapat dipilih."))
    x$temp_id <- NULL
    message(paste0("Total data ", fnum(n_all), " / terfilter ", fnum(n_filtered),
                   " / terpilih imputasi 0 dengan ", iter,
                   " iterasi, total weight: 0 (0%)"))
    message(paste0("Baris terpilih ditandai flag=", sample_flag, "."))
    return(x)
  }

  # --- Adjustment 3: If total available weight <= target, select all filtered rows directly ---
  if (total_weight_available <= weight_aggregate) {
    filter_text <- paste(sapply(filters, function(f) deparse(rlang::quo_get_expr(f))), collapse = ", ")
    message(paste0("\n\033[31m\u26A0 WARNING!\033[0m\n",
                   "[", filter_text, "] tidak mencukupi target.\n",
                   "Weight tersedia ", fnum(total_weight_available),
                   " / target ", fnum(weight_aggregate),
                   " / kekurangan ", fnum(weight_aggregate - total_weight_available),
                   ".\nSemua data terfilter dipilih."))
    x[x$temp_id %in% x_filtered$temp_id, "flag"] <- sample_flag
    x$temp_id <- NULL
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
  x$temp_id <- NULL

  n_selected <- candidates[[candidates_final]]$n
  w_selected <- candidates[[candidates_final]]$sum
  pct <- round(w_selected / weight_aggregate * 100, 4)

  message(paste0("Total data ", fnum(n_all), " / terfilter ", fnum(n_filtered),
                 " / terpilih imputasi ", fnum(n_selected), " dengan ", iter,
                 " iterasi, total weight: ", fnum(w_selected), " (", pct, "%)"))
  message(paste0("Baris terpilih ditandai flag=", sample_flag, "."))
  return(x)
}
