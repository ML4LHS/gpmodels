# gpm_combine_old = function(time_frame, ..., files = NULL, use_output_folder = TRUE, dplyr_join = inner_join) {
#
#   if (is.null(files)) {
#     temporal_dfs = append(list(time_frame$fixed_data %>%
#                                  rename(!!rlang::parse_expr(time_frame$temporal_id) := !!rlang::parse_expr(time_frame$fixed_id))),
#                           list(...))
#   } else {
#     temporal_dfs = append(list(time_frame$fixed_data %>%
#                                  rename(!!rlang::parse_expr(time_frame$temporal_id) := !!rlang::parse_expr(time_frame$fixed_id))),
#                           as.list(files))
#   }
#   temporal_dfs =
#     temporal_dfs %>%
#     lapply(function (x) {
#       if ('data.frame' %in% class(x)) {
#         return(x)
#       } else if (class(x) == 'character' & use_output_folder) {
#         return(data.table::fread(file.path(time_frame$output_folder, x)))
#       } else if (class(x) == 'character' & !use_output_folder) {
#         return(data.table::fread(x))
#       } else {
#         stop('Error: the ... must be limited to data frames and file paths.')
#       }
#     })
#
#   return(Reduce(dplyr_join, temporal_dfs) %>% as.data.frame())
# }

#' New combine_output function
#' @export
combine_output = function(time_frame,
                           ...,
                           files = NULL,
                           include_files = TRUE,
                           use_output_folder = TRUE,
                           dplyr_join = dplyr::inner_join,
                           log_file = TRUE) {

    return_frame = list(time_frame$fixed_data %>%
                          rename(!!rlang::parse_expr(time_frame$temporal_id) := !!rlang::parse_expr(time_frame$fixed_id)))

    if (length(list(...)) > 0) {
      return_frame = append(return_frame, list(...))
    }

    if (include_files) {
      if (is.null(files)) {
        files = dir(time_frame$output_folder, pattern = '.csv')
        use_output_folder = TRUE # overwrite use_output_folder
      }
      num_files = length(files)
    }

    if (include_files && num_files == 0) {
      stop(paste0('No .csv files were found in ', time_frame$output_folder, '. ',
                  'If you do not want to combine any files, please set ',
                  'include_files to FALSE.'))
    }

    if (include_files) {
      detect_chunks = stringr::str_detect(files, '\\bchunk_\\d+')

      if (use_output_folder) {
        files = file.path(time_frame$output_folder, files)
      }

      if (!any(detect_chunks)) { # if no files are chunked
        return_frame =
          append(return_frame,
                 lapply(files[!detect_chunks],
                        function (file_name) {
                          message(paste0('Reading file: ', file_name, '...'))
                          if (log_file) {
                            write(paste0(Sys.time(), ': Reading file: ', file_name, '...'),
                                  file.path(time_frame$output_folder, 'gpm_log.txt'), append = TRUE)
                          }
                          data.table::fread(file_name, data.table = FALSE)
                        }))
      }

      if (any(detect_chunks) && !all(detect_chunks)) { # if only some files are chunked
        # append only those files that are not chunked first
        return_frame =
          append(return_frame,
                 lapply(files[!detect_chunks],
                        function (file_name) {
                          message(paste0('Reading file: ', file_name, '...'))
                          if (log_file) {
                            write(paste0(Sys.time(), ': Reading file: ', file_name, '...'),
                                  file.path(time_frame$output_folder, 'gpm_log.txt'), append = TRUE)
                          }
                          data.table::fread(file_name, data.table = FALSE)
                        }))
      }

      if (any(detect_chunks)) { # now handle chunked files
        # limit files to those with chunks (since we already appended non-chunked files above)
        files = files[detect_chunks]
        unique_chunks =
          stringr::str_extract(files, '\\bchunk_\\d+') %>%
          unique() %>%
          sort()

        return_frame =
          append(return_frame,
                 lapply(unique_chunks, function (chunk_name) {
                   message(paste0('Reading chunk: ', chunk_name, '...'))
                   if (log_file) {
                     write(paste0(Sys.time(), ': Reading chunk: ', chunk_name, '...'),
                           file.path(time_frame$output_folder, 'gpm_log.txt'), append = TRUE)
                   }
                   lapply(files[stringr::str_detect(files, chunk_name)], data.table::fread) %>%
                     Reduce(dplyr_join, .) %>%
                     as.data.frame()
                 }) %>%
                   bind_rows() %>%
                   list())
        }
    }

  return(Reduce(dplyr_join, return_frame) %>% as.data.frame())
}
