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

% Recorremos cada paciente en el grupoA_data
% Extraemos las columnas
% Inicializamos matrices para guardar el vector por paciente --> cambiar
% cuando sepa el tamaño real
grupoA_vector = zeros(43, 24);
grupoB_vector = zeros(44, 24);

for i = 1:43
    tiempo_A{i} = table2array(datosFiltradosA{i}(:, 2));
    posicionX_A{i} = table2array(datosFiltradosA{i}(:, 4));
    posicionY_A{i} = table2array(datosFiltradosA{i}(:, 5));
    posicionZ_A{i} = table2array(datosFiltradosA{i}(:, 6));
    anguloEulerX_A{i} = table2array(datosFiltradosA{i}(:, 11));
    anguloEulerY_A{i} = table2array(datosFiltradosA{i}(:, 12));
    anguloEulerZ_A{i} = table2array(datosFiltradosA{i}(:, 13));

     %Centramos en 0 los datos--> restamos el promedio de las primeras 50 muestras
    promedio_X_A{i} = mean(posicionX_A{i}(1:50));
    promedio_Y_A{i} = mean(posicionY_A{i}(1:50));
    promedio_Z_A{i} = mean(posicionZ_A{i}(1:50));
    
    % Centrar las posiciones restando el promedio correspondiente
    posicionX_A_centrada{i} = posicionX_A{i} - promedio_X_A{i};
    posicionY_A_centrada{i} = posicionY_A{i} - promedio_Y_A{i};
    posicionZ_A_centrada{i} = posicionZ_A{i} - promedio_Z_A{i};

    %Centramos en 0 los datos--> restamos el promedio de las primeras 50 muestras
    promedio_x_A{i} = mean(anguloEulerX_A{i}(1:50));
    promedio_y_A{i} = mean(anguloEulerY_A{i}(1:50));
    promedio_z_A{i} = mean(anguloEulerZ_A{i}(1:50));
    
    % Centrar los ángulos restando el promedio correspondiente
    anguloEulerX_A_centrado{i} = anguloEulerX_A{i} - promedio_x_A{i};
    anguloEulerY_A_centrado{i} = anguloEulerY_A{i} - promedio_y_A{i};
    anguloEulerZ_A_centrado{i} = anguloEulerZ_A{i} - promedio_z_A{i};
    
    % Hago wrapping para que los ángulos que están entre [0,360] estén entre [-180,180] grados
    anguloEulerX_A_centrado{i} = wrapTo180(anguloEulerX_A_centrado{i});
    anguloEulerY_A_centrado{i} = wrapTo180(anguloEulerY_A_centrado{i});
    anguloEulerZ_A_centrado{i} = wrapTo180(anguloEulerZ_A_centrado{i});

    % Vector con las medias + desviaciones + kurtosis + skewness en cada eje
    mediaPos_A = [ mean(posicionX_A_centrada{i}),mean(posicionY_A_centrada{i}),mean(posicionZ_A_centrada{i})];
    mediaAng_A = [ mean(anguloEulerX_A_centrado{i}),mean(anguloEulerY_A_centrado{i}),mean(anguloEulerZ_A_centrado{i})];
    stdPos_A = [ std(posicionX_A_centrada{i}),std(posicionY_A_centrada{i}),std(posicionZ_A_centrada{i})];
    stdAng_A = [ std(anguloEulerX_A_centrado{i}),std(anguloEulerY_A_centrado{i}),std(anguloEulerZ_A_centrado{i})];
    kurPos_A = [ kurtosis(posicionX_A_centrada{i}),kurtosis(posicionY_A_centrada{i}),kurtosis(posicionZ_A_centrada{i})];
    kurAng_A = [ kurtosis(anguloEulerX_A_centrado{i}),kurtosis(anguloEulerY_A_centrado{i}),kurtosis(anguloEulerZ_A_centrado{i})];
    skwPos_A = [ skewness(posicionX_A_centrada{i}),skewness(posicionY_A_centrada{i}),skewness(posicionZ_A_centrada{i})];
    skwAng_A = [ skewness(anguloEulerX_A_centrado{i}),skewness(anguloEulerY_A_centrado{i}),skewness(anguloEulerZ_A_centrado{i})];

    % Concatenar todas las medidas en un vector para el paciente i
    grupoA_vector(i, :) = [mediaPos_A, mediaAng_A, stdPos_A, stdAng_A, kurPos_A, kurAng_A, skwPos_A, skwAng_A];

end

