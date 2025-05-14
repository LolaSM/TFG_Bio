%% 
% *ACCESO A LAS CARPETAS DE LA BASE DE DATOS*

% Ruta de la carpeta donde están las subcarpetas 'Grupo A' y 'Grupo B'
outputFolder = 'C:\Users\lolas\OneDrive\Documentos\Universidad\5º\TFG_Biomédica\BBDD\Grupos A y B_Punto\Grupos A y B_Punto\Grupos A y B';

% Verificar si la ruta existe
if exist(outputFolder, 'dir') == 0
    error('La ruta no existe. Verifica la ruta de la carpeta.');
end

% Verificar si hay archivos CSV en 'Grupo A'
grupoA_CSV = dir(fullfile(outputFolder, 'Grupo A', '*.csv'));
if isempty(grupoA_CSV)
    disp('No se encontraron archivos CSV en la carpeta Grupo A.');
else
    disp('Archivos CSV encontrados en Grupo A:');
    disp({grupoA_CSV.name});
end
% Verificar si hay archivos CSV en 'Grupo B'
grupoB_CSV = dir(fullfile(outputFolder, 'Grupo B', '*.csv'));
if isempty(grupoB_CSV)
    disp('No se encontraron archivos CSV en la carpeta Grupo B.');
else
    disp('Archivos CSV encontrados en Grupo B:');
    disp({grupoB_CSV.name});
end
%% 
% 
% 
% *GENERACIÓN DE DOS TABLAS PARA  ALMACENAR DATOS DE GRUPO A (PAIN-FREE) Y GRUPO 
% B (PAIN-AFFECTED)*

% Inicializar las celdas para almacenar los datos de todos los pacientes
pacienteA_data = {};
pacienteB_data = {};

% Cargar archivos CSV de 'grupo A' (43 pacientes)
for i = 1:43
    csvPathA{i} = fullfile(grupoA_CSV(i).folder, grupoA_CSV(i).name);
    opts = detectImportOptions(csvPathA{i}, 'Delimiter', ';');
    opts.VariableNames = {'Sample', 'Time', 'Device', 'X', 'Y', 'Z', 'qX', 'qY', 'qZ', 'qW', 'x', 'y', 'z'};
    opts.VariableTypes = {'double', 'double', 'char', 'double', 'double', 'double', ...
                          'double', 'double', 'double', 'double', 'double', 'double', 'double'};
    pacienteA_data{i} = readtable(csvPathA{i}, opts);
    % Filtrar y procesar datos
    tablaPacienteA{i} = pacienteA_data{i};
    % Eliminar registros de calentamiento
    idxStored = find(strcmp(tablaPacienteA{i}.Device, 'stored.Apple 3'), 1, 'first');
    if ~isempty(idxStored)
        tablaPacienteA{i} = tablaPacienteA{i}(idxStored:end, :);
    else
        warning('No se encontró "stored.Apple 3" en el paciente %d', i);
    end
    % Solo registros 'H'
    datosFiltradosA{i} = tablaPacienteA{i}(strcmp(tablaPacienteA{i}.Device, 'H'), :);
    % Eliminar registros donde X o el siguiente valor de X sea 0
    idxA = find(datosFiltradosA{i}.X ~= 0 & [datosFiltradosA{i}.X(2:end); 0] ~= 0, 1);
    datosFiltradosA{i} = datosFiltradosA{i}(idxA:end, :);
end

