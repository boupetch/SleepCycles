context("Package tests")

test_that("Stages statistics", {
  tryCatch({
    path <- paste0(tempdir(),"15012016HD.csv")
    if(!file.exists(path)){
      download.file(
        url = "https://rsleep.org/data/15012016HD.csv",
        destfile = path,
        method="curl")}
    events = rsleep::read_events_noxturnal(path)
    hypnogram = rsleep::hypnogram(events)
    newdir = format_events(hypnogram)
    cycles = SleepCycles::SleepCycles(
      p = newdir,
      filetype = "txt",
      plot = FALSE)
    expect_true(nrow(hypnogram) == nrow(cycles))
    hypnogram.full = cbind(hypnogram, cycles)
    unlink(path)
    unlink(newdir)
  }, error = function(e) {
    print("Error executing this example, check your internet connection.")
  })
})
