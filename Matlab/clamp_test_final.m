% -------------------------------------------------------------------------
% PROGRAM: 3D Mozgáskövetés - 4-SZENZOROS KINEMATIKAI LÁNC 
% -------------------------------------------------------------------------
function Test_Vall_Alkar_Kezfej()
    clearvars; close all; clc;
    app = struct(); 
    
    %% GUI beállítása
    app.figure = uifigure('Name','Kinematikai Lánc - Core','Position', [100 100 800 600]);
    app.figure.CloseRequestFcn = @(~,~) exitProgram(); 
    grids = uigridlayout(app.figure,[1 2]); 
    grids.ColumnWidth = {200,'1x'};         
    
    panel_control_grid = uigridlayout(grids,[6 1]);
    
    uibutton(panel_control_grid,'Text','Csatlakozás', 'ButtonPushedFcn', @(~,~) connectSerial());
    button_start = uibutton(panel_control_grid,'Text','Indítás','Enable','off', 'ButtonPushedFcn', @(~,~) startProgram());
    button_calibrate = uibutton(panel_control_grid, 'Text', 'T-POSE KALIBRÁCIÓ', 'Enable', 'off', 'ButtonPushedFcn', @(~,~) Calibration(), 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.33 0.1]);
    label_status = uilabel(panel_control_grid,'Text','Status: Disconnected');
    
    %% 3D Tér és Modellek beállítása
    model_ax = uiaxes(grids); 
    axis(model_ax,'equal'); grid(model_ax,'on'); hold(model_ax,'on');
    xlabel(model_ax,'X'); ylabel(model_ax,'Y'); zlabel(model_ax,'Z');
    view(model_ax, 3); 
    xlim(model_ax,[-100 100]); ylim(model_ax,[-100 100]); zlim(model_ax,[-100 100]);    
    
    app.arm_fix = [0, 0, 30]; 
    
    app.size_upper_arm = [40 12 12]; 
    [app.V_local_ua, app.Faces] = boxGeometry(app.size_upper_arm);
    app.patch_ua = patch(model_ax, 'Vertices', app.V_local_ua, 'Faces', app.Faces, 'FaceColor', 'red');
    
    app.size_forearm = [30 10 10]; 
    [app.V_local_fa, ~] = boxGeometry(app.size_forearm);
    app.patch_fa = patch(model_ax, 'Vertices', app.V_local_fa, 'Faces', app.Faces, 'FaceColor', 'green'); 
    
    app.size_hand = [15 10 4]; 
    [app.V_local_hand, ~] = boxGeometry(app.size_hand);
    app.patch_hand = patch(model_ax, 'Vertices', app.V_local_hand, 'Faces', app.Faces, 'FaceColor', 'blue'); 
    
    app.R_calib_0 = eye(3); app.R_calib_1 = eye(3); 
    app.R_calib_2 = eye(3); app.R_calib_3 = eye(3);
    app.requestCalibration = false;
    app.isCalibrated = false; 
    
    %% Fő programciklus és adatfeldolgozás
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
                    
                    % Szenzoradatok beolvasása
                    if startsWith(line, '0:')
                        data = sscanf(line, '0: %f %f %f %f'); 
                        if length(data) == 4, R_raw_0 = quat2rotm(data'); end
                    elseif startsWith(line, '1:')
                        data = sscanf(line, '1: %f %f %f %f'); 
                        if length(data) == 4
                            R_raw_1 = quat2rotm(data') * [1, 0, 0; 0, 0, 1; 0, -1, 0];
                        end
                    elseif startsWith(line, '2:') 
                        data = sscanf(line, '2: %f %f %f %f'); 
                        if length(data) == 4, R_raw_2 = quat2rotm(data'); end
                    elseif startsWith(line, '4:')
                        data = sscanf(line, '4: %f %f %f %f'); 
                        if length(data) == 4, R_raw_3 = quat2rotm(data'); end
                    end
                    
                    % Kalibráció rögzítése
                    if app.requestCalibration
                        app.R_calib_0 = R_raw_0; 
                        app.R_calib_1 = R_raw_1; 
                        app.R_calib_2 = R_raw_2; 
                        app.R_calib_3 = R_raw_3; 
                        app.requestCalibration = false;
                        app.isCalibrated = true; 
                        disp('--- Kalibráció rögzítve (T-Pose) ---');
                    end
                    
                    % Relatív kinematikai számítások
                    R_arm_aligned = R_raw_0 * app.R_calib_0';
                    R_chest_aligned = R_raw_1 * app.R_calib_1';
                    R_forearm_aligned = R_raw_2 * app.R_calib_2'; 
                    R_hand_aligned = R_raw_3 * app.R_calib_3'; 
                    
                    R_shoulder_joint = R_chest_aligned' * R_arm_aligned;
                    R_shoulder_viz = processShoulderAngles(R_shoulder_joint, app.isCalibrated);
                    
                    R_elbow_joint = R_arm_aligned' * R_forearm_aligned; 
                    R_elbow_viz = processElbowAngles(R_elbow_joint, app.isCalibrated); 
                    
                    R_wrist_joint = R_forearm_aligned' * R_hand_aligned; 
                    R_wrist_viz = processWristAngles(R_wrist_joint, app.isCalibrated);
                    
                    % 3D Rajzolás (Forward Kinematics)
                    drawnow; 
                    
                    % Felkar
                    V_ua_final = (R_shoulder_viz * app.V_local_ua')' + app.arm_fix;
                    set(app.patch_ua, 'Vertices', V_ua_final);
                    
                    % Alkar
                    current_elbow_pos = (R_shoulder_viz * [-app.size_upper_arm(1); 0; 0])' + app.arm_fix;
                    R_forearm_global = R_shoulder_viz * R_elbow_viz;
                    V_fa_final = (R_forearm_global * app.V_local_fa')' + current_elbow_pos;
                    set(app.patch_fa, 'Vertices', V_fa_final);
                    
                    % Kézfej
                    current_wrist_pos = (R_forearm_global * [-app.size_forearm(1); 0; 0])' + current_elbow_pos;
                    R_hand_global = R_forearm_global * R_wrist_viz; 
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

%% Segédfüggvények (Geometria és Kinematikai Clamp)
function [V, F] = boxGeometry(sizeVec)
    L = sizeVec(1); W = sizeVec(2); H = sizeVec(3);
    V = [0, -W/2, -H/2; 0,  W/2, -H/2; 0,  W/2,  H/2; 0, -W/2,  H/2; ...
        -L, -W/2, -H/2; -L,  W/2, -H/2; -L,  W/2,  H/2; -L, -W/2,  H/2];
    F = [1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8; 1 2 3 4; 5 6 7 8];
end

function R_out = processShoulderAngles(R_in, isCalibrated)
    eul_deg = rad2deg(rotm2eul(R_in, 'ZYX')); 
    modell_Z_side = -eul_deg(1); 
    modell_Y_hinge = -eul_deg(2);   
    modell_X_twist = -eul_deg(3);  
    
    if isCalibrated
        modell_Z_side = max(min(modell_Z_side, 95), -95);
        modell_Y_hinge = max(min(modell_Y_hinge, 55), -190); 
        modell_X_twist = max(min(modell_X_twist, 190), -65); 
    end
    R_out = eul2rotm(deg2rad([-modell_Z_side, modell_Y_hinge, modell_X_twist]), 'ZYX');
end

function R_out = processElbowAngles(R_in, isCalibrated)
    eul_deg = rad2deg(rotm2eul(R_in, 'ZYX')); 
    modell_Z_side = -eul_deg(1); 
    modell_Y_hinge = -eul_deg(2);   
    modell_X_twist = -eul_deg(3);  
    
    if isCalibrated
        modell_Z_side = max(min(modell_Z_side, 5), -150);
        modell_Y_hinge = max(min(modell_Y_hinge, 5), -5);
        modell_X_twist = max(min(modell_X_twist, 95), -95);
    end
    R_out = eul2rotm(deg2rad([-modell_Z_side, modell_Y_hinge, modell_X_twist]), 'ZYX');
end

function R_out = processWristAngles(R_in, isCalibrated)
    eul_deg = rad2deg(rotm2eul(R_in, 'ZYX')); 
    modell_Z_side = -eul_deg(1);  
    modell_Y_hinge = -eul_deg(2);   
    modell_X_twist = -eul_deg(3); 
    
    if isCalibrated
        modell_Z_side = max(min(modell_Z_side, 45), -45);
        modell_Y_hinge = max(min(modell_Y_hinge, 90), -90);
        modell_X_twist = max(min(modell_X_twist, 5), -5);
    end
    R_out = eul2rotm(deg2rad([-modell_Z_side, modell_Y_hinge, modell_X_twist]), 'ZYX');
end