scaffolding_load() {
  _set_lang
  _detect_python
  _add_vendored_deps
}


_add_vendored_deps() {
  for package in ${scaffolding_vendored_python_modules[*]}
  do
    local package_name="$(echo $package | cut -d/ -f2)"
    for module in $(grep $package_name $PLAN_CONTEXT/../requirements.txt | grep -v '^#' | cut -d' ' -f1 | sed 's@==@/@')
    do
      build_line "Checking if there is a $pkg_origin/$module that will satisfy 'requirements.txt'"
      if [ $(hab pkg install $pkg_origin/$module --channel="$(date +%s)" 2>&1 | grep -c "The following releases were found") -eq 1 ]
      then
        build_line "Adding vendored version of $pkg_origin/$module to package dependencies"
        pkg_deps+=($(echo $pkg_origin/$module))
      # This second conditional is needed in case we have a locally-installed copy
      # of the vendored module already:
      elif hab pkg path $pkg_origin/$module &> "/dev/null"
      then
        build_line "Adding vendored version of $pkg_origin/$module to package dependencies"
        pkg_deps+=($(echo $pkg_origin/$module))
      fi
    done
  done
}


_record_pkg_metadata() {
  echo "export pkg_origin=$pkg_origin
export pkg_name=$pkg_name
export pkg_version=$pkg_version
export pkg_release=$pkg_release" > "/src/.pkg.vars"
  return $?
}


_promote_pkg() {
  local builder_channel=$1
  source "/src/.pkg.vars"
  hab origin key download "$pkg_origin" --secret
  hab origin key download "$pkg_origin"
  hab pkg upload "/src/results/$pkg_origin-$pkg_name-$pkg_version-$pkg_release-x86_64-linux.hart"
  hab pkg promote "$pkg_origin/$pkg_name/$pkg_version/$pkg_release" "$builder_channel"
  return $?
}


_get_pkg_deps() {
  for element in ${pkg_deps[*]}
  do
    echo $element
  done
  return $?
}


_detect_python() {
  if [[ -n "$scaffolding_python_pkg" ]]
  then
    _python_pkg="$scaffolding_python_pkg"
    build_line "Detected Python version in Plan, using '$_python_pkg'"
  fi
  pkg_deps+=($(echo $_python_pkg))
  return $?
}


_set_lang() {
  if [[ -n "$scaffolding_pkg_lang" ]]
  then
    _pkg_lang="$scaffolding_pkg_lang"
    build_line "Detected locale LANG variable in Plan, using '$_pkg_lang'"
  else
    _pkg_lang="en_US.utf8"
    build_line "No detected locale LANG variable in Plan, defaulting to 'en_US.utf8'"
  fi
  return $?
}


do_setup_environment() {
  python_package="$(_get_pkg_deps | grep /python)"
  python_major_version="$(hab pkg path $python_package | cut -d'/' -f6 | cut -d'.' -f1,2)"

  push_runtime_env   "PYTHONPATH"    "${pkg_prefix}/lib/python${python_major_version}/site-packages"
  set_runtime_env -f "FLASK_APP"     "$pkg_prefix/app.py"
  set_runtime_env -f "LANG"          "$_pkg_lang"
  set_runtime_env -f "SSL_CERT_FILE" "$(pkg_path_for core/cacerts)/ssl/cert.pem"
  return $?
}


do_prepare() {
  _record_pkg_metadata
  pip install \
    --cache-dir="/src/.pip_cache" \
    --progress-bar="off" \
    --upgrade "pip" "virtualenv"
  virtualenv "$pkg_prefix"
  source "$pkg_prefix/bin/activate"
  return $?
}


do_build() {
  build_line "Installing Pip module dependencies to $pkg_prefix/lib/python${python_major_version}/site-packages"
  pip install \
    --cache-dir="/src/.pip_cache" \
    --progress-bar="off" \
    --requirement="$PLAN_CONTEXT/../requirements.txt" --progress-bar="off"
  return $?
}


do_install() {
  build_line "Installing Flask app to $pkg_prefix..."
  cp --verbose --preserve --recursive \
    "$PLAN_CONTEXT/../" "$pkg_prefix/"
  mkdir --parents "$pkg_prefix/hooks/"  # TODO: find a cleaner way to inherit templates
  cp --interactive --verbose --preserve --recursive \
    $(hab pkg path "smartb/scaffolding-flask")/hooks/* "$pkg_prefix/hooks/"
  return $?
}


do_strip() {
  return 0
}


do_after() {
  if [ ! -z $HAB_CREATE_ARTIFACT ] && [ $HAB_CREATE_ARTIFACT == 'false' ]
  then
    build_line "INFO: Skipping artifact creation because 'HAB_CREATE_ARTIFACT=false'"
    _generate_artifact() {
      return 0
    }
    _prepare_build_outputs() {
      return 0
    }
  else
    build_line "INFO: Creating package artifact. This stage can optionally be"
    build_line "skipped by setting 'HAB_CREATE_PACKAGE=false' in order to speed"
    build_line "up local Studio development."
  fi
  return $?
}
