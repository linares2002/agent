from cryptography.fernet import Fernet
import base64, hashlib, sys

if len(sys.argv) != 4 or sys.argv[1] not in ("enc", "dec"):
    print("Uso:")
    print("  python crypt.py enc archivo.txt miClave")
    print("  python crypt.py dec archivo.txt.enc miClave")
    sys.exit(1)

modo, archivo, clave = sys.argv[1], sys.argv[2], sys.argv[3]
key = base64.urlsafe_b64encode(hashlib.sha256(clave.encode()).digest())
f = Fernet(key)

if modo == "enc":
    data = f.encrypt(open(archivo, "rb").read())
    open(archivo + ".enc", "wb").write(data)
    print("✓ Encriptado:", archivo + ".enc")
elif modo == "dec":
    data = f.decrypt(open(archivo, "rb").read())
    open(archivo.replace(".enc", ""), "wb").write(data)
    print("✓ Desencriptado:", archivo.replace(".enc", ""))