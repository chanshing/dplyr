test_that("key vars are found", {
  vars <- join_cols(c("x", "y"), c("x", "z"), by = join_by(x))
  expect_equal(vars$x$key, c(x = 1L))
  expect_equal(vars$y$key, c(x = 1L))

  vars <- join_cols(c("a", "x", "b"), c("x", "a"), by = join_by(x))
  expect_equal(vars$x$key, c(x = 2L))
  expect_equal(vars$y$key, c(x = 1L))

  vars <- join_cols(c("x", "y"), c("a", "x", "z"), by = join_by(y == z))
  expect_equal(vars$x$key, c(y = 2L))
  expect_equal(vars$y$key, c(y = 3L))

  vars <- join_cols(c("x", "y"), c("a", "x", "z"), by = join_by(y >= z))
  expect_equal(vars$x$key, c(y = 2L))
  expect_equal(vars$y$key, c(y = 3L))
})

test_that("y key matches order and names of x key", {
  vars <- join_cols(c("x", "y", "z"), c("c", "b", "a"), by = join_by(x == a, y == b))
  expect_equal(vars$x$key, c(x = 1L, y = 2L))
  expect_equal(vars$y$key, c(x = 3L, y = 2L))
})

test_that("duplicate column names are given suffixes", {
  vars <- join_cols(c("x", "y"), c("x", "y"), by = join_by(x))
  expect_equal(vars$x$out, c("x" = 1, "y.x" = 2))
  expect_equal(vars$y$out, c("y.y" = 2))

  # including join vars when keep = TRUE
  vars <- join_cols(c("x", "y"), c("x", "y"), by = join_by(x), keep = TRUE)
  expect_equal(vars$x$out, c("x.x" = 1, "y.x" = 2))
  expect_equal(vars$y$out, c("x.y" = 1, "y.y" = 2))

  vars <- join_cols(c("x", "y"), c("x", "y"), by = join_by(x < x), keep = TRUE)
  expect_equal(vars$x$out, c("x.x" = 1, "y.x" = 2))
  expect_equal(vars$y$out, c("x.y" = 1, "y.y" = 2))

  # suffixes don't create duplicates
  vars <- join_cols(c("x", "y", "y.x"), c("x", "y"), by = join_by(x))
  expect_equal(vars$x$out, c("x" = 1, "y.x" = 2, "y.x.x" = 3))
  expect_equal(vars$y$out, c("y.y" = 2))

  # but not when they're the join vars
  vars <- join_cols(c("A", "A.x"), c("B", "A.x", "A"), by = join_by(A.x))
  expect_named(vars$x$out, c("A.x.x", "A.x"))
  expect_named(vars$y$out, c("B", "A.y"))

  # or when no suffix is requested
  vars <- join_cols(c("x", "y"), c("x", "y"), by = join_by(x), suffix = c("", ".y"))
  expect_equal(vars$x$out, c("x" = 1, "y" = 2))
  expect_equal(vars$y$out, c("y.y" = 2))
})

test_that("duplicate non-equi key columns are given suffixes", {
  vars <- join_cols(c("a", "y", "z"), c("b", "y", "z"), by = join_by(y >= y, z <= z))
  expect_equal(vars$x$out, c("a" = 1, "y.x" = 2, "z.x" = 3))
  expect_equal(vars$y$out, c("b" = 1, "y.y" = 2, "z.y" = 3))
})

test_that("NA names are preserved", {
  vars <- join_cols(c("x", NA), c("x", "z"), by = join_by(x))
  expect_named(vars$x$out, c("x", NA))

  vars <- join_cols(c("x", NA), c("x", NA), by = join_by(x))
  expect_named(vars$x$out, c("x", "NA.x"))
  expect_named(vars$y$out, "NA.y")
})

test_that("by default, `by` columns omited from y with equi-conditions, but not non-equi conditions" , {
  # equi keys always keep the LHS name, regardless of whether of not a duplicate exists in the RHS
  # non-equi keys will get a suffix if a duplicate exists
  vars <- join_cols(c("x", "y", "z"), c("x", "y", "z"), by = join_by(x == y, y > z))
  expect_equal(vars$x$out, c("x" = 1, "y" = 2, "z.x" = 3))
  expect_equal(vars$y$out, c("x.y" = 1, "z.y" = 3))

  # unless specifically requested either way
  vars <- join_cols(c("x", "y", "z"), c("x", "y", "z"), by = join_by(x == y, y > z), keep = TRUE)
  expect_equal(vars$x$out, c("x.x" = 1, "y.x" = 2, "z.x" = 3))
  expect_equal(vars$y$out, c("x.y" = 1, "y.y" = 2, "z.y" = 3))

  vars <- join_cols(c("x", "y", "z"), c("x", "y", "z"), by = join_by(x == y, y > z), keep = FALSE)
  expect_equal(vars$x$out, c("x" = 1, "y" = 2, "z" = 3))
  expect_equal(vars$y$out, c("x.y" = 1))
})

test_that("can duplicate key between non-equi conditions", {
  vars <- join_cols("x", c("xl", "xu"), by = join_by(x > xl, x < xu))

  expect_identical(vars$x$key, c(x = 1L, x = 1L))
  expect_identical(vars$x$out, c(x = 1L))

  expect_identical(vars$y$key, c(x = 1L, x = 2L))
  expect_identical(vars$y$out, c(xl = 1L, xu = 2L))

  expect_identical(
    join_cols("x", c("xl", "xu"), by = join_by(x > xl, x < xu), keep = NULL),
    join_cols("x", c("xl", "xu"), by = join_by(x > xl, x < xu), keep = TRUE)
  )

  # unless `key = FALSE`, since we'd have to merge both `xl` and `xu` into `x`
  expect_snapshot(error = TRUE, join_cols("x", c("xl", "xu"), by = join_by(x > xl, x < xu), keep = FALSE))
  expect_snapshot(error = TRUE, join_cols(c("xl", "xu"), "x", by = join_by(xl < x, xu > x), keep = FALSE))
})

test_that("can't duplicate key between equi condition and non-equi condition", {
  expect_snapshot(error = TRUE, join_cols("x", c("xl", "xu"), by = join_by(x > xl, x == xu)))
  expect_snapshot(error = TRUE, join_cols(c("xl", "xu"), "x", by = join_by(xl < x, xu == x)))
})

test_that("emits useful messages", {
  # names
  expect_snapshot(error = TRUE, join_cols(c("x", "y"), c("y", "y"), join_by(y)))
  expect_snapshot(error = TRUE, join_cols(c("y", "y"), c("x", "y"), join_by(y)))

  xy <- c("x", "y")
  xyz <- c("x", "y", "z")

  # join vars errors
  expect_snapshot(error = TRUE, join_cols(xy, xy, by = as_join_by(list(1, 2))))
  expect_snapshot(error = TRUE, join_cols(xy, xy, by = as_join_by(c("x", NA))))
  expect_snapshot(error = TRUE, join_cols(xy, xy, by = as_join_by(c("aaa", "bbb"))))

  # join vars uniqueness
  expect_snapshot(error = TRUE, join_cols(xy, xy, by = as_join_by(c("x", "x", "x"))))
  expect_snapshot(error = TRUE, join_cols(xyz, xyz, by = join_by(x, x > y, z)))

  # suffixes
  expect_snapshot(error = TRUE, join_cols(xy, xy, by = join_by(x), suffix = "x"))
  expect_snapshot(error = TRUE, join_cols(xy, xy, by = join_by(x), suffix = c("", NA)))
})
