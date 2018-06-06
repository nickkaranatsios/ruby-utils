# to get to load the mnist data
# /Applications/Python 3.6/Install Certificates.command
import tensorflow as tf
import numpy as np
from six.moves import xrange
from sklearn import datasets

def read_infile():
	mnist = tf.contrib.learn.datasets.load_dataset("mnist")
	train_X, train_Y, test_X, test_Y = mnist.train.images, mnist.train.labels, mnist.test.images, mnist.test.labels
	return(train_X, train_Y, test_X, test_Y)

# define the weights and biases for the neural network

def weights_biases_placeholder(n_dim, n_classes):
	X = tf.placeholder(tf.float32, [None, n_dim])
	Y = tf.placeholder(tf.float32, [None, n_classes])
	w = tf.Variable(tf.random_normal([n_dim, n_classes], stddev=0.01), name='weights')
	b = tf.Variable(tf.random_normal([n_classes]), name='weights')
	return X, Y, w, b

def forward_pass(w, b, X):
	out = tf.matmul(X, w) + b
	return out

# define the cost function for the softmax unit
def multiclass_cost(out, Y):
	cost = tf.reduce_mean(tf.nn.softmax_cross_entropy_with_logits(logits=out, labels=Y))
	return cost

# define the initialization op
def init():
	return tf.global_variables_initilizer()


# define the training op
def train_op(learning_rate, cost):
	op_train = tf.train.GradientDescentOptimizer(learning_rate).minimize(cost)
	return op_train

train_X, train_Y, test_X, test_Y = read_infile()
X, Y, w, b = weights_biases_placeholder(train_X.shape[1], train_Y.shape[1])
out = forward_pass(w, b, X)
cost = multiclass_cost(out, Y)
learning_rate, epochs = 0.01, 1000
op_train = train_op(learning_rate, cost)
init = init()
accurate_trace = []

with tf.Session() as sess:
	sess.run(init)

	for i in xrange(epochs):
		sess.run(op_train, feed_dict={X: train_X, Y: train_Y})
		loss_ = sess.run(cost, feed_dict={X: train_X, Y: train_Y})
		accuracy_ = np.mean(np.argmax(sess.run(out, feed_dict={X: train_X, Y: train_Y}), axis=1) == np.argmax(train_Y, axis=1))
		loss_trace.append(loss_)
		accuracy_trace.append(accuracy_)
		if (((i + 1) >= 100) and ((i + 1) % 100 == 0)):
			print('Epoch:', (i + 1), 'loss:', loss_, 'accuracy:', accuracy_)

	print('Final training result:', 'loss:', loss_, 'accuracy:', accuracy_)
	loss_test = sess.run(cost, feed_dict={X: test_X, Y: test_Y})
	test_pred = np.argmax(sess.run(out, feed_dict={X: test_X, Y: test_Y}), axis=1)
	accuracy_test = np.mean(test_pred == np.argmax(test_Y, axis=1))
	print('Results on test dataset:', 'loss:', loss_test, 'accuracy:', accuracy_test)