for i = 1:44
    tiempo_B{i} = table2array(datosFiltradosB{i}(:, 2));
    posicionX_B{i} = table2array(datosFiltradosB{i}(:, 4));
    posicionY_B{i} = table2array(datosFiltradosB{i}(:, 5));
    posicionZ_B{i} = table2array(datosFiltradosB{i}(:, 6));
    anguloEulerX_B{i} = table2array(datosFiltradosB{i}(:, 11));
    anguloEulerY_B{i} = table2array(datosFiltradosB{i}(:, 12));
    anguloEulerZ_B{i} = table2array(datosFiltradosB{i}(:, 13));

    %Centramos en 0 los datos--> restamos el promedio de las primeras 50 muestras
    promedio_X_B{i} = mean(posicionX_B{i}(1:50));
    promedio_Y_B{i} = mean(posicionY_B{i}(1:50));
    promedio_Z_B{i} = mean(posicionZ_B{i}(1:50));
    
    % Centrar las posiciones restando el promedio correspondiente
    posicionX_B_centrada{i} = posicionX_B{i} - promedio_X_B{i};
    posicionY_B_centrada{i} = posicionY_B{i} - promedio_Y_B{i};
    posicionZ_B_centrada{i} = posicionZ_B{i} - promedio_Z_B{i};

    %Centramos en 0 los datos--> restamos el promedio de las primeras 50 muestras
    promedio_x_B{i} = mean(anguloEulerX_B{i}(1:50));
    promedio_y_B{i} = mean(anguloEulerY_B{i}(1:50));
    promedio_z_B{i} = mean(anguloEulerZ_B{i}(1:50));
    
    % Centrar los ángulos restando el promedio correspondiente
    anguloEulerX_B_centrado{i} = anguloEulerX_B{i} - promedio_x_B{i};
    anguloEulerY_B_centrado{i} = anguloEulerY_B{i} - promedio_y_B{i};
    anguloEulerZ_B_centrado{i} = anguloEulerZ_B{i} - promedio_z_B{i};
    
    %Hago wrapping para que los ángulos que están entre [0,360] estén entre [-180,180] grados
    anguloEulerX_B_centrado{i} = wrapTo180(anguloEulerX_B_centrado{i});
    anguloEulerY_B_centrado{i} = wrapTo180(anguloEulerY_B_centrado{i});
    anguloEulerZ_B_centrado{i} = wrapTo180(anguloEulerZ_B_centrado{i});

    % Vector con las medias + desviaciones + XXX en cada eje
    mediaPos_B = [ mean(posicionX_B_centrada{i}),mean(posicionY_B_centrada{i}),mean(posicionZ_B_centrada{i})];
    mediaAng_B = [ mean(anguloEulerX_B_centrado{i}),mean(anguloEulerY_B_centrado{i}),mean(anguloEulerZ_B_centrado{i})];
    stdPos_B = [ std(posicionX_B_centrada{i}),std(posicionY_B_centrada{i}),std(posicionZ_B_centrada{i})];
    stdAng_B = [ std(anguloEulerX_B_centrado{i}),std(anguloEulerY_B_centrado{i}),std(anguloEulerZ_B_centrado{i})];
    kurPos_B = [ kurtosis(posicionX_B_centrada{i}),kurtosis(posicionY_B_centrada{i}),kurtosis(posicionZ_B_centrada{i})];
    kurAng_B = [ kurtosis(anguloEulerX_B_centrado{i}),kurtosis(anguloEulerY_B_centrado{i}),kurtosis(anguloEulerZ_B_centrado{i})];
    skwPos_B = [ skewness(posicionX_B_centrada{i}),skewness(posicionY_B_centrada{i}),skewness(posicionZ_B_centrada{i})];
    skwAng_B = [ skewness(anguloEulerX_B_centrado{i}),skewness(anguloEulerY_B_centrado{i}),skewness(anguloEulerZ_B_centrado{i})];

    % Concatenar medias y desviaciones en un vector para el paciente i
    grupoB_vector(i, :) = [mediaPos_B, mediaAng_B, stdPos_B, stdAng_B, kurPos_B, kurAng_B, skwPos_B, skwAng_B];
end
% *EXPORTACIÓN DE LOS DATOS A UN CSV*
% *CREO UNA TABLA CON TODOS LOS DATOS FILTRADOS (SOLO INFO DE 'H' Y QUITANDO 
% PRIMERAS CELDAS SIN DATOS)  DEL GRUPO A Y B*

% Inicializar una tabla vacía para almacenar todos los datos
tablaAB = table();

% Recorrer todas las tablas de los pacientes 
for i = 1:43
    % Filtrar los datos para cada paciente (en este caso, "datosFiltradosA{i}")
    tabla_paciente_A = datosFiltradosA{i};
    
    % Crear una columna nueva que identifique al paciente
    paciente_columna = repmat(i, height(tabla_paciente_A), 1);  % Asignar el número del paciente
    
    % Añadir la columna de paciente a la tabla
    tabla_paciente_A.Paciente = paciente_columna;

    % Crear una columna que identifique el grupo (Grupo A)
    grupo_columna = repmat('A', height(tabla_paciente_A), 1);  % Asignar el grupo 'A'
    tabla_paciente_A.Grupo = grupo_columna;
    
    % Concatenar los datos de este paciente con todos los demás
    tablaAB = [tablaAB; tabla_paciente_A];  % Concatenar por filas
