pkg_build_deps=(
  "core/gcc"
)
pkg_deps=(
  "core/bash"
  "core/cacerts"
  "core/curl/7.63.0"
  "core/python36"
)


do_begin() {
  for module in $(cat $PLAN_CONTEXT/../flask/requirements.txt | sed 's@==@/@')
  do
    module_basename=$(echo $pkg_origin/$module | cut -d/ -f1,2)
    if hab pkg search $module_basename | grep $module_basename/ &> "/dev/null"
    then
      build_line "Adding vendored version of $pkg_origin/$module to package dependencies"
      pkg_deps+=($(echo smartb/$module))
    fi
  done
}


_get_pkg_deps() {
  for element in ${pkg_deps[*]}
  do
    echo $element
  done
  return $?
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


do_setup_environment() {
  python_package="$(_get_pkg_deps | grep /python)"
  python_major_version="$(hab pkg path $python_package | cut -d'/' -f6 | cut -d'.' -f1,2)"

  push_runtime_env   "PYTHONPATH"    "${pkg_prefix}/lib/python${python_major_version}/site-packages"
  set_runtime_env -f "FLASK_APP"     "$pkg_prefix/flask/app.py"
  set_runtime_env -f "LANG"          "$pkg_lang"
  set_runtime_env -f "SSL_CERT_FILE" "$(pkg_path_for core/cacerts)/ssl/cert.pem"
  return $?
}


do_prepare() {
  _record_pkg_metadata
  pip install --quiet --progress-bar="off" --upgrade "pip" "virtualenv"
  virtualenv "$pkg_prefix"
  source "$pkg_prefix/bin/activate"
  return $?
}


do_build() {
  build_line "Installing Pip module dependencies to $pkg_prefix/lib/python${python_major_version}/site-packages"
  pip install --requirement="$PLAN_CONTEXT/../flask/requirements.txt" --progress-bar="off"
  return $?
}


do_install() {
  build_line "Installing Flask app to $pkg_prefix..."
  cp --verbose --preserve --recursive \
    "$PLAN_CONTEXT/../flask" "$pkg_prefix/flask"
  mkdir --parents "$pkg_prefix/hooks/"  # TODO: find a cleaner way to inherit templates
  cp --interactive --verbose --preserve --recursive \
    $(hab pkg path "smartb/flask_rigging")/hooks/* "$pkg_prefix/hooks/"
  return $?
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
  fi
  return $?
}


do_after_success() {
  if [ ! -z $pkg_channel ]
  then
    build_line "INFO: Promoting $pkg_ident to the $pkg_channel Builder channel because \$pkg_channel has been set"
    _promote_pkg "$pkg_channel"
  fi
  return $?
}
