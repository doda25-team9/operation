# Continuous Experimentation

## Introduction

We want to evaluate and compare a different model for spam prediction. According to the creators of the SMS Spam Collection Dataset, which was used to train our models, SVM performed the best baseline performance out of their evaluated models [[1]](#1). Further analysis that included more models still had the same conclusion [[2]](#2). Thus, we chose to compare our initial model, a decision tree, against a SVC that is available in the `model-service` repository.
 
However, changing the model will change the predictions. For example, some messages classified as spam can now be classified as ham and the other way around. Since we want the transition between the different versions to be smooth, we will evaluate the differences in predictions. Hence, our hypothesis is the following.

H0: The spam prediction rates of the new version will not differ significantly.

## Experiment Design

### Data

We want to test how the models generalize, thus, reusing the training data will not give us great insights. Upon researching alternatives to the SMS Spam Collection which was used to train the models, we found the ExAIS SMS dataset. It contains 5,240 spam and ham messages across 20 users [[3]](#3). However, we also found a pre-processed version of which removes private data (e.g. bank account and phone numbers) and duplicate messages [[4]](#4).

### Experiment

The full corpus was sent to both models. Then the results were compared using McNemar's test with p=0.05.

The decision tree is represented by model v0.1.0 and app v0.0.7 SVC is represented by model v0.2.0 and app v0.1.0

The test statistic was calculated with this formula:
χ^2 = (|b - c| - 1)^2 / (b + c)

where:
b is the count of messages flagged as spam by model 1, but not by model 2
c is the count of messages flagged as spam by model 2, but not by model 1

H0 will be rejected if χ^2 >= 3.841

Why 3.841? In a χ^2 (Chi-squared) distribution with 1 degree of freedom, 95% of the area under the curve falls below 3.841. If your result is higher than this, the probability (p-value) that the difference happened by random chance is less than 5%.


### Metrics

To measure the outcomes we utilized `predictions_result_total` which tracks the counts of predictions by result (spam/ham).


## Result

model_predictions_total{result="spam",version="v1"} 922.0
model_predictions_total{result="ham",version="v1"} 4059.0

model_predictions_total{result="ham",version="v3"} 4981.0

χ^2 = (338 - 1)^2 / 338 ~= 336
b is the count of messages flagged as spam by model 1, but not by model 2
c is the count of messages flagged as spam by model 2, but not by model 1

[TODO: Visualisation]

Lines 1089-1099 are fucked up


## Discussion


## References

<a id="1">[1]</a> 
Almeida, T. A., Hidalgo, J. M. G., & Yamakami, A. (2011, September). Contributions to the study of SMS spam filtering: new collection and results. In Proceedings of the 11th ACM symposium on Document engineering (pp. 259-262).

<a id="2">[2]</a> 
Almeida, T., Hidalgo, J. M., & Silva, T. (2013). Towards sms spam filtering: Results under a new dataset. International Journal of Information Security Science, 2(1), 1-18.

<!-- Abayomi‐Alli, O., Misra, S., & Abayomi‐Alli, A. (2022). A deep learning method for automatic SMS spam classification: Performance of learning algorithms on indigenous dataset. Concurrency and Computation: Practice and Experience, 34(17), e6989. -->

<a id="3">[3]</a> 
Onashoga, A. S., Abayomi-Alli, O. O., Sodiya, A. S., & Ojo, D. A. (2015). An adaptive and collaborative server-side SMS spam filtering scheme using artificial immune system. Information Security Journal: A Global Perspective, 24(4-6), 133-145.

<a id="4">[4]</a> 
ysfbil. (2025). ExAIS SMS dataset [Data set]. Kaggle. https://www.kaggle.com/datasets/ysfbil/exais-sms-dataset