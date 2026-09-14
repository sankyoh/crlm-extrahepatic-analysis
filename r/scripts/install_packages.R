packages <- c("haven", "survival", "survRM2", "adjustedCurves", "cobalt")
missing <- packages[!vapply(packages, requireNamespace, quietly = TRUE, FUN.VALUE = logical(1))]

if (length(missing) > 0) {
  install.packages(missing, repos = "https://cloud.r-project.org", dependencies = TRUE)
}

versions <- vapply(packages, function(x) as.character(packageVersion(x)), character(1))
print(data.frame(package = packages, version = versions, row.names = NULL))

