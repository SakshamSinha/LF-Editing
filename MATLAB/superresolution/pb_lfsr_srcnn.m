function SR_LF = pb_lfsr_srcnn(LR_LF,mf,lf_name)

% addpath('MATLAB/optical_flow/');
% %--------------------------------------------------------------------------
% % COMPUTE OPTICAL FLOW TO ALIGN THE LIGHT FIELD WITH CENTER VIEW
% %--------------------------------------------------------------------------
% if ~exist('FLOW/','dir')
%     mkdir('FLOW/');
% end
% 
% % Determine the filename where the flow vectors will be stored
% flow_filename = sprintf('FLOW/%s.mat',lf_name);
% 
% if ~exist(flow_filename,'file')
%     % Compute the optical flow
%     [u,v] = optical_flow(LR_LF);
%     % Save the optical flow vectors
%     save(flow_filename,'u','v');
% else
%     load(flow_filename,'u','v');
% end
% 
% % Use inverse warping to align all sub-aperture images to the centre view
% LR_LF_align = inverse_warping(LR_LF,u,v);
% 
% clearvars LR_LF;
% %--------------------------------------------------------------------------
% 
% %--------------------------------------------------------------------------
% % LIGHT FIELD DECOMPOSITION
% %--------------------------------------------------------------------------
% 
% % Permute the channels of the aligned light field
% LR_LF_align = permute(LR_LF_align,[1,2,4,5,3]);
% 
% 
% %--- Display the progress of the sift-flow computation
% msg = '  Matrix decomposition (R-Channel)...';
% fprintf('%s',msg);
% lengthLastMsg = length(msg);
% pause(0.005);
% 
% [B_r,C_r] = matrix_decomposition(LR_LF_align(:,:,:,:,1));
% 
% %--- Clear the last entry
% fprintf(repmat('\b', 1, lengthLastMsg));
% 
% %--- Display the progress of the sift-flow computation
% msg = '  Matrix decomposition (G-Channel)...';
% fprintf('%s',msg);
% lengthLastMsg = length(msg);
% pause(0.005);
% 
% [B_g,C_g] = matrix_decomposition(LR_LF_align(:,:,:,:,2));
% %--- Clear the last entry
% fprintf(repmat('\b', 1, lengthLastMsg));
% 
% %--- Display the progress of the sift-flow computation
% msg = '  Matrix decomposition (B-Channel)...';
% fprintf('%s',msg);
% lengthLastMsg = length(msg);
% pause(0.005);
% 
% [B_b,C_b] = matrix_decomposition(LR_LF_align(:,:,:,:,3));
% 
% %--- Clear the last entry
% fprintf(repmat('\b', 1, lengthLastMsg));
% 
% % Encode the principal basis to get the principal bases as an image
% [Ipb, param] = principal_basis_encoding(B_r(:,1), B_g(:,1), B_b(:,1),size(LR_LF_align));
% 
% %--------------------------------------------------------------------------
% 
% %--------------------------------------------------------------------------
% % SUPERRESOLUTION OF THE PRINCIPAL BASIS
% %--------------------------------------------------------------------------
% 
% addpath('MATLAB\matconvnet\');
% addpath('MATLAB\matconvnet\matlab\');
% addpath('MATLAB\superresolution\srcnn\');
% 
% %run matconvnet/matlab/vl_setupnn;
% run vl_setupnn
% 
% model_filename = sprintf('MATLAB\\superresolution\\srcnn\\mf_%d_model.mat',mf);
% load(model_filename);
% 
% % Test that the convolution function works properly
% try
%     vl_nnconv(single(1),single(1),[]) ;
% catch
%     warning('VL_NNCONV() does not seem to be compiled. Trying to compile it now.') ;
%     vl_compilenn('enableGpu', opts.useGpu, 'verbose', opts.verbose, ...
%         'enableImreadJpeg', false) ;
% end
% 
% % Super-resolve the current sub-aperture image
% Ipb_sr = srcnn(uint8(Ipb*255),net);
% 
% % Convert the image in range [0,1]
% Ipb_sr = double(Ipb_sr)/255;
% 
% %--------------------------------------------------------------------------
% 
% %--------------------------------------------------------------------------
% % LIGHT FIELD RECONSTRUCTION
% %--------------------------------------------------------------------------
% 
% % Decode the principal basis
% [B_r(:,1), B_g(:,1),B_b(:,1)] = principal_basis_decoding(Ipb_sr,param);
% 
% % Initialize the SR_LF_align matrix
% SR_LF_align = zeros(size(LR_LF_align));
% 
% % Reconstruct the super-ersolved aligned light field
% SR_LF_align(:,:,:,:,1) = reshape(reshape(B_r*C_r,[size(LR_LF_align,1), ...
%     size(LR_LF_align,2),size(LR_LF_align,3)*size(LR_LF_align,4)]), ...
%     [size(LR_LF_align,1),size(LR_LF_align,2),size(LR_LF_align,3), ...
%     size(LR_LF_align,4)]);
% SR_LF_align(:,:,:,:,2) = reshape(reshape(B_g*C_g,[size(LR_LF_align,1), ...
%     size(LR_LF_align,2),size(LR_LF_align,3)*size(LR_LF_align,4)]), ...
%     [size(LR_LF_align,1),size(LR_LF_align,2),size(LR_LF_align,3), ...
%     size(LR_LF_align,4)]);
% SR_LF_align(:,:,:,:,3) = reshape(reshape(B_b*C_b,[size(LR_LF_align,1), ...
%     size(LR_LF_align,2),size(LR_LF_align,3)*size(LR_LF_align,4)]), ...
%     [size(LR_LF_align,1),size(LR_LF_align,2),size(LR_LF_align,3), ...
%     size(LR_LF_align,4)]);
% 
% % % Permute the channels of the aligned light field
% SR_LF_align = uint8(permute(SR_LF_align,[1,2,5,3,4]));

%--------------------------------------------------------------------------

% %--------------------------------------------------------------------------
% % LIGHT FIELD RECONSTRUCTION
% %--------------------------------------------------------------------------
% % Restore the original disparities using forward warping
% SR_LF = forward_warping(SR_LF_align,u,v);

clc; close all; clear all;
load('temp.mat','SR_LF');

SR_LF = light_field_inpainting(SR_LF);

function X = light_field_inpainting(X_)

% Derive the mask that needs to be inpainted [1 indicates the crackes to be
% inpainted]
mask = reshape(X_(:,:,1,:,:),[size(X_,1),size(X_,2),size(X_,4),size(X_,5)]) == -1; 

% Reshape the mask
mask = reshape(mask,[size(mask,1),size(mask,2),size(mask,3)*size(mask,4)]);

% Reshape the input light field to be inpainted
X_ = reshape(X_,[size(X_,1),size(X_,2),size(X_,3),size(X_,4)*size(X_,5)]);

% Initialize the inpainted light field
X = zeros(size(X_)); X(X_~=-1) = X_(X_~=-1);

sz = [size(X,1) size(X,2)];

% Clear variables
clearvars X_;

% Initialize the fillRegion to be equivalent to the mask
fillRegion = mask;
sourceRegion = ~fillRegion;


% Initialize the isophote values
LF_x = zeros(size(X,1),size(X,2),size(X,4));
LF_y = zeros(size(X,1),size(X,2),size(X,4));

for i = 1:size(mask,3)
    % Compute the gradient of the i-th sub-aperture image
    [Ix(:,:,3),Iy(:,:,3)] = gradient(X(:,:,3,i));
    [Ix(:,:,2),Iy(:,:,2)] = gradient(X(:,:,2,i));
    [Ix(:,:,1),Iy(:,:,1)] = gradient(X(:,:,1,i));
    % Compute the mean across the color channels
    Ix = sum(Ix,3)/(3*255); Iy = sum(Iy,3)/(3*255);
    % Rotate the gradient by 90 degrees
    temp = Ix; Ix = -Iy; Iy = temp;
    % Put this gradient for the sub-aperture image
    LF_x(:,:,i) = Ix;
    LF_y(:,:,i) = Iy;
end

% Initialize confidence and data terms
C = double(sourceRegion);   % confidence term
D = repmat(-.1,sz);         % data term

% Loop until entire fill region has been covered
while any(fillRegion(:))
    % Find contour & normalized gradients of fill region
    fillRegionD = double(fillRegion); % Marcel 11/30/05
    for i = 1:size(fillRegionD,3)
        % Find the indices of this sub-aperture image that have crackes to be
        % inpainted
        dR = find(conv2(fillRegionD(:,:,i),[1,1,1;1,-8,1;1,1,1],'same')>0);
      
        % Compute the gradient to derive the normal to the fill region
        [Nx,Ny] = gradient(double(~fillRegion(:,:,i))); 
        % Derive the normal vectors for dR
        N = [Nx(dR(:)) Ny(dR(:))];
        % Normalize the normal vector
        N = normr(N);  
        % Ensure there are no nans
        N(~isfinite(N))=0; 
        
        % Compute confidences along the fill front of the i-th sub-aperture
        % image
        for k=dR'
            Hp = getpatch(sz,k,psz);
            q = Hp(~(fillRegion(Hp))); % fillRegion�?�中�?�パッ�?�?�部分�?��?��?�り出�?��?��?
            C(k) = sum(C(q))/numel(Hp);
        end

  end
end


% % Derive the index of the smallest number of missing pixels
% [~,idx] = sort(reshape(Nholes,[size(Nholes,1)*size(Nholes,2),1]),'ascend');
% 
% % Convert the index to 2D indices
% [c_idx,r_idx] = ind2sub(size(Nholes),idx);
% 
% for i = 1:size(r_idx,1)
%     if Nholes(r_idx(i),c_idx(i)) > 0 % This sub-aperture image must be restored
%         % Compute the distance between the current sub-aperture image and
%         % those which do not have holes
%         dist = sqrt((c_idx(1:i-1) - c_idx(i)).^2 + (r_idx(1:i-1) - r_idx(i)).^2);
%         
%         % Find the minimum distance
%         min_val = min(dist);
%         
%         % Find the indices of the minimum distances to be used as
%         % references
%         Jidx = find(dist == min_val);
%         
%         % Initialize the reference
%         Xref = zeros(size(X,1),size(X,2),size(X,3),size(Jidx,1));
%         
%         % Extract the reference views
%         for j = 1:size(Jidx,1)
%             % Derive the reference images
%             Xref(:,:,:,j) = X(:,:,:,r_idx(Jidx(j)),c_idx(Jidx(j)));
%         end
%         
%         % Extract the sub-aperture image being processed
%         I = X(:,:,:,r_idx(i),c_idx(i));
%         
%         % Extract the mask
%         mk = mask(:,:,r_idx(i),c_idx(i));
%         
%         % Restore the current sub-aperture image
%         I = inpainting(I, Xref,mk);
%         
%         % Put the restored sub-aperture image in the light field
%         X(:,:,:,r_idx(i),c_idx(i)) = I;
%     end
% end
% 
% function Y = inpainting(I, Xref, mask)
% 
% 
