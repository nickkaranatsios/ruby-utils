import gym
import sys
import numpy as np
env = gym.make("FrozenLake-v0")
env.seed(0)
np.random.seed(56776)

# hyperparameters
num_epis = 500
num_iter = 200
learning_rate = 0.3
discount = 0.8

print(env.observation_space)
print(env.action_space)

q_learning_table = np.zeros([env.observation_space.n, env.action_space.n])
print(q_learning_table)

print(env.render())

#env = gym.make("FrozenLakeNotSlippery-v0")
#s = env.reset()
#perfect_step = [1, 1, 2, 2, 1, 2]
#for x in perfect_step:
#	env.step(x)
#	env.render()

for epis in range(num_epis):
	state = env.reset()
	for iter in range(num_iter):
		action = np.argmax(q_learning_table[state,:] + np.random.randn(1, 4))
		state_new, reward, done, _ = env.step(action)
		q_learning_table[state, action] = (1 - learning_rate) * q_learning_table[state, action] + learning_rate * (reward + discount * np.max(q_learning_table[state_new, :]))
		state = state_new
		if done: break

print(np.argmax(q_learning_table, axis=1))
print(np.around(q_learning_table, 6))
print('----------------------------------')
s = env.reset()
for _ in range(100):
	action = np.argmax(q_learning_table[s,:])
	state_new, _, done, _ = env.step(action)
	env.render()
	s = state_new
	if done: break

env.close()
