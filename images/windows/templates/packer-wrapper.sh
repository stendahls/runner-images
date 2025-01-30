#!/bin/bash

#
# Echo:
#  env_name vault-path property 
# for each env we need to set
ls_envs () {
    cat <<EOF
VCENTER_USERNAME secret/infrastructure/system/vcenter/Administrator username
VCENTER_PASSWORD secret/infrastructure/system/vcenter/Administrator password
ACT_RUNNER_USERNAME secret/infrastructure/common/act_runner username
ACT_RUNNER_PASSWORD secret/infrastructure/common/act_runner password
ACT_INSTALLER_USERNAME secret/infrastructure/common/act_installer username
ACT_INSTALLER_PASSWORD secret/infrastructure/common/act_installer password
ADMIN_PASSWORD secret/infrastructure/common/Administrator password
PRODUCT_KEY secret/product/windows/server2022 product_key
EOF
}

set_envs () {
    local env_name path prop v
    while read env_name path prop; do
        v=$(vault read -field="$prop" "$path")
        eval export ${env_name}="$v"
    done < <(ls_envs)
}

echo_vars () {
    local env_name path prop var_name
    while read env_name path prop; do
        var_name=$(echo "$env_name" | tr A-Z a-z)
        cat <<EOF
variable "$var_name" {
  type = string
  default = "\${env("${env_name}")}"
EOF
        case $var_name in
            *password|*key)
                cat <<EOF
  sensitive = true
EOF
            ;;
            *)
                ;;
        esac
        cat <<EOF
}

EOF
    done < <(ls_envs)
}

set_envs

exec packer "$@"
