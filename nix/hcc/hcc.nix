{ stdenv, llvmPackages, fetchFromGitHub, cmake, pkgconfig, writeText, python,
  hcc-clang, hcc-clang-unwrapped, rocr, libunwind, file }:
stdenv.mkDerivation rec {
  name = "hcc";
  version = "1.7.0";
  tag = "roc-${version}";
  src = fetchFromGitHub {
    owner = "RadeonOpenCompute";
    repo = "hcc";
    rev = tag;
    sha256 = "14f3xfil15vs3dgaxzsha349khyyhihc15bhf2n0jcskljygs7ag";
    fetchSubmodules = true;
  };
  propagatedBuildInputs = [ file libunwind ];
  nativeBuildInputs = [ cmake pkgconfig python ];
  buildInputs = [ rocr ];
  cmakeFlags = [
    "-DROCM_ROOT=${rocr}"
    "-DROCM_DEVICE_LIB_DIR=${hcc-clang-unwrapped}/lib"
    "-DCLANG_BIN_DIR=${hcc-clang}"
    "-DROCDL_BUILD_DIR=${hcc-clang-unwrapped}/rocdl"
    "-DHCC_INTEGRATE_ROCDL=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
  ]
  ++ stdenv.lib.optional (stdenv.cc.libc != null) "-DC_INCLUDE_DIRS=${stdenv.cc.libc}/include"
  ;

  preConfigure = ''
    for f in $(find lib -name '*.in'); do
      sed 's_#!/bin/bash_#!${stdenv.shell}_' -i "$f"
    done
  '';

  # We split the build so that we can build a Nix wrapper for clang
  # which is then used for this latter phase of the build.
  patches = [ ./prebuilt-clang.patch ];

  postConfigure = ''
    mkdir -p compiler/bin
    ln -s ${hcc-clang-unwrapped}/bin/* compiler/bin/
    ln -sf ${hcc-clang}/bin/* compiler/bin/

    mkdir compiler/lib
    ln -s ${hcc-clang-unwrapped}/lib/* compiler/lib/

    export PATH="$(pwd)/compiler/bin:$PATH"
  '';
  hardeningDisable = ["all"];

  postFixup = ''
    ln -s ${hcc-clang-unwrapped}/bin/* $out/bin
    ln -sf ${hcc-clang}/bin/* $out/bin
    ln -s ${hcc-clang-unwrapped}/include $out/include/hcc
    cp -rs ${hcc-clang-unwrapped}/lib/* $out/lib
  '';

  # We get several warnings about unused include paths during
  # compilation. We quiet them here, though it would be better to not
  # be passing those flags to the hcc clang.
  setupHook = writeText "setupHook.sh" ''
    export NIX_CFLAGS_COMPILE+=" -Wno-unused-command-line-argument"
  '';
}
