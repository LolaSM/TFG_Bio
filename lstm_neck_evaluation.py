"""
Script para entrenar un modelo LSTM sobre series temporales de pacientes,
asegurando la separación subject-wise (paciente completo) en train y test.

Clasificación binaria (pain vs no-pain), usando pérdida `binary_crossentropy` y salida `sigmoid`.

Columnas del CSV:
- paciente_columna: identificador único de paciente
- grupo_columna: etiqueta de clasificación (0 = no-pain, 1 = pain; constante por paciente)
- tiempo: instante temporal (en segundos)
- posicionX, posicionY, posicionZ: coordenadas espaciales
- anguloEulerX, anguloEulerY, anguloEulerZ: orientación en ángulos de Euler
"""

import pandas as pd
import numpy as np
from sklearn.preprocessing import StandardScaler
from sklearn.model_selection import train_test_split
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import LSTM, Dense, Dropout
import matplotlib.pyplot as plt
import warnings

# 1. Cargar y ordenar datos
df = pd.read_csv('tabla_gruposAB.csv')  # Ajustar ruta al CSV
# Mapear etiquetas A/B a 1/0 para clasificación binaria
df['grupo_columna'] = df['grupo_columna'].map({'A': 1, 'B': 0})
df.sort_values(by=['paciente_columna', 'tiempo'], inplace=True)

# 1.b. Calcular frecuencia de muestreo. Calcular frecuencia de muestreo
warnings.filterwarnings('ignore')
df['dt'] = df.groupby('paciente_columna')['tiempo'].diff()
median_dt = df['dt'].median()
if pd.isna(median_dt) or median_dt == 0:
    print('No se pudo calcular frecuencia de muestreo.')
    sampling_freq = None
else:
    sampling_freq = 1.0 / median_dt
    print(f"Frecuencia de muestreo: {sampling_freq:.2f} Hz")
df.drop(columns='dt', inplace=True)

# 2. Convertir tiempo de ms a segundos para cálculos físicos
df['tiempo_s'] = df['tiempo'] / 1000.0  # ahora en segundos

# 3. Calcular velocidad y aceleración por paciente (usando tiempo_s)
for axis in ['X', 'Y', 'Z']:
    df[f'vel_{axis}'] = df.groupby('paciente_columna')[f'posicion{axis}'].diff() \
                         / df.groupby('paciente_columna')['tiempo_s'].diff()
    df[f'acel_{axis}'] = df.groupby('paciente_columna')[f'vel_{axis}'].diff() \
                          / df.groupby('paciente_columna')['tiempo_s'].diff()

# Rellenar NaN iniciales con 0 (inicio de cada paciente sin cambio)
df.fillna(0, inplace=True)

# 4. Selección y normalización de features
features = [
    'posicionX','posicionY','posicionZ',
    'anguloEulerX','anguloEulerY','anguloEulerZ',
    'vel_X','vel_Y','vel_Z',
    'acel_X','acel_Y','acel_Z'
]
scaler = StandardScaler()
df[features] = scaler.fit_transform(df[features])

# 4. Función para crear secuencias por paciente
def create_sequences(data, seq_length):
    Xs, ys = [], []
    for _, group in data.groupby('paciente_columna'):
        vals = group[features].values
        lab = group['grupo_columna'].iloc[0]  # constante por paciente
        for i in range(len(vals) - seq_length + 1):
            Xs.append(vals[i:i+seq_length])
            ys.append(lab)
    return np.array(Xs), np.array(ys)

# 5. Definir ventana de tiempo y calcular longitud de secuencia
window_seconds = 300  # segundos de historia
if sampling_freq is None:
    raise ValueError('sampling_freq no determinado.')
seq_len = max(1, int(window_seconds * sampling_freq))
print(f"Seq_len: {seq_len} muestras (~{window_seconds}s)")

# 6. División subject-wise en train/test
pacientes = df['paciente_columna'].unique()
etiq_pac = df.groupby('paciente_columna')['grupo_columna'].first().loc[pacientes].values
train_pac, test_pac = train_test_split(pacientes, test_size=0.2, random_state=42, stratify=etiq_pac)

df_train = df[df['paciente_columna'].isin(train_pac)]
df_test  = df[df['paciente_columna'].isin(test_pac)]

# 7. Crear secuencias y etiquetas binarias
X_train, y_train = create_sequences(df_train, seq_len)
X_test,  y_test  = create_sequences(df_test,  seq_len)

y_train = y_train.astype('float32')
y_test  = y_test.astype('float32')

# 8. Definir modelo LSTM para clasificación binaria
model = Sequential([
    LSTM(64, input_shape=(seq_len, len(features)), return_sequences=True),
    Dropout(0.3),
    LSTM(32),
    Dropout(0.3),
    Dense(16, activation='relu'),
    Dense(1, activation='sigmoid')
])
model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])
model.summary()

# 9. Entrenamiento
epochs = 50
batch_size = 32
history = model.fit(
    X_train, y_train,
    epochs=epochs,
    batch_size=batch_size,
    validation_split=0.2
)

# 10. Graficar métricas
plt.figure()
plt.plot(history.history['accuracy'], label='Entrenamiento')
plt.plot(history.history['val_accuracy'], label='Validación')
plt.title('Precisión por época')
plt.xlabel('Época')
plt.ylabel('Precisión')
plt.legend()
plt.show()

plt.figure()
plt.plot(history.history['loss'], label='Entrenamiento')
plt.plot(history.history['val_loss'], label='Validación')
plt.title('Pérdida por época')
plt.xlabel('Época')
plt.ylabel('Pérdida')
plt.legend()
plt.show()

# 11. Evaluación y guardado
loss, acc = model.evaluate(X_test, y_test)
print(f"Precisión en test: {acc*100:.2f}%")
model.save('modelo_lstm_binary.h5')
import joblib
joblib.dump(scaler, 'scaler_binary.pkl')