end

% Recorrer todas las tablas de los pacientes 
for i = 1:44
    % Filtrar los datos para cada paciente (en este caso, "datosFiltradosA{i}")
    tabla_paciente_B = datosFiltradosB{i};
    
    % Crear una columna nueva que identifique al paciente
    paciente_columna = repmat(i+43, height(tabla_paciente_B), 1);  % Asignar el número del paciente
    
    % Añadir la columna de paciente a la tabla
    tabla_paciente_B.Paciente = paciente_columna;

     % Crear una columna que identifique el grupo (Grupo B)
    grupo_columna = repmat('B', height(tabla_paciente_B), 1);  % Asignar el grupo 'B'
    tabla_paciente_B.Grupo = grupo_columna;

    % Concatenar los datos del paciente del Grupo B con todos los demás
    tablaAB = [tablaAB; tabla_paciente_B];  % Concatenar por filas
end

% Guardar en un csv esta tabla que contiene los datos iniciales
writetable(tablaAB, 'tablaAB_inicial.csv');
%% 
% *CREO UNA TABLA CON TODOS LOS PACIENTES (GRUPO A Y B)* 
% 
% *Esta tabla contiene todos los datos de tiempo, posicion, ángulos cada eje 
% y centrados* 

% Inicializar una tabla vacía para almacenar todos los datos de ambos grupos
tabla_completa = table();

% Recorrer los 43 pacientes del Grupo A
for i = 1:43
    % Crear una tabla para los datos del paciente i del Grupo A
    paciente_columna = repmat(i, length(tiempo_A{i}), 1);  % Número del paciente
    grupo_columna = repmat('A', length(tiempo_A{i}), 1);  % Indicar que es del Grupo A
    
    % Obtener los datos del paciente i del Grupo A
    tiempo = tiempo_A{i};
    posicionX = posicionX_A_centrada{i};
    posicionY = posicionY_A_centrada{i};
    posicionZ = posicionZ_A_centrada{i};
    anguloEulerX = anguloEulerX_A_centrado{i};
    anguloEulerY = anguloEulerY_A_centrado{i};
    anguloEulerZ = anguloEulerZ_A_centrado{i};

    
    % Crear la tabla del paciente del Grupo A
    tabla_paciente_A = table(paciente_columna, grupo_columna, tiempo, ...
                              posicionX, posicionY, posicionZ, ...
                              anguloEulerX, anguloEulerY, anguloEulerZ);
    
    % Concatenar los datos del paciente del Grupo A
    tabla_completa = [tabla_completa; tabla_paciente_A];
end
% Recorrer los 44 pacientes del Grupo B
for i = 1:44
    % Crear una tabla para los datos del paciente i del Grupo B
    paciente_columna = repmat(i+43, length(tiempo_B{i}), 1);  % Número del paciente
    grupo_columna = repmat('B', length(tiempo_B{i}), 1);  % Indicar que es del Grupo B
    
    % Obtener los datos del paciente i del Grupo B
    tiempo = tiempo_B{i};
    posicionX = posicionX_B_centrada{i};
    posicionY = posicionY_B_centrada{i};
    posicionZ = posicionZ_B_centrada{i};
    anguloEulerX = anguloEulerX_B_centrado{i};
    anguloEulerY = anguloEulerY_B_centrado{i};
    anguloEulerZ = anguloEulerZ_B_centrado{i};
    
    % Crear la tabla del paciente del Grupo B
    tabla_paciente_B = table(paciente_columna, grupo_columna, tiempo, ...
                              posicionX, posicionY, posicionZ, ...
                              anguloEulerX, anguloEulerY, anguloEulerZ);
    
    % Concatenar los datos del paciente del Grupo B
    tabla_completa = [tabla_completa; tabla_paciente_B];
end

% Ahora 'tabla_completa' contiene los datos de todos los pacientes del Grupo A y Grupo B
% Guardar los datos combinados en un archivo CSV
writetable(tabla_completa, 'tablagrupos_AB.csv');
%% 
% *Dataset con los vectores por paciente para el modelo*

% Definir los nombres de las variables (columnas) que corresponden a los 12 elementos
varNames = {'mediaPosX','mediaPosY','mediaPosZ', ...
            'mediaAngX','mediaAngY','mediaAngZ', ...
            'stdPosX','stdPosY','stdPosZ', ...
            'stdAngX','stdAngY','stdAngZ', ...
            'kurPosX','kurPosY','kurPosZ', ...
            'kurAngX','kurAngY','kurAngZ', ...
            'skwPosX','skwPosY','skwPosZ', ...
            'skwAngX','skwAngY','skwAngZ'};

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
writetable(tabla_completa_vectores, 'tablaVectores_AB.csv');