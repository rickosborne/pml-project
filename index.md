# Practical Machine Learning Project

_Author:_ Rick Osborne
_Date:_ 2014-06-22

This writeup covers my analysis of the [Human Activity Recognition dataset](http://groupware.les.inf.puc-rio.br/har) for the Practical Machine Learning course offered by the Johns Hopkins University School of Biostatistics and Coursera.

## Data Preparation

I found that the dataset needed significant cleanup before it was ready for use.  The source CSV had 160 columns, but many of them did not have usable data.

  1. I eliminated any summary rows (`new_window == "yes"`), as they were not mirrored in the testing dataset.

  2. I eliminated the non-numeric columns, such as `user_name`, `num_window`, etc.
  
  3. I eliminated columns that did not have non-`NA` values.
  
Overall, this cleanup reduced the column count to 53.

### Cross Validation

For the most part I let the Caret package worry about subsampling, but to get an estimate of the out-of-sample error I split the dataset 70/30 into training and testing datasets.  When using training `method = "rpart"`, this produced a model that was little better than 50% accurate against the testing dataset.

### Model Selection

Because the result (`classe`) is a factor variable, I initially chose to use a CART model (`method = "rpart"`).  This trained relatively quickly, but I found its accuracy was very dependant on the initial training/testing data selection, and would not produce leaves for entire factors.  For example, on one run it did not have a classifier for a "D" result.

I then tried to let Caret choose a model by not specifying a method.  Caret attempted to create a random forest model, but I was forced to kill the R process after it trained for an hour without producing a result.

My next successful model used RDA. Though it took more than a wall-clock hour using 7 CPU cores, it was far more accurate than the CART model.  And interestingly, the saved version of the RDA model takes up almost an order of magnitude less disk space than the CART model.

I then tried several other models by specifying them explicitly, but the following took too long to train and were discarded: Bagged CART (`treebag`), Parallel Random Forest (`parRF`), Conditional Inference Random Forest (`cforest`), Support Vector Machines with Radial Basis Function Kernel (`svmRadial`).

## Result

The best accuracy I could get was 98.7% with a Bagged CART model, followed by ~89% with an RDA model and ~52% with a CART model.  As random choice would provide ~20% accuracy, the CART model is an improvement, but not a great one.  Had I been more proactive and started the assignment sooner, I would have tried and compared many more models.

When broken down by result factor, I discovered that the CART model was far more accurate for some results than others, while still being less accurate than the RDA model for even its most accurate result.  But then when upgraded to a Bagged CART the accuracy was truly impressive:

|Result|CART|RDA|Bagged CART|
|:-:|:---:|:---:|:-----:|
| A | 91% | 94% | 99.5% |
| B | 33% | 81% | 98.6% |
| C | 43% | 94% | 98.2% |
| D | 24% | 83% | 97.4% |
| E | 44% | 91% | 99.2% |

Had I been able to generate more models before the deadline, I believe I could have generated a composite model by weighting the predictions according to the different measured accuracies.
