# Supplementary verification using imputation 1 only; see ../README.md.
# Input data and every generated output are private and must not be committed.
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2L) {
  stop("Usage: Rscript --vanilla run_wrmst_analysis.R PRIVATE_INPUT.dta PRIVATE_OUTPUT [n_boot] [seed]")
}
input_file <- args[[1]]
output_dir <- args[[2]]
n_boot <- if (length(args) >= 3) as.integer(args[[3]]) else 2000L
seed <- if (length(args) >= 4) as.integer(args[[4]]) else 20260904L

required_packages <- c("haven", "survival", "survRM2", "adjustedCurves", "cobalt")
missing_packages <- required_packages[
  !vapply(required_packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))
]
if (length(missing_packages) > 0) {
  stop("Missing R packages: ", paste(missing_packages, collapse = ", "))
}

dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

analysis_warnings <- character()
capture_warnings <- function(expr) {
  withCallingHandlers(
    expr,
    warning = function(w) {
      analysis_warnings <<- unique(c(analysis_warnings, conditionMessage(w)))
      invokeRestart("muffleWarning")
    }
  )
}

kish_ess <- function(x) {
  x <- x[is.finite(x) & x > 0]
  sum(x)^2 / sum(x^2)
}

extract_rmst2 <- function(data, tau, analysis_id, analysis_label) {
  fit <- survRM2::rmst2(
    time = data$time_os_m,
    status = data$event_os,
    arm = data$trt,
    tau = tau
  )

  arm_c <- fit$RMST.arm0$result["RMST", ]
  arm_b <- fit$RMST.arm1$result["RMST", ]
  contrast <- fit$unadjusted.result["RMST (arm=1)-(arm=0)", ]

  data.frame(
    analysis_id = analysis_id,
    analysis = analysis_label,
    tau_months = tau,
    b_n = sum(data$trt == 1),
    b_rmst = unname(arm_b["Est."]),
    b_ci_lower = unname(arm_b["lower .95"]),
    b_ci_upper = unname(arm_b["upper .95"]),
    c_n = sum(data$trt == 0),
    c_rmst = unname(arm_c["Est."]),
    c_ci_lower = unname(arm_c["lower .95"]),
    c_ci_upper = unname(arm_c["upper .95"]),
    rmst_diff_b_minus_c = unname(contrast["Est."]),
    diff_ci_lower = unname(contrast["lower .95"]),
    diff_ci_upper = unname(contrast["upper .95"]),
    p_value = unname(contrast["p"]),
    group_ci_method = "survRM2 asymptotic normal",
    diff_ci_method = "survRM2 asymptotic normal",
    n_boot = NA_integer_,
    stringsAsFactors = FALSE
  )
}

dat_all <- haven::read_dta(input_file)
dat_all <- as.data.frame(dat_all)

required_vars <- c(
  "id", "_mi_m", "trt", "time_os_m", "event_os", "ps", "mp", "stbw",
  "sex", "age_cat", "side", "grade", "primary_n", "ehd3", "ras_mut",
  "recu_6m", "tumor_count_cat", "tumor_size_cat", "cea_cat", "ca199_cat",
  "grade_mind", "primary_n_mind", "tumor_count_cat_mind",
  "tumor_size_cat_mind", "cea_cat_mind", "ca199_cat_mind"
)
missing_vars <- setdiff(required_vars, names(dat_all))
if (length(missing_vars) > 0) {
  stop("Required variables missing from data: ", paste(missing_vars, collapse = ", "))
}

dat_full <- dat_all[dat_all$`_mi_m` == 1, required_vars, drop = FALSE]
if (nrow(dat_full) == 0) stop("No observations found for _mi_m = 1.")
if (anyDuplicated(dat_full$id)) stop("Duplicate patient IDs found in _mi_m = 1.")
if (!all(dat_full$trt %in% c(0, 1))) stop("trt must be coded 0/1.")
if (!all(dat_full$event_os %in% c(0, 1))) stop("event_os must be coded 0/1.")
if (any(!is.finite(dat_full$time_os_m)) || any(dat_full$time_os_m < 0)) {
  stop("time_os_m contains missing, infinite, or negative values.")
}

