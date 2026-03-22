% -------------------------------------------------------------------------
% PROGRAM: 3D Mozgáskövetés - 4-SZENZOROS KINEMATIKAI LÁNC (Kézfejjel)
% Protokoll: Kalibráció T-POSE-ban (Kinyújtott kar, tenyér lefelé/előre)
% -------------------------------------------------------------------------
function Test_Vall_Alkar_Kezfej()
    clearvars; close all; clc;
    app = struct(); 
    
    %% Főablak és GUI beállítása
    app.figure = uifigure('Name','Kinematikai Lánc Teszt - 4 Szenzor','Position', [100 100 800 600]);
    app.figure.CloseRequestFcn = @(~,~) exitProgram(); 
    grids = uigridlayout(app.figure,[1 2]); 
    grids.ColumnWidth = {200,'1x'};         
    
    panel_control_grid = uigridlayout(grids,[6 1]);
    
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
    app.arm_fix = [0, 0, 30]; % Vállízület
    
    % 1. FELKAR (Piros)
    app.size_upper_arm = [40 12 12]; 
    [app.V_local_ua, app.Faces] = boxGeometry(app.size_upper_arm);
    app.patch_ua = patch(model_ax, 'Vertices', app.V_local_ua, 'Faces', app.Faces, 'FaceColor', 'red');
    
    % 2. ALKAR (Zöld)
    app.size_forearm = [30 10 10]; 
    [app.V_local_fa, ~] = boxGeometry(app.size_forearm);
    app.patch_fa = patch(model_ax, 'Vertices', app.V_local_fa, 'Faces', app.Faces, 'FaceColor', 'green'); 
    
    % 3. ÚJ: KÉZFEJ (Kék, rövidebb és laposabb)
    app.size_hand = [15 10 4]; 
    [app.V_local_hand, ~] = boxGeometry(app.size_hand);
    app.patch_hand = patch(model_ax, 'Vertices', app.V_local_hand, 'Faces', app.Faces, 'FaceColor', 'blue'); 
    
    % Változók inicializálása (Már 4 db!)
    app.R_calib_0 = eye(3); app.R_calib_1 = eye(3); 
    app.R_calib_2 = eye(3); app.R_calib_3 = eye(3);
    app.requestCalibration = false;
    app.isCalibrated = false; 
    
    %% GUI Függvények
    function connectSerial()
        try
            app.serial = serialport("COM3", 115200); 
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
        flush(app.serial); 
        
        R_raw_0 = eye(3); R_raw_1 = eye(3); R_raw_2 = eye(3); R_raw_3 = eye(3);
        
       while app.run
            if ~isvalid(app.figure), break; end
            
            if app.serial.NumBytesAvailable > 0
                try
                    line = char(readline(app.serial));
                    
                    % 4-SZENZOROS ADATBEOLVASÁS
                    if startsWith(line, '0:')
                        data = sscanf(line, '0: %f %f %f %f'); 
                        if length(data) == 4, R_raw_0 = quat2rotm(data'); end
                        
                    elseif startsWith(line, '1:')
                        data = sscanf(line, '1: %f %f %f %f'); 
                        if length(data) == 4
                            R_raw_1 = quat2rotm(data'); 
                            T_align = [1, 0, 0; 0, 0, 1; 0, -1, 0];
                            R_raw_1 = R_raw_1 * T_align;
                        end
                    
                    elseif startsWith(line, '2:') 
                        data = sscanf(line, '2: %f %f %f %f'); 
                        if length(data) == 4, R_raw_2 = quat2rotm(data'); end
                        
                    elseif startsWith(line, '4:')
                        data = sscanf(line, '4: %f %f %f %f'); 
                        if length(data) == 4, R_raw_3 = quat2rotm(data'); end
                    end
                    
                    % 1. KALIBRÁCIÓ (4 szenzor nullázása)
                    if app.requestCalibration
                        app.R_calib_0 = R_raw_0; 
                        app.R_calib_1 = R_raw_1; 
                        app.R_calib_2 = R_raw_2; 
                        app.R_calib_3 = R_raw_3; % ÚJ
                        app.requestCalibration = false;
                        app.isCalibrated = true; 
                        disp('--- 4-SZENZOROS LÁNC KIEGYENESÍTVE ---');
                    end
                    
                    % 2. ALIGNMENT: Rögzítési hibák "lehámozása"
                    R_arm_aligned = R_raw_0 * app.R_calib_0';
                    R_chest_aligned = R_raw_1 * app.R_calib_1';
                    R_forearm_aligned = R_raw_2 * app.R_calib_2'; 
                    R_hand_aligned = R_raw_3 * app.R_calib_3'; % ÚJ
                    
                    % 3. HIERARCHIKUS KINEMATIKA
                    
                    % Ízület 1: Váll (Felkar viszonyul a Mellkashoz)
                    R_shoulder_joint = R_chest_aligned' * R_arm_aligned;
                    R_shoulder_viz = processShoulderAngles(R_shoulder_joint, app.isCalibrated);
                    
                    % Ízület 2: Könyök (Alkar viszonyul a Felkarhoz)
                    R_elbow_joint = R_arm_aligned' * R_forearm_aligned; 
                    R_elbow_viz = processElbowAngles(R_elbow_joint, app.isCalibrated); 
                    
                    % ÚJ Ízület 3: Csukló (Kézfej viszonyul az Alkarhoz)
                    R_wrist_joint = R_forearm_aligned' * R_hand_aligned; 
                    R_wrist_viz = processWristAngles(R_wrist_joint, app.isCalibrated);
                    
                    % 4. RAJZOLÁS: FORWARD KINEMATICS
                    drawnow; 
                    
                    % A: Felkar (Fix vállponthoz)
                    V_ua_final = (R_shoulder_viz * app.V_local_ua')' + app.arm_fix;
                    set(app.patch_ua, 'Vertices', V_ua_final);
                    
                    % B: Virtuális Könyökpont kiszámolása
                    current_elbow_pos = (R_shoulder_viz * [-app.size_upper_arm(1); 0; 0])' + app.arm_fix;
                    
                    % C: Alkar (Csatlakozik a könyökhöz)
                    R_forearm_global = R_shoulder_viz * R_elbow_viz;
                    V_fa_final = (R_forearm_global * app.V_local_fa')' + current_elbow_pos;
                    set(app.patch_fa, 'Vertices', V_fa_final);
                    
                    % ÚJ D: Virtuális Csuklópont kiszámolása (Alkar vége)
                    current_wrist_pos = (R_forearm_global * [-app.size_forearm(1); 0; 0])' + current_elbow_pos;
                    
                    % ÚJ E: Kézfej (Csatlakozik a csuklóhoz)
                    R_hand_global = R_forearm_global * R_wrist_viz; % Örökli az alkar és a felkar forgását is!
                    V_hand_final = (R_hand_global * app.V_local_hand')' + current_wrist_pos;
                    set(app.patch_hand, 'Vertices', V_hand_final);
                    
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

%% 1. VÁLL
function R_out = processShoulderAngles(R_in, isCalibrated)
    eul_deg = rad2deg(rotm2eul(R_in, 'ZYX')); 
    modell_Z_twist = -eul_deg(1); 
    modell_Y_side = -eul_deg(2);   
    modell_X_hinge = -eul_deg(3);  
    if isCalibrated
        modell_Z_twist = max(min(modell_Z_twist, 95), -95);
        modell_Y_side = max(min(modell_Y_side, 55), -190); 
        modell_X_hinge = max(min(modell_X_hinge, 190), -65); 
    end
    R_out = eul2rotm(deg2rad([-modell_Z_twist, modell_Y_side, modell_X_hinge]), 'ZYX');
end

%% 2. KÖNYÖK
function R_out = processElbowAngles(R_in, isCalibrated)
    eul_deg = rad2deg(rotm2eul(R_in, 'ZYX')); 
    modell_Z_hinge = -eul_deg(1); 
    modell_Y_side = -eul_deg(2);   
    modell_X_twist = -eul_deg(3);  
    if isCalibrated
        modell_Z_hinge = max(min(modell_Z_hinge, 5), -150);
        modell_Y_side = max(min(modell_Y_side, 5), -5);
        modell_X_twist = max(min(modell_X_twist, 95), -95);
    end
    R_out = eul2rotm(deg2rad([-modell_Z_hinge, modell_Y_side, modell_X_twist]), 'ZYX');
end

%% 3. ÚJ: CSUKLÓ (Kézfej-Alkar)
function R_out = processWristAngles(R_in, isCalibrated)
    eul_deg = rad2deg(rotm2eul(R_in, 'ZYX')); 
    
    % Egyelőre nyers beolvasás, előjel cserék és Clamp nélkül!
    modell_Z_flex = -eul_deg(1);  % Csukló hajlítása (Flexió/Extenzió)
    modell_Y_dev = -eul_deg(2);   % Csukló oldalra (Ulnáris/Radiális deviáció)
    modell_X_twist = -eul_deg(3); % Bár a csukló nem tud csavarodni (az alkar csavarodik), a szenzor zajt mérhet
    
    % =========================================================
    % CLAMP KIKAPCSOLVA: Nyers teszteléshez
    % =========================================================
    
    R_out = eul2rotm(deg2rad([-modell_Z_flex, modell_Y_dev, modell_X_twist]), 'ZYX');
end