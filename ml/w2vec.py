
from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import collections
import math
import os
import sys
import argparse
import random
from tempfile import gettempdir
import zipfile

import numpy as np
from six.moves import urllib
from six.moves import xrange

import tensorflow as tf

from tensorflow.contrib.tensorboard.plugins import projector

current_path = os.path.dirname(os.path.realpath(sys.argv[0]))

parser = argparse.ArgumentParser()
parser.add_argument(
	'--log_dir',
	type=str,
	default=os.path.join(current_path, 'log'),
	help='The log directory for TensorBoard summaries.')
FLAGS, unparsed = parser.parse_known_args()

if not os.path.exists(FLAGS.log_dir):
	os.makedirs(FLAGS.log_dir)

# step 1 download the data
url = 'http://mattmahoney.net/dc/'

def maybe_download(filename, expected_bytes):
	"""Download a file if not present and make sure it's the right size."""
	local_filename = os.path.join(gettempdir(), filename)
	if not os.path.exists(local_filename):
		local_filename, _ = urllib.request.urlretrieve(url + filename, 
			local_filename)

	statinfo = os.stat(local_filename)
	if statinfo.st_size == expected_bytes:
		print('Found and verified', filename)
	else:
		print(statinfo.st_size)
		raise Exception('Failed to verify ' + local_filename +
			'. Can you get to it with a browser?')
	return(local_filename)

filename = maybe_download('text8.zip', 31344016)

# read the data into a list of strings
def read_data(filename):
	"""extract the first file enclosed in a zip file as a list of words."""
	with zipfile.ZipFile(filename) as f:
		data = tf.compat.as_str(f.read(f.namelist()[0])).split()
	return data

vocabulary = read_data(filename)
print('Data size', len(vocabulary))

# step 2: Build the dictionary and replace rare words with UNK tokens
vocabulary_size = 50000

def build_dataset(words, n_words):
	"""process raw inputs into a dataset."""
	count = [['UNK', -1]]
	count.extend(collections.Counter(words).most_common(n_words - 1))
	dictionary = dict()
	for word, _ in count:
		dictionary[word] = len(dictionary)
	data = list()
	unk_count = 0
	for word in words:
		index = dictionary.get(word, 0)
		if index == 0: # dictionary['UNK']
			unk_count += 1
		data.append(index)
	count[0][1] = unk_count
	reversed_dictionary = dict(zip(dictionary.values(), dictionary.keys()))
	return data, count, dictionary, reversed_dictionary

# filling 4 global variables
# data - list of codes (integers from 0 to vocabulary_size - 1)
# this is the original text but words are replaced by their codes
# count - map of words(strings) to count of occurences
# dictionary - map of words(strings) to their codes(integers)
# reversed_dictionary - maps codes(integers) to words (strings)
data, count, dictionary, reverse_dictionary = build_dataset(
	vocabulary, vocabulary_size)
del vocabulary # Hint to reduce memory.
print('Most common words (+UNK)', count[:5])
print('Sample data', data[:10], [reverse_dictionary[i] for i in data[:10]])

data_index = 0

