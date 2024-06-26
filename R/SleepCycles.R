#' @title Sleep Cycle Detection
#'
#' @description Sleep cycles are largely detected according to the originally proposed criteria by Feinberg & Floyd (1979) and as described in Blume & Cajochen (2020) \doi{10.31219/osf.io/r2q8v} from sleep staging results.
#' NREM periods are periods starting with N1 (default) or N2 at the beginning of the night and W or another NREM stage following a REM period. NREMPs have a minimal duration of 15min (can include W, up to <5min REM, except for the first REMP,
#' for which there is no minimum duration criterion). REM following a NREM period always represents a potential REM period (REMP), however any REMP must be at least
#' 5min (except the first REMP, for which no minimum duration criterion is applied). If a NREMP exceeds 120min in duration (excl. wake), it can be split into 2 parts.
#' The new cycle then starts with the first N3 episode following a phase (>12min) with any other stage than N3, that is
#' a lightening of sleep (cf. Rudzik et al., 2020; Jenni et al., 2004; Kurth et al., 2010). The code makes suggestions where
#' splitting could take place according to the criteria and visualises the potential splitting points on top of a hypnogram. The user can then interactively choose where to split the NREMP. However, the code also offers the possibility to provide a numeric value for an epoch
#' at which to split or you can decide to not split at all. A combination of a NREMP and the following REMP represents one sleep cycle, except for the case when a NREMP is split.
#' In this case, the first of the two resulting NREMPs represents a sleep cycle (without REM).
#'
#' The function requires any sleep staging results file with a column, in which the sleep stages are coded
#' in the usual 0,1,2,3,5 (i.e., W, N1, N2, N3, REM) pattern (i.e., a numeric vector). The user can define other integers to be handled as W or N3
#' (i.e. in the case stagings were done according to the Rechtschaffen and Kales criteria including S3 and S4). The presence of further columns in the data is not an issue.
#' Staging must be in 30s epochs. Besides text files, it can also handle csv files and marker files for the Brain Vision Analyzer (filetype = "txt" (default), "csv", or "vmrk").

