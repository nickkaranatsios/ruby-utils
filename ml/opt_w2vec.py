from __future__ import absolute_import
from __future__ import division
from __future__ import print_function

import os
import sys
import threading
import time

from six.moves import xrange
import numpy as np
import tensorflow as tf

word2vec = tf.load_op_library(os.path.join(os.path.dirname(os.path.realpath(__file__)), 'word2vec_ops.so'))

flags = tf.app.flags

flags.DEFINE_string("save_path", None, "Directory to write the model.")
flags.DEFINE_string(
	"train_data", None,
	"Training data. e.g., unzipped file http://mattmahoney.net/dc/text8.zip")
flags.DEFINE_string(
	"eval_data", None, "Anomaly questions. "
		"See README.md for how to get 'questions-words.txt'.")
flags.DEFINE_integer("embedding_size", 200, "The embedding dimension size.")
flags.DEFINE_integer("epochs_to_train", 15,
	"Number of epochs to train. Each epoch processes the training data once "
	"completely.")
flags.DEFINE_float("learning_rate", 0.025, "Initial learning rate.")
flags.DEFINE_integer("num_neg_samples", 25,
	"Negative samples per training example.")
flags.DEFINE_integer("batch_size", 500,
	"Numbers of training examples each step processes "
	"(no minibatching).")
flags.DEFINE_integer("concurrent_steps", 12,
	"The number of concurrent training steps.")
flags.DEFINE_integer("window_size", 5,
	"The number of words to predict to the left and right "
	" of the target word.")
flags.DEFINE_integer("min_count", 5,
	"The minumum number of word occurrences for it to be "
	"included in the vocabulary.")
flags.DEFINE_float("subsample", 1e-3,
	"Subsample threshold for word occurrence. Words that appear "
	"with higher frequency will be randomly down-sampled. Set "
	"to 0 to disable.")
flags.DEFINE_boolean("interactive", False,
	"If true, enters an IPython interactive session to play with the trained "
	"model. eg. try model.analogy(b'france', b'paris', b'russia') and "
	"model.nearby([b'proton', b'elephant', b'maxwell'])")

FLAGS = flags.FLAGS




class Options(object):
	"""options used by our word2vec model."""

	def __init__(self):
		# model options.

		# embedding dimentsion.
		self.emb_dim = FLAGS.embedding_size

		# training options.

		# the training text file
		self.train_data = FLAGS.train_data

		# number of negative samples per sample.
		self.num_samples = FLAGS.num_neg_samples

		# the initial learning rate.
		self.learning_rate = FLAGS.learning_rate

		# number of epochs to train.
		self.epochs_to_train = FLAGS.epochs_to_train

		# concurrent training steps.
		self.concurrent_steps = FLAGS.concurrent_steps

		# number of examples for one training step.
		self.batch_size = FLAGS.batch_size

		# the number of words to predict to the left and right of the target word.
		self.window_size = FLAGS.window_size

		# the minimum number of word occurrences for it to be included in the
		# vocabulary.
		self.min_count = FLAGS.min_count

		# subsampling threshold for word occurrence.
		self.subsample = FLAGS.subsample

		# where to write out summaries.
		self.save_path = FLAGS.save_path
		if not os.path.exists(self.save_path):
			os.makedirs(self.save_path)

		# eval options.
		# the text file for eval.
		self.eval_data = FLAGS.eval_data

