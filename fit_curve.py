from scipy.optimize import curve_fit
import numpy as np

def msd_func(x,a,b):
    return 4*a*np.power(x,b)

def fit_msd(t,curve):
    fita = curve_fit(msd_func,t,curve)
    return fita[0]