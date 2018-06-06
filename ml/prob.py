import tensorflow as tf
from tensorflow_probablity import edward2 as ed

def model(features):
	# setup fixed effects and other parameters
	intercept = tf.get_variable("intercept", [])
	service_effects = tf.get_variable("service_effects", [])
	student_stddev_unconstrained = tf.get_variable("student_stddev_pre", [])
	instructor_stddev_unconstrained = tf.get_variable("instructor_stddev_pre", [])

	# setup random effects
	student_effects = ed.MultivariateNormalDiag(
		loc=tf.zeros(num_students),
		scale_identity_multiplier=tf.exp(student_stddev_unconstrained), name="student_effects")

	instructor_effects = ed.MultivariateNormalDiag(
		loc=tf.zeros(num_instructors),
		scale_identity_multiplier=tf.exp(instructor_stddev_unconstrained), name="instructor_effects")

	# setup up likelihood given fixed and random effects
	ratings = ed.Normal(
		loc=(service_effects * features["service"] +
			tf.gather(student_effects, features["students"]) +
			tf.gather(instructor_effects, features["instructors"]) + intercept),
		scale=1.,
		name="ratings")

	return ratings