# step 3: function to generate a training batch for the skip-gram model
def generate_batch(batch_size, num_skips, skip_window):
	global data_index
	assert batch_size % num_skips == 0
	assert num_skips <= 2 * skip_window
	batch = np.ndarray(shape=(batch_size), dtype=np.int32)
	labels = np.ndarray(shape=(batch_size, 1), dtype=np.int32)
	span = 2 * skip_window + 1 # [ skip_window target skip_window ]
	buffer = collections.deque(maxlen=span)

	if data_index + span > len(data):
		data_index = 0

	buffer.extend(data[data_index:data_index + span])
	data_index += span
	for i in range(batch_size // num_skips):
		context_words = [w for w in range(span) if w != skip_window]
		words_to_use = random.sample(context_words, num_skips)
		for j, context_word in enumerate(words_to_use):
			batch[i * num_skips + j] = buffer[skip_window]
			labels[i * num_skips + j, 0] = buffer[context_word]
		if data_index == len(data):
			buffer.extend(data[0:span])
			data_index = span
		else:
			buffer.append(data[data_index])
			data_index += 1
	data_index = (data_index + len(data) - span) % len(data)
	return batch, labels

batch, labels = generate_batch(batch_size=8, num_skips=2, skip_window=1)
for i in range(8):
	print(batch[i], reverse_dictionary[batch[i]], '->', labels[i, 0],
		reverse_dictionary[labels[i, 0]])

# step 4 build and train a skip-gram model

batch_size = 128
embedding_size = 128 # dimension of the embedding vector.
skip_window = 1 # how many times to consider left and right.
num_skips = 2 # how many times to reuse an input to generate a label.
num_sampled = 64 # number of negative examples to sample.

valid_size = 16 # random set of words to evaluate similarity on.
valid_window = 100 # only pick dev sample in the head the distribution
valid_examples = np.random.choice(valid_window, valid_size, replace=False)

graph = tf.Graph()

with graph.as_default():
	# input data.
	with tf.name_scope('inputs'):
		train_inputs = tf.placeholder(tf.int32, shape=[batch_size])
		train_labels = tf.placeholder(tf.int32, shape=[batch_size, 1])
		valid_dataset = tf.constant(valid_examples, dtype=tf.int32)

	with tf.device('/cpu:0'):
		# look up embeddings for inputs:
		with tf.name_scope('embeddings'):
			embeddings = tf.Variable(
				tf.random_uniform([vocabulary_size, embedding_size], -1.0, 1.0))
			embed = tf.nn.embedding_lookup(embeddings, train_inputs)

		# construct the variables for the NCE loss
		with tf.name_scope('weights'):
			nce_weights = tf.Variable(
				tf.truncated_normal(
					[vocabulary_size, embedding_size],
					stddev=1.0 / math.sqrt(embedding_size)))
		with tf.name_scope('biases'):
			nce_biases = tf.Variable(tf.zeros([vocabulary_size]))

	# compute the average NCE loss for the batch.
	with tf.name_scope('loss'):
		loss = tf.reduce_mean(
			tf.nn.nce_loss(
				weights=nce_weights,
				biases=nce_biases,
				labels=train_labels,
				inputs=embed,
				num_sampled=num_sampled,
				num_classes=vocabulary_size))

	tf.summary.scalar('loss', loss)

	# construct the SGD optimizer using the learning rate of 1.0
	with tf.name_scope('optimizer'):
		optimizer = tf.train.GradientDescentOptimizer(1.0).minimize(loss)

	# compute the cosine similarity between minibatch examples and all embeddings
	norm = tf.sqrt(tf.reduce_sum(tf.square(embeddings), 1, keep_dims=True))
	normalized_embeddings = embeddings / norm
	valid_embeddings = tf.nn.embedding_lookup(normalized_embeddings,
		valid_dataset)

	similarity = tf.matmul(
		valid_embeddings, normalized_embeddings, transpose_b=True)

	# merge all summaries.
	merged = tf.summary.merge_all()

	# add variable initializer.
	init = tf.global_variables_initializer()

	# create a saver.
	saver = tf.train.Saver()

# step 5: begin training
num_steps = 100001

with tf.Session(graph=graph) as session:
	# open the writer to write summaries
	writer = tf.summary.FileWriter(FLAGS.log_dir, session.graph)

	# we must initialize all variables before we use them
	init.run()
	print('Initialized')

	average_loss = 0
	for step in xrange(num_steps):
		batch_inputs, batch_labels = generate_batch(batch_size, num_skips,
			skip_window)
		feed_dict = {train_inputs: batch_inputs, train_labels: batch_labels}

		# define metadata variable.
		run_metadata = tf.RunMetadata()

		_, summary, loss_val = session.run(
			[optimizer, merged, loss],
			feed_dict=feed_dict,
			run_metadata=run_metadata)
		average_loss += loss_val

	# add returned summaries to writer in each step
	writer.add_summary(summary, step)

	# add metadata to visualize the graph for the last run
	if step == (num_steps - 1):
		writer.add_run_metadata(run_metadata, 'step%d' % step)

	if step % 2000 == 0:
		if step > 0:
			average_loss /= 2000
		# the average loss is an estimate of the loss over the last 2000 batches
		print('Average loss at step ', step, ': ', average_loss)
		average_loss = 0

	if step % 10000 == 0:
		sim = similarity.eval()
		for i in xrange(valid_size):
			valid_word = reverse_dictionary[valid_examples[i]]
			top_k = 8
			nearest = (-sim[i, :]).argsort()[1:top_k + 1]
			log_str = 'Nearest to %s:' % valid_word
			for k in xrange(top_k):
				close_word = reverse_dictionary[nearest[k]]
				log_str = '%s %s,' % (log_str, close_word)
			print(log_str)
	final_embeddings = normalized_embeddings.eval()

	# write corresponding labels for the embeddings.
	with open(FLAGS.log_dir + '/metadata.tsv', 'w') as f:
		for i in xrange(vocabulary_size):
			f.write(reverse_dictionary[i] + '\n')

	# save the model for checkpoints.
	saver.save(session, os.path.join(FLAGS.log_dir, 'model.ckpt'))

	# create a configuration for visualizing embeddings with the labels in tensorboard
	config = projector.ProjectorConfig()
	embedding_conf = config.embeddings.add()
	embedding_conf.tensor_name = embeddings.name
	embedding_conf.metadata_path = os.path.join(FLAGS.log_dir, 'metadata.tsv')
	projector.visualize_embeddings(writer, config)

writer.close()

# step 6 visualize the embeddings.
def plot_with_labels(low_dim_embs, labels, filename):
	assert low_dim_embs.shape[0] >= len(labels), 'More labels than embeddings'
	plt.figure(figsize=(18, 18)) # in inches
	for i, label in enumerate(labels):
		x, y = low_dim_embs[i, :]
		plt.scatter(x, y)
		plt.annotate(
			label,
			xy=(x, y),
			xytext=(5, 2),
			textcoords='offset points',
			ha='right',
			va='bottom')
	plt.savefig(filename)

try:
	from sklearn.manifold import TSNE
	import matplotlib.pyplot as plt

	tsne = TSNE(
		perplexity=30, n_components=2, init='pca', n_iter=5000, method='exact')
	plot_only = 500
	low_dim_embs = tsne.fit_transform(final_embeddings[:plot_only, :])
	labels = [reverse_dictionary[i] for i in xrange(plot_only)]
	plot_with_labels(low_dim_embs, labels, os.path.join(gettempdir(), 'tsne.png'))
except ImportError as ex:
	print('Please install sklearn, matplotlib, and scipy to show embeddings.')
	print(ex)