%Cargar archivos CSV de 'grupo B' (44 pacientes)
for i = 1:44
    csvPathB{i} = fullfile(grupoB_CSV(i).folder, grupoB_CSV(i).name);
    opts = detectImportOptions(csvPathB{i}, 'Delimiter', ';');
    opts.VariableNames = {'Sample', 'Time', 'Device', 'X', 'Y', 'Z', 'qX', 'qY', 'qZ', 'qW', 'x', 'y', 'z'};
    opts.VariableTypes = {'double', 'double', 'char', 'double', 'double', 'double', ...
                          'double', 'double', 'double', 'double', 'double', 'double', 'double'};
    pacienteB_data{i} = readtable(csvPathB{i}, opts);
    % Filtrar y procesar datos
    tablaPacienteB{i} = pacienteB_data{i};
    % Eliminar registros de calentamiento
    idxStored = find(strcmp(tablaPacienteB{i}.Device, 'stored.Apple 3'), 1, 'first');
    if ~isempty(idxStored)
        tablaPacienteB{i} = tablaPacienteB{i}(idxStored:end, :);
    else
        warning('No se encontró "stored.Apple 3" en el paciente %d', i);
    end
    % Solo registros 'H'
    datosFiltradosB{i} = tablaPacienteB{i}(strcmp(tablaPacienteB{i}.Device, 'H'), :);
    % Eliminar registros donde X o el siguiente valor de X sea 0
    idxB = find(datosFiltradosB{i}.X ~= 0 & [datosFiltradosB{i}.X(2:end); 0] ~= 0, 1);
    datosFiltradosB{i} = datosFiltradosB{i}(idxB:end, :);
end
%% 
% *EXTRACCIÓN DE VARIABLES*

% Recorremos cada paciente 
% Extraemos las columnas
% Inicializamos matrices para guardar el vector por paciente 
% cuando sepa el tamaño real
grupoA_vector = zeros(43, 24);
grupoB_vector = zeros(44, 24);

dt = (1/50); %Periodo de muestreo = 20ms

%Filtrado de las velocidades y aceleraciones
fs = 50;  % Frecuencia de muestreo (Hz)
fc = 20;  % Frecuencia de corte (Hz) 
orden = 2;  % Orden del filtro 
[b, a] = butter(orden, fc/(fs/2), 'low');

for i = 1:43
    tiempo_A{i} = table2array(datosFiltradosA{i}(:, 2));
    posicionX_A{i} = table2array(datosFiltradosA{i}(:, 4));
    posicionY_A{i} = table2array(datosFiltradosA{i}(:, 5));
    posicionZ_A{i} = table2array(datosFiltradosA{i}(:, 6));

     %Centramos en 0 los datos--> restamos el promedio de las primeras 50 muestras
    promedio_X_A{i} = mean(posicionX_A{i}(1:50));
    promedio_Y_A{i} = mean(posicionY_A{i}(1:50));
    promedio_Z_A{i} = mean(posicionZ_A{i}(1:50));
    
    % Centrar las posiciones restando el promedio correspondiente
    posicionX_A_centrada{i} = posicionX_A{i} - promedio_X_A{i};
    posicionY_A_centrada{i} = posicionY_A{i} - promedio_Y_A{i};
    posicionZ_A_centrada{i} = posicionZ_A{i} - promedio_Z_A{i};

    %La velocidad es la primera derivada y la aceleración la segunda derivada
    velocidad_X_A{i} = diff(posicionX_A_centrada{i})/dt;
    velocidad_Y_A{i} = diff(posicionY_A_centrada{i})/dt;
    velocidad_Z_A{i} = diff(posicionZ_A_centrada{i})/dt;
    aceleracion_X_A{i} = diff(velocidad_X_A{i})/dt;
    aceleracion_Y_A{i} = diff(velocidad_Y_A{i})/dt;
    aceleracion_Z_A{i} = diff(velocidad_Z_A{i})/dt;

    velocidad_X_A_filtrada{i} = filtfilt(b, a, velocidad_X_A{i});
    velocidad_Y_A_filtrada{i} = filtfilt(b, a, velocidad_Y_A{i});
    velocidad_Z_A_filtrada{i} = filtfilt(b, a, velocidad_Z_A{i});
    aceleracion_X_A_filtrada{i} = diff(velocidad_X_A_filtrada{i})/dt;
    aceleracion_Y_A_filtrada{i} = diff(velocidad_Y_A_filtrada{i})/dt;
    aceleracion_Z_A_filtrada{i} = diff(velocidad_Z_A_filtrada{i})/dt;

    % Vector con las medias + desviaciones + kurtosis + skewness en cada eje
    mediaVel_A = [ mean(velocidad_X_A_filtrada{i}),mean(velocidad_Y_A_filtrada{i}),mean(velocidad_Z_A_filtrada{i})];
    mediaAcc_A = [ mean(aceleracion_X_A_filtrada{i}),mean(aceleracion_Y_A_filtrada{i}),mean(aceleracion_Z_A_filtrada{i})];
    stdVel_A = [ std(velocidad_X_A_filtrada{i}),std(velocidad_Y_A_filtrada{i}),std(velocidad_Z_A_filtrada{i})];
    stdAcc_A = [ std(aceleracion_X_A_filtrada{i}),std(aceleracion_Y_A_filtrada{i}),std(aceleracion_Z_A_filtrada{i})];
    kurVel_A = [ kurtosis(velocidad_X_A_filtrada{i}),kurtosis(velocidad_Y_A_filtrada{i}),kurtosis(velocidad_Z_A_filtrada{i})];
    kurAcc_A = [ kurtosis(aceleracion_X_A_filtrada{i}),kurtosis(aceleracion_Y_A_filtrada{i}),kurtosis(aceleracion_Z_A_filtrada{i})];
    skwVel_A = [ skewness(velocidad_X_A_filtrada{i}),skewness(velocidad_Y_A_filtrada{i}),skewness(velocidad_Z_A_filtrada{i})];
    skwAcc_A = [ skewness(aceleracion_X_A_filtrada{i}),skewness(aceleracion_Y_A_filtrada{i}),skewness(aceleracion_Z_A_filtrada{i})];

    % Concatenar todas las medidas en un vector para el paciente i
    grupoA_vector(i, :) = [mediaVel_A, mediaAcc_A, stdVel_A, stdAcc_A, kurVel_A, kurAcc_A, skwVel_A, skwAcc_A];

