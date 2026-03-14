% -------------------------------------------------------------------------
% PROGRAM: 3D Mozgáskövetés - TISZTA RELATÍV KINEMATIKA (Végleges Teszt)
% Módszertan kalibrációhoz: szenzor 0 leddel felfelé , szenzor 1 ( referencia szenzor)
% leddel felfelé tetejével kifelé 
% -------------------------------------------------------------------------
function Test_Vall_Vegleges()
    clearvars; close all; clc;
    app = struct(); 
    
    %% Főablak és GUI beállítása
    app.figure = uifigure('Name','Relatív Teszt - I-Pose & Irányfordítás','Position', [100 100 800 600]);
    app.figure.CloseRequestFcn = @(~,~) exitProgram(); 
    grids = uigridlayout(app.figure,[1 2]); 
    grids.ColumnWidth = {200,'1x'};         
    
    panel_control_grid = uigridlayout(grids,[6 1]);
    
    % Gombok és státusz
    button_connect = uibutton(panel_control_grid,'Text','Csatlakozás', 'ButtonPushedFcn', @(~,~) connectSerial());
    button_start = uibutton(panel_control_grid,'Text','Indítás','Enable','off', 'ButtonPushedFcn', @(~,~) startProgram());
    button_calibrate  = uibutton(panel_control_grid, 'Text', 'I-POSE KALIBRÁCIÓ', 'Enable', 'off', 'ButtonPushedFcn', @(~,~) Calibration(), 'FontWeight', 'bold', 'BackgroundColor', [0.85 0.33 0.1]);
    label_status = uilabel(panel_control_grid,'Text','Status: Disconnected');
    
    % 3D Tér beállítása
    model_ax = uiaxes(grids); 
    axis(model_ax,'equal'); grid(model_ax,'on'); hold(model_ax,'on');
    xlabel(model_ax,'X (Abdukció tengelye)'); 
    ylabel(model_ax,'Y (Flexió tengelye)'); 
    zlabel(model_ax,'Z (Függőleges / Csavarás)');
    view(model_ax, 3); 
    xlim(model_ax,[-100 100]); ylim(model_ax,[-100 100]); zlim(model_ax,[-100 100]);    
    
    %% 3D modell setup (A kar lefelé lóg)
    app.size_arm = [40 12 12];
    app.arm_fix = [0, 0, 30]; % Vállízület (forgáspont) a térben
    [app.V_local, app.Faces] = boxGeometry(app.size_arm);
    app.patch_arm = patch(model_ax, 'Vertices', app.V_local, 'Faces', app.Faces, 'FaceColor', 'red');
    
    % Ide mentjük a ferde rögzítések mátrixait (Alignment)
    app.R_calib_0 = eye(3); 
    app.R_calib_1 = eye(3); 
    app.requestCalibration = false;
    
    %% GUI Függvények
    function connectSerial()
        try
            % Cseréld ki a COM portot, ha nálad nem COM3!
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
        
        R_raw_0 = eye(3); % Kar szenzor
        R_raw_1 = eye(3); % Mellkas szenzor
        
        while app.run
            if ~isvalid(app.figure), break; end
            
            if app.serial.NumBytesAvailable > 0
                try
                    line = char(readline(app.serial));
                    
                    % Nyers adatok beolvasása
                    if startsWith(line, '0:')
                        data = sscanf(line, '0: %f %f %f %f'); 
                        if length(data) == 4, R_raw_0 = quat2rotm(data'); end
                    elseif startsWith(line, '1:')
                        data = sscanf(line, '1: %f %f %f %f'); 
                        if length(data) == 4, R_raw_1 = quat2rotm(data'); end
                    end
                    
                    % 1. KALIBRÁCIÓ (I-Pose Mentése)
                    if app.requestCalibration
                        app.R_calib_0 = R_raw_0; 
                        app.R_calib_1 = R_raw_1; 
                        app.requestCalibration = false;
                        disp('--- SZENZOROK VIRTUÁLISAN KIEGYENESÍTVE ---');
                    end
                    
                    % 2. ALIGNMENT: A rögzítési hiba "lehámozása" (Jobbról szorzás az inverzzel)
                    R_arm_aligned = R_raw_0 * app.R_calib_0';
                    R_chest_aligned = R_raw_1 * app.R_calib_1';
                    
                    % 3. RELATÍV KINEMATIKA: Mellkas vs Kar (Balról szorzás a mellkas inverzével)
                    R_joint = R_chest_aligned' * R_arm_aligned;
                    
                    % 4. IRÁNYOK MEGFORDÍTÁSA ÉS KIÍRÁS
                    R_vizualis = processJointAngles(R_joint);
                    
                    % 5. RAJZOLÁS a képernyőre
                    updatePose(app.patch_arm, app.V_local, R_vizualis, app.arm_fix);
                    drawnow limitrate;
                    
                catch
                    % Hiba elnyomása futás közben
                end
            else
                pause(0.002);
            end
        end
    end

    function Calibration()
        app.requestCalibration = true; 
    end
    function exitProgram()
        app.run = false; 
        if isfield(app, "serial") && ~isempty(app.serial), delete(app.serial); end
        delete(app.figure); 
    end
end

%% Segédfüggvények
function [V, F] = boxGeometry(sizeVec)
    L = sizeVec(1); W = sizeVec(2); H = sizeVec(3);
    % ÚJ GEOMETRIA: A forgáspont a [0,0,0], a doboz lefelé (-Z irányba) lóg!
    V = [-W/2, -H/2,  0;
          W/2, -H/2,  0;
          W/2,  H/2,  0;
         -W/2,  H/2,  0;
         -W/2, -H/2, -L;
          W/2, -H/2, -L;
          W/2,  H/2, -L;
         -W/2,  H/2, -L];
    F = [1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8; 1 2 3 4; 5 6 7 8];
end

function updatePose(patch_arm, V_local, R_arm, fix_pos)
    if ~isvalid(patch_arm), return; end
    % Mivel a doboz alapból a [0,0,0]-ból lóg lefelé, csak forgatjuk és eltoljuk a helyére
    V_final = (R_arm * V_local')' + fix_pos;
    set(patch_arm, 'Vertices', V_final);
end

function R_out = processJointAngles(R_in)
    % ZYX sorrend az Euler szögekhez
    eul_deg = rad2deg(rotm2eul(R_in, 'ZYX'));
    
    szog_Z = eul_deg(1); % Tengely körüli Csavarás (Pronáció/Szupináció)
    szog_Y = eul_deg(2); % Előre/Hátra emelés (Flexió/Extenzió)
    szog_X = eul_deg(3); % Oldalra emelés (Abdukció/Addukció)
    
    % =========================================================
    % VIZUÁLIS IRÁNYFORDÍTÁS
    % =========================================================
    szog_Y = -szog_Y;   % Marad mínusz (Flexió javítása)
    szog_X = -szog_X;   % Marad mínusz (Abdukció javítása)
    
    % --- JAVÍTÁS ITT: Kivettük a mínuszt, így megfordul a csavarás iránya! ---
    % szog_Z = -szog_Z; helyett most csak:
    szog_Z = szog_Z;    
    
    % Nyers, tisztított értékek kiírása a konzolra
    fprintf('Flexió: %5.1f° | Abdukció: %5.1f° | Csavarás: %5.1f°\n', szog_Y, szog_X, szog_Z);
    
    % Visszaalakítjuk forgatási mátrixba a 3D rajzoló motornak
    R_out = eul2rotm(deg2rad([szog_Z, szog_Y, szog_X]), 'ZYX');
end