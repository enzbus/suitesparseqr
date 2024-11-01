CCFLAGS = -fPIC
PYTHON_INCLUDE = $(shell pkg-config --cflags --libs python3)
NUMPY_INCLUDE = -I$(shell python -c "import numpy; print(numpy.get_include())")
SPQR_INCLUDE = $(shell pkg-config --cflags --libs SPQR)
CHOLMOD_INCLUDE = $(shell pkg-config --cflags --libs CHOLMOD)
# gh runner uses ancient debian package without pkg-config stubs
# FALLBACK = -I/usr/include/suitesparse/ -lcholmod -lspqr

# Valgrind: Numpy causes some "possibly lost" errors, check with:
# valgrind --leak-check=yes python -c "import numpy"
# so we suppress those errors;
VALGRIND_FLAGS = --leak-check=yes --errors-for-leak-kinds=definite --error-exitcode=1

default: test

_pyspqr.so: _pyspqr.c
	gcc _pyspqr.c -shared -o _pyspqr.so $(CCFLAGS) $(PYTHON_INCLUDE) $(NUMPY_INCLUDE) $(SPQR_INCLUDE) $(CHOLMOD_INCLUDE)

test: _pyspqr.so
	python -m pyspqr.test

valgrind: CCFLAGS += -g -O0
valgrind: clean _pyspqr.so
	valgrind $(VALGRIND_FLAGS) python -c "import _pyspqr"
	cp pyspqr/test.py .
	valgrind $(VALGRIND_FLAGS) python test.py
	rm test.py

build: env clean
	env/bin/python -m build .
	env/bin/python -m twine check dist/*.whl
	# sudo apt install patchelf
	env/bin/python -m auditwheel repair dist/*.whl --plat linux_x86_64 -w dist/
	env/bin/python -m abi3audit --strict --report dist/*.whl

env: clean
	python -m venv --system-site-packages env
	env/bin/pip install -e .[dev]
	env/bin/python -m pyspqr.test

clean:
	rm *.so || true
	rm -rf build || true
	rm -rf env || true
	rm -rf dist || true 
	rm -rf *.egg-info | true

release: build
	env/bin/python -m twine upload --skip-existing dist/*.tar.gz
