%%
% load input image
im = imread('../../images/junction_gray.png');
im = imresize(im, 1);
[ny, nx, nc] = size(im);
im = double(im) / 255;

% compute unary potentials
means = eye(3);
f = zeros(ny, nx, 3);
for i=1:3
    f(:, :, i) = sum((im - repmat(reshape(means(:, i), 1, 1, 3), ny, nx)).^2, 3);
end
f = f(:);

%%
% parameters
lmb = 1;
L = 3;
k = L*(L-1)/2; % number of pairwise terms

% gradient operator
grad = spmat_gradient2d(nx,ny,L);

% sum over the indicator functions
sum_op = kron(ones(1, L), speye(ny*nx));

% pairwise constraints
pair_local = sparse(2*k, 2*L);
idx = 1;
for i=1:L
    for j=(i+1):L
        pair_local(idx, i) = 1;
        pair_local(idx, j) = -1;
        pair_local(idx + k, i + L) = 1;
        pair_local(idx + k, j + L) = -1;
        idx = idx + 1;
    end
end
pair_op = kron(pair_local, speye(ny*nx))';

% primal variables
u = prost.variable(nx*ny*L);
v = prost.variable(2*nx*ny*k); % lagrange multiplier for pairwise constraints

% dual variables
q = prost.variable(2*nx*ny*L);
p = prost.variable(2*nx*ny*k); 
s = prost.variable(nx*ny);

prob = prost.min_max_problem( {u, v}, {q, p, s} );

% I(u >= 0) + <u, f>
prob.add_function(u, prost.function.sum_1d('ind_geq0', 1, 0, 1, f, 0));

% |p_i| <= lmb
prob.add_function(p, prost.function.sum_norm2(... 
    2, false, 'ind_leq0', 1 / lmb, 1, 1, 0, 0));

% <s, -1>
prob.add_function(s, prost.function.sum_1d('zero', 1, 0, 1, 1, 0));

% Implementation with sparse matrices.
% %<grad u, q>
% prob.add_dual_pair(u, q, prost.block.sparse(grad));

% % <sum_i u_i, s>
% prob.add_dual_pair(u, s, prost.block.sparse(sum_op));

% % <v_ij, p_ij>
% prob.add_dual_pair(v, p, prost.block.sparse(speye(2*ny*nx*k)));

% % <v_ij, -(q_i - q_j)>
% prob.add_dual_pair(v, q, prost.block.sparse(pair_op));

% Implementation with linear operators.
% <grad u, q>
prob.add_dual_pair(u, q, prost.block.gradient2d(nx,ny,L));

% <sum_i u_i, s>
prob.add_dual_pair(u, s, prost.block.sparse_kron_id(sparse(ones(1, L)), ny*nx));

% <v_ij, p_ij>
prob.add_dual_pair(v, p, prost.block.identity());

% <v_ij, -(q_i - q_j)>
prob.add_dual_pair(v, q, prost.block.sparse_kron_id(pair_local', ny*nx));



%%
% options and solve
backend = prost.backend.pdhg('stepsize', 'boyd', ...
                             'residual_iter', 10);

%backend = prost.backend.admm('rho0', 1);

opts = prost.options('max_iters', 20000, ...
                     'tol_rel_primal', 2e-6, ...
                     'tol_abs_primal', 2e-6, ...
                     'tol_rel_dual', 2e-6, ...
                     'tol_abs_dual', 2e-6, ...
                     'num_cback_calls', 25, ...
                     'interm_cb', @(it, x, y) ...
                     example_multilabel_callback(it, x, y, ny, nx, ...
                                                 L, im));

tic;
result = prost.solve(prob, backend, opts);
toc;

u = reshape(u.val, [ny nx L]);
imshow([im, u]);
