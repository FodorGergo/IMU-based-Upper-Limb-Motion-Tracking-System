function R_out = clampJointRotation(joint_name, R_in, isCalibrated, isLeftArm)
    % Euler szögek kinyerése [Z, Y, X]
    eul_deg = rad2deg(rotm2eul(R_in, 'ZYX')); 

    modell_Z = -eul_deg(1); % Oldalra fordítás (jobb-bal)
    modell_Y = -eul_deg(2); % Emelés (fel-le)
    modell_X = -eul_deg(3); % Csavarás (be-ki) 

    % Tükrözés balkézre 
    if isLeftArm
        modell_Z = -modell_Z;
        modell_Y = -modell_Y;
        modell_X = -modell_X;
    end

    switch joint_name
        case 'shoulder'
            if isCalibrated
                modell_Z = max(min(modell_Z, 45), -110); % magam elé 110°, mögém 45°
                modell_Y = max(min(modell_Y, 90), -90);  % Felfelé 90°, lefelé 90°
                modell_X = max(min(modell_X, 95), -95);  % Csavarás mindkét irányba 90°
            end
        case 'elbow'
            if isCalibrated
                modell_Z = max(min(modell_Z, 5), -150); 
                modell_Y = max(min(modell_Y, 5), -5);
                modell_X = max(min(modell_X, 95), -95);
            end
        case 'wrist'
            if isCalibrated
                modell_Z = max(min(modell_Z, 45), -45);
                modell_Y = max(min(modell_Y, 90), -90);
                modell_X = max(min(modell_X, 5), -5);
            end
    end
    
    if isLeftArm
        modell_Z = -modell_Z;
    end
    
    R_out = eul2rotm(deg2rad([-modell_Z, -modell_Y, -modell_X]), 'ZYX');
end

