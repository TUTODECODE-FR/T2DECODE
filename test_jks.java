import java.io.*;
import java.security.*;

public class test_jks {
    public static void main(String[] args) throws Exception {
        File f = new File("fake.jks");
        FileOutputStream fos = new FileOutputStream(f);
        fos.write(new byte[]{(byte)0xFE, (byte)0xED, (byte)0xFE, (byte)0xED});
        fos.close();

        try {
            KeyStore ks = KeyStore.getInstance("PKCS12");
            ks.load(new FileInputStream("fake.jks"), "password".toCharArray());
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
