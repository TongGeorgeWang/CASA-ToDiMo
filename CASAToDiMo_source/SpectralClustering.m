function [C, L, U, value] = SpectralClustering(W, k, Type, num)

warning('off','all') 

%SPECTRALCLUSTERING Executes spectral clustering algorithm
%   Executes the spectral clustering algorithm defined by
%   Type on the adjacency matrix W and returns the k cluster
%   indicator vectors as columns in C.
%   If L and U are also called, the (normalized) Laplacian and
%   eigenvectors will also be returned.
%
%   'W' - Adjacency matrix, needs to be square
%   'k' - Number of clusters to look for
%   'Type' - Defines the type of spectral clustering algorithm
%            that should be used. Choices are:
%      1 - Unnormalized
%      2 - Normalized according to Shi and Malik (2000)
%      3 - Normalized according to Jordan and Weiss (2002)
%
%   GW - added automatic determination of # of K-means clusters based on
%   silhouette maximization 
%

if nargin < 4
    num = 0;
end

degs = sum(W, 2);
D    = sparse(1:size(W, 1), 1:size(W, 2), degs);
% compute unnormalized Laplacian
L = D - W;
% compute normalized Laplacian if needed
switch Type
    case 2
        % avoid dividing by zero
        degs(degs == 0) = eps;
        % calculate inverse of D
        D = spdiags(1./degs, 0, size(D, 1), size(D, 2));
        
        % calculate normalized Laplacian
        L = D * L;
    case 3
        % avoid dividing by zero
        degs(degs == 0) = eps;
        % calculate D^(-1/2)
        D = spdiags(1./(degs.^0.5), 0, size(D, 1), size(D, 2));
        
        % calculate normalized Laplacian
        L = D * L * D;
end

%% Compute the eigenvectors corresponding to the k smallest eigenvalues

%warning('off','last');
diff   = eps;

if k ~= 0        
    [U, value] = eigs(L, k + num, diff);
    value = diag(value);
    %[U, ~] = eigs(L, k, 'smallestreal');

    % in case of the Jordan-Weiss algorithm, we need to normalize the eigenvectors row-wise
    if Type == 3
        U = bsxfun(@rdivide, U, sqrt(sum(U.^2, 2)));
    end

    % now use the k-means algorithm to cluster U row-wise
    % C will be a n-by-1 matrix containing the cluster number for each data point, minus 1 for the consistant with the true label
    C = kmeans(U, k, 'start', 'cluster') - 1;
    %C = sparse(1:size(D, 1), C, 1); % now convert C to a n-by-k matrix containing the k indicator vectors as columns

elseif k == 0 % Determine optimal number of clusters by maximizing the average silhouette
    
    kRange = 2:1:20; % nClusters search range

    for N = 1:10 % Do a few trials, as Kmeans result can vary between runs
        for k = kRange
            
            % Compute U as normal 
            [U, value] = eigs(L, k + num, diff);
            if Type == 3
                U = bsxfun(@rdivide, U, sqrt(sum(U.^2, 2)));
            end

            C_vary{N,k-1} = kmeans(U, k, 'start', 'cluster') - 1;

            % Compute silhouette metric, which we aim to maximize 
            s{N,k-1} = silhouette(U,C_vary{N,k-1});
            s_avg(N,k-1) = mean(s{N,k-1});

        end
    end
    
    % Index the trial where average silhouette value is maximized and keep the
    % clustering result corresponding to that trial 
    [maxSavg,whereMaxSavg] = max(s_avg(:)); 
    [whereMax_row, whereMax_col] = ind2sub(size(s_avg),whereMaxSavg);
    C = C_vary{whereMax_row,whereMax_col};

end


end