#' @details Besides sleep cycles (NREM-REM), the result also splits the NREM and REM parts of each cycle in percentiles.
#' In case the length of a period is not divisible by 10 (e.g., 203 epochs), one epoch is added to percentiles in a randomized fashion to reach the correct
#' length of a period (here: 7 percentiles of 20 epochs, 3 of 21 epochs).
#'
#' The code offers to choose whether incomplete periods should be removed at the end of the night (rm_incomplete_period, default = F). Incomplete periods are defined by cycles that are followed
#' by <5min NREM or W (e.g. because a participant is woken up).
#'
#' Although this is not encouraged, for some participants it may be necessary to decrease the minimum duration of REM from 5min to 4 or 4.5min
#' as otherwise a seemingly 'clear' REM period is skipped. While the default length of REMPs is 10 segments, it can be decreased.
#'
#' The user can either process all files in a given directory (default) or specific files by specifying a vector of files.
#'
#' By default, the function produces and saves a plot for visual inspection of the results.
#'
#' @references Feinberg, I. and Floyd, T.C. (1979), Systematic Trends Across the Night in Human Sleep Cycles. Psychophysiology, 16: 283-291. https://doi.org/10.1111/j.1469-8986.1979.tb02991.x
#' @references Rudzik, F., Thiesse, L., Pieren, R., Heritier, H., Eze I.C., Foraster, M., Vienneau, D., Brink, M., Wunderli, J.M., Probst-Hensch, N., Roeoesli, M., Fulda, S., Cajochen, C. (2020). Ultradian modulation of cortical arousals during sleep: effects of age and exposure to nighttime transportation noise. Sleep, Volume 43, Issue 7. https://doi.org/10.1093/sleep/zsz324
#' @references Jenni, O.E., Carskadon, M.A. (2004). Spectral Analysis of the Sleep Electroencephalogram During Adolescence. Sleep, Volume 27, Issue 4, Pages 774-783. https://doi.org/10.1093/sleep/27.4.774
#' @references Kurth, S., Ringli, M., Geiger, A., LeBourgeois, M., Jenni, O.G., Huber, R. (2010). Mapping of Cortical Activity in the First Two Decades of Life: A High-Density Sleep Electroencephalogram Study. Journal of Neuroscience. 30 (40) 13211-13219; DOI: 10.1523/JNEUROSCI.2532-10.2010
#'
#' @param p character vector indicating the directory containing the sleep staging files
#' @param sleepstart character vector indicating whether the first NREMP at the beginning of the night should start with N1 or N2. Default: N1
#' @param files numeric vector indicating which files in 'p' to process. Default: NA
#' @param filetype character indicating file type of the files containing the sleep staging results. Can be "txt" (default) or "csv", or "vmrk" (i.e., marker files for Brain Vision Analyzer Software).
#' @param treat_as_W numeric vector indicating which values should be treated as 'wake'. Default: NA
#' @param treat_as_N3 numeric vector indicating which values should be treated as 'N3'. Default: NA
#' @param rm_incomplete_period logical: should incomplete period at the end of the night be removed? Default: FALSE.
#' @param plot logical: should a plot for the result of the detection procedure be generated and saved? Default: TTRUE.
#' @param REMP_length numeric value specifying the minimum duration of a REM period following the first REM period. Default is 10 segments (i.e. 5 minutes). Decreasing the min. length is not encouraged and should only be done following careful consideration.
#'
#' @return Saves results of the detection in a results folder in 'p'. The resulting textfile contains the sleepstages in a column named 'SleepStages', the sleep cycles in
#' a column 'SleepCycles' (numeric value indicating the cycle number), information on whether it is a NREM or REM period (numeric value in column 'N_REM', 0 = NREM, 1 = REM), and an indicator of the percentiles
#' of the (N)REM period of the cycle (numeric value in 'percentile' column; 1 = first percentile, 2 = second percentile, etc.). In case a (N)REM period is less than 10 epochs long,
#' no percentiles are calculated (all epochs are coded as '1' in the 'percentile' column).
#'
#' @import ggplot2 reshape2 plyr stringr viridis
#'
#' @importFrom stats na.omit time
#' @importFrom utils data glob2rx head read.csv read.table tail write.table
#'
#' @examples
#' data(sleepstages)
#' olddir <- getwd()
#' newdir <- file.path(tempdir(),"SleepCycles_exmpl")
#' dir.create(newdir, showWarnings = FALSE)
#' write.table(sleepstages, file = paste(newdir, "sleepstages.vmrk", sep = "/"),
#' row.names=FALSE, col.names = FALSE, quote = FALSE, sep = ",")
#' SleepCycles(newdir, filetype = "vmrk")
#' setwd(olddir)
#'
#' \dontrun{
#' # Dataset that requires splitting of a NREMP
#' data(sleepstages2)
#' olddir <- getwd()
#' newdir <- file.path(tempdir(),"SleepCycles_exmpl2")
#' dir.create(newdir, showWarnings = FALSE)
#' write.table(sleepstages2, file = paste(newdir, "sleepstages2.txt", sep = "/"),
#'             row.names=FALSE, col.names = TRUE, quote = FALSE, sep = ",")
#' SleepCycles(newdir, filetype = "txt")
#' setwd(olddir)
#' }
#'
#' @export
SleepCycles <- function(p, sleepstart = "N1", files = NA, filetype = "txt", treat_as_W = NA, treat_as_N3 = NA, rm_incomplete_period = FALSE, plot = TRUE, REMP_length = 10, sp=',', hd='y'){

  # # --- set a few things
  oldwd <- getwd()
  on.exit(setwd(oldwd))

  setwd(p)
  filename <- NA
  REMs <- NA
  Description <- NA

  # check if there are result files of this function in the directory as they will mess with the code
  # stop code execution if they are found
  x <- list.files(p, pattern = glob2rx("*SCycles.txt"))
  if (length(x)>0){
    stop("Please remove files from previous Sleep Cycle detections from the folder.")
  }

  #----- list all files in directory
  if (filetype == "vmrk"){
    d <- list.files(p, pattern = "*.vmrk")
    hd <- NA
  }else if (filetype == "txt"){
    d <- list.files(p, pattern = "*.txt")
    if (sp == "tabulator"){
      sp = "\t"
    }
    if (sp == "NA"){
      sp = ""
    }
  }else if (filetype == "csv"){
    d <- list.files(p, pattern = "*.csv") # csv files were added on 17/02/21
    hd <- readline("Do your files have a header with column names (y/n)? ") #check if first line contains column names
    sp <- readline("Which separator do the files have? Choose one of the following: , or ; or tabulator. If the data only contains one column, write NA.") #check which separator is used
    if (sp == "tabulator"){
      sp = "\t"
    }
    if (sp == "NA"){
      sp = ""
    }
  }

  #----- has a vector for a subset of files to be processed been specified?
  if (!all(is.na(files))){
    d <- d[files]
  }

  #----- prepare results folder, create new directory
  sv <- paste("SleepCycles", Sys.Date(), sep = "_")
  dir.create(file.path(paste(p, sv, sep = "/")), showWarnings = FALSE)

  #--------------------------------------------------------
  #----- loop through files to determine sleep cycles
  #--------------------------------------------------------

  for (i in 1:length(d)){
    print(i) #tell user which file is processed
    filename <- d[i]

    ## load data
    D <- load_data(filetype, filename, treat_as_W, treat_as_N3, hd, sp)
    data <- D[[1]]
    cycles <- D[[2]]
    rm(D)

    ##-- prep data for further processing
    data <- prep_data(data, treat_as_W, treat_as_N3)

    # Find NREM periods: start with N1 and can then also include W. >=15min
    NREMWs <- which(data$Descr3 == "NREM"| data$Descr3 == "W") #which 30s epochs are NREM or wake
    NREMs <- which(data$Descr3 == "NREM")
    first_N2 <- which(data$Description == 2)[1] # for option to have first NREMP start with N2

    # exclude W or W/N1 at the beginning of the night before the first NREM epoch
    if (sleepstart == "N1"){
      NREMWs <- subset(NREMWs, NREMWs >= NREMs[1])
    }else if (sleepstart == "N2"){
      NREMWs <- subset(NREMWs, NREMWs >= first_N2)
    }

    ## Loop through NREMWs
    # check if the sequence of NREWM is continuous and the period is >=15min AND beginning is not wake -> first NREMP
    # Further: find discontinuities in the sequence (= potential beginnings of new NREM periods during the remaining night)
    NREMWs_start2 <- find_NREMPs(NREMWs, data)
    data$CycleStart <- NA
    data$CycleStart[NREMWs_start2] <- "NREMP" #marks all potential NREM period beginnings

    ## Find REM episodes (first can be <5min, others have to be at least 5min)
    REMs_start2 <- find_REMPs(REMs, REMP_length, data)
    data$CycleStart[REMs_start2] <- "REMP"

    ## remove several NREMPs or REMPs in a row
    rm <- delete_reps(data)
    data$CycleStart[c(rm)] <- NA

    ## is any NREM part (excl. wake) of a NREMP longer than 120min?
    toolong <- is.toolong(data)
    toolong1 <- toolong # for comparison with second round
    ## now split NREMPs that are too long
    if (length(toolong) > 0){
      data <- toolong_split(data, toolong, filename)
    }

    ## now check again if there are still NREMPs > 120min
    ## is any NREM part (excl. wake) of a NREMP longer than 120min?
    rm(toolong)
    toolong <- is.toolong(data)
    toolong2 <- toolong

    ## now split NREMPs that are too long
    if (length(toolong) > 0 & any(toolong2 != toolong1)){
      message("~ Still detected a NREMP > 120min. Let's go through the splitting process again. ~")
      data <- toolong_split(data, toolong, filename)
    }

    # -----------------------------------------------------------------------------
    # now finish and add cycle markers and percentiles

    # add cycle markers to file (only for NREM cycles) & add NREM vs. REM part info
    data <- addinfo1(data)

    # remove incomplete NREM-REM cycle at the end of the night (i.e., cycles followed by <5min NREM or W)
    if (rm_incomplete_period == TRUE){
      data  <- rm.incompleteperiod(data)

    #remove NREM/W following last REMP (in case no new NREMP begins) or REM/W following last NREMP  (in case no new REMP begins)
    }else if (rm_incomplete_period == FALSE){
      data <- clean_endofnight(data)
    }

    ## merge cycle marker & NREM/REM marker & add percentiles of NREM & REM parts
    data <- addinfo2(data)

    ## prep new marker file with cycle info
    if (filetype == "vmrk"){
      cycles <- cycles[,-c(4,5)]
    }
    cycles$Description <- data$cycle_perc
    cycles$SleepCycle <- data$cycles
    cycles$N_REM <- data$REM.NREM
    cycles$percentile <- data$perc

    ## save new file
    svv <- paste(p, sv, sep = "/")
    name <- unlist(stringr::str_split(filename, pattern = "[.]"))[1]
    savename <- paste(name, "SCycles.txt", sep = "_")
    write.table(cycles, file = paste(svv, savename, sep = "/"), row.names = F)

    ## plot results if desired
    if (plot == TRUE){
      plot_result(data, filetype, name, svv)
    } else {
      return(cycles)
    }
  }
}

#' @export
format_events <- function(events){

  events.vmrk = data.frame(Description = as.character(events$event))
  events.vmrk$Description[events.vmrk$Description == "AWA"] = 0
  events.vmrk$Description[events.vmrk$Description == "N1"] = 1
  events.vmrk$Description[events.vmrk$Description == "N2"] = 2
  events.vmrk$Description[events.vmrk$Description == "N3"] = 3
  events.vmrk$Description[events.vmrk$Description == "REM"] = 5
  events.vmrk$Description = as.integer(events.vmrk$Description)
  events.vmrk$Type = "SleepStage"
  events.vmrk = events.vmrk[,c(2,1)]

  newdir <- file.path(
    tempdir(),
    paste0(
      "SleepCycles-",
      substr(paste(sample(1:1000),collapse=''),1,10)))

  dir.create(newdir, showWarnings = FALSE)

  write.table(
    events.vmrk,
    file = paste(newdir, "events.txt", sep = "/"),
    row.names=FALSE,
    col.names = TRUE,
    quote = FALSE,
    sep = ",")
  return(newdir)
}