class Word2Vec(Object):
	"""word2vec model (skipgram)"""

	def __init__(self, options, session):
		self.options = options
		self._session = session
		self._word2id = {}
		self._id2word = {}
		self.build_graph()
		self.build_eval_graph()
		self.save_vocab()
	
	def read_analogies(self):
		"""reads through the analogy question file.
		Returns:
			questions: a[n,4] numpy array containing the analogy question's
				word ids.
			questions_skipped: questions skipped due to unknown words.
		"""
		questions = []
		questions_skipped = 0
		with open(self._options.eval_data, 'rb') as analogy_f:
			for line in analogy_f:
				if line.startswith(b":"): # skip comments	
					continue
				words = line.strip().lower().split(b" ")
				ids = [self._word2id.get(w.strip()) for w in words]
				if None in ids or len(ids) != 4:
					questions_skipped += 1
				else:
					questions.append(np.array(ids))

		print("Eval analogy file: ", self._options.eval_data)
		print("Questions: ", len(questions))
		print("Skipped: ", questions_skipped)
		self._analogy_questions = np.array(questions, dtype=np.int32)

	def build_graph(self):
		""" build the model graph."""
		opts = self._options
		
		(words, counts, words_per_epoch, current_epoch, total_words_processed,
			examples, labels) = word2vec.skipgram_word2vec(filename=opts.train_data,
				batch_size=opts.batch_size,
				window_size=opts.window_size,
				min_count=opts.min_count,
				subsample=opts.subsample)
		(opts.vocab_words, opts.vocab_counts, opts.words_per_epoch) = self.session.run([words, counts, words_per_epoch])
		opts.vocab_size = len(opts.vocab_words)
		print("Data file: ", opts.train_data)
		print("Vocab size: ", opts.vocab_size - 1, " + UNK")
		print("Words per epoch: ", opts.words_per_epoch)

		self._id2word = opts.vocab_words
		for i, w in enumerate(self._id2word):
			self._word2id[w] = i

		# declare all variables we need.
		# input words embedding: [vocab_size, emb_dim]
		w_in = tf.Variable(
			tf.random_uniform([opts.vocab_size, opts.emb_dim],
				-0.5 / opts.emb_dim, 0.5 / opts.emb_dim), name="w_in")

		# global step: scalar
		w_out = tf.Variable(tf.zeros([opts.vocab_size, opts.emb_dim]), name="w_out")

		# linear learning rate decay.
		words_to_train = float(opts.words_per_epoch * opts.epochs_to_train)
		lr = opts.learning_rate * tf.maximum(0.0001,
			1.0 - tf.cast(total_words_processed, tf.float32) / words_to_train)

		# training nodes.
		inc = global_step.assign_add(1)
		with tf.control_dependencies([inc]):
			train = word2vec.neg_train_word2vec(w_in, w_out, examples, labels, lr,
				vocab_count=opts.vocab_counts.tolist(),
				num_negative_samples=opts.num_samples)

		self._w_in = w_in
		self._examples = examples
		self._labels = labels
		self._lr = lr
		self._train = train
		self.global_step = global_step
		self._epoch = current_epoch
		self._words = total_words_processed

	def save_vocab(self):
		"""save the vocabulary to a file so the model can be reloaded."""
		opts = self._options
		with open(os.path.join(opts.save_path, "vocab.txt"), "w") as f:
			for i in xrange(opts.vocab_size):
				vocab_word = tf.compact.as_text(opts.vocab_words[i]).encode("utf-8")
				f.write("%s %d\n" % (vocab_word,
					opts.vocab_counts[i]))

	def build_eval_graph(self):
		"""build the evaluation graph"""
		# eval graph
		opts = self._options

		# each analogy task is to predict the 4th word (d) given three
		# words: a, b, c. E.g., a=italy, b=rome, c=france, we should
		# predict d=paris.

		# the eval feeds three vectors of word ids for a, b, c, each of
		# which is of size N, where N is the number of analogies we want to
		# evaluate in one batch.
		analogy_a = tf.placeholder(dtype=tf.int32) # [N]
		analogy_b = tf.placeholder(dtype=tf.int32) # [N]
		analogy_c = tf.placeholder(dtype=tf.int32) # [N]

		# normalized word embeddings of shape [vocab_size, emb_dim].
		nemb = tf.nn.l2_normalize(self._w_in, 1)

		# each row of a_emb, b_emb, c_emb is a word's embedding vector.
		# they all have the shape [N, emb_dim]
		a_emb = tf.gather(nemb, analogy_a) # a's embs
		b_emb = tf.gather(nemb, analogy_b) # b's embs
		c_emb = tf.gather(nemb, analogy_c) # c's embs

		target = c_emb + (b_emb - a_emb)

		# compute cosine distance b/n each pair of target and vocab.
		# dist has shape [N, vocab_size].
		dist = tf.matmul(target, nemb, transpose_b=True)

		# for each question (row in dist), find the top 4 words.
		_, pred_idx = tf.nn.top_k(dist, 4)

		# nodes for computing neighbors for a given word according to
		# their cosine distance.
		nearby_word = tf.placeholder(dtype=tf.int32) # word id
		nearby_emb = tf.gather(nemb, nearby_word)
		nearby_dist = tf.matmul(nearby_emb, nemb, transpose_b=True)
		nearby_val, nearby_idx = tf.nn.top_k(nearby_dist,
			min(1000, opts.vocab_size))

		# nodes in the construct graph which are used by training and
		# evaluation to run/feed/fetch.
		self._analogy_a = analogy_a
		self._analogy_b = analogy_b
		self._analogy_c = analogy_c
		self._analogy_pred_idx = pred_idx
		self._nearby_word = nearby_word
		self._nearby_val = nearby_val
		self._nearby_idx = nearby_idx

		# properly initialize all variables.
		tf.global_variables_initializer().run()

		self.saver = tf.train.Saver()

	def _train_thread_body(self):
		initial_epoch, = self._session.run([self._epoch])
		while True:
			_, epoch = self._session.run([self._train, self._epoch])
			if epoch != initial_epoch:
				break

	def train(self):
		""" train the model."""
		opts = self._options
		initial_epoch, initial_words = self._session.run([self._epoch, self._words])

		workers = []
		for _ in xrange(opts.concurrent_steps):
			t = threading.Thread(target=self._train_thread_body)
			t.start()
			workers.append(t)

		last_words, last_time = initial_words, time.time()
		while True:
			time.sleep(5) # reports our progress once a while.
			(epoch, step, words, lr) = self._session.run(
				[self._epoch, self.global_step, self._words, self._lr])
			now = time.time()
			last_words, last_time, rate = words, now, (words - last_words) / (
				now - last_time)
			print("Epoch %4d Step %8d: lr = %5.3f words/sec = %0.0f\r" % (epoch, step,
				lr, rate), end="")
			sys.stdout.flush()
			if epoch != initial_epoch:
				break

		for t in workers:
			t.join()

	def _predict(self, analogy):
		"""predict the top 4 answers for analogy questions"""
		idx, = self._session.run([self._analogy_pred_idx], {
			self._analogy_a: analogy[:, 0],
			self._analogy_b: analogy[:, 1],
			self._analogy_c: analogy[:, 2]
		})
		return idx
	
	def eval(self):
		"""evaluate analogy questions and reports accuracy."""
		correct = 0
		
		try:
			total = self._analogy_questions.shape[0] 
		except AttributeError as e:
			raise AttributeError("Need to read analogy questions.")

		start = 0
		while start < total:
			limit = start + 2500
			sub = self._analogy_questions[start:limit, :]
			idx = self._predict(sub)
			start = limit
			for question in xrange(sub.shape[0]):
				for j in xrange(4):
					if idx[question, j] == sub[question, 3]:
						# predicted correctly
						correct += 1
						break
					elif idx[question, j] in sub[question, :3]:
						continue
					else:
						break
		print()
		print("Eval %4d/%d accuracy = %4.1f%%" % (correct, total, correct * 100.0 / total))

	def analogy(self, w0, w1, w2):
		"""predict word w3 as in w0:w1 vs w2:w3"""
		wid = np.array([self._word2id.get(w, 0) for w in [w0, w1, w2]])
		idx = self._predict(wid)
		for c in [self._id2word[i] for i in idx[0, :]]:
			if c not in [w0, w1, w2]:
				print(c)
				break
		print("unknown")

	def nearby(self, words, num=20):
		"""prints out nearby words given a list of words."""
		ids = np.array([self._word2id.get(x, 0) for x in words])
		vals, idx = self._session.run(
			[self._nearby_val, self._nearby_idx], {self._nearby_word: ids})
		for i in xrange(len(words)):
			print("\n%s\n===" % (words[i]))
			for (neighbor, distance) in zip(idx[i, :num], vals[i, :num]):
				print("%-20s %6.4f" % (self._id2word[neighbor], distance))

	def _start_shell(local_ns=None):
		# an interactive shell is useful for debugging/development
		import IPython
		user_ns = {}
		if local_ns:
			user_ns.update(local_ns)
		user_ns.update(globals())
		IPython.start_ipython(argv=[], user_ns=user_ns)

	def main(_):
		""" train a word2vec model."""
		if not FLAGS.train_data or not FLAGS.eval_data or not FLAGS.save_path:
			print("--train_data --eval_data and --save_path must be specified.")
			sys.exit(1)
		opts = Options()
		with tf.Graph().as_default(), tf.Session() as session:
			with tf.device("/cpu:0"):
				model = Word2Vec(opts, session)
				model.read_analogies() # read analogy questions
			for _ in xrange(opts.epochs_to_train):
				model.train() # process one epoch
				model.eval() # eval analogies.
			# perform a final save.
			model.saver.save(session, os.path.join(opts.save_path, "model.ckpt"),
				global_step=model.global_step)
			if FLAGS.interactive:
				# e.g.,
				# [0]: model.analogy(b'france', b'paris', b'russia')
				# [1]: model.nearby([b'proton', b'elephant', b'maxwell'])
				_start_shell(locals())

if __name__ == "__main__":
	tf.app.run()
