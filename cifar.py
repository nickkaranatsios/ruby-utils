import keras
from keras.datasets import cifar10
from keras.layers import Dense, Conv2D, MaxPooling2D, Flatten, AveragePooling2D, Dropout, BatchNormalization, Activation
from keras.models import Model, Input
from keras.optimizers import Adam
from keras.callbacks import LearningRateScheduler
from keras.callbacks import ModelCheckpoint
from math import ceil
import os
from keras.preprocessing.image import ImageDataGenerator

def unit(x, filters):
	out = BatchNormalization()(x)
	out = Activation("relu")(out)
	out = Conv2D(filters=filters, kernel_size=[3,3], strides=[1,1], padding="same")(out)
	return out

def minimodel(input_shape):
	images = Input(input_shape)

	net = unit(images, 64)
	net = unit(net, 64)
	net = unit(net, 64)
	net = MaxPooling2D(pool_size=(2,2))(net)

	net = unit(net, 128)
	net = unit(net, 128)
	net = unit(net, 128)
	net = MaxPooling2D(pool_size=(2,2))(net)

	net = unit(net, 256)
	net = unit(net, 256)
	net = unit(net, 256)
	
	net = Dropout(0.25)(net)
	net = AveragePooling2D(pool_size=(8, 8))(net)
	net = Flatten()(net)
	net = Dense(units=10, activation="softmax")(net)
	
	model = Model(inputs=images, outputs=net)
	return model

(train_x, train_y), (test_x, test_y) = cifar10.load_data()
train_x = train_x[:500]
train_y = train_y[:500]
test_x = test_x[:100]
test_y = test_y[:100]

train_x = train_x.astype('float32') / 255
test_x = test_x.astype('float32') / 255

train_x = train_x - train_x.mean()
test_x = test_x - test_x.mean()

train_x = train_x / train_x.std(axis=0)
test_x = test_x / test_x.std(axis=0)

datagen = ImageDataGenerator(rotation_range=10, width_shift_range=5. / 32, height_shift_range=5. / 32, horizontal_flip=True)

datagen.fit(train_x)

train_y = keras.utils.to_categorical(train_y, 10)
test_y = keras.utils.to_categorical(test_y, 10)

input_shape = (32, 32, 3)
model = minimodel(input_shape)

model.summary()
model.compile(optimizer=Adam(0.001), loss="categorical_crossentropy", metrics=["accuracy"])

epochs = 20
# steps_per_epoch = ceil(50000/128)
steps_per_epoch = ceil(500/128)

print(train_x.shape)
print(train_y.shape)
print(test_x.shape)
print(test_y.shape)
# model.fit_generator(datagen.flow(train_x, train_y, batch_size=128),
model.fit_generator(datagen.flow(train_x, train_y, batch_size=32),
	validation_data=[test_x, test_y],
	epochs=epochs, steps_per_epoch=steps_per_epoch,
	verbose=1, workers=4)

accuracy = model.evaluate(x=test_x, y=test_y, batch_size=32)
model.save("cifar10model.h5")

