import os
import tensorflow as tf
import tensorflow.contrib.eager as tfe

tf.enable_eager_execution()

train_dataset_url = "http://download.tensorflow.org/data/iris_training.csv"

train_dataset_fp = tf.keras.utils.get_file(fname=os.path.basename(train_dataset_url), origin=train_dataset_url)
print("Local copy of the dataset file: {}".format(train_dataset_fp))
	

def parse_csv(line):
	example_defaults = [[0.], [0.], [0.], [0.], [0.]]
	parsed_line = tf.decode_csv(line, example_defaults)
	# first four fields are features combine into single tensor
	features = tf.reshape(parsed_line[:-1], shape=(4,))
	# last field is the label
	label = tf.reshape(parsed_line[-1], shape=())
	return features, label

train_dataset = tf.data.TextLineDataset(train_dataset_fp)
train_dataset = train_dataset.skip(1)
train_dataset = train_dataset.map(parse_csv)
train_dataset = train_dataset.shuffle(buffer_size=1000) 
train_dataset = train_dataset.batch(32)

# view a single example entry from a batch
#features, label = tfe.Iterator(train_dataset).next()
#print("example features", features[0])
#print("example label:", label[0])

model = tf.keras.Sequential([
	tf.keras.layers.Dense(10, activation="relu", input_shape=(4,)), 
	tf.keras.layers.Dense(10, activation="relu"),
	tf.keras.layers.Dense(3)])

def loss(model, x, y):
	y_ = model(x)
	return tf.losses.sparse_softmax_cross_entropy(labels=y, logits=y_)

def grad(model, inputs, targets):
	with tfe.GradientTape() as tape:
		loss_value = loss(model, inputs, targets)
	return tape.gradient(loss_value, model.variables)

optimizer = tf.train.GradientDescentOptimizer(learning_rate=0.01)

# keep results for plotting
train_loss_results = []
train_accuracy_results = []

num_epochs = 201
for epoch in range(num_epochs):
	epoch_loss_avg = tfe.metrics.Mean()
	epoch_accuracy = tfe.metrics.Accuracy()

	# training loop - using batches of 32
	for x, y in tfe.Iterator(train_dataset):
		# optimize the model
		grads = grad(model, x, y)
		optimizer.apply_gradients(zip(grads, model.variables),
			global_step=tf.train.get_or_create_global_step())

		# track progress
		epoch_loss_avg(loss(model, x, y))
		epoch_accuracy(tf.argmax(model(x), axis=1, output_type=tf.int32), y)

	# end epoch
	train_loss_results.append(epoch_loss_avg.result())
	train_accuracy_results.append(epoch_accuracy.result())

	if epoch % 50 == 0:
		print("Epoch {:03d}: Loss: {:.3f}, Accuracy: {:.3%}".format(epoch,
			epoch_loss_avg.result(),
			epoch_accuracy.result()))

