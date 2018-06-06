# This code is a copy from the deep computer vision 2 pdf book.
import keras
from keras.datasets import mnist
from keras.layers import Dense
from keras.models import Sequential
# Stochastic Gradient Descent
from keras.optimizers import SGD
from keras.callbacks import LearningRateScheduler
from keras.callbacks import ModelCheckpoint
import matplotlib.pyplot as plt

def lr_scheduler(epoch):
	lr = 0.1
	if epoch > 15:
		lr = lr / 100
	elif epoch > 10: 
		lr = lr / 10
	elif epoch > 5:
		lr = lr / 5

	print("Learning rate ", lr)
	return lr
		

# step 2 load the data
(train_x, train_y), (test_x, test_y) = mnist.load_data()
# step 3 normalize the data
train_x = train_x.astype('float32') / 255
test_x = test_x.astype('float32') / 255

print("Train images: ", train_x.shape)
print("Train labels: ", train_y.shape)
print("Test images: ", test_x.shape)
print("Test labels: ", test_y.shape)

# reshape to 1-Densional vector (28 * 28) = 784
# specifying the -1 option is better than the explicit size
train_x = train_x.reshape(-1, 784)
test_x = test_x.reshape(-1, 784)

# convert labels to vectors
train_y = keras.utils.to_categorical(train_y, 10)
test_y = keras.utils.to_categorical(test_y, 10)

# define your model network
model = Sequential()
model.add(Dense(units=128, activation="relu", input_shape=(784,)))
model.add(Dense(units=128, activation="relu"))
model.add(Dense(units=128, activation="relu"))
model.add(Dense(units=10, activation="softmax"))
model.compile(optimizer=SGD(0.01), loss="categorical_crossentropy", metrics=["accuracy"])

lr_scheduler = LearningRateScheduler(lr_scheduler)
# fit the function
model.fit(train_x, train_y, batch_size=32, epochs=20, shuffle=True, verbose=1, callbacks=[lr_scheduler])

# model.save("mnistmodel.h5")

# model.load_weights("mnistmodel.h5")

# evaluate accuracy
accuracy = model.evaluate(x=test_x, y=test_y, batch_size=32)
print("Accuracy: ", accuracy[1])

test_x = test_x.astype('float32') / 255
img = test_x[167]
test_img = img.reshape((1, 784))

img_class = model.predict_classes(test_img)
classname = img_class[0]
print("Class : ", classname)

plt.title("Prediction result: %s"% (classname))
plt.imshow(test_img)
plt.show()
