"""
This code is copied from the youtube video tutorial.
https://www.youtube.com/watch?v=FgGjc5oabrA
"""

from pyspark.ml.evaluation import RegressionEvaluator
from pyspark.ml.recommendataion import ALS
from pyspark.ml.tunning import TrainValidationSplit, ParamGridBuilder

# Create test and train set
(training, test) = movie_ratings.randomSplit([0.8, 0.2])

# Create ALS model
als = ALS(userCol="userId", itemCol="movieId", ratingCol="rating",
	coldStartStrategy="drop", nonnegative=True)

# Tune model using ParamGridBuilder
param_grid = ParamGridBuilder()\
	.addGrid(als.rank, [12, 13, 14])\
	.addGrid(als.maxIter, [18, 19, 20])\
	.addGrid(als.regParam, [0.17, 0.18, 0.19])\
	.build()
# Define evaluator as RMSE
evaluator = RegressionEvaluator(metricName="rmse", labelCol="rating",
	predictionCol="prediction")

# Build cross validation using TrainValidationSplit
tvs = TrainValidationSplit(
	estimator=als,
	estimatorParamMaps=param_grid,
	evalutor=evaluator)

# Fit ALS model to training data
model = tvs.fit(training)

# Extract best model from the tuning exercise using ParamGridBuilder
best_model = model.bestModel

# Generate predictions and evaluate using RMSE
predictions = best_model.transform(test)
rmse = evaluator.evaluate(predictions)

# Print evaluation metrics and model parameters
print("RMSE = " + str(rmse))
print("**Best Model**")
print(" Rank:"), best_model.rank
print(" MaxIter:"), best_model._java_obj.parent().getMaxIter()
print(" RegParam:"), best_model._java_obj.parent().getRegParam()

display(predictions.sort("userId", "rating"))

user_recs = best_model.recommendForAllUsers(10)
def get_recs_for_user(recs):
	# Recs should be for a specific user.
	recs = recs.select("recommendations.movieId", "recommendations.ratings")
	movies = recs.select("movieId").toPandas().iloc[0,0]
	ratings = recs.select("rating").toPandas().iloc[0,0]
	ratings_matrix = pd.DataFrame(movies, columns = ["movieId"])
	ratings_matrix["ratings"] = ratings
	ratings_matrix_ps = sqlContext.createDataFrame(ratings_matrix)
	return ratings_matrix_ps


