#' Detect where values fall in a specified range
#'
#' This is a shortcut for `x >= left & x <= right`, implemented for local
#' vectors and translated to the appropriate SQL for remote tables.
#'
#' @param x A vector
#' @param left,right Boundary values. Both `left` and `right` are recycled to
#'   the size of `x` and are cast to the type of `x`.
#' @export
#' @examples
#' between(1:12, 7, 9)
#'
#' x <- rnorm(1e2)
#' x[between(x, -1, 1)]
#'
#' # On a tibble using `filter()`
#' filter(starwars, between(height, 100, 150))
between <- function(x, left, right) {
  args <- list(left = left, right = right)
  args <- vec_cast_common(!!!args, .to = x)
  args <- vec_recycle_common(!!!args, .size = vec_size(x))
  left <- args[[1L]]
  right <- args[[2L]]

  left <- vec_compare(x, left)
  left <- left >= 0L

  right <- vec_compare(x, right)
  right <- right <= 0L

  left & right
}

#' Cumulativate versions of any, all, and mean
#'
#' dplyr provides `cumall()`, `cumany()`, and `cummean()` to complete R's set
#' of cumulative functions.
#'
#' @section Cumulative logical functions:
#'
#' These are particularly useful in conjunction with `filter()`:
#'
#' * `cumall(x)`: all cases until the first `FALSE`.
#' * `cumall(!x)`: all cases until the first `TRUE`.
#' * `cumany(x)`: all cases after the first `TRUE`.
#' * `cumany(!x)`: all cases after the first `FALSE`.
#'
#' @param x For `cumall()` and `cumany()`, a logical vector; for
#'   `cummean()` an integer or numeric vector.
#' @return A vector the same length as `x`.
#' @examples
#' # `cummean()` returns a numeric/integer vector of the same length
#' # as the input vector.
#' x <- c(1, 3, 5, 2, 2)
#' cummean(x)
#' cumsum(x) / seq_along(x)
#'
#' # `cumall()` and `cumany()` return logicals
#' cumall(x < 5)
#' cumany(x == 3)
#'
#' # `cumall()` vs. `cumany()`
#' df <- data.frame(
#'   date = as.Date("2020-01-01") + 0:6,
#'   balance = c(100, 50, 25, -25, -50, 30, 120)
#' )
#' # all rows after first overdraft
#' df %>% filter(cumany(balance < 0))
#' # all rows until first overdraft
#' df %>% filter(cumall(!(balance < 0)))
#'
#' @export
cumall <- function(x) {
  .Call(`dplyr_cumall`, as.logical(x))
}

#' @rdname cumall
#' @export
cumany <- function(x) {
  .Call(`dplyr_cumany`, as.logical(x))
}

#' @rdname cumall
#' @export
cummean <- function(x) {
  .Call(`dplyr_cummean`, as.numeric(x))
}