core_eligible <- dat_full$primary_n_mind == 0 &
  dat_full$tumor_count_cat_mind == 0 &
  dat_full$tumor_size_cat_mind == 0
if (any(is.na(core_eligible))) stop("Core eligibility indicators contain missing values.")

dat_weighted <- dat_full[core_eligible, , drop = FALSE]
dat_weighted$group <- factor(
  ifelse(dat_weighted$trt == 1, "B", "C"),
  levels = c("C", "B")
)

expected_counts <- c(full_b = 83L, full_c = 89L, weighted_b = 83L, weighted_c = 79L)
observed_counts <- c(
  full_b = sum(dat_full$trt == 1),
  full_c = sum(dat_full$trt == 0),
  weighted_b = sum(dat_weighted$trt == 1),
  weighted_c = sum(dat_weighted$trt == 0)
)
if (!identical(unname(observed_counts), unname(expected_counts))) {
  stop(
    "Cohort count mismatch. Observed: ",
    paste(names(observed_counts), observed_counts, collapse = ", ")
  )
}

ps_formula <- group ~
  sex + age_cat + side + factor(grade) + primary_n + factor(ehd3) +
  factor(ras_mut) + recu_6m + factor(tumor_count_cat) +
  factor(tumor_size_cat) + factor(cea_cat) + factor(ca199_cat) +
  grade_mind + primary_n_mind + tumor_count_cat_mind +
  tumor_size_cat_mind + cea_cat_mind + ca199_cat_mind

ps_model <- capture_warnings(
  glm(ps_formula, data = dat_weighted, family = binomial(link = "logit"))
)
if (!isTRUE(ps_model$converged)) stop("Propensity score model did not converge.")

dat_weighted$ps_r <- predict(ps_model, newdata = dat_weighted, type = "response")
p_b <- mean(dat_weighted$group == "B")
dat_weighted$stbw_r <- ifelse(
  dat_weighted$group == "B",
  p_b / dat_weighted$ps_r,
  (1 - p_b) / (1 - dat_weighted$ps_r)
)
if (any(!is.finite(dat_weighted$stbw_r)) || any(dat_weighted$stbw_r <= 0)) {
  stop("Re-estimated stabilized weights contain non-finite or non-positive values.")
}

taus <- c(36, 60)
if (any(taus > min(tapply(dat_weighted$time_os_m, dat_weighted$group, max)))) {
  stop("At least one RMST truncation time exceeds the maximum follow-up in a group.")
}

unweighted_results <- do.call(
  rbind,
  c(
    lapply(taus, function(tau) {
      extract_rmst2(dat_full, tau, "unweighted_reference", "Non-weighted: Reference reproduction cohort")
    }),
    lapply(taus, function(tau) {
      extract_rmst2(dat_weighted, tau, "unweighted_restricted", "Non-weighted: weighted-analysis cohort")
    })
  )
)

times_grid <- sort(unique(c(
  0,
  dat_weighted$time_os_m[
    dat_weighted$event_os == 1 & dat_weighted$time_os_m <= max(taus)
  ],
  taus
)))

set.seed(seed)
adj_sw <- capture_warnings(
  adjustedCurves::adjustedsurv(
    data = dat_weighted,
    variable = "group",
    ev_time = "time_os_m",
    event = "event_os",
    method = "iptw_km",
    treatment_model = ps_model,
    stabilize = TRUE,
    trim = FALSE,
    trim_quantiles = FALSE,
    bootstrap = TRUE,
    n_boot = n_boot,
    conf_int = FALSE,
    times = times_grid,
    n_cores = 1
  )
)

