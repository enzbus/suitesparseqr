"""Python bindings for SuiteSparseQR."""

import numpy as np
import scipy as sp
from _suitesparseqr import qr

def _make_csc_matrix(m,n, data, indices, indptr):
    if indptr[-1] != len(data):
        indptr = np.concatenate([indptr, [len(data)]], dtype=np.int32)
    return sp.sparse.csc_matrix((data, indices, indptr),shape=(m,n))

def spqr(matrix: sp.sparse.csc_matrix):
    """Factorize Scipy sparse CSC matrix."""
    matrix = sp.sparse.csc_matrix(matrix)
    HPinv, R, H = qr(
        matrix.shape[0], matrix.shape[1], matrix.data, matrix.indices,
        matrix.indptr)
    return HPinv, _make_csc_matrix(*H), _make_csc_matrix(*R)

if __name__ == '__main__':
    import matplotlib.pyplot as plt
    np.random.seed(0);

    import cvxpy as cp
    N = 100
    M = 200
    x = cp.Variable(N)
    obj = cp.Minimize(cp.norm1(x @ np.random.randn(N,M)) + cp.norm1(x))
    constr = [cp.abs(x) <= .5]
    matrix = cp.Problem(obj, constr).get_problem_data('SCS')[0]['A']
    plt.imshow(matrix.todense())
    plt.colorbar()
    plt.title('INPUT')
    # plt.show()

    # matrix = sp.sparse.rand(200,200, density=.01, format='csc', dtype=float)
    print("matrix")
    print(repr(matrix))
    HPinv, H, R = spqr(matrix)
    # print("HPinv")
    # print(HPinv)
    print("R")
    print(repr(R))
    print("H")
    print(repr(H))
    
    plt.figure()
    plt.imshow(R.todense())
    plt.title("R")
    plt.colorbar()
    #plt.show()

    
    plt.figure()
    plt.imshow(H.todense())
    plt.title("H")
    plt.colorbar()
    # plt.show()