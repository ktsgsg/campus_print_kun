from bs4 import BeautifulSoup
import html as html_lib
import requests as req
from dotenv import load_dotenv
import urllib3.contrib.pyopenssl as pyopenssl
import certifi

pyopenssl.inject_into_urllib3()# OpenSSLをurllib3に注入
load_dotenv()
import os

from . import F5_ST, auth_token
def connect_ccmoon(username=None,password=None):
   if username is None:
      username = os.getenv("USERID")
   if password is None:
      password = os.getenv("PASSWORD")
   #ccmoonに接続
   session,html = get_ccmoon_session(username,password)
   #SAMLResponseを送信
   session = SendSAMLResponse(session,html)
   # F5_ST cookieを設定
   F5_ST_value = F5_ST.gen_f5_st(session.cookies.get("F5_ST"))
   ccmoon_domain = "ccmoon2.meijo-u.ac.jp"
   cookie_path = "/"
   session.cookies.clear(domain=ccmoon_domain, path=cookie_path, name="F5_ST")
   session.cookies.set("F5_ST", F5_ST_value, domain=ccmoon_domain, path=cookie_path)
   session.cookies.set("TIN", "18000", domain=ccmoon_domain, path=cookie_path)
   session.cookies.set("F5_fullWT", "1", domain=ccmoon_domain, path=cookie_path)
   return session
def get_baseurl():
   with open("ccmoon_webtop.html","r") as f:
      for line in f:
         if 'var ur_baseurl=' in line:
            baseurl = line.split("'")[1]
            return baseurl
   return baseurl
def SendSAMLResponse(session:req.Session,html:str):
   soup = BeautifulSoup(html, 'html.parser')
   form = soup.find_all('form')[0]
   #送信先などの様々なurlを取得
   action_url = html_lib.unescape(form.get('action'))#SAMLResponse送信先URL,エンコードされているのでデコードする
   SAML_Response = form.find('input', {'name': 'SAMLResponse'}).get('value')#SAMLResponseの値を取得
   # SAMLResponseを送信
   res = session.post(action_url,
      data={
         'SAMLResponse': SAML_Response
      },
      verify=certifi.where(),
      allow_redirects=False
   )
   location = "https://ccmoon2.meijo-u.ac.jp"+res.headers["Location"]
   res1 = session.get(location,
      verify=certifi.where(),
      allow_redirects=False
   )
   return session
def get_ccmoon_session(username,password):
   ccmoono_baseurl = "https://ccmoon2.meijo-u.ac.jp"
   token = auth_token.getToken(username,password)
   # セッションを作成してcookieを自動管理
   session = req.Session()
   # 初期cookieを設定
   session.cookies.set("iPlanetDirectoryPro", token)
   #一番最初のアクセス
   res0 = session.get("https://slbsso.meijo-u.ac.jp/opensso/sso.jsp?app=ccmoon",
      verify=certifi.where(),
      allow_redirects=False
   )
   
   res = session.get(res0.headers["Location"],
      verify=certifi.where(),
      allow_redirects=False
   )
   res2 = session.get(ccmoono_baseurl+res.headers['Location'],
      verify=certifi.where(),
      allow_redirects=False
   )
   if(res2.status_code != 302):
      raise Exception("ccmoonへの接続に失敗しました")
   
   raw_location = res2.headers['Location']
   req3 = req.Request('GET', raw_location)
   prepared = session.prepare_request(req3)
   # requestsが勝手に書き換えるのを防ぐため、urlを直接上書きする
   prepared.url = raw_location 
   res3 = session.send(prepared, verify=certifi.where(), allow_redirects=False)

   if(res3.status_code != 200):
      raise Exception("ccmoonへの接続に失敗しました")
   
   return session,res3.text