rmst_group <- adjustedCurves::adjusted_rmst(
  adjsurv = adj_sw,
  from = 0,
  to = taus,
  conf_int = TRUE,
  conf_level = 0.95,
  interpolation = "steps",
  contrast = "none"
)

weighted_rows <- lapply(taus, function(tau) {
  b <- rmst_group[rmst_group$to == tau & rmst_group$group == "B", , drop = FALSE]
  c_group <- rmst_group[rmst_group$to == tau & rmst_group$group == "C", , drop = FALSE]
  diff_test <- adjustedCurves::adjusted_curve_test(
    adj = adj_sw,
    from = 0,
    to = tau,
    group_1 = "B",
    group_2 = "C",
    conf_level = 0.95,
    interpolation = "steps"
  )

  data.frame(
    analysis_id = "weighted_iptw",
    analysis = "Stabilized IPTW: weighted-analysis cohort",
    tau_months = tau,
    b_n = sum(dat_weighted$group == "B"),
    b_rmst = b$rmst,
    b_ci_lower = b$ci_lower,
    b_ci_upper = b$ci_upper,
    c_n = sum(dat_weighted$group == "C"),
    c_rmst = c_group$rmst,
    c_ci_lower = c_group$ci_lower,
    c_ci_upper = c_group$ci_upper,
    rmst_diff_b_minus_c = diff_test$observed_diff_integral,
    diff_ci_lower = unname(diff_test$conf_int["ci_lower"]),
    diff_ci_upper = unname(diff_test$conf_int["ci_upper"]),
    p_value = diff_test$p_value,
    group_ci_method = "Bootstrap SE with normal approximation",
    diff_ci_method = "Percentile bootstrap",
    n_boot = diff_test$n_boot,
    stringsAsFactors = FALSE
  )
})
weighted_results <- do.call(rbind, weighted_rows)
main_results <- rbind(unweighted_results, weighted_results)

rmst_difference_check <- weighted_results$b_rmst - weighted_results$c_rmst
if (max(abs(rmst_difference_check - weighted_results$rmst_diff_b_minus_c)) > 1e-8) {
  stop("Weighted group RMST values do not reconcile with the reported B-C difference.")
}

stored_valid <- is.finite(dat_weighted$stbw)
weight_max_abs_diff <- if (all(stored_valid)) {
  max(abs(dat_weighted$stbw - dat_weighted$stbw_r))
} else {
  NA_real_
}
ps_max_abs_diff <- max(abs(dat_weighted$ps - dat_weighted$ps_r), na.rm = TRUE)
internal_weight_max_abs_diff <- max(
  abs(unname(adj_sw$weights) - unname(dat_weighted$stbw_r)),
  na.rm = TRUE
)

group_levels <- c("B", "C")
weight_summary <- do.call(rbind, lapply(group_levels, function(g) {
  x <- dat_weighted$stbw_r[dat_weighted$group == g]
  data.frame(
    group = g,
    n = length(x),
    sum_weight = sum(x),
    mean_weight = mean(x),
    sd_weight = stats::sd(x),
    min_weight = min(x),
    p01 = unname(stats::quantile(x, 0.01)),
    p05 = unname(stats::quantile(x, 0.05)),
    median = stats::median(x),
    p95 = unname(stats::quantile(x, 0.95)),
    p99 = unname(stats::quantile(x, 0.99)),
    max_weight = max(x),
    kish_ess = kish_ess(x),
    stringsAsFactors = FALSE
  )
}))

# The legacy smd_* field names below are retained for provenance. No binary="std"
# option is specified; do not assume all returned differences are standardized.
balance <- cobalt::bal.tab(
  ps_formula,
  data = dat_weighted,
  weights = dat_weighted$stbw_r,
  method = "weighting",
  estimand = "ATE",
  un = TRUE
)
balance_detail <- data.frame(
  covariate = rownames(balance$Balance),
  type = balance$Balance$Type,
  smd_unweighted = balance$Balance$Diff.Un,
  smd_weighted = balance$Balance$Diff.Adj,
  stringsAsFactors = FALSE,
  row.names = NULL
)

