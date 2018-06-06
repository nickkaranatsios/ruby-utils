import tensorflow as tf

tf.InteractiveSession()


v = tf.constant([1, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5])
w = tf.constant([0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5])

euclidean = tf.sqrt(tf.reduce_sum(tf.square(tf.subtract(v, w))))
print(euclidean.eval())

a = tf.constant([
	[1, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5], 
	[0, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5, 0.5]])
print(a.eval())

norm = tf.norm(a)
print(norm.eval())

yz = tf.constant([
	[1, 1, 1, 0, 0.25, 0.75, 1, 1, 0.75, 1],
	[0, 1, 0.75, 0.25, 0, 1, 0.75, 1, 1, 1]])

y = tf.constant([1, 1, 1, 0, 0.25, 0.75, 1, 1, 0.75, 1])
z = tf.constant([0, 1, 0.75, 0.25, 0, 1, 0.75, 1, 1, 1])

print(tf.square(y).eval())
print(tf.square(z).eval())


euclidean = tf.sqrt(tf.reduce_sum(tf.square(tf.subtract(y, z))))
print(euclidean.eval())

norm = tf.norm(yz)
print(norm.eval())
