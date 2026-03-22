% -------------------------------------------------------------------------
% PROGRAM: 3D Mozgáskövetés - 3-SZENZOROS KINEMATIKAI LÁNC (Mellkas-Kar)
% Protokoll: Kalibráció T-POSE-ban (Kinyújtott kar oldalra, vízszintesen)
% Geometria: Dobozok az X-tengely mentén
% -------------------------------------------------------------------------
function Test_Vall_Alkar()
    clearvars; close all; clc;
    app = struct(); 
    
    %% Főablak és GUI beállítása
    app.figure = uifigure('Name','Kinematikai Lánc Teszt - T-Pose','Position', [100 100 800 600]);
    app.figure.CloseRequestFcn = @(~,~) exitProgram(); 
    grids = uigridlayout(app.figure,[1 2]); 
    grids.ColumnWidth = {200,'1x'};         
    
    panel_control_grid = uigridlayout(grids,[6 1]);
    
    % Gombok és státusz
    button_connect = uibutton(panel_control_grid,'Text','Csatlakozás', 'ButtonPushedFcn', @(~,~) connectSerial());
    button_start = uibutton(panel_control_grid,'Text','Indítás','Enable','off', 'ButtonPushedFcn', @(~,~) startProgram());
    button_calibrate  = uibutton(panel_control_grid, 'Text', 'T-POSE KALIBRÁCIÓ', 'Enable', 'off', 'ButtonPushedFcn', @(~,~) Calibration(), 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.33 0.1]);
    label_status = uilabel(panel_control_grid,'Text','Status: Disconnected');
    
    % 3D Tér beállítása
    model_ax = uiaxes(grids); 
    axis(model_ax,'equal'); grid(model_ax,'on'); hold(model_ax,'on');
    xlabel(model_ax,'X'); ylabel(model_ax,'Y'); zlabel(model_ax,'Z');
    view(model_ax, 3); 
    xlim(model_ax,[-100 100]); ylim(model_ax,[-100 100]); zlim(model_ax,[-100 100]);    
    
    %% 3D modell setup (Hierarchikus geometriák)
    app.arm_fix = [0, 0, 30]; % Vállízület (gyökér pont) a térben
    
    % 1. FELKAR (Piros)
    app.size_upper_arm = [40 12 12]; % Hossz: 40
    [app.V_local_ua, app.Faces] = boxGeometry(app.size_upper_arm);
    app.patch_ua = patch(model_ax, 'Vertices', app.V_local_ua, 'Faces', app.Faces, 'FaceColor', 'red');
    
    % 2. ALKAR (Zöld - Rövidebb)
    app.size_forearm = [30 12 12]; % Hossz: 30 (Kicsit rövidebb, mint kérted)
    [app.V_local_fa, ~] = boxGeometry(app.size_forearm);
    app.patch_fa = patch(model_ax, 'Vertices', app.V_local_fa, 'Faces', app.Faces, 'FaceColor', 'green'); % <--- ZÖLD SZÍN
    
    % Változók inicializálása
    app.R_calib_0 = eye(3); app.R_calib_1 = eye(3); app.R_calib_2 = eye(3);
    app.requestCalibration = false;
    app.isCalibrated = false; 
    
    %% GUI Függvények
    function connectSerial()
        try
            app.serial = serialport("COM3", 115200); % Cseréld, ha kell!
            configureTerminator(app.serial, "CR/LF");
            label_status.Text = "Csatlakozva: COM3";
            button_start.Enable = 'on';
        catch err
            label_status.Text = "Hiba: " + err.message;
        end
    end

    function startProgram()
        app.run = true; 
        button_start.Enable = 'off'; 
        button_calibrate.Enable = 'on';
        flush(app.serial); % Takarítás indításkor
        
        R_raw_0 = eye(3); R_raw_1 = eye(3); R_raw_2 = eye(3); % Nyers mátrixok
        
       while app.run
            if ~isvalid(app.figure), break; end
            
            if app.serial.NumBytesAvailable > 0
                try
                    line = char(readline(app.serial));
                    
                    % PROTOKOLL: 3-SZENZOROS ADATBEOLVASÁS
                    if startsWith(line, '0:')
                        data = sscanf(line, '0: %f %f %f %f'); 
                        if length(data) == 4, R_raw_0 = quat2rotm(data'); end
                        
                    elseif startsWith(line, '1:')
                        data = sscanf(line, '1: %f %f %f %f'); 
                        if length(data) == 4
                            R_raw_1 = quat2rotm(data'); 
                            % TENGELYCSERE A MELLKASON (Marad a tegnapi)
                            T_align = [1,  0,  0; 0,  0,  1; 0, -1,  0];
                            R_raw_1 = R_raw_1 * T_align;
                        end
                    
                    elseif startsWith(line, '2:') % <--- ÚJ: ALKAR ADAT
                        data = sscanf(line, '2: %f %f %f %f'); 
                        if length(data) == 4, R_raw_2 = quat2rotm(data'); end
                    end
                    
                    % =========================================================
                    % 1. KALIBRÁCIÓ (Hierarchikus T-Pose Mentése)
                    % Ekkor a kar teljesen kinyújtva, vízszintesen áll!
                    % =========================================================
                    if app.requestCalibration
                        app.R_calib_0 = R_raw_0; 
                        app.R_calib_1 = R_raw_1; 
                        app.R_calib_2 = R_raw_2; % <--- ÚJ: Alkar nullpont mentés
                        app.requestCalibration = false;
                        app.isCalibrated = true; 
                        disp('--- HIERARCHIKUS LÁNC KIEGYENESÍTVE (T-POSE) ---');
                    end
                    
                    % 2. ALIGNMENT: A rögzítési hibák "lehámozása"
                    R_arm_aligned = R_raw_0 * app.R_calib_0';
                    R_chest_aligned = R_raw_1 * app.R_calib_1';
                    R_forearm_aligned = R_raw_2 * app.R_calib_2'; % <--- ÚJ
                    
                    % =========================================================
                    % 3. HIERARCHIKUS KINEMATIKA (A SZABÁLY)
                    % Mindig a "Szülő" inverzével szorozzuk a "Gyermeket".
                    % =========================================================
                    
                    % Ízület 1: Váll (Felkar viszonyul a Mellkashoz)
                    R_shoulder_joint = R_chest_aligned' * R_arm_aligned;
                    R_shoulder_viz = processShoulderAngles(R_shoulder_joint, app.isCalibrated);
                    
                    % Ízület 2: Könyök (Alkar viszonyul a Felkarhoz - mellkas kihagyva)
                    R_elbow_joint = R_arm_aligned' * R_forearm_aligned; % <--- ÚJ MATEK
                    R_elbow_viz = processElbowAngles(R_elbow_joint, app.isCalibrated); % <--- ÚJ FÜGGVÉNY
                    
                    % =========================================================
                    % 4. RAJZOLÁS: FORWARD KINEMATICS (Az Egymásba fűzés)
                    % =========================================================
                    drawnow; % Frissítés kezdete
                    
                    % Lépés A: Felkar kirajzolása a vállhoz (Fix pont)
                    V_ua_final = (R_shoulder_viz * app.V_local_ua')' + app.arm_fix;
                    set(app.patch_ua, 'Vertices', V_ua_final);
                    
                    % Lépés B: Virtuális Könyökpont kiszámolása (Felkar vége)
                    % Alap geometriánk -X irányú, így ott a vége!
                    current_elbow_pos = (R_shoulder_viz * [-app.size_upper_arm(1); 0; 0])' + app.arm_fix;
                    
                    % Lépés C: Alkar globális forgása (Váll forgása + Könyök forgása)
                    R_forearm_global = R_shoulder_viz * R_elbow_viz;
                    
                    % Lépés D: Alkar kirajzolása a mozgó könyökponthoz!
                    V_fa_final = (R_forearm_global * app.V_local_fa')' + current_elbow_pos;
                    set(app.patch_fa, 'Vertices', V_fa_final);
                    
                catch
                    % Hiba elnyomása futás közben
                end
            else
                pause(0.002);
            end
        end
    end

    function Calibration(), app.requestCalibration = true; end
    
    function exitProgram()
        app.run = false; 
        if isfield(app, "serial") && ~isempty(app.serial), delete(app.serial); end
        delete(app.figure); 
    end
end

%% Segédfüggvények
function [V, F] = boxGeometry(sizeVec)
    L = sizeVec(1); W = sizeVec(2); H = sizeVec(3);
    V = [0, -W/2, -H/2; 0,  W/2, -H/2; 0,  W/2,  H/2; 0, -W/2,  H/2; ...
        -L, -W/2, -H/2; -L,  W/2, -H/2; -L,  W/2,  H/2; -L, -W/2,  H/2];
    F = [1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8; 1 2 3 4; 5 6 7 8];
end

%% 1. VÁLL ÍZÜLET FELDOLGOZÁSA (Felkar-Mellkas)
function R_out = processShoulderAngles(R_in, isCalibrated)
    eul_deg = rad2deg(rotm2eul(R_in, 'ZYX')); % [Z, Y, X]
    
    % Tengelycsere és irányítás (A tegnapi tiszta logikád)
    % Geometry axis is -X, hinge flexion is Yaw(Z), Twist is Roll(X)
    modell_Z_twist = -eul_deg(1); % Csavarás (Z)
    modell_Y_side = eul_deg(2);   % Oldalra emelés (Y)
    modell_X_hinge = eul_deg(3);  % Előre emelés (X) 
    
    % Clamp (Tegnapi megfordított határok, mivel T-pose-ban 0)
    if isCalibrated
        modell_Z_twist = max(min(modell_Z_twist, 95), -95);
        modell_Y_side = max(min(modell_Y_side, 55), -190); % Emelés negatív
        modell_X_hinge = max(min(modell_X_hinge, 65), -190); % Emelés negatív
    end
            
    R_out = eul2rotm(deg2rad([-modell_Z_twist, modell_Y_side, modell_X_hinge]), 'ZYX');
end

%% 2. ÚJ: KÖNYÖK ÍZÜLET FELDOLGOZÁSA (Alkar-Felkar)
%% 2. ÚJ: KÖNYÖK ÍZÜLET FELDOLGOZÁSA (Alkar-Felkar)
function R_out = processElbowAngles(R_in, isCalibrated)
    eul_deg = rad2deg(rotm2eul(R_in, 'ZYX')); % [Z, Y, X]
    
    % Mivel a szenzorok ugyanúgy állnak, a leképezés hasonló
    modell_Z_hinge = eul_deg(1); % <--- Vedd ki a mínuszt, és rögtön jó irányba hajlít!
    modell_Y_side = eul_deg(2);   % Oldalirányú hiba
    modell_X_twist = eul_deg(3);  % Alkar csavarása
    
    % =========================================================
    % CLAMP KIKAPCSOLVA: 
    % Egyelőre hagyjuk a nyers relatív mozgást érvényesülni!
    % =========================================================
            
    R_out = eul2rotm(deg2rad([-modell_Z_hinge, modell_Y_side, modell_X_twist]), 'ZYX');
end