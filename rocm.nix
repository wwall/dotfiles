self: super:
{
  # hcc-clang-unwrapped = super.callPackage ./nix/hcc/clang.nix {};
  # hcc-env = let hccself = {
  #   clang = super.wrapCCWith {
  #     cc = self.hcc-clang-unwrapped;
  #     bintools = super.binutils;
  #     libc = super.binutils.libc;
  #     extraBuildCommands = ''
  #       mkdir -p $out/include
  #       ln -s ${self.hcc-clang-unwrapped}/include $out/include/hcc
  #       ln -s $out/bin/clang++ $out/bin/hcc
  #     '';
  #   };
  #   stdenv = super.stdenvAdapters.overrideCC super.stdenv hccself.clang;
  # }; in hccself;
  # hcc-clang = self.hcc-env.clang;
  # hcc = self.callPackage ./nix/hcc/hcc.nix {};
  # hip = self.callPackage ./nix/hip {};

  hipblas-check = self.callPackage ./nix/hipblas { doCheck = true; };
  hipblas = self.callPackage ./nix/hipblas {};
  rocblas-check = self.callPackage ./nix/rocblas { doCheck = true; };
  rocblas = self.callPackage ./nix/rocblas {};

  rocrand-check = self.callPackage ./nix/rocrand { doCheck = true; };
  rocrand = self.callPackage ./nix/rocrand {};
  rocfft-check = self.callPackage ./nix/rocfft { doCheck = true; };
  rocfft = self.callPackage ./nix/rocfft {};

  # rocm-smi = self.callPackage ./nix/rocm-smi {};
  # rocm-bandwidth = self.callPackage ./nix/rocm-bandwidth {};
  # clang-ocl = self.callPackage ./nix/clang-ocl {};

  miopengemm = self.callPackage ./nix/miopengemm {};
  miopen = self.callPackage ./nix/miopen {};
  miopen-hip = self.callPackage ./nix/miopen { useHip = true; };

  rocprim = self.callPackage ./nix/rocprim {};
  rocm-thrust = self.callPackage ./nix/rocm-thrust {};
  google-gflags-dyn = super.google-gflags.overrideAttrs (old: {
    cmakeFlags = super.lib.filter (f: isNull (builtins.match ".*STATIC.*" f)) old.cmakeFlags;
  });

  rocprofiler = self.callPackage ./nix/rocprofiler {};

  rocm-caffe2 = self.callPackage ./nix/rocm-caffe2 {
    eigen3 = super.eigen3_3;
    inherit (super.python3Packages) python future six numpy pydot;
    protobuf = super.protobuf3_1;
    python-protobuf = super.python3Packages.protobuf3_1;
    # Used only for image loading.
    opencv3 = super.opencv3WithoutCuda;
    google-gflags = self.google-gflags-dyn;
  };
  rocm-caffe2-check = self.rocm-caffe2.override { doCheck = true; };
  rocm-caffe2-python = super.callPackage ./nix/rocm-caffe2/rocm-caffe2-python.nix {
    inherit (super.python3Packages) buildPythonPackage six numpy;
    python-protobuf = super.python3Packages.protobuf3_1;
  };

  cxlactivitylogger = super.callPackage ./nix/cxlactivitylogger {};
  hipcaffe = super.callPackage ./nix/hipcaffe {};
  rcp = super.callPackage ./nix/rcp {};
  # buildBazelPackage_0_4 = pkgs.buildBazelPackage.override { bazel = pkgs.bazel_0_4; };
  buildBazelPackage_0_4 = super.callPackage (~/src/nixpkgs/pkgs/build-support/build-bazel-package/default.nix) { bazel = super.bazel_0_4; };
  rocm-tensorflow-build = super.callPackage ./nix/rocm-tensorflow/rocm-tensorflow-build.nix {
    bazel = super.bazel_0_4;
    buildBazelPackage = self.buildBazelPackage_0_4;
      inherit (super.python3Packages) python pip six numpy buildPythonPackage pythonAtLeast;
    };
  rocm-tensorflow = super.callPackage ./nix/rocm-tensorflow {
    buildBazelPackage = self.buildBazelPackage_0_4;
    inherit (super.python3Packages) python pip six numpy buildPythonPackage pythonAtLeast;
  };
  lapack_3_8 = super.callPackage ./nix/liblapack/3.8.nix {};
  mxnet = super.callPackage ./nix/mxnet { lapack = self.lapack_3_8; };
}
