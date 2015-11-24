#!/bin/bash
set -o pipefail
cd "${SRC_DIR}"

# Determine the R and PostgreSQL versions; these will be used to construct the
# conda package build string, as well as provide hints to building the package
# itself on certain target platforms (e.g., CentOS/RHEL).
r_ver=$(R --version | head -n1 | awk '{print $3;}')
[ -z "$r_ver" ] && \
    { echo "ERROR: Could not get R version." >&2; exit 1; }
pg_ver=$(psql --version | awk -F'[ .]' '{print $3"."$4;}')
[ -z "$pg_ver" ] && \
    { echo "ERROR: Could not get PostgreSQL version." >&2; exit 1;}

# Might need some help on Linux systems to find where PostgreSQL is installed;
# especially true if we're using pgdg's and not a distro vendor's package.
if [ `uname -s` == 'Linux' ]; then
    # Try to "pg_config" in our standard PATH; this should be installed by
    # the PostgreSQL "devel" package appropriate for the distribution.
    set +e
    pg_config=$(command -v pg_config 2>/dev/null)
    set -e

    # Where pgdg installs newer PostgreSQL versions on RedHat-based systems
    if [[ -z "$pg_config" && -x "/usr/pgsql-${pg_ver}/bin/pg_config" ]]; then
        export PATH="/usr/pgsql-${pg_ver}/bin:$PATH"
    else
        echo "WARNING: Could not find pg_config! Trying build anyways..." >&2
    fi
fi

$R CMD INSTALL --build .

# Generate build string based on R and PostgreSQL versions
[ $PKG_BUILDNUM != "" ] || PKG_BUILDNUM=0
echo "r${r_ver}_pg${pg_ver}_${PKG_BUILDNUM}" > "__conda_buildstr__.txt"
