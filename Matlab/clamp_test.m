% -------------------------------------------------------------------------
% PROGRAM: 3D Mozgáskövetés - IZOLÁCIÓS TESZT (Csak Váll)
% -------------------------------------------------------------------------
function Test_Vall()
    clearvars; close all; clc;
    app = struct(); % Központi adattároló struktúra
    
    %% Főablak (GUI)
    app.figure = uifigure('Name','Izolációs Teszt - Váll','Position', [0 50 1200 700]);
    app.figure.CloseRequestFcn = @(~,~) exitProgram(); 
    
    grids = uigridlayout(app.figure,[2 2]); 
    grids.ColumnWidth = {320,'1x'};         
    grids.RowHeight = {'1x', '1x'};         
    
    %% Panelek
    panel_control = uipanel(grids,'Title','Vezérlés','TitlePosition','centertop');
    panel_control.Layout.Row = 1; panel_control.Layout.Column = 1;
    
    panel_display = uipanel(grids,'Title','3D Tér');
    panel_display.Layout.Row = [1 2]; panel_display.Layout.Column = 2;
    
    panel_control_grid = uigridlayout(panel_control,[7 2]);
    panel_control_grid.RowHeight = {25, 25, 25, 25, 25, 25, 25};
    
    grid_display = uigridlayout(panel_display, [1 1]);
    model_ax = uiaxes(grid_display);
    axis(model_ax,'equal'); grid(model_ax,'on'); hold(model_ax,'on');
    xlabel(model_ax,'X (Csavarás)'); ylabel(model_ax,'Y (Abdukció)'); zlabel(model_ax,'Z (Flexió)');
    view(model_ax,3);                                                                   
    xlim(model_ax,[-100 100]); ylim(model_ax,[-100 100]); zlim(model_ax,[-100 100]);    
    
    %% GUI Elemek
    uilabel(panel_control_grid,'Text','COM Port:','HorizontalAlignment','right');
    port = uieditfield(panel_control_grid, 'numeric', 'Value', 3); 
    app.portName = "COM" + string(port.Value);
    
    uilabel(panel_control_grid,'Text','Baud:','HorizontalAlignment','right');
    baud = uidropdown(panel_control_grid,'Items',{'115200','230400'},'Value','115200');
    app.baudRate = str2double(baud.Value);
    
    button_connect = uibutton(panel_control_grid,'Text','Csatlakozás', 'ButtonPushedFcn', @(~,~) connectSerial());
    button_disconnect = uibutton(panel_control_grid,'Text','Lecsatlakozás','Enable','off', 'ButtonPushedFcn', @(~,~) disconnectSerial());
    button_start = uibutton(panel_control_grid,'Text','Indítás','Enable','off', 'ButtonPushedFcn', @(~,~) startProgram());
    button_stop = uibutton(panel_control_grid,'Text','Megállítás','Enable','off', 'ButtonPushedFcn', @(~,~) stopProgram());
    button_calibrate  = uibutton(panel_control_grid, 'Text', 'Kalibráció', 'Enable', 'off', 'FontWeight', 'bold', 'ButtonPushedFcn', @(~,~) Calibration());
    
    label_status = uilabel(panel_control_grid,'Text','Status: Disconnected');
    label_status.Layout.Column = [1 2];

    %% 3D modell (CSAK A VÁLL)
    app.size_upper_arm = [40 12 12];
    app.upper_arm_fix = [0, 0, 30];
    [app.V_local_upper_arm, app.Faces] = boxGeometry(app.size_upper_arm);
    
    app.patch_upper_arm = patch(model_ax, 'Vertices', app.V_local_upper_arm, 'Faces', app.Faces, 'FaceColor', 'red', 'FaceAlpha', 0.6);
    app.marker_upper_arm = plot3(model_ax, 0, 0, 0, 'ro','MarkerSize', 10, 'MarkerFaceColor', 'w');
    
    updateSingleArmPose(app.patch_upper_arm, app.marker_upper_arm, app.V_local_upper_arm, app.size_upper_arm, eye(3), app.upper_arm_fix);
    
    app.R_offset_upper_arm = eye(3);
    app.requestCalibration = false;
    
    %% Lokális függvények
    function connectSerial()
        app.portName = "COM" + string(port.Value);
        try
            app.serial = serialport(app.portName, str2double(baud.Value));
            configureTerminator(app.serial, "CR/LF");
            label_status.Text = "Csatlakozva: " + app.portName;
            button_start.Enable = 'on'; button_disconnect.Enable = 'on';
        catch err
            label_status.Text = "Hiba: " + err.message;
        end
    end

    function startProgram()
        app.run = true; 
        button_start.Enable = 'off'; button_stop.Enable = 'on'; button_calibrate.Enable = 'on';
        R_upper_arm = eye(3);
        
        while app.run
            if ~isvalid(app.figure), break; end
            
            if app.serial.NumBytesAvailable > 0
                try
                    line = char(readline(app.serial));
                    
                    % Csak a 0. szenzort (Váll) olvassuk!
                    if startsWith(line, '0:')
                        data = sscanf(line, '0: %f %f %f %f'); 
                        if length(data) == 4
                            R_upper_arm = quat2rotm(data');
                        end
                    end
                    
                    if app.requestCalibration
                        app.R_offset_upper_arm = R_upper_arm'; 
                        app.requestCalibration = false;
                        disp('--- SIKERES KALIBRÁCIÓ ---');
                    end
                    
                    R_upper_arm_final = app.R_offset_upper_arm * R_upper_arm;
                    
                    % KORLÁTOZÁS ÉS NYERS ADAT KIÍRÁSA
                    R_upper_arm_final = clampJointRotation(R_upper_arm_final, 'shoulder');
                    
                    updateSingleArmPose(app.patch_upper_arm, app.marker_upper_arm, app.V_local_upper_arm, app.size_upper_arm, R_upper_arm_final, app.upper_arm_fix);
                    drawnow limitrate;
                    
                catch errRead
                    % Csendes hibakezelés a teszthez
                end
            else
                pause(0.002);
            end
        end
    end

    function stopProgram()
        app.run = false;
        button_start.Enable = 'on'; button_stop.Enable = 'off';
    end

    function disconnectSerial()
        if ~isempty(app.serial), delete(app.serial); app.serial = []; end
        button_connect.Enable = "on"; button_disconnect.Enable = "off"; button_start.Enable = "off"; button_stop.Enable = "off";
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

%% --- SEGÉDFÜGGVÉNYEK ---

function [V, F] = boxGeometry(sizeVec)
    L = sizeVec(1); W = sizeVec(2); H = sizeVec(3);
    V = [0 -W/2 -H/2; L -W/2 -H/2; L W/2 -H/2; 0 W/2 -H/2;
         0 -W/2 H/2; L -W/2 H/2; L W/2 H/2; 0 W/2 H/2];
    F = [1 2 6 5; 2 3 7 6; 3 4 8 7; 4 1 5 8; 1 2 3 4; 5 6 7 8];
end

function updateSingleArmPose(patch_arm, marker_arm, V_local, size_arm, R_arm, fix_pos)
    if ~isvalid(patch_arm), return; end
    % Henger/Doboz eltolása a forgáspontba
    V_shifted = V_local + [size_arm(1)/2, 0, 0];
    V_rotated = (R_arm * V_shifted')';
    V_final = V_rotated + fix_pos;
    set(patch_arm, 'Vertices', V_final);
    
    % Felső marker frissítése
    top_local = [size_arm(1)/2; 0; size_arm(3)/2]; 
    top_final = fix_pos' + (R_arm * top_local);
    set(marker_arm, 'XData', top_final(1), 'YData', top_final(2), 'ZData', top_final(3));
end

function R_out = clampJointRotation(R_in, jointType)
    % ZYX Euler konverzió
    eul_deg = rad2deg(rotm2eul(R_in, 'ZYX'));
    szog_Z = eul_deg(1);  % Z-tengely (Függőleges)
    szog_Y = eul_deg(2);  % Y-tengely (Mélység)
    szog_X = eul_deg(3);  % X-tengely (Csavarás)
    
    if strcmp(jointType, 'shoulder')
        % --- ÉLŐ NYERS ADAT KIÍRÁSA A PARANCSABLAKBA ---
        fprintf('Váll nyers -> Z(Flexió): %5.1f° | Y(Abdukció): %5.1f° | X(Csavarás): %5.1f°\n', szog_Z, szog_Y, szog_X);
        
        % Szöghatárok beállítása
        Z_MAX = 150; Z_MIN = -50;  
        Y_MAX = 180; Y_MIN = -50;  
        X_MAX = 90;  X_MIN = -70;  
        
        % Lekorlátozás (Kommentezd ki valamelyiket, ha tesztelni akarod a határokat!)
        szog_Z = max(Z_MIN, min(Z_MAX, szog_Z));
        szog_Y = max(Y_MIN, min(Y_MAX, szog_Y));
        szog_X = max(X_MIN, min(X_MAX, szog_X));
    end
    
    clamped_eul_rad = deg2rad([szog_Z, szog_Y, szog_X]);
    R_out = eul2rotm(clamped_eul_rad, 'ZYX');
end