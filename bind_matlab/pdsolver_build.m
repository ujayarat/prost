cuda_lib = '/work/sdks/cudacurrent/lib64';
cuda_inc = '/work/sdks/cudacurrent/include';

if ismac
    cuda_lib = '/usr/local/cuda/lib';
    cuda_inc = '/usr/local/cuda/include';
end

unix('make -C ../build/ -j16');

if ismac
    eval(sprintf(['mex -g -largeArrayDims -output pdsolver ' ...
                  'CXXFLAGS=''\\$CXXFLAGS -stdlib=libstdc++'' '...
                  'LDFLAGS=''\\$LDFLAGS -stdlib=libstdc++ -Wl,-rpath,%s'' '...
                  'pdsolver_mex.cpp factory_mex.cpp ../build/libpdsolver.a' ...
                  ' -L%s -I%s -lcudart -lcublas -lcusparse -I../include' ], ...
                 cuda_lib, cuda_lib, cuda_inc))

    eval(sprintf(['mex -g -largeArrayDims -output eval_prox ' ...
                  'CXXFLAGS=''\\$CXXFLAGS -stdlib=libstdc++'' '...
                  'LDFLAGS=''\\$LDFLAGS -stdlib=libstdc++ -Wl,-rpath,%s'' '...
                  'eval_prox_mex.cpp factory_mex.cpp ../build/libpdsolver.a' ...
                  ' -L%s -I%s -lcudart -lcublas -lcusparse -I../include' ], ...
                 cuda_lib, cuda_lib, cuda_inc))
else
    eval(sprintf(['mex -g -largeArrayDims -output pdsolver ' ...
                  'CXXFLAGS=''\\$CXXFLAGS'' '...
                  'LDFLAGS=''\\$LDFLAGS -Wl,-rpath,%s'' '...
                  'pdsolver_mex.cpp factory_mex.cpp ../build/libpdsolver.a' ...
                  ' -L%s -I%s -lcudart -lcublas -lcusparse -I../include' ], ...
                  cuda_lib, cuda_lib, cuda_inc))

    eval(sprintf(['mex -g -largeArrayDims -output eval_prox ' ...
                  'CXXFLAGS=''\\$CXXFLAGS'' '...
                  'LDFLAGS=''\\$LDFLAGS -Wl,-rpath,%s'' '...
                  'eval_prox_mex.cpp factory_mex.cpp ../build/' ...
                  'libpdsolver.a' ...
                  ' -L%s -I%s -lcudart -lcublas -lcusparse -I../include' ], ...
                 cuda_lib, cuda_lib, cuda_inc))
end
