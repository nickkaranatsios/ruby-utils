import pandas as pd
import matplotlib.pyplot as plt
import numpy as np
import scipy.stats as spstats


poke_df = pd.read_csv('data/Pokemon.csv', encoding='utf-8') 
print(poke_df.head())

print(poke_df[['HP', 'Attack', 'Defense']].head())

print(poke_df[['HP', 'Attack', 'Defense']].describe())

atk_def = poke_df[['Attack', 'Defense']]
atk_def.head()
