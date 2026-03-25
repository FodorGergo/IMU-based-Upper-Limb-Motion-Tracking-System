function updateArmPose( ...
        patch_upper_arm, patch_forearm, patch_hand, ...
        marker_elbow, marker_wrist, ...
        V_local_upper_arm, V_local_forearm, V_local_hand, ...
        size_upper_arm, size_forearm, size_hand, ...
        R_shoulder, R_elbow, R_wrist, ... 
        upper_arm_fix)

    if ~isvalid(patch_upper_arm) || ~isvalid(patch_forearm), 
        return; 
    end
    
    % Felkar
    V_shifted_upper_arm = V_local_upper_arm + [-size_upper_arm(1)/2, 0, 0];
    V_final_upper_arm = (R_shoulder * V_shifted_upper_arm')' + upper_arm_fix;
    set(patch_upper_arm, 'Vertices', V_final_upper_arm);
    
    % Könyök pozíció
    elbow_pos = (R_shoulder * [-size_upper_arm(1); 0; 0])' + upper_arm_fix;
    
    % Alkar
    V_shifted_forearm = V_local_forearm + [-size_forearm(1)/2, 0, 0];
    R_global_forearm = R_shoulder * R_elbow; % Örökli a váll forgását!
    V_final_forearm = (R_global_forearm * V_shifted_forearm')' + elbow_pos;
    set(patch_forearm, 'Vertices', V_final_forearm);
    
    % Csukló pozíció
    wrist_pos = (R_global_forearm * [-size_forearm(1); 0; 0])' + elbow_pos;

    % Kézfej
    V_shifted_hand = V_local_hand + [-size_hand(1)/2, 0, 0];
    R_global_hand = R_global_forearm * R_wrist; % Örökli az alkar és a váll forgását is!
    V_final_hand = (R_global_hand * V_shifted_hand')' + wrist_pos;
    set(patch_hand, 'Vertices', V_final_hand);
   
    % Markerek
    set(marker_elbow, 'XData', elbow_pos(1), 'YData', elbow_pos(2), 'ZData', elbow_pos(3));
    set(marker_wrist, 'XData', wrist_pos(1), 'YData', wrist_pos(2), 'ZData', wrist_pos(3));

    drawnow limitrate;
end
