RETRY_TIME=5
MAX_RETRIES=3
SECRET_NAME="helm-secret"
NAMESPACE="kyma-installer"

function kyma-init {
    mkdir -p "$(helm home)"
    echo "---> Finding Helm secret..."
    for i in $(seq 1 "${MAX_RETRIES}"); do _findHelmSecret && break || _tiller-defer "${i}" || _tiller-fail ; done
    echo "---> Helm secret found. Saving Helm certificates under the \"$(helm home)\" directory..."
    _saveCerts
    
    echo "----------"
    tmpfile=$(mktemp /tmp/temp-cert.XXXXXX) \
	&& kubectl get configmap net-global-overrides -n kyma-installer -o jsonpath='{.data.global\.ingress\.tlsCrt}' | base64 --decode > $tmpfile \
	&& sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain $tmpfile \
	&& rm $tmpfile
    kubectl get virtualservice core-console -n kyma-system -o jsonpath='{ .spec.hosts[0] }'
    echo ""
    kubectl get secret admin-user -n kyma-system -o jsonpath="{.data.password}" | base64 --decode
    echo ""
}


function _findHelmSecret() {
    kubectl get -n "${NAMESPACE}" secret "${SECRET_NAME}" > /dev/null
}


function _tiller-defer() {
    local current="${1}"
    if [[ "${current}" -eq "${MAX_RETRIES}" ]]; then return 1; fi
    echo "---> Retrying in ${RETRY_TIME} seconds..."
    sleep "${RETRY_TIME}"
}


function _tiller-fail() {
    echo "---> Warning! Unable to find Helm secret: timeout."
    exit 1
}

function _saveCerts {
    kubectl get -n "${NAMESPACE}" secret "${SECRET_NAME}" -o jsonpath="{.data['global\\.helm\\.ca\\.crt']}" | base64 --decode > "$(helm home)/ca.pem"
    kubectl get -n "${NAMESPACE}" secret "${SECRET_NAME}" -o jsonpath="{.data['global\\.helm\\.tls\\.crt']}" | base64 --decode > "$(helm home)/cert.pem"
    kubectl get -n "${NAMESPACE}" secret "${SECRET_NAME}" -o jsonpath="{.data['global\\.helm\\.tls\\.key']}" | base64 --decode > "$(helm home)/key.pem"
}
