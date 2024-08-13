function isSupported() {
    return window.PublicKeyCredential;
}

async function getPasskey(optionsJson) {
    if (!optionsJson) {
        return null;
    }
    credentialRequestOptions = JSON.parse(optionsJson);

    credentialRequestOptions.publicKey.challenge = bufferDecode(credentialRequestOptions.publicKey.challenge);
    if (credentialRequestOptions.publicKey.allowCredentials) {
        for (var i = 0; i < credentialRequestOptions.publicKey.allowCredentials.length; i++) {
            credentialRequestOptions.publicKey.allowCredentials[i].id = bufferDecode(credentialRequestOptions.publicKey.allowCredentials[i].id);
        }
    }

    const assertion = await navigator.credentials.get({
        publicKey: credentialRequestOptions.publicKey
    });

    let authData = assertion.response.authenticatorData;
    let clientDataJSON = assertion.response.clientDataJSON;
    let rawId = assertion.rawId;
    let sig = assertion.response.signature;
    let userHandle = assertion.response.userHandle;

    return JSON.stringify({
        id: assertion.id,
        rawId: bufferEncode(rawId),
        type: assertion.type,
        response: {
           authenticatorData: bufferEncode(authData),
           clientDataJSON: bufferEncode(clientDataJSON),
           signature: bufferEncode(sig),
           userHandle: bufferEncode(userHandle),
        },
    });
}

async function createPasskey(optionsJson) {
    if (!optionsJson) {
        return null;
    }
    credentialCreationOptions = JSON.parse(optionsJson);

    challenge = String(credentialCreationOptions.publicKey.challenge);
    userId = String(credentialCreationOptions.publicKey.user.id);
    credentialCreationOptions.publicKey.challenge = bufferDecode(challenge);
    credentialCreationOptions.publicKey.user.id = bufferDecode(userId);
    if (credentialCreationOptions.publicKey.excludeCredentials) {
        for (var i = 0; i < credentialCreationOptions.publicKey.excludeCredentials.length; i++) {
            credentialCreationOptions.publicKey.excludeCredentials[i].id = bufferDecode(credentialCreationOptions.publicKey.excludeCredentials[i].id);
        }
    }

    const credential = await navigator.credentials.create({
        publicKey: credentialCreationOptions.publicKey
    });

    let attestationObject = credential.response.attestationObject;
    let clientDataJSON = credential.response.clientDataJSON;
    let rawId = credential.rawId;

    return JSON.stringify({
        id: credential.id,
        rawId: bufferEncode(rawId),
        type: credential.type,
        response: {
            attestationObject: bufferEncode(attestationObject),
            clientDataJSON: bufferEncode(clientDataJSON),
        },
    });
}

// Base64 to ArrayBuffer
function bufferDecode(value) {
    return Uint8Array.from(atob(value.replace(/_/g, '/').replace(/-/g, '+')), c => c.charCodeAt(0));
}

// ArrayBuffer to URLBase64
function bufferEncode(value) {
    return btoa(String.fromCharCode.apply(null, new Uint8Array(value)))
        .replace(/\+/g, "-")
        .replace(/\//g, "_")
        .replace(/=/g, "");
}