cohort_counts <- data.frame(
  stage = c(
    "Imputation set 1",
    "Reference non-weighted RMST",
    "Core-staging restriction applied",
    "Finite positive re-estimated weight"
  ),
  definition = c(
    "_mi_m = 1",
    "All B/C patients in _mi_m = 1",
    "Original Primary N, liver lesion count, and maximum diameter all observed",
    "Included in stabilized IPTW analysis"
  ),
  b_n = c(
    sum(dat_full$trt == 1),
    sum(dat_full$trt == 1),
    sum(dat_weighted$trt == 1),
    sum(dat_weighted$trt == 1 & is.finite(dat_weighted$stbw_r) & dat_weighted$stbw_r > 0)
  ),
  c_n = c(
    sum(dat_full$trt == 0),
    sum(dat_full$trt == 0),
    sum(dat_weighted$trt == 0),
    sum(dat_weighted$trt == 0 & is.finite(dat_weighted$stbw_r) & dat_weighted$stbw_r > 0)
  ),
  stringsAsFactors = FALSE
)
cohort_counts$total_n <- cohort_counts$b_n + cohort_counts$c_n

at_risk <- do.call(rbind, lapply(taus, function(tau) {
  do.call(rbind, lapply(group_levels, function(g) {
    data.frame(
      cohort = c("Reference reproduction cohort", "Weighted-analysis cohort"),
      tau_months = tau,
      group = g,
      n_at_risk = c(
        sum(dat_full$time_os_m >= tau & ifelse(dat_full$trt == 1, "B", "C") == g),
        sum(dat_weighted$time_os_m >= tau & dat_weighted$group == g)
      ),
      stringsAsFactors = FALSE
    )
  }))
}))

reference_60 <- main_results[
  main_results$analysis_id == "unweighted_reference" & main_results$tau_months == 60,
  ,
  drop = FALSE
]
reproduction_check <- data.frame(
  item = c(
    "Reference reported approximate 60-month RMST difference (B-C)",
    "Reproduced 60-month RMST difference (B-C)",
    "Reproduced minus reported",
    "Reproduction assessment"
  ),
  value = c(
    "6.8",
    format(reference_60$rmst_diff_b_minus_c, digits = 15, trim = TRUE),
    format(reference_60$rmst_diff_b_minus_c - 6.8, digits = 15, trim = TRUE),
    if (abs(reference_60$rmst_diff_b_minus_c - 6.8) < 0.1) "Matched after rounding" else "Not matched"
  ),
  stringsAsFactors = FALSE
)

max_abs_smd_unweighted <- max(abs(balance_detail$smd_unweighted), na.rm = TRUE)
max_abs_smd_weighted <- max(abs(balance_detail$smd_weighted), na.rm = TRUE)
n_smd_ge_01_unweighted <- sum(abs(balance_detail$smd_unweighted) >= 0.1, na.rm = TRUE)
n_smd_ge_01_weighted <- sum(abs(balance_detail$smd_weighted) >= 0.1, na.rm = TRUE)