end

for i = 1:44
    tiempo_B{i} = table2array(datosFiltradosB{i}(:, 2));
    posicionX_B{i} = table2array(datosFiltradosB{i}(:, 4));
    posicionY_B{i} = table2array(datosFiltradosB{i}(:, 5));
    posicionZ_B{i} = table2array(datosFiltradosB{i}(:, 6));

    %Centramos en 0 los datos--> restamos el promedio de las primeras 50 muestras
    promedio_X_B{i} = mean(posicionX_B{i}(1:50));
    promedio_Y_B{i} = mean(posicionY_B{i}(1:50));
    promedio_Z_B{i} = mean(posicionZ_B{i}(1:50));
    
    % Centrar las posiciones restando el promedio correspondiente
    posicionX_B_centrada{i} = posicionX_B{i} - promedio_X_B{i};
    posicionY_B_centrada{i} = posicionY_B{i} - promedio_Y_B{i};
    posicionZ_B_centrada{i} = posicionZ_B{i} - promedio_Z_B{i};

    dt = (1/50); %Periodo de muestreo = 20ms

    %La velocidad es la primera derivada y la aceleración la segunda derivada
    velocidad_X_B{i} = diff(posicionX_B_centrada{i})/dt;
    velocidad_Y_B{i} = diff(posicionY_B_centrada{i})/dt;
    velocidad_Z_B{i} = diff(posicionZ_B_centrada{i})/dt;
    aceleracion_X_B{i} = diff(velocidad_X_B{i})/dt;
    aceleracion_Y_B{i} = diff(velocidad_Y_B{i})/dt;
    aceleracion_Z_B{i} = diff(velocidad_Z_B{i})/dt;

    velocidad_X_B_filtrada{i} = filtfilt(b, a, velocidad_X_B{i});
    velocidad_Y_B_filtrada{i} = filtfilt(b, a, velocidad_Y_B{i});
    velocidad_Z_B_filtrada{i} = filtfilt(b, a, velocidad_Z_B{i});
    aceleracion_X_B_filtrada{i} = diff(velocidad_X_B_filtrada{i})/dt;
    aceleracion_Y_B_filtrada{i} = diff(velocidad_Y_B_filtrada{i})/dt;
    aceleracion_Z_B_filtrada{i} = diff(velocidad_Z_B_filtrada{i})/dt;

    % Vector con las medias + desviaciones + kurtosis + skewness en cada eje
    mediaVel_B = [ mean(velocidad_X_B_filtrada{i}),mean(velocidad_Y_B_filtrada{i}),mean(velocidad_Z_B_filtrada{i})];
    mediaAcc_B = [ mean(aceleracion_X_B_filtrada{i}),mean(aceleracion_Y_B_filtrada{i}),mean(aceleracion_Z_B_filtrada{i})];
    stdVel_B = [ std(velocidad_X_B_filtrada{i}),std(velocidad_Y_B_filtrada{i}),std(velocidad_Z_B_filtrada{i})];
    stdAcc_B = [ std(aceleracion_X_B_filtrada{i}),std(aceleracion_Y_B_filtrada{i}),std(aceleracion_Z_B_filtrada{i})];
    kurVel_B = [ kurtosis(velocidad_X_B_filtrada{i}),kurtosis(velocidad_Y_B_filtrada{i}),kurtosis(velocidad_Z_B_filtrada{i})];
    kurAcc_B = [ kurtosis(aceleracion_X_B_filtrada{i}),kurtosis(aceleracion_Y_B_filtrada{i}),kurtosis(aceleracion_Z_B_filtrada{i})];
    skwVel_B = [ skewness(velocidad_X_B_filtrada{i}),skewness(velocidad_Y_B_filtrada{i}),skewness(velocidad_Z_B_filtrada{i})];
    skwAcc_B = [ skewness(aceleracion_X_B_filtrada{i}),skewness(aceleracion_Y_B_filtrada{i}),skewness(aceleracion_Z_B_filtrada{i})];

    % Concatenar medias y desviaciones en un vector para el paciente i
    grupoB_vector(i, :) = [mediaVel_B, mediaAcc_B, stdVel_B, stdAcc_B, kurVel_B, kurAcc_B, skwVel_B, skwAcc_B];
