function pool_out = f_remove_from_pool(pool, x, tol)
    if nargin < 3, tol = 1e-4; end
    diff = abs(pool - x);
    is_match = all(diff < tol, 2);
    pool_out = pool(~is_match, :);
end
