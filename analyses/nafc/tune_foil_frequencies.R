#!/usr/bin/env Rscript
## Search Kilo / foil frequencies: A vs B differ on bands 1,3,4; shared 2 & 5.
## Two foils per Kilo perturb band 2 (+/-) and band 5 (-/+) symmetrically.
##
## Current study1 mapping (2026-10, row-wise sigdist from Nafc.Rmd):
##   Kilo-A: 40;140;310;1080;1560   Kilo-B: 40;140;400;1230;1560
##   shrimp / whitefish -> near A (low2+high5 / high2+low5 on A backbone)
##   dolphin pod / whale -> near B (same delta pattern on B backbone)
##   Mean d(own foils) ~0.219 each side; cross ~0.321; d(A,B)=0.234

scale_band_hz <- function(f) {
  if (f <= 250) f / 250
  else if (f <= 750) (f - 250) / 500 + 1.0
  else (f - 750) / 1000 + 2.0
}
split_waterfall_rows <- function(sig) {
  list(
    row1 = sig[sig <= 250],
    row2 = sig[sig > 250 & sig <= 750],
    row3 = sig[sig > 750]
  )
}
row_ss <- function(a, b) {
  a <- sort(a)
  b <- sort(b)
  if (length(a) == 0 && length(b) == 0) return(0)
  nmin <- min(length(a), length(b))
  ss <- 0
  if (nmin > 0) {
    sa <- vapply(a[seq_len(nmin)], scale_band_hz, numeric(1))
    sb <- vapply(b[seq_len(nmin)], scale_band_hz, numeric(1))
    ss <- ss + sum((sa - sb)^2)
  }
  if (length(a) > nmin) {
    sa <- vapply(a[(nmin + 1):length(a)], scale_band_hz, numeric(1))
    ss <- ss + sum(sa^2)
  }
  if (length(b) > nmin) {
    sb <- vapply(b[(nmin + 1):length(b)], scale_band_hz, numeric(1))
    ss <- ss + sum(sb^2)
  }
  ss
}
sigdist <- function(sig1, sig2) {
  r1 <- split_waterfall_rows(sig1)
  r2 <- split_waterfall_rows(sig2)
  sqrt(row_ss(r1$row1, r2$row1) + row_ss(r1$row2, r2$row2) + row_ss(r1$row3, r2$row3))
}

valid_sig <- function(v, min_sep = 25L) {
  if (any(is.na(v)) || length(v) != 5L) return(FALSE)
  if (v[1] > 250 || v[2] > 250) return(FALSE) # bands 1–2 in low row
  if (v[3] <= 250 || v[3] > 750) return(FALSE)
  if (v[4] <= 750 || v[5] <= 750) return(FALSE)
  if (v[5] <= v[4]) return(FALSE)
  if (any(diff(sort(v)) < min_sep)) return(FALSE)
  TRUE
}

make_design <- function(a1, a3, a4, b1, b3, b4, s2, s5, d2, d5) {
  kA <- c(a1, s2, a3, a4, s5)
  kB <- c(b1, s2, b3, b4, s5)
  fA1 <- c(a1, s2 + d2, a3, a4, s5 - d5) # higher 2, lower 5
  fA2 <- c(a1, s2 - d2, a3, a4, s5 + d5)
  fB1 <- c(b1, s2 + d2, b3, b4, s5 - d5)
  fB2 <- c(b1, s2 - d2, b3, b4, s5 + d5)
  list(kA = kA, kB = kB, fA1 = fA1, fA2 = fA2, fB1 = fB1, fB2 = fB2)
}

score_design <- function(d, tol = 0.05) {
  kA <- d$kA
  kB <- d$kB
  sigs <- list(d$fA1, d$fA2, d$fB1, d$fB2)
  if (!all(vapply(sigs, valid_sig, logical(1)))) return(Inf)
  if (!valid_sig(kA) || !valid_sig(kB)) return(Inf)

  dA <- c(sigdist(kA, d$fA1), sigdist(kA, d$fA2))
  dB <- c(sigdist(kB, d$fB1), sigdist(kB, d$fB2))
  mA <- mean(dA)
  mB <- mean(dB)
  sym_err <- abs(mA - mB) / mean(c(mA, mB))

  # near > far (foils closer to own Kilo than opposite)
  cross <- c(
    sigdist(kB, d$fA1), sigdist(kB, d$fA2),
    sigdist(kA, d$fB1), sigdist(kA, d$fB2)
  )
  own <- c(dA, dB)
  if (any(own >= cross)) return(Inf)

  dAB <- sigdist(kA, kB)
  # Near foils must look more like own Kilo than the opposite Kilo prototype
  if (any(dA >= dAB) || any(dB >= dAB)) return(Inf)

  target <- 0.22
  spread_pen <- sum((own - target)^2)

  sym_err * 10 + spread_pen + 0.5 * (dAB - 0.26)^2
}

fmt <- function(v) paste(as.integer(round(v)), collapse = ";")

best <- list(score = Inf)
# Anchor from current study; shared 2/5 between kilos
for (s2 in seq(130, 165, by = 5)) {
  for (s5 in seq(1480, 1580, by = 20)) {
    for (d2 in seq(15, 55, by = 5)) {
      for (d5 in seq(40, 120, by = 10)) {
        d <- make_design(
          a1 = 40, a3 = 310, a4 = 1080,
          b1 = 40, b3 = 400, b4 = 1230,
          s2 = s2, s5 = s5, d2 = d2, d5 = d5
        )
        sc <- score_design(d)
        if (sc < best$score) best <- list(score = sc, design = d, s2 = s2, s5 = s5, d2 = d2, d5 = d5)
      }
    }
  }
}

if (!is.finite(best$score)) stop("no valid design found")

d <- best$design
kA <- d$kA
kB <- d$kB
foils <- list(
  `foil-A-high2-low5` = d$fA1,
  `foil-A-low2-high5` = d$fA2,
  `foil-B-high2-low5` = d$fB1,
  `foil-B-low2-high5` = d$fB2
)

cat("Best grid params: s2=", best$s2, " s5=", best$s5, " d2=", best$d2, " d5=", best$d5, "\n\n")
cat("Kilo-A:", fmt(kA), "\n")
cat("Kilo-B:", fmt(kB), "\n\n")
for (nm in names(foils)) cat(nm, ":", fmt(foils[[nm]]), "\n")

dA <- sapply(foils[1:2], sigdist, sig2 = kA)
dB <- sapply(foils[3:4], sigdist, sig2 = kB)
cat("\nMean dist own Kilo (target symmetry):\n")
cat("  Kilo-A foils:", paste(round(dA, 4), collapse = ", "), " mean=", round(mean(dA), 4), "\n")
cat("  Kilo-B foils:", paste(round(dB, 4), collapse = ", "), " mean=", round(mean(dB), 4), "\n")
cat("  Symmetry gap:", sprintf("%.1f%%", 100 * abs(mean(dA) - mean(dB)) / mean(c(dA, dB))), "\n")

cat("\nCross distances (should be > own):\n")
for (nm in names(foils)) {
  cat(sprintf("  %s: d(A)=%.3f d(B)=%.3f\n", nm, sigdist(kA, foils[[nm]]), sigdist(kB, foils[[nm]])))
}

cat("\nDistmatrix row Kilo-A:\n")
nms <- c("kA", names(foils), "kB")
all_s <- c(list(kA = kA), foils, list(kB = kB))
for (nm in nms[-1]) cat(" ", nm, round(sigdist(kA, all_s[[nm]]), 3), "\n")