end

%% 
% *Dataset con los vectores por paciente para el modelo*

% Definir los nombres de las variables (columnas) que corresponden a los 12 elementos
varNames = {'mediaVelX','mediaVelY','mediaVelZ', ...
            'mediaAccX','mediaAccY','mediaAccZ', ...
            'stdVelX','stdVelY','stdVelZ', ...
            'stdAccX','stdAccY','stdAccZ', ...
            'kurVelX','kurVelY','kurVelZ', ...
            'kurAccX','kurAccY','kurAccZ', ...
            'skwVelX','skwVelY','skwVelZ', ...
            'skwAccX','skwAccY','skwAccZ'};

% Crear tabla para Grupo A
patientA = (1:43)';  % Número de paciente para el grupo A
groupA = repmat("A", 43, 1);  % Identificador de grupo
tablaA = array2table(grupoA_vector, 'VariableNames', varNames);
tablaA.patient = patientA;
tablaA.group   = groupA;
% Reordenar para dejar las columnas de identificación al principio
tablaA = movevars(tablaA, {'patient','group'}, 'Before', 1);

% Crear tabla para Grupo B
patientB = (44:43+44)';  % Los pacientes del grupo B numerados consecutivamente (44 a 87)
groupB = repmat("B", 44, 1);  % Identificador de grupo
tablaB = array2table(grupoB_vector, 'VariableNames', varNames);
tablaB.patient = patientB;
tablaB.group   = groupB;
tablaB = movevars(tablaB, {'patient','group'}, 'Before', 1);

% Concatenar ambas tablas
tabla_completa_vectores = [tablaA; tablaB];

% Exportar la tabla a CSV
writetable(tabla_completa_vectores, 'tablaVectores_AB_speed_acceleration.csv');