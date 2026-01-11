import numpy as np
from scipy import stats

def extract_behavioral_features(signal, window_size=128):
    """
    Transforms raw tri-axial sensor data into statistical features.
    Demonstrates handling of high-frequency sequential data for 
    behavioral monitoring and anomaly detection.
    """
    # Reshape signal into windows (Time, Axes)
    # Assumes signal is a NumPy array of shape (N, 3) for X, Y, Z axes
    features = []
    
    # Temporal Domain Features
    mean = np.mean(signal, axis=0)
    std = np.std(signal, axis=0)
    mag = np.linalg.norm(signal, axis=1).mean() # Signal Magnitude Area
    
    # Frequency Domain Features (via Fast Fourier Transform)
    # Critical for distinguishing between 'static' and 'dynamic' behaviors
    fft_values = np.abs(np.fft.rfft(signal, axis=0))
    spectral_energy = np.sum(fft_values**2, axis=0) / len(fft_values)
    
    # Concatenate features into a single behavioral vector
    feature_vector = np.hstack([mean, std, mag, spectral_energy])
    
    return feature_vector

# Example: Processing a synthetic 50Hz sensor stream
if __name__ == "__main__":
    synthetic_stream = np.random.normal(0, 1, (128, 3))
    vector = extract_behavioral_features(synthetic_stream)
    print(f"Extracted {len(vector)} features from raw sensor trajectory.")
