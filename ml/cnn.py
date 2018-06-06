import keras
from matplotlib import pyplot as plt
import numpy as np
import gzip
import tensorflow as tf

def extract_data(filename, num_images):
	with gzip.open(filename) as bytestream:
		bytestream.read(16)
		buf = bytestream.read(28 * 28 * num_images)
		data = np.frombuffer(buf, dtype=np.uint8).astype(np.float32)	
		data = data.reshape(num_images, 28, 28)
		return data

def extract_labels(filename, num_images):
	with gzip.open(filename) as bytestream:
		bytestream.read(8)
		buf = bytestream.read(1 * num_images)
		labels = np.frombuffer(buf, dtype=np.uint8).astype(np.int64)
		return labels


train_data = extract_data("data/fashion-mnist/data/fashion/train-images-idx3-ubyte.gz", 55000)
train_labels = extract_labels("data/fashion-mnist/data/fashion/train-labels-idx1-ubyte.gz", 55000)

test_data = extract_data("data/fashion-mnist/data/fashion/t10k-images-idx3-ubyte.gz", 10000)

test_labels = extract_labels("data/fashion-mnist/data/fashion/t10k-labels-idx1-ubyte.gz", 10000)

print(train_data.shape)
print(train_labels.shape)
print(test_data.shape)
print(test_labels.shape)

# create dictionary of target classes
label_dict = {
	0: 'T-shirt/top',
	1: 'Trouser',
	2: 'Pullover',
	3: 'Dress',
	4: 'Coat',
	5: 'Sandal',
	6: 'shirt',
	7: 'Sneaker',
	8: 'Bag',
	9: 'Ankle boot'
}

plt.figure(figsize=[5, 5])

# display the first image in training data
plt.subplot(121)
curr_img = np.reshape(train_data[0], (28, 28))
curr_lbl = train_labels[0]
plt.imshow(curr_img, cmap='gray')
plt.title("Label: " + str(label_dict[curr_lbl]) + ")")

# display the first image in testing data
plt.subplot(122)
curr_img = np.reshape(test_data[0], (28, 28))
curr_lbl = test_labels[0]
plt.imshow(curr_img, cmap='gray')
plt.title("(Label: " + str(label_dict[curr_lbl]) + ")")

train_data = train_data/ np.max(train_data)
test_data = test_data / np.max(test_data)

train_x = train_data.reshape(-1, 28, 28, 1)
test_x = test_data.reshape(-1, 28, 28, 1)
train_y = tf.reshape(train_labels, [-1, 10])
test_y = tf.reshape(test_labels, [-1, 10])
print(train_x.shape, test_x.shape)
print("train_y.shape, test_y.shape")
# (55000,),(10000,) 
print(train_y.shape, test_y.shape)

x = tf.placeholder(tf.float32, [None, 28, 28, 1])
y = tf.placeholder(tf.float32, [None, 10])

def conv2d(x, w, b, strides=1):
	# conv2d wrapper with bias and relu activation
	x = tf.nn.conv2d(x, w, strides=[1, strides, strides, 1], padding='SAME')
	x = tf.nn.bias_add(x, b)
	return tf.nn.relu(x)

def maxpool2d(x, k=2):
	return tf.nn.max_pool(x, ksize=[1, k, k, 1], strides=[1, k, k, 1], padding='SAME')

n_classes = 10
weights = {
	'wc1': tf.get_variable('W0', shape=(3, 3, 1, 32), initializer=tf.contrib.layers.xavier_initializer()),
	'wc2': tf.get_variable('W1', shape=(3, 3, 32, 64), initializer=tf.contrib.layers.xavier_initializer()),
	'wc3': tf.get_variable('W2', shape=(3, 3, 64, 128), initializer=tf.contrib.layers.xavier_initializer()),
	'wd1': tf.get_variable('W3', shape=(4 * 4 * 128, 128), initializer=tf.contrib.layers.xavier_initializer()),
	'out': tf.get_variable('W6', shape=(128, n_classes), initializer=tf.contrib.layers.xavier_initializer())
}

biases = {
	'bc1': tf.get_variable('B0', shape=(32), initializer=tf.contrib.layers.xavier_initializer()),
	'bc2': tf.get_variable('B1', shape=(64), initializer=tf.contrib.layers.xavier_initializer()),
	'bc3': tf.get_variable('B2', shape=(128), initializer=tf.contrib.layers.xavier_initializer()),
	'bd1': tf.get_variable('B3', shape=(128), initializer=tf.contrib.layers.xavier_initializer()),
	'out': tf.get_variable('B4', shape=(10), initializer=tf.contrib.layers.xavier_initializer())
}


def conv_net(x, weights, biases):
	conv1 = conv2d(x, weights['wc1'], biases['bc1'])
	conv1 = maxpool2d(conv1, k=2)

	conv2 = conv2d(conv1, weights['wc2'], biases['bc2'])
	conv2 = maxpool2d(conv2, k=2)

	conv3 = conv2d(conv2, weights['wc3'], biases['bc3'])
	conv3 = maxpool2d(conv3, k=2)

	fc1 = tf.reshape(conv3, [-1, weights['wd1'].get_shape().as_list()[0]])

	fc1 = tf.add(tf.matmul(fc1, weights['wd1']), biases['bd1'])
	fc1 = tf.nn.relu(fc1)

	out = tf.add(tf.matmul(fc1, weights['out']), biases['out'])
	return out

pred = conv_net(x, weights, biases)
cost = tf.reduce_mean(tf.nn.softmax_cross_entropy_with_logits(logits=pred, labels=y))
optimizer = tf.train.AdamOptimizer(learning_rate=0.001).minimize(cost)

correct_prediction = tf.equal(tf.argmax(pred, 1), tf.argmax(y, 1))

# calculate accuracy across all the given images and average them out.
accuracy = tf.reduce_mean(tf.cast(correct_prediction, tf.float32))

init = tf.global_variables_initializer()

training_iters = 200
batch_size = 128
n_input = 28
n_classes = 10

with tf.Session() as sess:
	sess.run(init)
	train_loss = []
	test_loss = []
	train_accuracy = []
	test_accuracy = []
	summary_writer = tf.summary.FileWriter('./log', sess.graph)
	for i in range(training_iters):
		for batch in range(len(train_x)//batch_size):
			batch_x = train_x[batch * batch_size:min((batch + 1) * batch_size, len(train_x))]
			batch_y = train_y[batch * batch_size:min((batch + 1) * batch_size, train_y.shape[0])]
			print(batch_x.shape, batch_y.shape)
			opt = sess.run(optimizer, feed_dict={x: batch_x, y: batch_y})

			loss, acc = sess.run([cost, accuracy], feed_dict={x: batch_x, y: batch_y})

		print("Iter " + str(i) + ", Loss= " + \
			"{:.6f}".format(loss) + ", Training Accuracy= " + \
			"{:.5f}".format(acc))
		print("Optimization Finished!")

		# calculate accuracy for all 10000 test images
		test_acc, valid_loss = sess.run([accuracy, cost], feed_dict={x: test_x, y: test_y})
		train_loss.append(loss)
		test_loss.append(valid_loss)
		train_accuracy.append(acc)
		test_accuracy.append(acc)
		print("Testing Accuracy: ", "{:.5f}".format(test_acc))
	summary_writer.close()


import pylab as p
p.show()
