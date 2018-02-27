{ stdenv, fetchFromGitHub, writeTextFile, python, git, llvmPackages }:
stdenv.mkDerivation rec {
  name = "cquery-${version}";
  version = "2018-02-22";

  src = fetchFromGitHub {
    owner = "jacobdufault";
    repo = "cquery";
    rev = "935dc7561bc745d6062bb27877e3650171527f7c";
    sha256 = "0r3pvpnm6rckwdrki23sjxfyq947ankdkwlwkiqk3pldkghmnzbn";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ python git ];
  buildInputs = [ llvmPackages.clang llvmPackages.clang-unwrapped llvmPackages.libclang ];

  # The header files we want cquery to find are under the
  # /nix/store/xxx-clang-version/lib/clang/version/include directory, while
  # the libclang it needs is in /nix/store/xxx-clang/lib so we can not
  # give it a single --clang-prefix that locates everything it needs.
  preConfigure = ''
    sed -e 's|^\([[:space:]]*\)\(prefix = ctx.root.find_node(ctx.options.clang_prefix)\)|\1\2\
\1prefixInc = ctx.root.find_node("${llvmPackages.clang-unwrapped}/lib/clang/${stdenv.lib.getVersion llvmPackages.clang.name}")\
\1prefixLib = ctx.root.find_node("${llvmPackages.libclang}")|' \
        -e 's|\(includes = \[ n.abspath() for n in \[ prefix\)|\1Inc|' \
        -e 's|\(libpath  = \[ n.abspath() for n in \[ prefix\)|\1Lib|' \
        -i wscript
      '';

  configurePhase = ''
    eval "$preConfigure"
    ./waf configure --prefix=$out --clang-prefix=${llvmPackages.clang-unwrapped}
  '';

  buildPhase = ''
    ./waf build
  '';

  installPhase = ''
    ./waf install
  '';

  # This helper is provided to help pass include directories nix
  # communicates in the environment to cquery through a
  # compile_commands.json. Such a file will record a compiler
  # invocation that might work to build a program, but this may rely
  # on the compiler being a nix-built wrapper that adds include paths
  # gleaned from the environment. Tooling like cquery needs to know
  # what the compiler knows, so we dig through the environment and
  # augment the compiler command to explicitly include the headers
  # from the nix environment variable. We also pick out the Libsystem
  # include directory needed on darwin.
  setupHook = writeTextFile {
    name = "setup-hook.sh";
    text = ''
    nix-cflags-include() {
      echo $NIX_CFLAGS_COMPILE | awk '{ for(i = 1; i <= NF; i++) if($i == "-isystem") printf "-isystem %s ", $(i+1); else if($i ~ /^-F/) printf "%s ", $i; }' | sed 's|-isystem \([^[:space:]]*libc++[^[:space:]]*\)|-isystem \1 -isystem \1/c++/v1|'; printf "%s " "-isystem ${llvmPackages.clang-unwrapped}/lib/clang/${stdenv.lib.getVersion llvmPackages.clang.name}/include"; cat $(dirname $(which clang++))/../nix-support/libc-cflags | awk '{ for(i = 1; i <= NF; i++) if($i == "-idirafter" && $(i+1) ~ /Libsystem/) printf "-isystem %s", $(i+1) }'
    }
    nix-cquery() {
      if [ -f compile_commands.json ]; then
        echo "Adding Nix include directories to the compiler commands"
        local extraincs=$(nix-cflags-include)
        sed "s|/bin/clang++ |/bin/clang++ ''${extraincs} |" -i compile_commands.json
      else
        echo "There is no compile_commands.json file to edit!"
        echo "Create one with cmake using:"
        echo "(cd build && cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 .. && mv compile_commands.json ..)"
        read -n 1 -p "Do you want to create a .cquery file instead? [Y/n]: " genCquery
        genCquery=''${genCquery:-y}
        case "$genCquery" in
          y|Y ) nix-cflags-include | tr ' ' '\n' > .cquery && echo $'\nGenerated a new .cquery file' ;;
          * ) echo $'\nNot doing anything!' ;;
        esac
      fi
    }
  '';};
  meta = {
    description = "Low-latency language server for C++, powered by libclang";
    homepage = https://github.com/jacobdufault/cquery;
    license = stdenv.lib.licenses.mit;
    platforms = stdenv.lib.platforms.all;
  };
}
