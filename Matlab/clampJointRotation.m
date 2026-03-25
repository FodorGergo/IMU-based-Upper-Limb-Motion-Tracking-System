function [R_out, main_angle] = clapJointRotation(joint_name, R_in, isCalibrated, isLeftArm)
    % Euler szögek kinyerése [Z, Y, X]
    eul_deg = rad2deg(rotm2eul(R_in, 'ZYX')); 
    main_angle = 0; % Ide mentjük a kiírandó szöget
    
    switch joint_name
        case 'shoulder'
            modell_Z = -eul_deg(1); % Oldalra fordítás (jobb-bal)
            modell_Y = -eul_deg(2); % Emelés (fel-le)
            modell_X = -eul_deg(3); % Csavarás (be-ki) 
            
            if isLeftArm
                modell_Y = -modell_Y; modell_Z = -modell_Z; % Tükrözés
            end
            
            if isCalibrated
                modell_Z = max(min(modell_Z, 95), -95);
                modell_Y = max(min(modell_Y, 55), -190); 
                modell_X = max(min(modell_X, 190), -65); 
            end

            % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            main_angle = modell_X; % Váll szög 
            % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

            if isLeftArm
                R_out = eul2rotm(deg2rad([-(-modell_Z), -modell_Y, modell_X]), 'ZYX');
            else
                R_out = eul2rotm(deg2rad([-modell_Z, modell_Y, modell_X]), 'ZYX');
            end
            
        case 'elbow'
            modell_Z = -eul_deg(1); % Oldalra fordítás (jobb-bal)
            modell_Y = -eul_deg(2); % Emelés (fel-le)
            modell_X = -eul_deg(3); % Csavarás (be-ki) 
            
            
            if isLeftArm
                modell_Y = -modell_Y; modell_X = -modell_X; 
            end
            
            if isCalibrated
                modell_Z = max(min(modell_Z, 5), -150); % Könyök falak
                modell_Y = max(min(modell_Y, 5), -5);
                modell_X = max(min(modell_X, 95), -95);
            end

            % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            main_angle = abs(modell_Z); % Könyök szög
            % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

            if isLeftArm
                R_out = eul2rotm(deg2rad([-modell_Z, -modell_Y, -modell_X]), 'ZYX');
            else
                R_out = eul2rotm(deg2rad([-modell_Z, modell_Y, modell_X]), 'ZYX');
            end
            
        case 'wrist'
            modell_Z = -eul_deg(1); % Oldalra fordítás (jobb-bal)
            modell_Y = -eul_deg(2); % Emelés (fel-le)
            modell_X = -eul_deg(3); % Csavarás (be-ki) 
            
            if isLeftArm
                modell_Z = -modell_Z; % Tükrözése
            end
            
            if isCalibrated
                modell_Z = max(min(modell_Z, 45), -45);
                modell_Y = max(min(modell_Y, 90), -90);
                modell_X = max(min(modell_X, 5), -5);
            end

            % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            main_angle = modell_Y; % Csukló szög
            % !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
            
            if isLeftArm
                R_out = eul2rotm(deg2rad([-(-modell_Z), modell_Y, modell_X]), 'ZYX');
            else
                R_out = eul2rotm(deg2rad([-modell_Z, modell_Y, modell_X]), 'ZYX');
            end
    end
end