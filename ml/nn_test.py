# This code is a copy from the deep computer vision 2 pdf book.
import keras
from keras.datasets import mnist
from keras.layers import Dense
from keras.models import Sequential
# Stochastic Gradient Descent
from keras.optimizers import SGD
import matplotlib.pyplot as plt

# step 2 load the data
(train_x, train_y), (test_x, test_y) = mnist.load_data()
# define your model network
model = Sequential()
model.add(Dense(units=128, activation="relu", input_shape=(784,)))
model.add(Dense(units=128, activation="relu"))
model.add(Dense(units=128, activation="relu"))
model.add(Dense(units=10, activation="softmax"))
model.compile(optimizer=SGD(0.01), loss="categorical_crossentropy", metrics=["accuracy"])

model.load_weights("mnistmodel.h5")

test_x = test_x.astype('float32') / 255
img = test_x[167]
test_img = img.reshape((1, 784))

img_class = model.predict_classes(test_img)
classname = img_class[0]
print("Class : ", classname)

plt.title("Prediction result: %s"% (classname))
plt.imshow(img)
plt.show()

