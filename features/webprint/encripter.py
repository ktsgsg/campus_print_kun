import base64
from Crypto.PublicKey import RSA
from Crypto.Cipher import PKCS1_v1_5 # OAEPから変更

def encrypt_for_meijo(message, public_key_pem):
   # 1. 公開鍵を読み込む
   recipient_key = RSA.import_key(public_key_pem)
   
   # 2. ブラウザと同じ PKCS#1 v1.5 パディングを使用する
   cipher_rsa = PKCS1_v1_5.new(recipient_key)
   
   # 3. 暗号化を実行
   encrypted_data = cipher_rsa.encrypt(message.encode('utf-8'))
   
   # 4. Base64でエンコード
   return base64.b64encode(encrypted_data).decode('utf-8')