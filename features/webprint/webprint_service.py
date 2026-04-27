import requests as req
from bs4 import BeautifulSoup
from dotenv import load_dotenv
import urllib3.contrib.pyopenssl as pyopenssl
from requests_toolbelt import MultipartEncoder
import certifi
import json

pyopenssl.inject_into_urllib3()# OpenSSLをurllib3に注入
load_dotenv()
import os

from .encripter import encrypt_for_meijo as encrypt_message

class webprint:
   hostname = "https://ccmoon2.meijo-u.ac.jp"
   baseurl = ""
   session:req.Session=None
   defaultformat = {
            "user_id":"0000",
            "queue_id":"web-ondemand",
            "ip":"0.0.0.0",
            "paper_type":"06",
            "duplex_type":"1",
            "color_mode_type":"1",
            "copies":"1",
            "number_up":"1",
            "orientation_edge":"1",
            "print_orientation":"2",
            "page_sort":"1"
   }
   
   def __init__(self,session:req.Session,baseurl:str,url_printservice:str=""):
      self.session = session
      self.baseurl = baseurl
      self.ipaddress = ""
      if url_printservice != "":
         self.get_printservice_page(url_printservice)
         self.authentic_user()
         self.get_own_ipaddress()
      
   def get_printservice_page(self,url):
      res = self.session.get(url,
         verify=certifi.where(),
         allow_redirects=False,
      )
      if(res.status_code != 200):
         return None
      with open("print_service_page.html","w") as f:
         f.write(res.text)
      return res.text
   
   def __get_pubkey__(self):
      res = self.session.get(self.hostname+self.baseurl+"user/f5-h-$$/api/auth/getpubkey")
      if res.status_code != 200:
         raise Exception("公開鍵の取得に失敗しました。\nstatus code:"+str(res.status_code)+"\nurl:"+self.hostname+self.baseurl+"user/f5-h-$$/api/auth/getpubkey")
      pubkey_json = res.json()
      raw = pubkey_json["pubkey"].strip()
      if raw.startswith("-----BEGIN PUBLIC KEY-----") and "-----END PUBLIC KEY-----" in raw:
         head = "-----BEGIN PUBLIC KEY-----"
         tail = "-----END PUBLIC KEY-----"
         body = raw.replace(head, "").replace(tail, "")
         body = body.strip()

         # 64 文字ごとに改行すると PEM 形式らしくなります
         wrapped = "\n".join(body[i:i+64] for i in range(0, len(body), 64))
         pubkey_pem = f"{head}\n{wrapped}\n{tail}\n"
      else:
         raise ValueError("公開鍵の形式が不正です")
      return pubkey_pem
   
   def encript_userinfo(self,username=os.getenv("USERNAME"),password=os.getenv("PASSWORD"),pubkey_pem=""):
      if(pubkey_pem == ""):
         pubkey_pem = self.__get_pubkey__()
      encrypted_username = encrypt_message(username,pubkey_pem)
      encrypted_password = encrypt_message(password,pubkey_pem)
      return {"user_id":encrypted_username,"user_password":encrypted_password}
   
   #/api/auth/authuserenc
   def authentic_user(self,username=os.getenv("USERNAME"),password=os.getenv("PASSWORD")):
      res = self.session.post(self.hostname+self.baseurl+"user/f5-h-$$/api/auth/authuserenc",
         json=self.encript_userinfo(username,password),
         verify=certifi.where(),
         allow_redirects=False,
         headers={
            "Content-Type":"application/json"
         }
      )
      if res.status_code != 200:
         raise Exception("ユーザ認証に失敗しました。\nstatus code:"+str(res.status_code)+"\nurl:"+self.hostname+self.baseurl+"user/f5-h-$$/api/auth/authuserenc")
      auth_json = res.json()
      if auth_json["result"] != "ok":
         return None
      return auth_json["result"]
   
   #user/f5-h-$$/api/system/settings
   def get_settings(self):
      res = self.session.get(self.hostname+self.baseurl+"user/f5-h-$$/api/system/settings",
         verify=certifi.where(),
         allow_redirects=False,
      )
      if res.status_code != 200:
         raise Exception("プリント設定の取得に失敗しました。\nstatus code:"+str(res.status_code)+"\nurl:"+self.hostname+self.baseurl+"user/f5-h-$$/api/print/getsettings")
      settings_json = res.json()
      with open("settings.json","w") as f:
         import json
         json.dump(settings_json,f,ensure_ascii=False,indent=4)
      return settings_json
   
   #user/f5-h-$$/api/user/users/241205181?type=1
   def get_userinfo(self,user_id="",type=1):
      res = self.session.get(self.hostname+self.baseurl+f"user/f5-h-$$/api/user/users/{user_id}?type={type}",
         verify=certifi.where(),
         allow_redirects=False,
      )
      if res.status_code != 200:
         raise Exception("ユーザ情報の取得に失敗しました。\nstatus code:"+str(res.status_code)+"\nurl:"+self.hostname+self.baseurl+f"user/f5-h-$$/api/user/users/{user_id}?type={type}")
      userinfo_json = res.json()
      with open(f"{user_id}_info.json","w") as f:
         import json
         json.dump(userinfo_json,f,ensure_ascii=False,indent=4)
      return userinfo_json
   
   #user/f5-h-$$/api/system/notice/ownipaddress
   def get_own_ipaddress(self):
      res = self.session.get(self.hostname+self.baseurl+"user/f5-h-$$/api/system/notice/ownipaddress",
         verify=certifi.where(),
         allow_redirects=False,
      )
      if res.status_code != 200:
         raise Exception("自分のIPアドレスの取得に失敗しました。\nstatus code:"+str(res.status_code)+"\nurl:"+self.hostname+self.baseurl+"user/f5-h-$$/api/system/notice/ownipaddress")
      ipaddress_json = res.json()
      self.ipaddress = ipaddress_json["ip_address"]
      return ipaddress_json["ip_address"]
   
   def pdf_print(self,filename,printdatapath,printformat):
      #print("プリントの実行")
      json_bytes = json.dumps(printformat).encode("utf-8")
      m = MultipartEncoder(
         fields={
               "data" : ("blob",json_bytes,"application/json"),
               "files" : (filename,open(printdatapath,"rb"),"application/pdf")
         },
         boundary="------geckoformboundary62e25ce6ff5a54f51fd44a79a4e0408c"
      )
      headers = {
         "Content-Type": m.content_type
      }
      res = self.session.post(self.hostname+self.baseurl+"user/f5-h-$$/api/spool01/files/webprint",
         data=m,
         headers=headers,
         verify=certifi.where(),
         allow_redirects=False,
      )
      return res.status_code