{ stdenv, fetchFromGitHub, pythonPackages, file, less
, imagePreviewSupport ? true, w3m ? null}:

with stdenv.lib;

assert imagePreviewSupport -> w3m != null;

pythonPackages.buildPythonApplication rec {
  name = "ranger-${version}";
  version = "1.9.0";

  src = fetchFromGitHub {
    owner = "ranger";
    repo = "ranger";
    rev = "v${version}";
    sha256= "0h3qz0sr21390xdshhlfisvscja33slv1plzcisg1wrdgwgyr5j6";
  };

  checkInputs = with pythonPackages; [ pytest ];
  propagatedBuildInputs = [ file ];

  checkPhase = ''
    py.test tests
  '';

  preConfigure = ''
    substituteInPlace ranger/data/scope.sh \
      --replace "/bin/echo" "echo"

    substituteInPlace ranger/__init__.py \
      --replace "DEFAULT_PAGER = 'less'" "DEFAULT_PAGER = '${stdenv.lib.getBin less}/bin/less'"

    for i in ranger/config/rc.conf doc/config/rc.conf ; do
      substituteInPlace $i --replace /usr/share $out/share
    done

    # give file previews out of the box
    substituteInPlace ranger/config/rc.conf \
      --replace "set preview_script ~/.config/ranger/scope.sh" "set preview_script $out/share/doc/ranger/config/scope.sh"
  '' + optionalString imagePreviewSupport ''
    substituteInPlace ranger/ext/img_display.py \
      --replace /usr/lib/w3m ${w3m}/libexec/w3m

    # give image previews out of the box when building with w3m
    substituteInPlace ranger/config/rc.conf \
      --replace "set preview_images false" "set preview_images true" \
  '';

  meta =  with stdenv.lib; {
    description = "File manager with minimalistic curses interface";
    homepage = http://ranger.github.io/;
    license = licenses.gpl3;
    platforms = platforms.unix;
    maintainers = [ maintainers.magnetophon ];
  };
}
