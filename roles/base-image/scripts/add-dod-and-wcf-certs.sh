#!/bin/bash
# Import DoD root and WCF certificates into linux CA store


    # Location of bundles
    dodbundle='/usr/local/share/certificates_pkcs7_DoD.zip'
    wcfbundle='/usr/local/share/certificates_pkcs7_WCF.zip'


    # Download the DoD certificate bundle from the specified URL and save it in the "bundle" directory
    curl -o "$dodbundle" "https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_DoD.zip"
    curl -o "$wcfbundle" "https://dl.dod.cyber.mil/wp-content/uploads/pki-pke/zip/unclass-certificates_pkcs7_WCF.zip"

    certdir='/etc/pki/ca-trust/source/anchors'
    update='update-ca-trust'

    echo $PWD
    cd $certdir
    echo $PWD
    mkdir tmp
    cp $dodbundle tmp
    cp $wcfbundle tmp
    unzip -qj -o tmp/${dodbundle##*/} -d tmp
    unzip -qj -o tmp/${wcfbundle##*/} -d tmp

    # Convert the PKCS#7 bundle into individual PEM files
    for input_file in tmp/*der.p7b; do
        openssl pkcs7 -inform DER -print_certs -in "$input_file" -out "${input_file%.p7b}.pem"
        # Set permissions on extracted files to 0644
        chmod 0644 "${input_file%.p7b}.pem"
    done

    # Rename the files based on the CA name
    for i in tmp/*.pem; do
        name=$(openssl x509 -noout -subject -in $i |
               awk -F '(=|= )' '{gsub(/ /, "_", $NF); print $NF}'
        )
        mv $i ${name}.crt
    done


    # Remove temp files and update certificate stores
    rm -fr tmp
    rm -fr $dodbundle
    rm -fr $wcfbundle
    $update