analysis_metadata <- data.frame(
  item = c(
    "Analysis date",
    "Source data file",
    "Source MD5",
    "Imputation set",
    "Outcome time variable",
    "Time unit",
    "Event definition",
    "Group B definition",
    "Group C definition",
    "RMST truncation times (months)",
    "Weighted estimand",
    "Weighting method",
    "Weight trimming/truncation",
    "Bootstrap requested",
    "Bootstrap used at 36 months",
    "Bootstrap used at 60 months",
    "Random seed",
    "PS model converged",
    "PS minimum",
    "PS maximum",
    "Maximum absolute SMD before weighting",
    "Maximum absolute SMD after weighting",
    "Covariates with absolute SMD >= 0.1 before weighting",
    "Covariates with absolute SMD >= 0.1 after weighting",
    "Maximum absolute difference: R PS vs stored Stata PS",
    "Maximum absolute difference: new stabilized weight vs stored stbw",
    "Maximum absolute difference: adjustedCurves weight vs manual R weight",
    "Important limitation"
  ),
  value = c(
    format(Sys.Date(), "%Y-%m-%d"),
    basename(input_file),
    unname(tools::md5sum(input_file)),
    "_mi_m = 1",
    "time_os_m",
    "months",
    "event_os = 1 indicates death",
    "trt = 1",
    "trt = 0",
    paste(taus, collapse = ", "),
    "ATE in the restricted B83/C79 cohort",
    "Stabilized IPTW Kaplan-Meier; PS and weights re-estimated within bootstrap samples",
    "None",
    as.character(n_boot),
    as.character(weighted_results$n_boot[weighted_results$tau_months == 36]),
    as.character(weighted_results$n_boot[weighted_results$tau_months == 60]),
    as.character(seed),
    as.character(ps_model$converged),
    format(min(dat_weighted$ps_r), digits = 15, trim = TRUE),
    format(max(dat_weighted$ps_r), digits = 15, trim = TRUE),
    format(max_abs_smd_unweighted, digits = 15, trim = TRUE),
    format(max_abs_smd_weighted, digits = 15, trim = TRUE),
    as.character(n_smd_ge_01_unweighted),
    as.character(n_smd_ge_01_weighted),
    format(ps_max_abs_diff, digits = 15, trim = TRUE),
    format(weight_max_abs_diff, digits = 15, trim = TRUE),
    format(internal_weight_max_abs_diff, digits = 15, trim = TRUE),
    "Exploratory verification using only the first of 22 imputed datasets; between-imputation uncertainty is not included."
  ),
  stringsAsFactors = FALSE
)

package_versions <- data.frame(
  package = c("R", required_packages),
  version = c(
    paste(R.version$major, R.version$minor, sep = "."),
    vapply(required_packages, function(p) as.character(packageVersion(p)), character(1))
  ),
  stringsAsFactors = FALSE
)

# These are private runtime outputs, not public repository content. In particular,
# the curve uses observed event times and the RDS includes patient-level data.
write.csv(main_results, file.path(output_dir, "main_results.csv"), row.names = FALSE, na = "")
write.csv(cohort_counts, file.path(output_dir, "cohort_counts.csv"), row.names = FALSE, na = "")
write.csv(weight_summary, file.path(output_dir, "weight_summary.csv"), row.names = FALSE, na = "")
write.csv(balance_detail, file.path(output_dir, "balance_detail.csv"), row.names = FALSE, na = "")
write.csv(at_risk, file.path(output_dir, "at_risk.csv"), row.names = FALSE, na = "")
write.csv(reproduction_check, file.path(output_dir, "reproduction_check.csv"), row.names = FALSE, na = "")
write.csv(analysis_metadata, file.path(output_dir, "analysis_metadata.csv"), row.names = FALSE, na = "")
write.csv(package_versions, file.path(output_dir, "package_versions.csv"), row.names = FALSE, na = "")
write.csv(adj_sw$adj, file.path(output_dir, "weighted_survival_curve.csv"), row.names = FALSE, na = "")

writeLines(
  if (length(analysis_warnings) == 0) "No captured warnings." else analysis_warnings,
  file.path(output_dir, "analysis_warnings.txt")
)
capture.output(sessionInfo(), file = file.path(output_dir, "sessionInfo.txt"))
saveRDS(adj_sw, file.path(output_dir, "adjustedsurv_m1.rds"))

cat("Analysis completed.\n")
cat("Cohort counts:\n")
print(cohort_counts)
cat("\nMain RMST results:\n")
print(main_results)
cat("\nWeight summary:\n")
print(weight_summary)
cat("\nReproduction check:\n")
print(reproduction_check)
