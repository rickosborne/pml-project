#!/opt/local/bin/Rscript

library(caret)
library(doMC)
registerDoMC(7)

TRAINING_URL <- "https://d396qusza40orc.cloudfront.net/predmachlearn/pml-training.csv"
TESTING_URL <- "https://d396qusza40orc.cloudfront.net/predmachlearn/pml-testing.csv"
DATA_DIR <- "data"
if (!file.exists(DATA_DIR)) dir.create(DATA_DIR)
MODEL_DIR <- "models"
if (!file.exists(MODEL_DIR)) dir.create(MODEL_DIR)
TRAINING_FILE <- "pml-training.csv"
TESTING_FILE <- "pml-testing.csv"
TRAINING_PATH <- file.path(DATA_DIR, TRAINING_FILE)
TESTING_PATH <- file.path(DATA_DIR, TESTING_FILE)
if (!file.exists(TRAINING_PATH)) download.file(TRAINING_URL, TRAINING_PATH, "curl")
if (!file.exists(TESTING_PATH)) download.file(TESTING_URL, TESTING_PATH, "curl")
SEED <- 20140622

loadAndScrub <- function(filePath, keepCols=NULL) {
    data <- read.csv(filePath)
    # for an easier time, eliminate the summary rows
    data <- subset(data, new_window == "no")
    # get rid of the columns we aren't going to work with
    data <- data[,!(names(data) %in% c("X", "user_name", "cvtd_timestamp", "new_window", "num_window", "raw_timestamp_part_1", "raw_timestamp_part_2"))]
    if (!is.null(keepCols)) {
        data <- data[,names(data) %in% keepCols]
    }
    else {
        emptyCols = c()
        for (name in names(data)) {
            if(class(data[[name]]) == "factor" & name != "classe") {
                data[[name]] <- suppressWarnings(as.numeric(as.character(data[[name]])))
            }
            if (!any(!is.na(data[[name]]))) {
                emptyCols <- c(emptyCols, name)
            }
        }
        data <- data[,!(names(data) %in% emptyCols)]
    }
    data
}
known <- loadAndScrub(TRAINING_PATH)
set.seed(SEED)
inTrain <- createDataPartition(y=known$classe, p=0.7, list=FALSE)
knownTrain <- known[inTrain,]
knownTest <- known[-inTrain,]
fitControl <- trainControl(method="boot")
makeModel <- function(method) {
    modelFile <- paste0(method, ".RData")
    modelPath <- file.path(MODEL_DIR, modelFile)
    if (file.exists(modelPath)) {
        fit <- readRDS(modelPath)
    }
    else {
        set.seed(SEED)
        fit <- train(classe ~ ., data=knownTrain, method=method, verbose=TRUE)
        saveRDS(fit, modelPath)
    }
    print(fit$finalModel)
    fit
}
fitRpart <- makeModel("rpart")
fitRDA <- makeModel("rda")
fitTreebag <- makeModel("treebag")

accuracyLevels <- function(fit) {
    acc <- data.frame()
    for (l in levels(knownTest$classe)) {
        a <- sum(predict(fit, knownTest[knownTest$classe==l,]) == l) / nrow(knownTest[knownTest$classe==l,])
        acc <- rbind(acc, data.frame(classe=l, acc=a))
    }
    print(acc)
    acc
}

accRpart <- accuracyLevels(fitRpart)
accRDA <- accuracyLevels(fitRDA)
accTreebag <- accuracyLevels(fitTreebag)
# predict(fitRpart, tail(knownTest), type="prob")
# resamps <- resamples(list(Rpart=fitRpart))
# set.seed(SEED) ; fitSVM <- train(classe ~ ., data=knownTrain, method="svmRadial")
# testing <- loadAndScrub(TESTING_PATH, names(known))
