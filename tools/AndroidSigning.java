import java.io.InputStream;
import java.nio.file.Path;
import java.security.KeyStore;
import java.security.MessageDigest;
import java.security.PrivateKey;
import java.security.cert.Certificate;
import java.util.Arrays;
import java.util.HexFormat;
import java.util.jar.JarFile;

/** Checks the private key before building and every signed AAB entry afterwards. */
class AndroidSigning {
    private static String env(String name) {
        String value = System.getenv(name);
        if (value == null || value.isEmpty()) throw new IllegalArgumentException();
        return value;
    }

    public static void main(String[] args) {
        try {
            char[] storePassword = env("ANDROID_KEYSTORE_PASSWORD").toCharArray();
            char[] keyPassword = env("ANDROID_KEY_PASSWORD").toCharArray();
            KeyStore store;
            try {
                store = KeyStore.getInstance(Path.of(env("ANDROID_KEYSTORE_PATH")).toFile(), storePassword);
            } finally {
                Arrays.fill(storePassword, '\0');
            }
            String alias = env("ANDROID_KEY_ALIAS");
            try {
                if (!(store.getKey(alias, keyPassword) instanceof PrivateKey)) {
                    throw new IllegalArgumentException();
                }
            } finally {
                Arrays.fill(keyPassword, '\0');
            }
            Certificate expected = store.getCertificate(alias);
            if (expected == null) throw new IllegalArgumentException();
            String fingerprint = HexFormat.of().withUpperCase().formatHex(
                MessageDigest.getInstance("SHA-256").digest(expected.getEncoded()));
            if (args.length == 1) {
                // Reading each entry completely triggers Java's cryptographic verification.
                try (JarFile jar = new JarFile(args[0], true)) {
                    boolean manifestFound = false;
                    var entries = jar.entries();
                    byte[] buffer = new byte[65536];
                    while (entries.hasMoreElements()) {
                        var entry = entries.nextElement();
                        if (entry.isDirectory()) continue;
                        try (InputStream input = jar.getInputStream(entry)) {
                            while (input.read(buffer) != -1) { }
                        }
                        String name = entry.getName();
                        // Only signing metadata may lack its own signer.
                        if (name.matches("(?i)META-INF/(MANIFEST\\.MF|[^/]+\\.(SF|RSA|DSA|EC))")) continue;
                        var signers = entry.getCodeSigners();
                        if (signers == null || signers.length != 1 || !expected.equals(
                                signers[0].getSignerCertPath().getCertificates().get(0))) {
                            throw new SecurityException();
                        }
                        if (name.equals("base/manifest/AndroidManifest.xml")) manifestFound = true;
                    }
                    if (!manifestFound) throw new SecurityException();
                }
            } else if (args.length != 0) {
                throw new IllegalArgumentException();
            }
            System.out.println(fingerprint);
        } catch (Exception exception) {
            // Never include exception messages: providers can echo credential-related data.
            System.err.println(args.length == 0
                ? "No se pudo abrir la clave privada. Revisa keystore, alias y ambas contraseñas."
                : "El AAB no tiene una firma íntegra del certificado esperado en todas sus entradas.");
            System.exit(1);
        }
    }
}
